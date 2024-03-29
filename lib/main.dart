import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:titanius/pages/filter.dart';

import 'package:titanius/pages/game_settings.dart';
import 'package:titanius/pages/settings.dart';
import 'package:titanius/pages/scraper.dart';
import 'package:titanius/pages/system_proxy.dart';
import 'package:titanius/pages/systems.dart';
import 'package:titanius/widgets/scraper_progress.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SDTFScope(
        child: MyApp(),
      ),
    ),
  );
}

Future<void> _ensureStoragePermission() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    GoRoute(
      path: '/',
      builder: (context, state) => const SystemsPage(),
    ),
    GoRoute(
      path: '/games/:system',
      builder: (context, state) => SystemProxy(system: state.pathParameters['system']!),
      routes: [
        GoRoute(
          path: "game/:hash",
          builder: (context, state) => GameSettingsPage(
            system: state.pathParameters['system']!,
            hash: int.parse(state.pathParameters['hash']!),
          ),
        ),
        GoRoute(
          path: 'filter',
          builder: (context, state) => FiltersPage(system: state.pathParameters['system']!),
          routes: [
            GoRoute(
              path: "genres",
              builder: (context, state) => GenresFilterPage(system: state.pathParameters['system']!),
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
        builder: (context, state) => SettingsPage(source: state.uri.queryParameters['source']),
        routes: [
          GoRoute(path: 'scraper', builder: (context, state) => const ScraperPage(), routes: [
            GoRoute(
              path: 'systems',
              builder: (context, state) => const ScraperSystemsPage(),
            ),
          ]),
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
              )
            ],
          ),
          GoRoute(
            path: 'emulators',
            builder: (context, state) => const AlternativeEmulatorsSettingPage(),
            routes: [
              GoRoute(
                path: ":system",
                builder: (context, state) => SelectAlternativeEmulatorSettingPage(state.pathParameters['system']!),
              )
            ],
          ),
          GoRoute(
            path: 'ui',
            builder: (context, state) => const UISettingsPage(),
          ),
          GoRoute(
            path: 'daijisho',
            builder: (context, state) => const DaijishoWallpaperPacksPage(),
          ),
        ]),
  ],
);

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scraperService = ref.watch(scraperServiceProvider);
    useEffect(() {
      final sub = scraperService.on("update").listen((event) {
        ref.read(scraperProgressStateProvider.notifier).set(ScraperProgress(
              total: event!["total"] as int,
              pending: event!["pending"] as int,
              success: event["success"] as int,
              error: event["error"] as int,
              system: event["system"] as String,
              rom: event["rom"] as String,
              message: event["msg"] as String,
            ));
      });
      return () => sub.cancel();
    }, []);
    return FutureBuilder(
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return FutureBuilder(
                builder: ((context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      title: 'Titanius Launcher',
                      theme: _buildTheme(Brightness.dark),
                      themeMode: ThemeMode.dark,
                      routerConfig: _router,
                    );
                  } else {
                    return _waitPage();
                  }
                }),
                future: SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive));
          } else {
            return _waitPage();
          }
        }),
        future: _ensureStoragePermission());
  }

  ThemeData _buildTheme(brightness) {
    final baseTheme = FlexThemeData.dark(
      scheme: FlexScheme.hippieBlue,
      darkIsTrueBlack: true,
    );
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Staatliches',
      ),
    );
  }

  Widget _waitPage() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Titanius Launcher',
      theme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
