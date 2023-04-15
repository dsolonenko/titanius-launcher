import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'settings.dart';

part 'storage.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) =>
    Isar.open([SettingSchema, AlternativeEmulatorSchema, FavouriteSchema, RecentGameSchema]);
