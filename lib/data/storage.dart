import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repo.dart';

part 'storage.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  final dir = await getApplicationSupportDirectory();
  return Isar.open(
    [
      SettingSchema,
      AlternativeEmulatorSchema,
      GameEmulatorSchema,
      RecentGameSchema,
      AndroidAppSchema,
    ],
    directory: dir.path,
  );
}
