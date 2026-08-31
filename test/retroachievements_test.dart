import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart' hide isNull, isNotNull;
import 'package:titanius/data/retroachievements.dart';
import 'package:titanius/data/retroachievements_matcher.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/storage.dart';
import 'package:titanius/pages/game_achievements.dart';
import 'package:titanius/pages/player_retroachievements.dart';
import 'package:titanius/pages/settings.dart';
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
        expect(find.text('Jetpack Joyride'), findsOneWidget);
        expect(find.text('Game Progress'), findsOneWidget);
        expect(find.text('(1)'), findsOneWidget);

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
  });
}

class _MockSelectedGameNotifier extends SelectedGameNotifier {
  final Game? _game;
  _MockSelectedGameNotifier(super.system, this._game);

  @override
  Game? build() => _game;
}
