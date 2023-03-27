import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/settings.dart';
import 'pages/system_proxy.dart';
import 'pages/systems.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SystemsPage(),
    ),
    GoRoute(
        path: '/games/:system',
        builder: (context, state) => SystemProxy(state.params['system']!)),
    GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'systems',
            builder: (context, state) => const ShowSystemsSettingsPage(),
          ),
          GoRoute(
            path: 'emulators',
            builder: (context, state) =>
                const AlternativeEmulatorsSettingPage(),
            routes: [
              GoRoute(
                path: ":system",
                builder: (context, state) =>
                    SelectAlternativeEmulatorSettingPage(
                        state.params['system']!),
              )
            ],
          ),
          GoRoute(
            path: 'ui',
            builder: (context, state) => const UISettingsPage(),
          ),
        ]),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return ProviderScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Titanius Launcher',
        theme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme(brightness) {
    final baseTheme = FlexThemeData.dark(
      scheme: FlexScheme.material,
      darkIsTrueBlack: true,
    );
    return baseTheme.copyWith(
      //textTheme: GoogleFonts.squadaOneTextTheme(baseTheme.textTheme),
      //textTheme: GoogleFonts.tourneyTextTheme(baseTheme.textTheme),
      textTheme: GoogleFonts.bebasNeueTextTheme(baseTheme.textTheme),
      //textTheme: GoogleFonts.koulenTextTheme(baseTheme.textTheme),
    );
  }
}
