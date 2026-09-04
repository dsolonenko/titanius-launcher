import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:titanius/data/repo.dart';

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final apps = await InstalledApps.getInstalledApps(
    excludeSystemApps: false,
    withIcon: true,
  );
  return apps
      .where((element) => element.packageName != 'app.titanius.launcher')
      .sortedBy((element) => element.name.toLowerCase());
});

class CategorizedAndroidApps {
  final List<AppInfo> games;
  final List<AppInfo> emulators;
  final List<AppInfo> apps;

  CategorizedAndroidApps({
    required this.games,
    required this.emulators,
    required this.apps,
  });

  bool get isEmpty => games.isEmpty && emulators.isEmpty && apps.isEmpty;
  bool get isNotEmpty => !isEmpty;

  List<AppInfo> get allVisible => [...games, ...emulators, ...apps];
}

final categorizedAndroidAppsProvider = FutureProvider<CategorizedAndroidApps>((
  ref,
) async {
  final installedApps = await ref.watch(installedAppsProvider.future);
  final selectedApps = await ref.watch(androidAppsProvider.future);

  final games = <AppInfo>[];
  final emulators = <AppInfo>[];
  final apps = <AppInfo>[];

  for (final app in installedApps) {
    if (selectedApps.isGame(app.packageName)) {
      games.add(app);
    } else if (selectedApps.isEmulator(app.packageName)) {
      emulators.add(app);
    } else if (selectedApps.isApp(app.packageName)) {
      apps.add(app);
    }
  }

  return CategorizedAndroidApps(games: games, emulators: emulators, apps: apps);
});

final selectedAndroidAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final categorized = await ref.watch(categorizedAndroidAppsProvider.future);
  return categorized.allVisible;
});

final selectedAndroidGamesProvider = FutureProvider<List<AppInfo>>((ref) async {
  final categorized = await ref.watch(categorizedAndroidAppsProvider.future);
  return categorized.games;
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});
