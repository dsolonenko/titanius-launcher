import 'package:collection/collection.dart';
import 'package:device_apps/device_apps.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:titanius/data/repo.dart';

part 'android_apps.g.dart';

@Riverpod(keepAlive: true)
Future<List<ApplicationWithIcon>> installedApps(InstalledAppsRef ref) async {
  final apps = await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps: true,
    onlyAppsWithLaunchIntent: true,
  );
  return apps.map((e) => e as ApplicationWithIcon).sortedBy((element) => element.appName);
}

@Riverpod(keepAlive: true)
Future<List<ApplicationWithIcon>> selectedAndroidApps(SelectedAndroidAppsRef ref) async {
  final installedApps = await ref.watch(installedAppsProvider.future);
  final selectedApps = await ref.watch(androidAppsProvider.future);
  return installedApps.where((element) => selectedApps.isSelected(element.packageName)).toList();
}

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(PackageInfoRef ref) async {
  return PackageInfo.fromPlatform();
}
