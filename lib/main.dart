import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/games.dart';
import 'pages/settings.dart';
import 'pages/systems.dart';

void main() {
  runApp(
    // For widgets to be able to read providers, we need to wrap the entire
    // application in a "ProviderScope" widget.
    // This is where the state of our providers will be stored.
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
        builder: (context, state) => GamesPage(state.params['system']!)),
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
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme(brightness) {
    var baseTheme = ThemeData(brightness: brightness);

    return baseTheme.copyWith(
      //textTheme: GoogleFonts.squadaOneTextTheme(baseTheme.textTheme),
      //textTheme: GoogleFonts.tourneyTextTheme(baseTheme.textTheme),
      //textTheme: GoogleFonts.bebasNeueTextTheme(baseTheme.textTheme),
      textTheme: GoogleFonts.koulenTextTheme(baseTheme.textTheme),
    );
  }
}
