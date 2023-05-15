import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repo.dart';

part 'storage.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [SettingSchema, AlternativeEmulatorSchema, FavouriteSchema, RecentGameSchema, AndroidAppSchema],
    directory: dir.path,
  );
}
