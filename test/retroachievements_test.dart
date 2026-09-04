import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:zstd_dart/zstd_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart' hide isNull, isNotNull;
import 'package:titanius/data/retroachievements.dart';
import 'package:titanius/data/retroachievements_matcher.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/storage.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';
import 'package:titanius/pages/game_achievements.dart';
import 'package:titanius/pages/player_retroachievements.dart';
import 'package:titanius/pages/settings.dart';
import 'package:titanius/pages/systems.dart';
import 'package:titanius/widgets/retroachievements_card.dart';

void main() {
  group('RetroAchievements Settings & Data', () {
    test(
      'SettingsRepo saves and clears RetroAchievements credentials',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final repo = SettingsRepo(db);

        var settings = await repo.getSettings();
        expect(settings.hasRetroAchievements, false);
        expect(settings.retroAchievementsUser, isNull);
        expect(settings.retroAchievementsApiKey, isNull);

        await repo.setRetroAchievementsUser('Scott');
        await repo.setRetroAchievementsApiKey('testKey123');

        settings = await repo.getSettings();
        expect(settings.hasRetroAchievements, true);
        expect(settings.retroAchievementsUser, 'Scott');
        expect(settings.retroAchievementsApiKey, 'testKey123');

        await repo.clearRetroAchievements();
        settings = await repo.getSettings();
        expect(settings.hasRetroAchievements, false);
        expect(settings.retroAchievementsUser, isNull);
        expect(settings.retroAchievementsApiKey, isNull);

        await db.close();
      },
    );

    test(
      'retroAchievementsAuthProvider builds AuthObject only when configured',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final repo = SettingsRepo(db);

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            settingsRepoProvider.overrideWithValue(repo),
          ],
        );

        // Initially null
        var auth = container.read(retroAchievementsAuthProvider);
        expect(auth, isNull);

        // Set credentials
        await repo.setRetroAchievementsUser('Scott');
        await repo.setRetroAchievementsApiKey('testKey123');
        container.invalidate(settingsProvider);
        await container.read(settingsProvider.future);

        auth = container.read(retroAchievementsAuthProvider);
        expect(auth, isNotNull);
        expect(auth!.username, 'Scott');
        expect(auth.webApiKey, 'testKey123');

        container.dispose();
        await db.close();
      },
    );
  });

  group('RetroAchievements Widgets', () {
    testWidgets('RetroAchievementsSettingsPage renders setting items', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepo(db);
      await repo.setRetroAchievementsUser('Scott');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            settingsRepoProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: RetroAchievementsSettingsPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('RetroAchievements'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Web API Key'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Clear Cheevos Caches'), findsOneWidget);

      await db.close();
    });

    testWidgets(
      'PlayerRetroAchievementsPage renders stats and single-scrollable game progress',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());
        final repo = SettingsRepo(db);
        await repo.setRetroAchievementsUser('Scott');
        await repo.setRetroAchievementsApiKey('testKey123');

        const mockSummary = UserSummary(
          recentlyPlayedCount: 1,
          recentlyPlayed: [],
          memberSince: '2020-01-01',
          richPresenceMsg: '',
          lastGameId: 0,
          contribCount: 0,
          contribYield: 0,
          totalPoints: 1870,
          totalSoftcorePoints: 393,
          totalTruePoints: 3276,
          permissions: 0,
          untracked: false,
          id: 1,
          userWallActive: false,
          motto: '',
          rank: 57401,
          awarded: {},
          recentAchievements: {},
          points: 1870,
          softcorePoints: 393,
          userPic: '',
          totalRanked: 161141,
          status: '',
        );

        const mockAwards = UserAwards(
          totalAwardsCount: 3,
          hiddenAwardsCount: 0,
          masteryAwardsCount: 1,
          completionAwardsCount: 0,
          beatenHardcoreAwardsCount: 2,
          beatenSoftcoreAwardsCount: 0,
          eventAwardsCount: 0,
          siteAwardsCount: 0,
          visibleUserAwards: [],
        );

        const mockProgress = UserCompletionProgress(
          count: 108,
          total: 108,
          results: [
            UserCompletionProgressEntity(
              gameId: 1,
              title: 'Jetpack Joyride',
              imageIcon: '',
              consoleId: 41,
              consoleName: 'PlayStation Portable',
              maxPossible: 21,
              numAwarded: 21,
              numAwardedHardcore: 21,
              highestAwardKind: AwardKind.mastered,
            ),
          ],
        );

        const mockWantToPlay = UserWantToPlayList(
          count: 1,
          total: 1,
          results: [
            UserWantToPlayItem(
              id: 2259,
              title: 'Wario World',
              imageIcon: '',
              consoleId: 16,
              consoleName: 'GameCube',
              pointsTotal: 610,
              achievementsPublished: 88,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              settingsRepoProvider.overrideWithValue(repo),
              retroAchievementsUserSummaryProvider.overrideWith(
                (ref) async => mockSummary,
              ),
              retroAchievementsUserAwardsProvider.overrideWith(
                (ref) async => mockAwards,
              ),
              retroAchievementsUserWantToPlayListProvider.overrideWith(
                (ref) async => mockWantToPlay,
              ),
              retroAchievementsUserCompletionProgressProvider.overrideWith(
                (ref) async => mockProgress,
              ),
            ],
            child: const MaterialApp(
              home: SDTFScope(child: PlayerRetroAchievementsPage()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(RetroAchievementsPlayerHeaderCard), findsOneWidget);
        expect(find.text('Scott'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data?.contains('1,870') == true ||
                    w.textSpan?.toPlainText().contains('1,870') == true),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data?.contains('#57,401') == true ||
                    w.textSpan?.toPlainText().contains('#57,401') == true),
          ),
          findsOneWidget,
        );
        expect(find.text('Want to Play'), findsOneWidget);
        expect(find.text('Wario World'), findsOneWidget);
        expect(find.text('Jetpack Joyride'), findsOneWidget);
        expect(find.text('Game Progress'), findsOneWidget);
        expect(find.text('(1)'), findsNWidgets(2));

        await db.close();
      },
    );
  });

  group('RetroAchievements Game Matching & Caching', () {
    test(
      'GameRetroAchievementsRepo saves and retrieves game entries',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final repo = GameRetroAchievementsRepo(db);

        var entry = await repo.getEntry('/roms/snes/Super Mario World.sfc');
        expect(entry, isNull);

        await repo.saveEntry(
          romPath: '/roms/snes/Super Mario World.sfc',
          md5Hash: 'cdd3c8c3732297873e4492834a189388',
          raGameId: 228,
          numAchievements: 50,
          points: 400,
          raTitle: 'Super Mario World',
          badgeUrl: '12345.png',
        );

        entry = await repo.getEntry('/roms/snes/Super Mario World.sfc');
        expect(entry, isNotNull);
        expect(entry!.raGameId, 228);
        expect(entry.numAchievements, 50);
        expect(entry.points, 400);
        expect(entry.raTitle, 'Super Mario World');

        final all = await repo.getAllEntries();
        expect(all.length, 1);
        expect(all['/roms/snes/Super Mario World.sfc']?.raGameId, 228);

        await db.close();
      },
    );

    test(
      'computeRomMd5 hashes raw files and .zip archives correctly',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('ra_test_');

        try {
          // Raw file
          final rawFile = File('${tempDir.path}/test.sfc');
          await rawFile.writeAsString('SUPER_MARIO_TEST_ROM');
          final rawMd5 = await computeRomMd5(rawFile.path);
          expect(rawMd5, isNotNull);
          expect(rawMd5!.primaryHash.length, 32);

          // Zip file
          final zipFile = File('${tempDir.path}/test.zip');
          final archive = Archive()
            ..addFile(
              ArchiveFile('game.sfc', 20, 'SUPER_MARIO_TEST_ROM'.codeUnits),
            );
          final zipBytes = ZipEncoder().encode(archive);
          await zipFile.writeAsBytes(zipBytes);

          final zipMd5 = await computeRomMd5(zipFile.path);
          expect(
            zipMd5?.primaryHash,
            rawMd5.primaryHash,
          ); // Inner ROM MD5 should match!
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test(
      'resolveGameRetroAchievements caches result and matches system',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final repo = GameRetroAchievementsRepo(db);
        final tempDir = await Directory.systemTemp.createTemp('ra_resolve_');

        try {
          final snesDir = Directory('${tempDir.path}/snes')
            ..createSync(recursive: true);
          final romFile = File('${snesDir.path}/game.sfc');
          await romFile.writeAsString('ROM_DATA');

          const system = System(
            id: 'snes',
            name: 'Super Nintendo',
            logo: 'snes.svg',
            screenScraperId: 3,
            retroAchievementsId: 3,
            folders: ['snes'],
            builtInEmulators: [],
          );

          final game = Game(
            system,
            'Test Game',
            tempDir.path,
            'snes',
            '.',
            'game.sfc',
          );

          final result = await resolveGameRetroAchievements(
            game: game,
            repo: repo,
          );

          expect(result, isNotNull);
          expect(result!.romPath, game.romPath);
          expect(result.md5Hash, isNotNull);

          // Cached lookup
          final cached = await repo.getEntry(game.romPath);
          expect(cached, isNotNull);
          expect(cached!.md5Hash, result.md5Hash);
        } finally {
          await tempDir.delete(recursive: true);
          await db.close();
        }
      },
    );

    test(
      'resolveGameRetroAchievements identifies GameCube disc ISO correctly',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final repo = GameRetroAchievementsRepo(db);
        final tempDir = await Directory.systemTemp.createTemp('ra_gc_resolve_');

        try {
          final gcDir = Directory('${tempDir.path}/gc')
            ..createSync(recursive: true);
          final romFile = File('${gcDir.path}/test_gc.iso');

          // Create synthetic GameCube disc
          const baseHeaderSize = 0x2440;
          final gcDisc = Uint8List(0x6000);
          gcDisc[0x1C] = 0xC2;
          gcDisc[0x1D] = 0x33;
          gcDisc[0x1E] = 0x9F;
          gcDisc[0x1F] = 0x3D;

          final apploaderInfo = ByteData.sublistView(
            gcDisc,
            baseHeaderSize + 0x14,
            baseHeaderSize + 0x1C,
          );
          apploaderInfo.setUint32(0, 0x40, Endian.big);
          apploaderInfo.setUint32(4, 0x20, Endian.big);

          final dolOffsetView = ByteData.sublistView(gcDisc, 0x420, 0x424);
          dolOffsetView.setUint32(0, 0x3000, Endian.big);

          await romFile.writeAsBytes(gcDisc);

          const system = System(
            id: 'gc',
            name: 'GameCube',
            logo: 'gc.svg',
            screenScraperId: 14,
            retroAchievementsId: 16,
            folders: ['gc'],
            builtInEmulators: [],
          );

          final game = Game(
            system,
            'Test GameCube Game',
            tempDir.path,
            'gc',
            '.',
            'test_gc.iso',
          );

          final result = await resolveGameRetroAchievements(
            game: game,
            repo: repo,
          );

          expect(result, isNotNull);
          expect(result!.romPath, game.romPath);
          expect(result.md5Hash, isNotNull);
          expect(result.md5Hash.length, 32);
        } finally {
          await tempDir.delete(recursive: true);
          await db.close();
        }
      },
    );

    test(
      'resolveGameRetroAchievements identifies GameCube disc RVZ correctly',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final repo = GameRetroAchievementsRepo(db);
        final tempDir = await Directory.systemTemp.createTemp(
          'ra_gc_rvz_resolve_',
        );

        try {
          final gcDir = Directory('${tempDir.path}/gc')
            ..createSync(recursive: true);
          final romFile = File('${gcDir.path}/test_gc.rvz');

          // Create minimal synthetic GameCube disc
          const baseHeaderSize = 0x2440;
          final gcDisc = Uint8List(0x8000);
          gcDisc[0x1C] = 0xC2;
          gcDisc[0x1D] = 0x33;
          gcDisc[0x1E] = 0x9F;
          gcDisc[0x1F] = 0x3D;

          final apploaderInfo = ByteData.sublistView(
            gcDisc,
            baseHeaderSize + 0x14,
            baseHeaderSize + 0x1C,
          );
          apploaderInfo.setUint32(0, 0x40, Endian.big);
          apploaderInfo.setUint32(4, 0x20, Endian.big);

          final dolOffsetView = ByteData.sublistView(gcDisc, 0x420, 0x424);
          dolOffsetView.setUint32(0, 0x3000, Endian.big);

          // Build valid Zstd RVZ structure
          final numChunks = (gcDisc.length + 0x8000 - 1) ~/ 0x8000;
          final compressedChunks = <Uint8List>[];
          for (var i = 0; i < numChunks; i++) {
            final start = i * 0x8000;
            final end = (start + 0x8000 < gcDisc.length)
                ? start + 0x8000
                : gcDisc.length;
            final chunkRaw = Uint8List(0x8000);
            chunkRaw.setRange(0, end - start, gcDisc.sublist(start, end));
            compressedChunks.add(
              Uint8List.fromList(ZstdCodec.compress(chunkRaw)),
            );
          }

          final rawBytes = Uint8List(24);
          final rawBd = ByteData.sublistView(rawBytes);
          rawBd.setUint64(0, 0, Endian.big);
          rawBd.setUint64(8, gcDisc.length, Endian.big);
          rawBd.setUint32(16, 0, Endian.big);
          rawBd.setUint32(20, numChunks, Endian.big);
          final rawComp = Uint8List.fromList(ZstdCodec.compress(rawBytes));

          final groupBytes = Uint8List(numChunks * 12);
          final groupBd = ByteData.sublistView(groupBytes);
          var currentFileOffset = 72 + 220;
          final rawOff = currentFileOffset;
          currentFileOffset += rawComp.length;
          while (currentFileOffset % 4 != 0) {
            currentFileOffset++;
          }
          final groupOff = currentFileOffset;

          for (var i = 0; i < numChunks; i++) {
            groupBd.setUint32(i * 12, 0, Endian.big);
            groupBd.setUint32(
              i * 12 + 4,
              (1 << 31) | compressedChunks[i].length,
              Endian.big,
            );
            groupBd.setUint32(i * 12 + 8, 0, Endian.big);
          }
          final tempGroupComp = Uint8List.fromList(
            ZstdCodec.compress(groupBytes),
          );
          var chunkDataStart = groupOff + tempGroupComp.length;
          while (chunkDataStart % 4 != 0) {
            chunkDataStart++;
          }

          var runningChunkOff = chunkDataStart;
          for (var i = 0; i < numChunks; i++) {
            groupBd.setUint32(i * 12, runningChunkOff >> 2, Endian.big);
            groupBd.setUint32(
              i * 12 + 4,
              (1 << 31) | compressedChunks[i].length,
              Endian.big,
            );
            groupBd.setUint32(i * 12 + 8, 0, Endian.big);
            runningChunkOff += compressedChunks[i].length;
            while (runningChunkOff % 4 != 0) {
              runningChunkOff++;
            }
          }
          final finalGroupComp = Uint8List.fromList(
            ZstdCodec.compress(groupBytes),
          );

          final h2 = Uint8List(220);
          final h2Bd = ByteData.sublistView(h2);
          h2Bd.setUint32(0, 1, Endian.big);
          h2Bd.setUint32(4, 5, Endian.big);
          h2Bd.setInt32(8, 3, Endian.big);
          h2Bd.setUint32(12, 0x8000, Endian.big);
          h2.setRange(16, 16 + 0x80, gcDisc.sublist(0, 0x80));
          h2Bd.setUint32(0xB4, 1, Endian.big);
          h2Bd.setUint64(0xB8, rawOff, Endian.big);
          h2Bd.setUint32(0xC0, rawComp.length, Endian.big);
          h2Bd.setUint32(0xC4, numChunks, Endian.big);
          h2Bd.setUint64(0xC8, groupOff, Endian.big);
          h2Bd.setUint32(0xD0, finalGroupComp.length, Endian.big);

          final h1 = Uint8List(72);
          final h1Bd = ByteData.sublistView(h1);
          h1Bd.setUint32(0, 0x52565A01, Endian.big);
          h1Bd.setUint32(4, 0x01000000, Endian.big);
          h1Bd.setUint32(8, 0x01000000, Endian.big);
          h1Bd.setUint32(12, 220, Endian.big);
          h1Bd.setUint64(36, gcDisc.length, Endian.big);
          h1Bd.setUint64(44, runningChunkOff, Endian.big);

          final rvzBytes = Uint8List(runningChunkOff);
          rvzBytes.setRange(0, 72, h1);
          rvzBytes.setRange(72, 72 + 220, h2);
          rvzBytes.setRange(rawOff, rawOff + rawComp.length, rawComp);
          rvzBytes.setRange(
            groupOff,
            groupOff + finalGroupComp.length,
            finalGroupComp,
          );
          var off = chunkDataStart;
          for (var i = 0; i < numChunks; i++) {
            rvzBytes.setRange(
              off,
              off + compressedChunks[i].length,
              compressedChunks[i],
            );
            off += compressedChunks[i].length;
            while (off % 4 != 0 && off < runningChunkOff) {
              off++;
            }
          }

          await romFile.writeAsBytes(rvzBytes);

          const system = System(
            id: 'gc',
            name: 'GameCube',
            logo: 'gc.svg',
            screenScraperId: 14,
            retroAchievementsId: 16,
            folders: ['gc'],
            builtInEmulators: [],
          );

          final game = Game(
            system,
            'Test GameCube RVZ Game',
            tempDir.path,
            'gc',
            '.',
            'test_gc.rvz',
          );

          final result = await resolveGameRetroAchievements(
            game: game,
            repo: repo,
          );

          expect(result, isNotNull);
          expect(result!.romPath, game.romPath);
          expect(result.md5Hash, isNotNull);
          expect(result.md5Hash.length, 32);
        } finally {
          await tempDir.delete(recursive: true);
          await db.close();
        }
      },
    );

    testWidgets(
      'GameAchievementsPage renders achievements list and user progress',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final repo = GameRetroAchievementsRepo(db);

        const system = System(
          id: 'snes',
          name: 'Super Nintendo',
          logo: 'snes.svg',
          screenScraperId: 3,
          retroAchievementsId: 3,
          folders: ['snes'],
          builtInEmulators: [],
        );

        final game = Game(
          system,
          'Super Mario World',
          '/roms',
          'snes',
          '.',
          'Super Mario World.sfc',
        );

        await repo.saveEntry(
          romPath: game.romPath,
          md5Hash: 'cdd3c8c3732297873e4492834a189388',
          raGameId: 228,
          numAchievements: 2,
          points: 30,
          raTitle: 'Super Mario World',
        );

        const mockProgress = GameInfoAndUserProgress(
          id: 228,
          title: 'Super Mario World',
          consoleId: 3,
          forumTopicId: 1,
          flags: 0,
          imageIcon: '000001.png',
          imageTitle: '',
          imageIngame: '',
          imageBoxArt: '',
          publisher: 'Nintendo',
          developer: 'Nintendo',
          genre: 'Platformer',
          released: '1990',
          isFinal: true,
          consoleName: 'SNES',
          richPresencePatch: '',
          numAchievements: 2,
          numDistinctPlayersCasual: 100,
          numDistinctPlayersHardcore: 50,
          claims: [],
          achievements: {
            1: GameExtendedAchievementEntityWithUserProgress(
              id: 1,
              numAwarded: 50,
              numAwardedHardcore: 40,
              title: 'Yoshi Island 1',
              description: 'Clear Yoshi Island 1',
              points: 5,
              trueRatio: 10,
              author: 'Scott',
              dateModified: '2020-01-01',
              dateCreated: '2020-01-01',
              badgeName: '00001',
              displayOrder: 1,
              memAddr: '',
              dateEarned: '2024-01-01 12:00:00',
            ),
            2: GameExtendedAchievementEntityWithUserProgress(
              id: 2,
              numAwarded: 20,
              numAwardedHardcore: 15,
              title: 'Defeat Bowser',
              description: 'Defeat Bowser in Valley of Bowser',
              points: 25,
              trueRatio: 50,
              author: 'Scott',
              dateModified: '2020-01-01',
              dateCreated: '2020-01-01',
              badgeName: '00002',
              displayOrder: 2,
              memAddr: '',
            ),
          },
          numAwardedToUser: 1,
          numAwardedToUserHardcore: 0,
          userCompletion: '50%',
          userCompletionHardcore: '0%',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              gameRetroAchievementsRepoProvider.overrideWithValue(repo),
              selectedGameProvider(
                'snes',
              ).overrideWith(() => _MockSelectedGameNotifier('snes', game)),
              gameRetroAchievementsDetailsProvider(
                228,
              ).overrideWith((ref) async => mockProgress),
            ],
            child: MaterialApp(
              home: GameAchievementsPage(system: 'snes', hash: game.hash),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Super Mario World'), findsWidgets);
        expect(find.text('1 / 2 Unlocked • 5 / 30 Points'), findsOneWidget);
        expect(find.text('Yoshi Island 1'), findsOneWidget);
        expect(find.text('Clear Yoshi Island 1'), findsOneWidget);
        expect(find.text('Defeat Bowser'), findsOneWidget);
        expect(find.text('Defeat Bowser in Valley of Bowser'), findsOneWidget);
        expect(find.text('5 pts'), findsOneWidget);
        expect(find.text('25 pts'), findsOneWidget);
        expect(find.text('Locked Only'), findsOneWidget);

        await db.close();
      },
    );

    test(
      'RetroAchievementsCacheRepo saves, retrieves, and invalidates API cache entries',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final cacheRepo = RetroAchievementsCacheRepo(db);

        // Initially empty
        expect(await cacheRepo.getValidCache('test_key'), isNull);
        expect(await cacheRepo.getAnyCache('test_key'), isNull);

        // Save cache entry
        await cacheRepo.putCache('test_key', '{"test": 123}');
        expect(await cacheRepo.getValidCache('test_key'), '{"test": 123}');
        expect(await cacheRepo.getAnyCache('test_key'), '{"test": 123}');

        // Invalidate
        await cacheRepo.invalidate('test_key');
        expect(await cacheRepo.getValidCache('test_key'), isNull);
        expect(await cacheRepo.getAnyCache('test_key'), isNull);

        await db.close();
      },
    );

    test(
      'clearing RetroAchievements caches removes mappings and API data',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final mappingRepo = GameRetroAchievementsRepo(db);
        final cacheRepo = RetroAchievementsCacheRepo(db);

        await mappingRepo.saveEntry(
          romPath: '/roms/snes/game.sfc',
          md5Hash: '0123456789abcdef0123456789abcdef',
          raGameId: 123,
        );
        await cacheRepo.putCache('game_progress_123_user', '{"ID":123}');

        await cacheRepo.clearAll();

        expect(await mappingRepo.getAllEntries(), isEmpty);
        expect(await cacheRepo.getAnyCache('game_progress_123_user'), isNull);

        await db.close();
      },
    );

    test('systemRetroAchievements collection defaults to disabled', () {
      final enabledSystems = EnabledSystems({});
      expect(systemRetroAchievements.id, 'retroachievements');
      expect(systemRetroAchievements.isCollection, true);
      expect(enabledSystems.showSystem('retroachievements'), false);
      expect(enabledSystems.showSystem('favourites'), true);
      expect(enabledSystems.showSystem('recent'), true);
    });

    testWidgets(
      'SystemsPage renders retroachievements panels above the navigation dots',
      (tester) async {
        tester.view.physicalSize = const Size(800, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const mockSummary = UserSummary(
          recentlyPlayedCount: 1,
          recentlyPlayed: [],
          memberSince: '2020-01-01',
          richPresenceMsg: '',
          lastGameId: 0,
          contribCount: 0,
          contribYield: 0,
          totalPoints: 1870,
          totalSoftcorePoints: 393,
          totalTruePoints: 3276,
          permissions: 0,
          untracked: false,
          id: 1,
          userWallActive: false,
          motto: '',
          rank: 57401,
          awarded: {},
          recentAchievements: {},
          points: 1870,
          softcorePoints: 393,
          userPic: '',
          totalRanked: 161141,
          status: '',
        );

        const mockAwards = UserAwards(
          totalAwardsCount: 3,
          hiddenAwardsCount: 0,
          masteryAwardsCount: 1,
          completionAwardsCount: 0,
          beatenHardcoreAwardsCount: 2,
          beatenSoftcoreAwardsCount: 0,
          eventAwardsCount: 0,
          siteAwardsCount: 0,
          visibleUserAwards: [],
        );

        final db = AppDatabase(NativeDatabase.memory());
        final repo = SettingsRepo(db);
        await repo.setRetroAchievementsUser('Scott');
        await repo.setRetroAchievementsApiKey('testKey123');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              settingsRepoProvider.overrideWithValue(repo),
              loadedSystemsProvider.overrideWith(
                (ref) async => [systemRetroAchievements],
              ),
              retroAchievementsUserSummaryProvider.overrideWith(
                (ref) async => mockSummary,
              ),
              retroAchievementsUserAwardsProvider.overrideWith(
                (ref) async => mockAwards,
              ),
              retroAchievementsUserCompletionProgressProvider.overrideWith(
                (ref) async => null,
              ),
            ],
            child: const MaterialApp(home: SDTFScope(child: SystemsPage())),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('RetroAchievements'), findsWidgets);
        final trophyTextFinder = find.byWidgetPredicate(
          (w) => w is Text && w.data == '\u{1F3C6}' && w.style?.fontSize == 20,
        );
        expect(trophyTextFinder, findsOneWidget);

        final cardFinder = find.byType(RetroAchievementsPlayerHeaderCard);
        final overviewFinder = find.byType(RetroAchievementsGamesOverviewBar);
        final dotsFinder = find.byType(PageViewDotIndicator);
        expect(cardFinder, findsOneWidget);
        expect(overviewFinder, findsOneWidget);
        expect(dotsFinder, findsOneWidget);

        final overviewBottom = tester.getBottomLeft(overviewFinder).dy;
        final dotsTop = tester.getTopLeft(dotsFinder).dy;
        expect(overviewBottom, lessThan(dotsTop));

        // Verify full width (800 - 16*2 = 768)
        final cardSize = tester.getSize(cardFinder);
        final overviewSize = tester.getSize(overviewFinder);
        expect(cardSize.width, equals(768.0));
        expect(overviewSize.width, equals(768.0));

        await db.close();
      },
    );

    for (final (name, size) in [
      ('4:3 (640x480)', const Size(640, 480)),
      ('3:2 (720x480)', const Size(720, 480)),
      ('3:2 small (480x320)', const Size(480, 320)),
      ('1:1 (720x720)', const Size(720, 720)),
      ('16:9 (854x480)', const Size(854, 480)),
    ]) {
      testWidgets('SystemsPage retroachievements layout on $name', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const mockSummary = UserSummary(
          recentlyPlayedCount: 1,
          recentlyPlayed: [],
          memberSince: '2020-01-01',
          richPresenceMsg: '',
          lastGameId: 0,
          contribCount: 0,
          contribYield: 0,
          totalPoints: 1870,
          totalSoftcorePoints: 393,
          totalTruePoints: 3276,
          permissions: 0,
          untracked: false,
          id: 1,
          userWallActive: false,
          motto: '',
          rank: 57401,
          awarded: {},
          recentAchievements: {},
          points: 1870,
          softcorePoints: 393,
          userPic: '',
          totalRanked: 161141,
          status: '',
        );

        const mockAwards = UserAwards(
          totalAwardsCount: 3,
          hiddenAwardsCount: 0,
          masteryAwardsCount: 1,
          completionAwardsCount: 0,
          beatenHardcoreAwardsCount: 2,
          beatenSoftcoreAwardsCount: 0,
          eventAwardsCount: 0,
          siteAwardsCount: 0,
          visibleUserAwards: [],
        );

        final db = AppDatabase(NativeDatabase.memory());
        final repo = SettingsRepo(db);
        await repo.setRetroAchievementsUser('Scott');
        await repo.setRetroAchievementsApiKey('testKey123');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              settingsRepoProvider.overrideWithValue(repo),
              loadedSystemsProvider.overrideWith(
                (ref) async => [systemRetroAchievements],
              ),
              retroAchievementsUserSummaryProvider.overrideWith(
                (ref) async => mockSummary,
              ),
              retroAchievementsUserAwardsProvider.overrideWith(
                (ref) async => mockAwards,
              ),
              retroAchievementsUserCompletionProgressProvider.overrideWith(
                (ref) async => null,
              ),
            ],
            child: const MaterialApp(home: SDTFScope(child: SystemsPage())),
          ),
        );

        await tester.pumpAndSettle();

        final overviewFinder = find.byType(RetroAchievementsGamesOverviewBar);
        final dotsFinder = find.byType(PageViewDotIndicator);
        expect(overviewFinder, findsOneWidget);
        expect(dotsFinder, findsOneWidget);

        final overviewBottom = tester.getBottomLeft(overviewFinder).dy;
        final dotsTop = tester.getTopLeft(dotsFinder).dy;
        expect(
          overviewBottom,
          lessThanOrEqualTo(dotsTop),
          reason:
              'Overview bottom ($overviewBottom) must not overlap dots top ($dotsTop) on $name',
        );

        await db.close();
      });
    }
  });
}

class _MockSelectedGameNotifier extends SelectedGameNotifier {
  final Game? _game;
  _MockSelectedGameNotifier(super.system, this._game);

  @override
  Game? build() => _game;
}
