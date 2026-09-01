import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:retroachievements/cache.dart';
import 'package:retroachievements/hash.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';

/// Computes the MD5 checksums of a ROM/disc file using the shared RetroAchievements rhash implementation.
Future<RcHashResult?> computeRomMd5(String filePath, {int? consoleId}) async {
  return Isolate.run(() async {
    try {
      return await rcHashCompute(path: filePath, consoleId: consoleId);
    } catch (e, stack) {
      debugPrint(
        '[RA Hasher] Error computing ROM MD5 for $filePath: $e\n$stack',
      );
      return null;
    }
  });
}

/// Resolves a Titanius [Game] against the embedded RetroAchievements hash cache.
/// Returns the matched or cached [GameRetroAchievements] record from SQLite.
Future<GameRetroAchievements?> resolveGameRetroAchievements({
  required Game game,
  required GameRetroAchievementsRepo repo,
  bool forceRehash = false,
}) async {
  if (!game.system.hasRetroAchievements) {
    return null;
  }

  final cached = await repo.getEntry(game.romPath);
  if (cached != null && !forceRehash) {
    return cached;
  }

  final consoleId = game.system.retroAchievementsId;
  debugPrint('[RA Matcher] Hashing "${game.name}" (${game.romPath})...');
  final hashResult = await computeRomMd5(
    game.absoluteRomPath,
    consoleId: consoleId,
  );
  if (hashResult == null) {
    debugPrint(
      '[RA Matcher] Could not hash "${game.name}" at "${game.absoluteRomPath}"',
    );
    await repo.saveEntry(
      romPath: game.romPath,
      md5Hash: '',
      raGameId: null,
      numAchievements: 0,
      points: 0,
    );
    return repo.getEntry(game.romPath);
  }
  var match = RaCache.findByHash(hashResult.primaryHash, consoleId: consoleId);
  var usedHash = hashResult.primaryHash;

  if (match == null && hashResult.alternateHashes.isNotEmpty) {
    for (final alt in hashResult.alternateHashes) {
      match = RaCache.findByHash(alt, consoleId: consoleId);
      if (match != null) {
        usedHash = alt;
        debugPrint(
          '[RA Matcher] Matched "${game.name}" using alternate hash ($alt)!',
        );
        break;
      }
    }
  }

  // Fallback check across all consoles if not found in specific console
  if (match == null) {
    for (final h in hashResult.allHashes) {
      final anyConsoleMatch = RaCache.findByHash(h);
      if (anyConsoleMatch != null) {
        match = anyConsoleMatch;
        usedHash = h;
        debugPrint(
          '[RA Matcher] Matched "${game.name}" in console ID ${anyConsoleMatch.consoleId} (expected $consoleId)',
        );
        break;
      }
    }
  }

  final raGameId = match?.id;
  final numAchievements = match?.numAchievements ?? 0;
  final points = match?.points ?? 0;
  final raTitle = match?.title;
  final badgeUrl = match?.imageIcon;

  if (match != null) {
    debugPrint(
      '[RA Matcher] [MATCH] "${game.name}" -> RA ID: $raGameId, Title: "$raTitle", Achievements: $numAchievements, Points: $points (MD5: $usedHash)',
    );
  } else {
    debugPrint(
      '[RA Matcher] [NO MATCH] "${game.name}" (MD5: ${hashResult.primaryHash}, Console ID: $consoleId)',
    );
  }

  await repo.saveEntry(
    romPath: game.romPath,
    md5Hash: usedHash,
    raGameId: raGameId,
    numAchievements: numAchievements,
    points: points,
    raTitle: raTitle,
    badgeUrl: badgeUrl,
  );

  return repo.getEntry(game.romPath);
}

/// Scans all un-cached games for a system in the background and populates SQLite.
Future<void> scanSystemRetroAchievements({
  required System system,
  required List<Game> games,
  required GameRetroAchievementsRepo repo,
  void Function()? onUpdated,
}) async {
  if (!system.hasRetroAchievements || games.isEmpty) {
    return;
  }

  final cachedMap = await repo.getEntriesForSystem(system, games);
  final unCached = games
      .where((g) => !g.isFolder && !cachedMap.containsKey(g.romPath))
      .toList();

  if (unCached.isEmpty) {
    debugPrint(
      '[RA Scanner] All ${games.length} games in "${system.name}" are already cached in SQLite.',
    );
    return;
  }

  debugPrint(
    '[RA Scanner] Scanning ${unCached.length} un-cached games in "${system.name}" (Console ID: ${system.retroAchievementsId})...',
  );

  int matchedCount = 0;
  for (final game in unCached) {
    final res = await resolveGameRetroAchievements(game: game, repo: repo);
    if (res?.raGameId != null && (res?.numAchievements ?? 0) > 0) {
      matchedCount++;
      onUpdated?.call();
    }
  }

  debugPrint(
    '[RA Scanner] Finished scan for "${system.name}". Found $matchedCount new games with achievements.',
  );
  onUpdated?.call();
}
