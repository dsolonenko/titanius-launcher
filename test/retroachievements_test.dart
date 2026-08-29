import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/repo.dart' hide isNull, isNotNull;
import 'package:titanius/data/retroachievements.dart';
import 'package:titanius/data/storage.dart';
import 'package:titanius/pages/settings.dart';
import 'package:titanius/widgets/retroachievements_profile.dart';

void main() {
  group('RetroAchievements Settings & Data', () {
    test('SettingsRepo saves and clears RetroAchievements credentials', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepo(db);

      var settings = await repo.getSettings();
      expect(settings.hasRetroAchievements, false);
      expect(settings.retroAchievementsUser, isNull);
      expect(settings.retroAchievementsApiKey, isNull);
      expect(settings.showRetroAchievementsInAppBar, true);

      await repo.setRetroAchievementsUser('Scott');
      await repo.setRetroAchievementsApiKey('testKey123');
      await repo.setShowRetroAchievementsInAppBar(false);

      settings = await repo.getSettings();
      expect(settings.hasRetroAchievements, true);
      expect(settings.retroAchievementsUser, 'Scott');
      expect(settings.retroAchievementsApiKey, 'testKey123');
      expect(settings.showRetroAchievementsInAppBar, false);

      await repo.clearRetroAchievements();
      settings = await repo.getSettings();
      expect(settings.hasRetroAchievements, false);
      expect(settings.retroAchievementsUser, isNull);
      expect(settings.retroAchievementsApiKey, isNull);

      await db.close();
    });

    test('retroAchievementsAuthProvider builds AuthObject only when configured', () async {
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
    });
  });

  group('RetroAchievements Widgets', () {
    testWidgets('RetroAchievementsProfileWidget renders nothing when not configured', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepo(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            settingsRepoProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RetroAchievementsProfileWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(InkWell), findsNothing);

      await db.close();
    });

    testWidgets('RetroAchievementsProfileWidget renders username and points when summary available', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepo(db);
      await repo.setRetroAchievementsUser('Scott');
      await repo.setRetroAchievementsApiKey('testKey123');

      const mockSummary = UserSummary(
        recentlyPlayedCount: 0,
        recentlyPlayed: [],
        memberSince: '2020-01-01',
        richPresenceMsg: '',
        lastGameId: 0,
        contribCount: 0,
        contribYield: 0,
        totalPoints: 1250,
        totalSoftcorePoints: 0,
        totalTruePoints: 2000,
        permissions: 0,
        untracked: false,
        id: 1,
        userWallActive: false,
        motto: '',
        rank: 42,
        awarded: {},
        recentAchievements: {},
        points: 1250,
        softcorePoints: 0,
        userPic: 'Scott.png',
        totalRanked: 1000,
        status: 'Active',
      );

      const mockAwards = UserAwards(
        totalAwardsCount: 3,
        hiddenAwardsCount: 0,
        masteryAwardsCount: 1,
        completionAwardsCount: 2,
        beatenHardcoreAwardsCount: 3,
        beatenSoftcoreAwardsCount: 0,
        eventAwardsCount: 0,
        siteAwardsCount: 0,
        visibleUserAwards: [],
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
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RetroAchievementsProfileWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Scott'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await db.close();
    });

    testWidgets('RetroAchievementsSettingsPage renders setting items', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepo(db);
      await repo.setRetroAchievementsUser('Scott');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            settingsRepoProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: RetroAchievementsSettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('RetroAchievements'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Web API Key'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Show Profile in Status Bar'), findsOneWidget);

      await db.close();
    });
  });
}
