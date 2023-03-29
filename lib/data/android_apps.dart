import 'package:collection/collection.dart';
import 'package:device_apps/device_apps.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'android_apps.g.dart';

@Riverpod(keepAlive: true)
Future<List<ApplicationWithIcon>> installedApps(InstalledAppsRef ref) async {
  final apps = await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps: false,
    onlyAppsWithLaunchIntent: true,
  );
  return apps
      .map((e) => e as ApplicationWithIcon)
      .sortedBy((element) => element.appName);
}

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(PackageInfoRef ref) async {
  return PackageInfo.fromPlatform();
}
