import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:installed_apps/app_info.dart';
import 'package:titanius/data/android_apps.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/storage.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:titanius/pages/android.dart';
import 'package:titanius/pages/settings.dart';
import 'package:titanius/widgets/battery.dart';
import 'package:titanius/widgets/selector.dart';
import 'package:titanius/widgets/wifi.dart';

void main() {
  group('Android Sections & AppType Tests', () {
    test('AndroidAppType cycle: hide -> game -> emulator -> app -> hide', () {
      expect(AndroidAppType.hidden.next(), AndroidAppType.game);
      expect(AndroidAppType.game.next(), AndroidAppType.emulator);
      expect(AndroidAppType.emulator.next(), AndroidAppType.app);
      expect(AndroidAppType.app.next(), AndroidAppType.hidden);
    });

    test(
      'AndroidAppType reverse cycle: hide -> app -> emulator -> game -> hide',
      () {
        expect(AndroidAppType.hidden.previous(), AndroidAppType.app);
        expect(AndroidAppType.app.previous(), AndroidAppType.emulator);
        expect(AndroidAppType.emulator.previous(), AndroidAppType.game);
        expect(AndroidAppType.game.previous(), AndroidAppType.hidden);
      },
    );

    test('AndroidAppsRepo sets type, cycles, and deletes on hide', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final appsRepo = AndroidAppsRepo(db);

      var apps = await appsRepo.getSelectedApps();
      expect(apps.isSelected('com.game.deadcells'), isFalse);
      expect(apps.typeOf('com.game.deadcells'), AndroidAppType.hidden);

      // Cycle backward from hidden -> app
      await appsRepo.cycleAppType('com.game.deadcells', forward: false);
      apps = await appsRepo.getSelectedApps();
      expect(apps.isApp('com.game.deadcells'), isTrue);

      // Cycle backward from app -> emulator
      await appsRepo.cycleAppType('com.game.deadcells', forward: false);
      apps = await appsRepo.getSelectedApps();
      expect(apps.isEmulator('com.game.deadcells'), isTrue);

      // Cycle forward from emulator -> app
      await appsRepo.cycleAppType('com.game.deadcells', forward: true);
      apps = await appsRepo.getSelectedApps();
      expect(apps.isApp('com.game.deadcells'), isTrue);

      // Reset to hidden
      await appsRepo.setAppType('com.game.deadcells', AndroidAppType.hidden);

      // Cycle from hidden -> game
      await appsRepo.cycleAppType('com.game.deadcells');
      apps = await appsRepo.getSelectedApps();
      expect(apps.isGame('com.game.deadcells'), isTrue);
      expect(apps.isSelected('com.game.deadcells'), isTrue);

      // Cycle from game -> emulator
      await appsRepo.cycleAppType('com.game.deadcells');
      apps = await appsRepo.getSelectedApps();
      expect(apps.isEmulator('com.game.deadcells'), isTrue);

      // Cycle from emulator -> app
      await appsRepo.cycleAppType('com.game.deadcells');
      apps = await appsRepo.getSelectedApps();
      expect(apps.isApp('com.game.deadcells'), isTrue);

      // Cycle from app -> hide (deleted from db)
      await appsRepo.cycleAppType('com.game.deadcells');
      apps = await appsRepo.getSelectedApps();
      expect(apps.isSelected('com.game.deadcells'), isFalse);
      expect(apps.typeOf('com.game.deadcells'), AndroidAppType.hidden);

      await db.close();
    });

    test(
      'categorizedAndroidAppsProvider partitions installed apps into sections',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final appsRepo = AndroidAppsRepo(db);
        await appsRepo.setAppType('com.game.subway', AndroidAppType.game);
        await appsRepo.setAppType('org.ppsspp.ppsspp', AndroidAppType.emulator);
        await appsRepo.setAppType('com.android.chrome', AndroidAppType.app);

        final dummyApps = <AppInfo>[
          AppInfo.create({
            'name': 'Calculator',
            'package_name': 'com.android.calculator',
            'version_name': '1.0',
            'version_code': 1,
          }),
          AppInfo.create({
            'name': 'Chrome',
            'package_name': 'com.android.chrome',
            'version_name': '100.0',
            'version_code': 100,
          }),
          AppInfo.create({
            'name': 'PPSSPP',
            'package_name': 'org.ppsspp.ppsspp',
            'version_name': '1.15',
            'version_code': 115,
          }),
          AppInfo.create({
            'name': 'Subway Surfers',
            'package_name': 'com.game.subway',
            'version_name': '2.0',
            'version_code': 200,
          }),
        ];

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            installedAppsProvider.overrideWith((ref) => dummyApps),
          ],
        );

        final categorized = await container.read(
          categorizedAndroidAppsProvider.future,
        );

        expect(categorized.games.length, 1);
        expect(categorized.games.first.name, 'Subway Surfers');

        expect(categorized.emulators.length, 1);
        expect(categorized.emulators.first.name, 'PPSSPP');

        expect(categorized.apps.length, 1);
        expect(categorized.apps.first.name, 'Chrome');

        expect(categorized.allVisible.length, 3);

        container.dispose();
        await db.close();
      },
    );
  });

  group('Android Page & Selection Widget Tests', () {
    testWidgets('AppsSettingsPage renders selector badges and cycles on tap', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final dummyApps = <AppInfo>[
        AppInfo.create({
          'name': 'Dead Cells',
          'package_name': 'com.playdigious.deadcells',
          'version_name': '1.0',
          'version_code': 1,
        }),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            installedAppsProvider.overrideWith((ref) => dummyApps),
          ],
          child: const MaterialApp(home: AppsSettingsPage()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially Hide with standard SelectorWidget
      expect(find.text('Dead Cells'), findsOneWidget);
      expect(find.byType(SelectorWidget), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);

      // Tap to cycle -> Game
      await tester.tap(find.text('Dead Cells'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Game'), findsOneWidget);
      expect(find.byType(SelectorWidget), findsOneWidget);

      // Tap to cycle -> Emulator
      await tester.tap(find.text('Dead Cells'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Emulator'), findsOneWidget);

      // Tap to cycle -> App
      await tester.tap(find.text('Dead Cells'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('App'), findsOneWidget);

      // Tap to cycle -> Hide
      await tester.tap(find.text('Dead Cells'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hide'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('AndroidPage renders empty state when no apps selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categorizedAndroidAppsProvider.overrideWith(
              (ref) =>
                  CategorizedAndroidApps(games: [], emulators: [], apps: []),
            ),
            batteryProvider.overrideWith(
              (ref) => Stream.value(BatteryInfo(BatteryState.full, 100)),
            ),
            connectivityProvider.overrideWith(
              (ref) => Stream.value(ConnectivityResult.wifi),
            ),
          ],
          child: const SDTFScope(child: MaterialApp(home: AndroidPage())),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No apps selected'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets(
      'AndroidPage renders section headers (Games, Emulators, Apps)',
      (tester) async {
        final dummyApps = <AppInfo>[
          AppInfo.create({
            'name': 'Chrome',
            'package_name': 'com.android.chrome',
            'version_name': '1.0',
            'version_code': 1,
          }),
          AppInfo.create({
            'name': 'Dead Cells',
            'package_name': 'com.playdigious.deadcells',
            'version_name': '1.0',
            'version_code': 1,
          }),
          AppInfo.create({
            'name': 'PPSSPP',
            'package_name': 'org.ppsspp.ppsspp',
            'version_name': '1.0',
            'version_code': 1,
          }),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categorizedAndroidAppsProvider.overrideWith(
                (ref) => CategorizedAndroidApps(
                  games: [dummyApps[1]],
                  emulators: [dummyApps[2]],
                  apps: [dummyApps[0]],
                ),
              ),
              batteryProvider.overrideWith(
                (ref) => Stream.value(BatteryInfo(BatteryState.full, 100)),
              ),
              connectivityProvider.overrideWith(
                (ref) => Stream.value(ConnectivityResult.wifi),
              ),
            ],
            child: const SDTFScope(child: MaterialApp(home: AndroidPage())),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Games'), findsOneWidget);
        expect(find.text('Emulators'), findsOneWidget);
        expect(find.text('Apps'), findsOneWidget);

        expect(find.text('Dead Cells'), findsOneWidget);
        expect(find.text('PPSSPP'), findsOneWidget);
        expect(find.text('Chrome'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  });
}
