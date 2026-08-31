import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/scraper.dart';
import 'package:titanius/pages/filter.dart';

import 'package:titanius/pages/game_achievements.dart';
import 'package:titanius/pages/game_settings.dart';
import 'package:titanius/pages/settings.dart';
import 'package:titanius/pages/scraper.dart';
import 'package:titanius/pages/system_proxy.dart';
import 'package:titanius/pages/systems.dart';
import 'package:titanius/widgets/scraper_progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'scraper_service_channel',
        channelName: 'Scraper Service',
        channelDescription:
            'Notification channel for ROM scraper background task',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  await _ensureStoragePermission();
  runApp(const ProviderScope(child: SDTFScope(child: MyApp())));
}

Future<void> _ensureStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted) {
      debugPrint("Storage permission already granted");
    } else {
      debugPrint("Requesting storage permission");
      await Permission.manageExternalStorage.request();
    }
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SystemsPage()),
    GoRoute(
      path: '/games/:system',
      builder: (context, state) =>
          SystemProxy(system: state.pathParameters['system']!),
      routes: [
        GoRoute(
          path: "game/:hash",
          builder: (context, state) => GameSettingsPage(
            system: state.pathParameters['system']!,
            hash: int.parse(state.pathParameters['hash']!),
          ),
          routes: [
            GoRoute(
              path: "achievements",
              builder: (context, state) => GameAchievementsPage(
                system: state.pathParameters['system']!,
                hash: int.parse(state.pathParameters['hash']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'filter',
          builder: (context, state) =>
              FiltersPage(system: state.pathParameters['system']!),
          routes: [
            GoRoute(
              path: "genres",
              builder: (context, state) =>
                  GenresFilterPage(system: state.pathParameters['system']!),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/select_apps',
      builder: (context, state) => const AppsSettingsPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          SettingsPage(source: state.uri.queryParameters['source']),
      routes: [
        GoRoute(
          path: 'scraper',
          builder: (context, state) => const ScraperPage(),
          routes: [
            GoRoute(
              path: 'systems',
              builder: (context, state) => const ScraperSystemsPage(),
            ),
          ],
        ),
        GoRoute(
          path: 'retroachievements',
          builder: (context, state) => const RetroAchievementsSettingsPage(),
        ),
        GoRoute(
          path: 'roms',
          builder: (context, state) => const RomsSettingsPage(),
        ),
        GoRoute(
          path: 'systems',
          builder: (context, state) => const ShowSystemsSettingsPage(),
        ),
        GoRoute(
          path: 'cemulators',
          builder: (context, state) => const CustomEmulatorsPage(),
          routes: [
            GoRoute(
              path: "edit",
              builder: (context, state) => const EditCustomEmulatorPage(),
            ),
          ],
        ),
        GoRoute(
          path: 'emulators',
          builder: (context, state) => const AlternativeEmulatorsSettingPage(),
          routes: [
            GoRoute(
              path: ":system",
              builder: (context, state) => SelectAlternativeEmulatorSettingPage(
                state.pathParameters['system']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'controller',
          builder: (context, state) => const ControllerSettingsPage(),
        ),
        GoRoute(
          path: 'ui',
          builder: (context, state) => const UISettingsPage(),
        ),
        GoRoute(
          path: 'daijisho',
          builder: (context, state) => const DaijishoWallpaperPacksPage(),
        ),
      ],
    ),
  ],
);

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Do not rebuild MaterialApp/router for every setting mutation. Font scale
    // is the only setting owned by this root widget.
    final fontScale = ref.watch(
      settingsProvider.select((settings) => settings.value?.fontScale ?? 1.0),
    );
    final scraperService = ref.watch(scraperServiceProvider);
    useEffect(() {
      final sub = scraperService.progressStream.listen((progress) {
        ref.read(scraperProgressStateProvider.notifier).set(progress);
        if (progress.message == "Done" ||
            progress.message == "Cancelled" ||
            progress.message == "Quota exceeded") {
          ref.read(gameLibraryProvider).clear();
          ref.invalidate(systemGamesProvider);
          ref.invalidate(allGamesProvider);
        }
      });
      return () => sub.cancel();
    }, [scraperService]);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Titanius Launcher',
      theme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      shortcuts: const <ShortcutActivator, Intent>{
        // Disable default directional focus traversal so gamepad / controller navigation is the primary driver
        SingleActivator(LogicalKeyboardKey.arrowUp):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.tab):
            DoNothingAndStopPropagationIntent(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child!,
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = FlexThemeData.dark(
      scheme: FlexScheme.hippieBlue,
      darkIsTrueBlack: true,
      fontFamily: 'KarenFat',
    );
    return baseTheme.copyWith(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      textTheme: baseTheme.textTheme.apply(fontFamily: 'KarenFat'),
      listTileTheme: const ListTileThemeData(
        selectedTileColor: Colors.white,
        selectedColor: Colors.black,
      ),
    );
  }
}
