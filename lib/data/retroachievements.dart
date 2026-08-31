import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retroachievements/retroachievements.dart';
import 'package:titanius/data/repo.dart';

export 'package:retroachievements/retroachievements.dart' hide Game, GameList;
export 'package:retroachievements/cache.dart';

final retroAchievementsAuthProvider = Provider<AuthObject?>((ref) {
  final credentials = ref.watch(
    settingsProvider.select(
      (settings) => (
        username: settings.value?.retroAchievementsUser,
        apiKey: settings.value?.retroAchievementsApiKey,
      ),
    ),
  );
  if (credentials.username == null ||
      credentials.username!.trim().isEmpty ||
      credentials.apiKey == null ||
      credentials.apiKey!.trim().isEmpty) {
    return null;
  }
  try {
    return buildAuthorization(
      username: credentials.username!,
      webApiKey: credentials.apiKey!,
    );
  } catch (e) {
    debugPrint("Failed to build RA authorization: $e");
    return null;
  }
});

Future<UserSummary?> _fetchAndCacheUserSummary(
  AuthObject auth,
  RetroAchievementsCacheRepo cacheRepo,
) async {
  try {
    final url = buildRequestUrl(
      apiBaseUrl,
      '/API_GetUserSummary.php',
      auth,
      args: {'u': auth.username, 'g': 5, 'a': 5},
    );
    final rawResponse = await call(url: url);
    if (rawResponse is! Map) {
      debugPrint(
        "RA API returned non-map response for user summary: $rawResponse",
      );
      return null;
    }
    final sanitized =
        serializeProperties(
              rawResponse,
              shouldCastToNumbers: [
                'RecentlyPlayedCount',
                'Points',
                'SoftcorePoints',
                'MemberSince',
                'TotalRank',
                'TotalSoftcoreRank',
                'ID',
                'NumAwarded',
                'NumAwardedHardcore',
                'TrueRatio',
                'DisplayOrder',
              ],
            )
            as Map<String, dynamic>;
    final summary = UserSummary.fromJson(sanitized);
    await cacheRepo.putCache(
      'user_summary_${auth.username}',
      json.encode(sanitized),
    );
    return summary;
  } catch (e, stack) {
    debugPrint("Failed to fetch RA user summary: $e\n$stack");
    return null;
  }
}

Future<UserAwards?> _fetchAndCacheUserAwards(
  AuthObject auth,
  RetroAchievementsCacheRepo cacheRepo,
) async {
  try {
    final url = buildRequestUrl(
      apiBaseUrl,
      '/API_GetUserAwards.php',
      auth,
      args: {'u': auth.username},
    );
    final rawResponse = await call(url: url);
    if (rawResponse is! Map) {
      debugPrint(
        "RA API returned non-map response for user awards: $rawResponse",
      );
      return null;
    }
    final sanitized =
        serializeProperties(
              rawResponse,
              shouldCastToNumbers: [
                'TotalAwardsCount',
                'HiddenAwardsCount',
                'MasteryAwardsCount',
                'CompletionAwardsCount',
                'BeatenHardcoreAwardsCount',
                'BeatenSoftcoreAwardsCount',
                'EventAwardsCount',
                'SiteAwardsCount',
                'AwardID',
                'AwardData',
                'AwardDataExtra',
                'DisplayOrder',
              ],
            )
            as Map<String, dynamic>;
    final cacheKey = 'user_awards_${auth.username}';
    await cacheRepo.putCache(cacheKey, json.encode(sanitized));
    return UserAwards.fromJson(sanitized);
  } catch (e, stack) {
    debugPrint("Failed to fetch RA user awards: $e\n$stack");
    return null;
  }
}

Future<UserCompletionProgress?> _fetchAndCacheUserCompletionProgress(
  AuthObject auth,
  RetroAchievementsCacheRepo cacheRepo,
) async {
  try {
    final url = buildRequestUrl(
      apiBaseUrl,
      '/API_GetUserCompletionProgress.php',
      auth,
      args: {'u': auth.username, 'o': 0, 'c': 500},
    );
    final rawResponse = await call(url: url);
    if (rawResponse is! Map) {
      debugPrint(
        "RA API returned non-map response for user completion progress: $rawResponse",
      );
      return null;
    }
    final sanitized =
        serializeProperties(
              rawResponse,
              shouldCastToNumbers: [
                'Count',
                'Total',
                'GameID',
                'ConsoleID',
                'MaxPossible',
                'NumAwarded',
                'NumAwardedHardcore',
              ],
            )
            as Map<String, dynamic>;
    final cacheKey = 'user_completion_progress_${auth.username}';
    await cacheRepo.putCache(cacheKey, json.encode(sanitized));
    return UserCompletionProgress.fromJson(sanitized);
  } catch (e, stack) {
    debugPrint("Failed to fetch RA user completion progress: $e\n$stack");
    return null;
  }
}

final retroAchievementsUserSummaryProvider = FutureProvider<UserSummary?>((
  ref,
) async {
  final auth = ref.watch(retroAchievementsAuthProvider);
  if (auth == null) {
    return null;
  }
  final cacheRepo = ref.watch(retroAchievementsCacheRepoProvider);
  final cacheKey = 'user_summary_${auth.username}';

  // 1. Fresh cache (< 24h) returns immediately
  final cached = await cacheRepo.getValidCache(cacheKey);
  if (cached != null) {
    try {
      final jsonMap = json.decode(cached) as Map<String, dynamic>;
      return UserSummary.fromJson(jsonMap);
    } catch (e) {
      debugPrint("Failed to parse cached user summary: $e");
    }
  }

  // 2. Stale cache (> 24h) returns immediately and silently refreshes in background
  final stale = await cacheRepo.getAnyCache(cacheKey);
  if (stale != null) {
    unawaited(() async {
      try {
        final fresh = await _fetchAndCacheUserSummary(auth, cacheRepo);
        if (fresh != null) {
          ref.invalidateSelf();
        }
      } catch (e) {
        debugPrint("Background refresh of user summary failed: $e");
      }
    }());
    try {
      return UserSummary.fromJson(json.decode(stale) as Map<String, dynamic>);
    } catch (_) {}
  }

  // 3. No cache at all: fetch synchronously from API
  return await _fetchAndCacheUserSummary(auth, cacheRepo);
});

final retroAchievementsUserAwardsProvider = FutureProvider<UserAwards?>((
  ref,
) async {
  final auth = ref.watch(retroAchievementsAuthProvider);
  if (auth == null) {
    return null;
  }
  final cacheRepo = ref.watch(retroAchievementsCacheRepoProvider);
  final cacheKey = 'user_awards_${auth.username}';

  // 1. Fresh cache (< 24h) returns immediately
  final cached = await cacheRepo.getValidCache(cacheKey);
  if (cached != null) {
    try {
      final jsonMap = json.decode(cached) as Map<String, dynamic>;
      return UserAwards.fromJson(jsonMap);
    } catch (e) {
      debugPrint("Failed to parse cached user awards: $e");
    }
  }

  // 2. Stale cache (> 24h) returns immediately and silently refreshes in background
  final stale = await cacheRepo.getAnyCache(cacheKey);
  if (stale != null) {
    unawaited(() async {
      try {
        final fresh = await _fetchAndCacheUserAwards(auth, cacheRepo);
        if (fresh != null) {
          ref.invalidateSelf();
        }
      } catch (e) {
        debugPrint("Background refresh of user awards failed: $e");
      }
    }());
    try {
      return UserAwards.fromJson(json.decode(stale) as Map<String, dynamic>);
    } catch (_) {}
  }

  // 3. No cache at all: fetch synchronously from API
  return await _fetchAndCacheUserAwards(auth, cacheRepo);
});

final retroAchievementsUserCompletionProgressProvider =
    FutureProvider<UserCompletionProgress?>((ref) async {
      final auth = ref.watch(retroAchievementsAuthProvider);
      if (auth == null) {
        return null;
      }
      final cacheRepo = ref.watch(retroAchievementsCacheRepoProvider);
      final cacheKey = 'user_completion_progress_${auth.username}';

      // 1. Fresh cache (< 24h) returns immediately
      final cached = await cacheRepo.getValidCache(cacheKey);
      if (cached != null) {
        try {
          final jsonMap = json.decode(cached) as Map<String, dynamic>;
          return UserCompletionProgress.fromJson(jsonMap);
        } catch (e) {
          debugPrint("Failed to parse cached user completion progress: $e");
        }
      }

      // 2. Stale cache (> 24h) returns immediately and silently refreshes in background
      final stale = await cacheRepo.getAnyCache(cacheKey);
      if (stale != null) {
        unawaited(() async {
          try {
            final fresh = await _fetchAndCacheUserCompletionProgress(
              auth,
              cacheRepo,
            );
            if (fresh != null) {
              ref.invalidateSelf();
            }
          } catch (e) {
            debugPrint(
              "Background refresh of user completion progress failed: $e",
            );
          }
        }());
        try {
          return UserCompletionProgress.fromJson(
            json.decode(stale) as Map<String, dynamic>,
          );
        } catch (_) {}
      }

      // 3. No cache at all: fetch synchronously from API
      return await _fetchAndCacheUserCompletionProgress(auth, cacheRepo);
    });

Future<void> refreshAllPlayerRetroAchievementsData(WidgetRef ref) async {
  final auth = ref.read(retroAchievementsAuthProvider);
  if (auth == null) return;
  final cacheRepo = ref.read(retroAchievementsCacheRepoProvider);

  await cacheRepo.invalidate('user_summary_${auth.username}');
  await cacheRepo.invalidate('user_awards_${auth.username}');
  await cacheRepo.invalidate('user_completion_progress_${auth.username}');

  ref.invalidate(retroAchievementsUserSummaryProvider);
  ref.invalidate(retroAchievementsUserAwardsProvider);
  ref.invalidate(retroAchievementsUserCompletionProgressProvider);
}

Future<GameInfoAndUserProgress?> fetchGameInfoAndUserProgressWithCache({
  required AuthObject auth,
  required int gameId,
  required RetroAchievementsCacheRepo cacheRepo,
  bool forceRefresh = false,
  bool allowNetwork = true,
}) async {
  final cacheKey = 'game_progress_${gameId}_${auth.username}';

  if (!forceRefresh) {
    final cached = await cacheRepo.getValidCache(cacheKey);
    if (cached != null) {
      try {
        final jsonMap = json.decode(cached) as Map<String, dynamic>;
        return GameInfoAndUserProgress.fromJson(jsonMap);
      } catch (e) {
        debugPrint("Failed to parse cached game progress for $gameId: $e");
      }
    }
  }

  if (!allowNetwork && !forceRefresh) {
    return null;
  }

  try {
    final url = buildRequestUrl(
      apiBaseUrl,
      '/API_GetGameInfoAndUserProgress.php',
      auth,
      args: {'g': gameId, 'u': auth.username, 'a': 1},
    );
    final rawResponse = await call(url: url);
    if (rawResponse is! Map) {
      if (rawResponse is List && rawResponse.isEmpty) {
        final fallback = <String, dynamic>{
          'id': gameId,
          'title': '',
          'achievements': <String, dynamic>{},
        };
        await cacheRepo.putCache(cacheKey, json.encode(fallback));
        return GameInfoAndUserProgress.fromJson(fallback);
      }
      debugPrint(
        "RA API returned non-map response for game $gameId: $rawResponse",
      );
      return null;
    }
    final sanitized =
        serializeProperties(
              rawResponse,
              shouldCastToNumbers: [
                'ID',
                'NumAwarded',
                'NumAwardedHardcore',
                'NumAwardedToUser',
                'NumAwardedToUserHardcore',
                'Points',
                'TrueRatio',
                'DisplayOrder',
                'NumDistinctPlayersCasual',
                'NumDistinctPlayersHardcore',
              ],
            )
            as Map<String, dynamic>;
    await cacheRepo.putCache(cacheKey, json.encode(sanitized));
    return GameInfoAndUserProgress.fromJson(sanitized);
  } catch (e, stack) {
    debugPrint("Failed to fetch game RA details ($gameId): $e\n$stack");
    final stale = await cacheRepo.getAnyCache(cacheKey);
    if (stale != null) {
      try {
        return GameInfoAndUserProgress.fromJson(
          json.decode(stale) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return null;
  }
}

class RetroAchievementsProgressNotifier
    extends Notifier<Map<int, GameInfoAndUserProgress>> {
  @override
  Map<int, GameInfoAndUserProgress> build() {
    final cacheRepo = ref.watch(retroAchievementsCacheRepoProvider);
    final auth = ref.watch(retroAchievementsAuthProvider);
    final initialMap = <int, GameInfoAndUserProgress>{};

    if (auth != null) {
      Future.microtask(() async {
        try {
          final entries = await cacheRepo.getAllValidCacheEntries(
            'game_progress_',
          );
          final parsed = <int, GameInfoAndUserProgress>{};
          for (final entry in entries) {
            final key = entry.$1;
            if (key.endsWith('_${auth.username}')) {
              final parts = key.split('_');
              if (parts.length >= 3) {
                final gameId = int.tryParse(parts[2]);
                if (gameId != null) {
                  try {
                    final jsonMap =
                        json.decode(entry.$2) as Map<String, dynamic>;
                    parsed[gameId] = GameInfoAndUserProgress.fromJson(jsonMap);
                  } catch (_) {}
                }
              }
            }
          }
          if (parsed.isNotEmpty) {
            state = {...state, ...parsed};
          }
        } catch (e) {
          debugPrint("Failed to preload RA game progress cache: $e");
        }
      });
    }

    return initialMap;
  }

  bool has(int gameId) => state.containsKey(gameId);

  void set(int gameId, GameInfoAndUserProgress progress) {
    state = {...state, gameId: progress};
  }

  void remove(int gameId) {
    final next = Map<int, GameInfoAndUserProgress>.from(state)..remove(gameId);
    state = next;
  }
}

final retroAchievementsProgressMapProvider =
    NotifierProvider<
      RetroAchievementsProgressNotifier,
      Map<int, GameInfoAndUserProgress>
    >(RetroAchievementsProgressNotifier.new);

/// Changes whenever all persisted RetroAchievements caches are cleared.
/// Screens that perform background matching watch this so an already-mounted
/// game list starts a fresh pass against the empty mapping table.
class RetroAchievementsCacheRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final retroAchievementsCacheRevisionProvider =
    NotifierProvider<RetroAchievementsCacheRevisionNotifier, int>(
      RetroAchievementsCacheRevisionNotifier.new,
    );

final gameRetroAchievementsDetailsProvider =
    FutureProvider.family<GameInfoAndUserProgress?, int>((ref, raGameId) async {
      final memoryProgress = ref.watch(
        retroAchievementsProgressMapProvider,
      )[raGameId];
      if (memoryProgress != null) {
        return memoryProgress;
      }

      final auth = ref.watch(retroAchievementsAuthProvider);
      if (auth == null) {
        return null;
      }
      final cacheRepo = ref.watch(retroAchievementsCacheRepoProvider);
      final progress = await fetchGameInfoAndUserProgressWithCache(
        auth: auth,
        gameId: raGameId,
        cacheRepo: cacheRepo,
        allowNetwork: true,
      );
      if (progress != null) {
        ref
            .read(retroAchievementsProgressMapProvider.notifier)
            .set(raGameId, progress);
      }
      return progress;
    });

extension GameInfoAndUserProgressUtils on GameInfoAndUserProgress {
  int get userEarnedPoints {
    int sum = 0;
    for (final a in achievements.values) {
      if (a.dateEarned != null || a.dateEarnedHardcore != null) {
        sum += a.points;
      }
    }
    return sum;
  }

  int get calculatedTotalPoints {
    if (achievements.isEmpty) return 0;
    return achievements.values.fold(0, (sum, a) => sum + a.points);
  }

  bool get isMastered =>
      highestAwardKind == AwardKind.mastered ||
      (numAchievements > 0 && numAwardedToUserHardcore == numAchievements);

  bool get isCompleted =>
      !isMastered &&
      (highestAwardKind == AwardKind.completed ||
          highestAwardKind == AwardKind.beatenHardcore ||
          highestAwardKind == AwardKind.beatenSoftcore ||
          (numAchievements > 0 && numAwardedToUser == numAchievements));
}

/// Validates RetroAchievements credentials by attempting to fetch the user profile.
/// Returns the [UserProfile] on success or throws an exception on failure.
Future<UserProfile> testRetroAchievementsCredentials({
  required String username,
  required String webApiKey,
}) async {
  final auth = buildAuthorization(username: username, webApiKey: webApiKey);
  return getUserProfile(auth, username: username);
}
