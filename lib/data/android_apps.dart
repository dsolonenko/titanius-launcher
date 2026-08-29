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

final selectedAndroidAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final installedApps = await ref.watch(installedAppsProvider.future);
  final selectedApps = await ref.watch(androidAppsProvider.future);
  return installedApps.where((element) => selectedApps.isSelected(element.packageName)).toList();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});
