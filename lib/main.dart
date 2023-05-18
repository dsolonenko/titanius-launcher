import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:titanius/pages/filter.dart';

import 'pages/game_settings.dart';
import 'pages/settings.dart';
import 'pages/system_proxy.dart';
import 'pages/systems.dart';

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
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
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
            GoRoute(
              path: "name",
              builder: (context, state) => NameFilterPage(system: state.pathParameters['system']!),
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
        builder: (context, state) => SettingsPage(source: state.queryParameters['source']),
        routes: [
          GoRoute(
            path: 'roms',
            builder: (context, state) => const RomsSettingsPage(),
          ),
          GoRoute(
            path: 'systems',
            builder: (context, state) => const ShowSystemsSettingsPage(),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
