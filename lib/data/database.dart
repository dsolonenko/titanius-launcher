import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:titanius/data/android_intent.dart';
import 'package:titanius/data/models.dart';

part 'database.g.dart';

@DataClassName('Setting')
class SettingEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

@DataClassName('CustomEmulator')
class CustomEmulatorEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get amStartCommand => text()();
}

@DataClassName('AlternativeEmulator')
class AlternativeEmulatorEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get system => text().unique()();
  TextColumn get emulator => text()();
}

@DataClassName('GameEmulator')
class GameEmulatorEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get romPath => text().unique()();
  TextColumn get emulator => text()();
}

@DataClassName('RecentGame')
class RecentGameEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get romPath => text().unique()();
  IntColumn get timestamp => integer()();
}

@DataClassName('AndroidApp')
class AndroidAppEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get package => text().unique()();
}

@DriftDatabase(tables: [
  SettingEntries,
  CustomEmulatorEntries,
  AlternativeEmulatorEntries,
  GameEmulatorEntries,
  RecentGameEntries,
  AndroidAppEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'titanius_db');
  }
}

extension CustomEmulatorUtils on CustomEmulator {
  static CustomEmulator empty() => const CustomEmulator(
        id: 0,
        name: "Custom PPSSPP",
        amStartCommand: 'am start -n org.ppsspp.ppssppgold/org.ppsspp.ppsspp.PpssppActivity '
            '-a android.intent.action.VIEW -d "{file.documenturi}" '
            '--activity-clear-task --activity-clear-top --activity-no-history',
      );

  Emulator toEmulator() {
    return Emulator(
      id: "custom:$name",
      name: name,
      intent: LaunchIntent.parseAmStartCommand(amStartCommand),
    );
  }
}
