// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingEntriesTable extends SettingEntries
    with TableInfo<$SettingEntriesTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingEntriesTable createAlias(String alias) {
    return $SettingEntriesTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String key;
  final String value;
  const Setting({required this.id, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingEntriesCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({int? id, String? key, String? value}) => Setting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  Setting copyWithCompanion(SettingEntriesCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingEntriesCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const SettingEntriesCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  SettingEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  SettingEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
  }) {
    return SettingEntriesCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntriesCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $CustomEmulatorEntriesTable extends CustomEmulatorEntries
    with TableInfo<$CustomEmulatorEntriesTable, CustomEmulator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomEmulatorEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _amStartCommandMeta = const VerificationMeta(
    'amStartCommand',
  );
  @override
  late final GeneratedColumn<String> amStartCommand = GeneratedColumn<String>(
    'am_start_command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, amStartCommand];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_emulator_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomEmulator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('am_start_command')) {
      context.handle(
        _amStartCommandMeta,
        amStartCommand.isAcceptableOrUnknown(
          data['am_start_command']!,
          _amStartCommandMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amStartCommandMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomEmulator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomEmulator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amStartCommand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}am_start_command'],
      )!,
    );
  }

  @override
  $CustomEmulatorEntriesTable createAlias(String alias) {
    return $CustomEmulatorEntriesTable(attachedDatabase, alias);
  }
}

class CustomEmulator extends DataClass implements Insertable<CustomEmulator> {
  final int id;
  final String name;
  final String amStartCommand;
  const CustomEmulator({
    required this.id,
    required this.name,
    required this.amStartCommand,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['am_start_command'] = Variable<String>(amStartCommand);
    return map;
  }

  CustomEmulatorEntriesCompanion toCompanion(bool nullToAbsent) {
    return CustomEmulatorEntriesCompanion(
      id: Value(id),
      name: Value(name),
      amStartCommand: Value(amStartCommand),
    );
  }

  factory CustomEmulator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomEmulator(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amStartCommand: serializer.fromJson<String>(json['amStartCommand']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amStartCommand': serializer.toJson<String>(amStartCommand),
    };
  }

  CustomEmulator copyWith({int? id, String? name, String? amStartCommand}) =>
      CustomEmulator(
        id: id ?? this.id,
        name: name ?? this.name,
        amStartCommand: amStartCommand ?? this.amStartCommand,
      );
  CustomEmulator copyWithCompanion(CustomEmulatorEntriesCompanion data) {
    return CustomEmulator(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amStartCommand: data.amStartCommand.present
          ? data.amStartCommand.value
          : this.amStartCommand,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomEmulator(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amStartCommand: $amStartCommand')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, amStartCommand);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomEmulator &&
          other.id == this.id &&
          other.name == this.name &&
          other.amStartCommand == this.amStartCommand);
}

class CustomEmulatorEntriesCompanion extends UpdateCompanion<CustomEmulator> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> amStartCommand;
  const CustomEmulatorEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amStartCommand = const Value.absent(),
  });
  CustomEmulatorEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String amStartCommand,
  }) : name = Value(name),
       amStartCommand = Value(amStartCommand);
  static Insertable<CustomEmulator> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? amStartCommand,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amStartCommand != null) 'am_start_command': amStartCommand,
    });
  }

  CustomEmulatorEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? amStartCommand,
  }) {
    return CustomEmulatorEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amStartCommand: amStartCommand ?? this.amStartCommand,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amStartCommand.present) {
      map['am_start_command'] = Variable<String>(amStartCommand.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomEmulatorEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amStartCommand: $amStartCommand')
          ..write(')'))
        .toString();
  }
}

class $AlternativeEmulatorEntriesTable extends AlternativeEmulatorEntries
    with TableInfo<$AlternativeEmulatorEntriesTable, AlternativeEmulator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlternativeEmulatorEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _systemMeta = const VerificationMeta('system');
  @override
  late final GeneratedColumn<String> system = GeneratedColumn<String>(
    'system',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _emulatorMeta = const VerificationMeta(
    'emulator',
  );
  @override
  late final GeneratedColumn<String> emulator = GeneratedColumn<String>(
    'emulator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, system, emulator];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alternative_emulator_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlternativeEmulator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('system')) {
      context.handle(
        _systemMeta,
        system.isAcceptableOrUnknown(data['system']!, _systemMeta),
      );
    } else if (isInserting) {
      context.missing(_systemMeta);
    }
    if (data.containsKey('emulator')) {
      context.handle(
        _emulatorMeta,
        emulator.isAcceptableOrUnknown(data['emulator']!, _emulatorMeta),
      );
    } else if (isInserting) {
      context.missing(_emulatorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlternativeEmulator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlternativeEmulator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      system: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system'],
      )!,
      emulator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emulator'],
      )!,
    );
  }

  @override
  $AlternativeEmulatorEntriesTable createAlias(String alias) {
    return $AlternativeEmulatorEntriesTable(attachedDatabase, alias);
  }
}

class AlternativeEmulator extends DataClass
    implements Insertable<AlternativeEmulator> {
  final int id;
  final String system;
  final String emulator;
  const AlternativeEmulator({
    required this.id,
    required this.system,
    required this.emulator,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['system'] = Variable<String>(system);
    map['emulator'] = Variable<String>(emulator);
    return map;
  }

  AlternativeEmulatorEntriesCompanion toCompanion(bool nullToAbsent) {
    return AlternativeEmulatorEntriesCompanion(
      id: Value(id),
      system: Value(system),
      emulator: Value(emulator),
    );
  }

  factory AlternativeEmulator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlternativeEmulator(
      id: serializer.fromJson<int>(json['id']),
      system: serializer.fromJson<String>(json['system']),
      emulator: serializer.fromJson<String>(json['emulator']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'system': serializer.toJson<String>(system),
      'emulator': serializer.toJson<String>(emulator),
    };
  }

  AlternativeEmulator copyWith({int? id, String? system, String? emulator}) =>
      AlternativeEmulator(
        id: id ?? this.id,
        system: system ?? this.system,
        emulator: emulator ?? this.emulator,
      );
  AlternativeEmulator copyWithCompanion(
    AlternativeEmulatorEntriesCompanion data,
  ) {
    return AlternativeEmulator(
      id: data.id.present ? data.id.value : this.id,
      system: data.system.present ? data.system.value : this.system,
      emulator: data.emulator.present ? data.emulator.value : this.emulator,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlternativeEmulator(')
          ..write('id: $id, ')
          ..write('system: $system, ')
          ..write('emulator: $emulator')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, system, emulator);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlternativeEmulator &&
          other.id == this.id &&
          other.system == this.system &&
          other.emulator == this.emulator);
}

class AlternativeEmulatorEntriesCompanion
    extends UpdateCompanion<AlternativeEmulator> {
  final Value<int> id;
  final Value<String> system;
  final Value<String> emulator;
  const AlternativeEmulatorEntriesCompanion({
    this.id = const Value.absent(),
    this.system = const Value.absent(),
    this.emulator = const Value.absent(),
  });
  AlternativeEmulatorEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String system,
    required String emulator,
  }) : system = Value(system),
       emulator = Value(emulator);
  static Insertable<AlternativeEmulator> custom({
    Expression<int>? id,
    Expression<String>? system,
    Expression<String>? emulator,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (system != null) 'system': system,
      if (emulator != null) 'emulator': emulator,
    });
  }

  AlternativeEmulatorEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? system,
    Value<String>? emulator,
  }) {
    return AlternativeEmulatorEntriesCompanion(
      id: id ?? this.id,
      system: system ?? this.system,
      emulator: emulator ?? this.emulator,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (system.present) {
      map['system'] = Variable<String>(system.value);
    }
    if (emulator.present) {
      map['emulator'] = Variable<String>(emulator.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlternativeEmulatorEntriesCompanion(')
          ..write('id: $id, ')
          ..write('system: $system, ')
          ..write('emulator: $emulator')
          ..write(')'))
        .toString();
  }
}

class $GameEmulatorEntriesTable extends GameEmulatorEntries
    with TableInfo<$GameEmulatorEntriesTable, GameEmulator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameEmulatorEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _romPathMeta = const VerificationMeta(
    'romPath',
  );
  @override
  late final GeneratedColumn<String> romPath = GeneratedColumn<String>(
    'rom_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _emulatorMeta = const VerificationMeta(
    'emulator',
  );
  @override
  late final GeneratedColumn<String> emulator = GeneratedColumn<String>(
    'emulator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, romPath, emulator];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_emulator_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameEmulator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rom_path')) {
      context.handle(
        _romPathMeta,
        romPath.isAcceptableOrUnknown(data['rom_path']!, _romPathMeta),
      );
    } else if (isInserting) {
      context.missing(_romPathMeta);
    }
    if (data.containsKey('emulator')) {
      context.handle(
        _emulatorMeta,
        emulator.isAcceptableOrUnknown(data['emulator']!, _emulatorMeta),
      );
    } else if (isInserting) {
      context.missing(_emulatorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameEmulator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameEmulator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      romPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rom_path'],
      )!,
      emulator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emulator'],
      )!,
    );
  }

  @override
  $GameEmulatorEntriesTable createAlias(String alias) {
    return $GameEmulatorEntriesTable(attachedDatabase, alias);
  }
}

class GameEmulator extends DataClass implements Insertable<GameEmulator> {
  final int id;
  final String romPath;
  final String emulator;
  const GameEmulator({
    required this.id,
    required this.romPath,
    required this.emulator,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['rom_path'] = Variable<String>(romPath);
    map['emulator'] = Variable<String>(emulator);
    return map;
  }

  GameEmulatorEntriesCompanion toCompanion(bool nullToAbsent) {
    return GameEmulatorEntriesCompanion(
      id: Value(id),
      romPath: Value(romPath),
      emulator: Value(emulator),
    );
  }

  factory GameEmulator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameEmulator(
      id: serializer.fromJson<int>(json['id']),
      romPath: serializer.fromJson<String>(json['romPath']),
      emulator: serializer.fromJson<String>(json['emulator']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'romPath': serializer.toJson<String>(romPath),
      'emulator': serializer.toJson<String>(emulator),
    };
  }

  GameEmulator copyWith({int? id, String? romPath, String? emulator}) =>
      GameEmulator(
        id: id ?? this.id,
        romPath: romPath ?? this.romPath,
        emulator: emulator ?? this.emulator,
      );
  GameEmulator copyWithCompanion(GameEmulatorEntriesCompanion data) {
    return GameEmulator(
      id: data.id.present ? data.id.value : this.id,
      romPath: data.romPath.present ? data.romPath.value : this.romPath,
      emulator: data.emulator.present ? data.emulator.value : this.emulator,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameEmulator(')
          ..write('id: $id, ')
          ..write('romPath: $romPath, ')
          ..write('emulator: $emulator')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, romPath, emulator);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameEmulator &&
          other.id == this.id &&
          other.romPath == this.romPath &&
          other.emulator == this.emulator);
}

class GameEmulatorEntriesCompanion extends UpdateCompanion<GameEmulator> {
  final Value<int> id;
  final Value<String> romPath;
  final Value<String> emulator;
  const GameEmulatorEntriesCompanion({
    this.id = const Value.absent(),
    this.romPath = const Value.absent(),
    this.emulator = const Value.absent(),
  });
  GameEmulatorEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String romPath,
    required String emulator,
  }) : romPath = Value(romPath),
       emulator = Value(emulator);
  static Insertable<GameEmulator> custom({
    Expression<int>? id,
    Expression<String>? romPath,
    Expression<String>? emulator,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (romPath != null) 'rom_path': romPath,
      if (emulator != null) 'emulator': emulator,
    });
  }

  GameEmulatorEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? romPath,
    Value<String>? emulator,
  }) {
    return GameEmulatorEntriesCompanion(
      id: id ?? this.id,
      romPath: romPath ?? this.romPath,
      emulator: emulator ?? this.emulator,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (romPath.present) {
      map['rom_path'] = Variable<String>(romPath.value);
    }
    if (emulator.present) {
      map['emulator'] = Variable<String>(emulator.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameEmulatorEntriesCompanion(')
          ..write('id: $id, ')
          ..write('romPath: $romPath, ')
          ..write('emulator: $emulator')
          ..write(')'))
        .toString();
  }
}

class $RecentGameEntriesTable extends RecentGameEntries
    with TableInfo<$RecentGameEntriesTable, RecentGame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentGameEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _romPathMeta = const VerificationMeta(
    'romPath',
  );
  @override
  late final GeneratedColumn<String> romPath = GeneratedColumn<String>(
    'rom_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, romPath, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_game_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentGame> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rom_path')) {
      context.handle(
        _romPathMeta,
        romPath.isAcceptableOrUnknown(data['rom_path']!, _romPathMeta),
      );
    } else if (isInserting) {
      context.missing(_romPathMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecentGame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentGame(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      romPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rom_path'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $RecentGameEntriesTable createAlias(String alias) {
    return $RecentGameEntriesTable(attachedDatabase, alias);
  }
}

class RecentGame extends DataClass implements Insertable<RecentGame> {
  final int id;
  final String romPath;
  final int timestamp;
  const RecentGame({
    required this.id,
    required this.romPath,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['rom_path'] = Variable<String>(romPath);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  RecentGameEntriesCompanion toCompanion(bool nullToAbsent) {
    return RecentGameEntriesCompanion(
      id: Value(id),
      romPath: Value(romPath),
      timestamp: Value(timestamp),
    );
  }

  factory RecentGame.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentGame(
      id: serializer.fromJson<int>(json['id']),
      romPath: serializer.fromJson<String>(json['romPath']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'romPath': serializer.toJson<String>(romPath),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  RecentGame copyWith({int? id, String? romPath, int? timestamp}) => RecentGame(
    id: id ?? this.id,
    romPath: romPath ?? this.romPath,
    timestamp: timestamp ?? this.timestamp,
  );
  RecentGame copyWithCompanion(RecentGameEntriesCompanion data) {
    return RecentGame(
      id: data.id.present ? data.id.value : this.id,
      romPath: data.romPath.present ? data.romPath.value : this.romPath,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentGame(')
          ..write('id: $id, ')
          ..write('romPath: $romPath, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, romPath, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentGame &&
          other.id == this.id &&
          other.romPath == this.romPath &&
          other.timestamp == this.timestamp);
}

class RecentGameEntriesCompanion extends UpdateCompanion<RecentGame> {
  final Value<int> id;
  final Value<String> romPath;
  final Value<int> timestamp;
  const RecentGameEntriesCompanion({
    this.id = const Value.absent(),
    this.romPath = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  RecentGameEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String romPath,
    required int timestamp,
  }) : romPath = Value(romPath),
       timestamp = Value(timestamp);
  static Insertable<RecentGame> custom({
    Expression<int>? id,
    Expression<String>? romPath,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (romPath != null) 'rom_path': romPath,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  RecentGameEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? romPath,
    Value<int>? timestamp,
  }) {
    return RecentGameEntriesCompanion(
      id: id ?? this.id,
      romPath: romPath ?? this.romPath,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (romPath.present) {
      map['rom_path'] = Variable<String>(romPath.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentGameEntriesCompanion(')
          ..write('id: $id, ')
          ..write('romPath: $romPath, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $AndroidAppEntriesTable extends AndroidAppEntries
    with TableInfo<$AndroidAppEntriesTable, AndroidApp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AndroidAppEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packageMeta = const VerificationMeta(
    'package',
  );
  @override
  late final GeneratedColumn<String> package = GeneratedColumn<String>(
    'package',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, package];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'android_app_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AndroidApp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('package')) {
      context.handle(
        _packageMeta,
        package.isAcceptableOrUnknown(data['package']!, _packageMeta),
      );
    } else if (isInserting) {
      context.missing(_packageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AndroidApp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AndroidApp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      package: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package'],
      )!,
    );
  }

  @override
  $AndroidAppEntriesTable createAlias(String alias) {
    return $AndroidAppEntriesTable(attachedDatabase, alias);
  }
}

class AndroidApp extends DataClass implements Insertable<AndroidApp> {
  final int id;
  final String package;
  const AndroidApp({required this.id, required this.package});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['package'] = Variable<String>(package);
    return map;
  }

  AndroidAppEntriesCompanion toCompanion(bool nullToAbsent) {
    return AndroidAppEntriesCompanion(id: Value(id), package: Value(package));
  }

  factory AndroidApp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AndroidApp(
      id: serializer.fromJson<int>(json['id']),
      package: serializer.fromJson<String>(json['package']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'package': serializer.toJson<String>(package),
    };
  }

  AndroidApp copyWith({int? id, String? package}) =>
      AndroidApp(id: id ?? this.id, package: package ?? this.package);
  AndroidApp copyWithCompanion(AndroidAppEntriesCompanion data) {
    return AndroidApp(
      id: data.id.present ? data.id.value : this.id,
      package: data.package.present ? data.package.value : this.package,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AndroidApp(')
          ..write('id: $id, ')
          ..write('package: $package')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, package);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AndroidApp &&
          other.id == this.id &&
          other.package == this.package);
}

class AndroidAppEntriesCompanion extends UpdateCompanion<AndroidApp> {
  final Value<int> id;
  final Value<String> package;
  const AndroidAppEntriesCompanion({
    this.id = const Value.absent(),
    this.package = const Value.absent(),
  });
  AndroidAppEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String package,
  }) : package = Value(package);
  static Insertable<AndroidApp> custom({
    Expression<int>? id,
    Expression<String>? package,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (package != null) 'package': package,
    });
  }

  AndroidAppEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? package,
  }) {
    return AndroidAppEntriesCompanion(
      id: id ?? this.id,
      package: package ?? this.package,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (package.present) {
      map['package'] = Variable<String>(package.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AndroidAppEntriesCompanion(')
          ..write('id: $id, ')
          ..write('package: $package')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingEntriesTable settingEntries = $SettingEntriesTable(this);
  late final $CustomEmulatorEntriesTable customEmulatorEntries =
      $CustomEmulatorEntriesTable(this);
  late final $AlternativeEmulatorEntriesTable alternativeEmulatorEntries =
      $AlternativeEmulatorEntriesTable(this);
  late final $GameEmulatorEntriesTable gameEmulatorEntries =
      $GameEmulatorEntriesTable(this);
  late final $RecentGameEntriesTable recentGameEntries =
      $RecentGameEntriesTable(this);
  late final $AndroidAppEntriesTable androidAppEntries =
      $AndroidAppEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settingEntries,
    customEmulatorEntries,
    alternativeEmulatorEntries,
    gameEmulatorEntries,
    recentGameEntries,
    androidAppEntries,
  ];
}

typedef $$SettingEntriesTableCreateCompanionBuilder =
    SettingEntriesCompanion Function({
      Value<int> id,
      required String key,
      required String value,
    });
typedef $$SettingEntriesTableUpdateCompanionBuilder =
    SettingEntriesCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
    });

class $$SettingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingEntriesTable,
          Setting,
          $$SettingEntriesTableFilterComposer,
          $$SettingEntriesTableOrderingComposer,
          $$SettingEntriesTableAnnotationComposer,
          $$SettingEntriesTableCreateCompanionBuilder,
          $$SettingEntriesTableUpdateCompanionBuilder,
          (
            Setting,
            BaseReferences<_$AppDatabase, $SettingEntriesTable, Setting>,
          ),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingEntriesTableTableManager(
    _$AppDatabase db,
    $SettingEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
              }) => SettingEntriesCompanion(id: id, key: key, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
              }) => SettingEntriesCompanion.insert(
                id: id,
                key: key,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingEntriesTable,
      Setting,
      $$SettingEntriesTableFilterComposer,
      $$SettingEntriesTableOrderingComposer,
      $$SettingEntriesTableAnnotationComposer,
      $$SettingEntriesTableCreateCompanionBuilder,
      $$SettingEntriesTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingEntriesTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$CustomEmulatorEntriesTableCreateCompanionBuilder =
    CustomEmulatorEntriesCompanion Function({
      Value<int> id,
      required String name,
      required String amStartCommand,
    });
typedef $$CustomEmulatorEntriesTableUpdateCompanionBuilder =
    CustomEmulatorEntriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> amStartCommand,
    });

class $$CustomEmulatorEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomEmulatorEntriesTable> {
  $$CustomEmulatorEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amStartCommand => $composableBuilder(
    column: $table.amStartCommand,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomEmulatorEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomEmulatorEntriesTable> {
  $$CustomEmulatorEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amStartCommand => $composableBuilder(
    column: $table.amStartCommand,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomEmulatorEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomEmulatorEntriesTable> {
  $$CustomEmulatorEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get amStartCommand => $composableBuilder(
    column: $table.amStartCommand,
    builder: (column) => column,
  );
}

class $$CustomEmulatorEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomEmulatorEntriesTable,
          CustomEmulator,
          $$CustomEmulatorEntriesTableFilterComposer,
          $$CustomEmulatorEntriesTableOrderingComposer,
          $$CustomEmulatorEntriesTableAnnotationComposer,
          $$CustomEmulatorEntriesTableCreateCompanionBuilder,
          $$CustomEmulatorEntriesTableUpdateCompanionBuilder,
          (
            CustomEmulator,
            BaseReferences<
              _$AppDatabase,
              $CustomEmulatorEntriesTable,
              CustomEmulator
            >,
          ),
          CustomEmulator,
          PrefetchHooks Function()
        > {
  $$CustomEmulatorEntriesTableTableManager(
    _$AppDatabase db,
    $CustomEmulatorEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomEmulatorEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomEmulatorEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomEmulatorEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> amStartCommand = const Value.absent(),
              }) => CustomEmulatorEntriesCompanion(
                id: id,
                name: name,
                amStartCommand: amStartCommand,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String amStartCommand,
              }) => CustomEmulatorEntriesCompanion.insert(
                id: id,
                name: name,
                amStartCommand: amStartCommand,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomEmulatorEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomEmulatorEntriesTable,
      CustomEmulator,
      $$CustomEmulatorEntriesTableFilterComposer,
      $$CustomEmulatorEntriesTableOrderingComposer,
      $$CustomEmulatorEntriesTableAnnotationComposer,
      $$CustomEmulatorEntriesTableCreateCompanionBuilder,
      $$CustomEmulatorEntriesTableUpdateCompanionBuilder,
      (
        CustomEmulator,
        BaseReferences<
          _$AppDatabase,
          $CustomEmulatorEntriesTable,
          CustomEmulator
        >,
      ),
      CustomEmulator,
      PrefetchHooks Function()
    >;
typedef $$AlternativeEmulatorEntriesTableCreateCompanionBuilder =
    AlternativeEmulatorEntriesCompanion Function({
      Value<int> id,
      required String system,
      required String emulator,
    });
typedef $$AlternativeEmulatorEntriesTableUpdateCompanionBuilder =
    AlternativeEmulatorEntriesCompanion Function({
      Value<int> id,
      Value<String> system,
      Value<String> emulator,
    });

class $$AlternativeEmulatorEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AlternativeEmulatorEntriesTable> {
  $$AlternativeEmulatorEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get system => $composableBuilder(
    column: $table.system,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emulator => $composableBuilder(
    column: $table.emulator,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlternativeEmulatorEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AlternativeEmulatorEntriesTable> {
  $$AlternativeEmulatorEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get system => $composableBuilder(
    column: $table.system,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emulator => $composableBuilder(
    column: $table.emulator,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlternativeEmulatorEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlternativeEmulatorEntriesTable> {
  $$AlternativeEmulatorEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get system =>
      $composableBuilder(column: $table.system, builder: (column) => column);

  GeneratedColumn<String> get emulator =>
      $composableBuilder(column: $table.emulator, builder: (column) => column);
}

class $$AlternativeEmulatorEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlternativeEmulatorEntriesTable,
          AlternativeEmulator,
          $$AlternativeEmulatorEntriesTableFilterComposer,
          $$AlternativeEmulatorEntriesTableOrderingComposer,
          $$AlternativeEmulatorEntriesTableAnnotationComposer,
          $$AlternativeEmulatorEntriesTableCreateCompanionBuilder,
          $$AlternativeEmulatorEntriesTableUpdateCompanionBuilder,
          (
            AlternativeEmulator,
            BaseReferences<
              _$AppDatabase,
              $AlternativeEmulatorEntriesTable,
              AlternativeEmulator
            >,
          ),
          AlternativeEmulator,
          PrefetchHooks Function()
        > {
  $$AlternativeEmulatorEntriesTableTableManager(
    _$AppDatabase db,
    $AlternativeEmulatorEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlternativeEmulatorEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AlternativeEmulatorEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AlternativeEmulatorEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> system = const Value.absent(),
                Value<String> emulator = const Value.absent(),
              }) => AlternativeEmulatorEntriesCompanion(
                id: id,
                system: system,
                emulator: emulator,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String system,
                required String emulator,
              }) => AlternativeEmulatorEntriesCompanion.insert(
                id: id,
                system: system,
                emulator: emulator,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlternativeEmulatorEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlternativeEmulatorEntriesTable,
      AlternativeEmulator,
      $$AlternativeEmulatorEntriesTableFilterComposer,
      $$AlternativeEmulatorEntriesTableOrderingComposer,
      $$AlternativeEmulatorEntriesTableAnnotationComposer,
      $$AlternativeEmulatorEntriesTableCreateCompanionBuilder,
      $$AlternativeEmulatorEntriesTableUpdateCompanionBuilder,
      (
        AlternativeEmulator,
        BaseReferences<
          _$AppDatabase,
          $AlternativeEmulatorEntriesTable,
          AlternativeEmulator
        >,
      ),
      AlternativeEmulator,
      PrefetchHooks Function()
    >;
typedef $$GameEmulatorEntriesTableCreateCompanionBuilder =
    GameEmulatorEntriesCompanion Function({
      Value<int> id,
      required String romPath,
      required String emulator,
    });
typedef $$GameEmulatorEntriesTableUpdateCompanionBuilder =
    GameEmulatorEntriesCompanion Function({
      Value<int> id,
      Value<String> romPath,
      Value<String> emulator,
    });

class $$GameEmulatorEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $GameEmulatorEntriesTable> {
  $$GameEmulatorEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get romPath => $composableBuilder(
    column: $table.romPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emulator => $composableBuilder(
    column: $table.emulator,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GameEmulatorEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $GameEmulatorEntriesTable> {
  $$GameEmulatorEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get romPath => $composableBuilder(
    column: $table.romPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emulator => $composableBuilder(
    column: $table.emulator,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameEmulatorEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameEmulatorEntriesTable> {
  $$GameEmulatorEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get romPath =>
      $composableBuilder(column: $table.romPath, builder: (column) => column);

  GeneratedColumn<String> get emulator =>
      $composableBuilder(column: $table.emulator, builder: (column) => column);
}

class $$GameEmulatorEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameEmulatorEntriesTable,
          GameEmulator,
          $$GameEmulatorEntriesTableFilterComposer,
          $$GameEmulatorEntriesTableOrderingComposer,
          $$GameEmulatorEntriesTableAnnotationComposer,
          $$GameEmulatorEntriesTableCreateCompanionBuilder,
          $$GameEmulatorEntriesTableUpdateCompanionBuilder,
          (
            GameEmulator,
            BaseReferences<
              _$AppDatabase,
              $GameEmulatorEntriesTable,
              GameEmulator
            >,
          ),
          GameEmulator,
          PrefetchHooks Function()
        > {
  $$GameEmulatorEntriesTableTableManager(
    _$AppDatabase db,
    $GameEmulatorEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameEmulatorEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameEmulatorEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GameEmulatorEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> romPath = const Value.absent(),
                Value<String> emulator = const Value.absent(),
              }) => GameEmulatorEntriesCompanion(
                id: id,
                romPath: romPath,
                emulator: emulator,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String romPath,
                required String emulator,
              }) => GameEmulatorEntriesCompanion.insert(
                id: id,
                romPath: romPath,
                emulator: emulator,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameEmulatorEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameEmulatorEntriesTable,
      GameEmulator,
      $$GameEmulatorEntriesTableFilterComposer,
      $$GameEmulatorEntriesTableOrderingComposer,
      $$GameEmulatorEntriesTableAnnotationComposer,
      $$GameEmulatorEntriesTableCreateCompanionBuilder,
      $$GameEmulatorEntriesTableUpdateCompanionBuilder,
      (
        GameEmulator,
        BaseReferences<_$AppDatabase, $GameEmulatorEntriesTable, GameEmulator>,
      ),
      GameEmulator,
      PrefetchHooks Function()
    >;
typedef $$RecentGameEntriesTableCreateCompanionBuilder =
    RecentGameEntriesCompanion Function({
      Value<int> id,
      required String romPath,
      required int timestamp,
    });
typedef $$RecentGameEntriesTableUpdateCompanionBuilder =
    RecentGameEntriesCompanion Function({
      Value<int> id,
      Value<String> romPath,
      Value<int> timestamp,
    });

class $$RecentGameEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $RecentGameEntriesTable> {
  $$RecentGameEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get romPath => $composableBuilder(
    column: $table.romPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentGameEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentGameEntriesTable> {
  $$RecentGameEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get romPath => $composableBuilder(
    column: $table.romPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentGameEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentGameEntriesTable> {
  $$RecentGameEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get romPath =>
      $composableBuilder(column: $table.romPath, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$RecentGameEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentGameEntriesTable,
          RecentGame,
          $$RecentGameEntriesTableFilterComposer,
          $$RecentGameEntriesTableOrderingComposer,
          $$RecentGameEntriesTableAnnotationComposer,
          $$RecentGameEntriesTableCreateCompanionBuilder,
          $$RecentGameEntriesTableUpdateCompanionBuilder,
          (
            RecentGame,
            BaseReferences<_$AppDatabase, $RecentGameEntriesTable, RecentGame>,
          ),
          RecentGame,
          PrefetchHooks Function()
        > {
  $$RecentGameEntriesTableTableManager(
    _$AppDatabase db,
    $RecentGameEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentGameEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentGameEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentGameEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> romPath = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
              }) => RecentGameEntriesCompanion(
                id: id,
                romPath: romPath,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String romPath,
                required int timestamp,
              }) => RecentGameEntriesCompanion.insert(
                id: id,
                romPath: romPath,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentGameEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentGameEntriesTable,
      RecentGame,
      $$RecentGameEntriesTableFilterComposer,
      $$RecentGameEntriesTableOrderingComposer,
      $$RecentGameEntriesTableAnnotationComposer,
      $$RecentGameEntriesTableCreateCompanionBuilder,
      $$RecentGameEntriesTableUpdateCompanionBuilder,
      (
        RecentGame,
        BaseReferences<_$AppDatabase, $RecentGameEntriesTable, RecentGame>,
      ),
      RecentGame,
      PrefetchHooks Function()
    >;
typedef $$AndroidAppEntriesTableCreateCompanionBuilder =
    AndroidAppEntriesCompanion Function({
      Value<int> id,
      required String package,
    });
typedef $$AndroidAppEntriesTableUpdateCompanionBuilder =
    AndroidAppEntriesCompanion Function({Value<int> id, Value<String> package});

class $$AndroidAppEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AndroidAppEntriesTable> {
  $$AndroidAppEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get package => $composableBuilder(
    column: $table.package,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AndroidAppEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AndroidAppEntriesTable> {
  $$AndroidAppEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get package => $composableBuilder(
    column: $table.package,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AndroidAppEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AndroidAppEntriesTable> {
  $$AndroidAppEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get package =>
      $composableBuilder(column: $table.package, builder: (column) => column);
}

class $$AndroidAppEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AndroidAppEntriesTable,
          AndroidApp,
          $$AndroidAppEntriesTableFilterComposer,
          $$AndroidAppEntriesTableOrderingComposer,
          $$AndroidAppEntriesTableAnnotationComposer,
          $$AndroidAppEntriesTableCreateCompanionBuilder,
          $$AndroidAppEntriesTableUpdateCompanionBuilder,
          (
            AndroidApp,
            BaseReferences<_$AppDatabase, $AndroidAppEntriesTable, AndroidApp>,
          ),
          AndroidApp,
          PrefetchHooks Function()
        > {
  $$AndroidAppEntriesTableTableManager(
    _$AppDatabase db,
    $AndroidAppEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AndroidAppEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AndroidAppEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AndroidAppEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> package = const Value.absent(),
              }) => AndroidAppEntriesCompanion(id: id, package: package),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String package,
              }) => AndroidAppEntriesCompanion.insert(id: id, package: package),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AndroidAppEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AndroidAppEntriesTable,
      AndroidApp,
      $$AndroidAppEntriesTableFilterComposer,
      $$AndroidAppEntriesTableOrderingComposer,
      $$AndroidAppEntriesTableAnnotationComposer,
      $$AndroidAppEntriesTableCreateCompanionBuilder,
      $$AndroidAppEntriesTableUpdateCompanionBuilder,
      (
        AndroidApp,
        BaseReferences<_$AppDatabase, $AndroidAppEntriesTable, AndroidApp>,
      ),
      AndroidApp,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingEntriesTableTableManager get settingEntries =>
      $$SettingEntriesTableTableManager(_db, _db.settingEntries);
  $$CustomEmulatorEntriesTableTableManager get customEmulatorEntries =>
      $$CustomEmulatorEntriesTableTableManager(_db, _db.customEmulatorEntries);
  $$AlternativeEmulatorEntriesTableTableManager
  get alternativeEmulatorEntries =>
      $$AlternativeEmulatorEntriesTableTableManager(
        _db,
        _db.alternativeEmulatorEntries,
      );
  $$GameEmulatorEntriesTableTableManager get gameEmulatorEntries =>
      $$GameEmulatorEntriesTableTableManager(_db, _db.gameEmulatorEntries);
  $$RecentGameEntriesTableTableManager get recentGameEntries =>
      $$RecentGameEntriesTableTableManager(_db, _db.recentGameEntries);
  $$AndroidAppEntriesTableTableManager get androidAppEntries =>
      $$AndroidAppEntriesTableTableManager(_db, _db.androidAppEntries);
}
