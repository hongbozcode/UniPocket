// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_store.dart';

// ignore_for_file: type=lint
class $SemesterRecordsTable extends SemesterRecords
    with TableInfo<$SemesterRecordsTable, StoredSemester> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemesterRecordsTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _firstMondayMeta = const VerificationMeta(
    'firstMonday',
  );
  @override
  late final GeneratedColumn<String> firstMonday = GeneratedColumn<String>(
    'first_monday',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalWeeksMeta = const VerificationMeta(
    'totalWeeks',
  );
  @override
  late final GeneratedColumn<int> totalWeeks = GeneratedColumn<int>(
    'total_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, firstMonday, totalWeeks];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semester_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredSemester> instance, {
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
    if (data.containsKey('first_monday')) {
      context.handle(
        _firstMondayMeta,
        firstMonday.isAcceptableOrUnknown(
          data['first_monday']!,
          _firstMondayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstMondayMeta);
    }
    if (data.containsKey('total_weeks')) {
      context.handle(
        _totalWeeksMeta,
        totalWeeks.isAcceptableOrUnknown(data['total_weeks']!, _totalWeeksMeta),
      );
    } else if (isInserting) {
      context.missing(_totalWeeksMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredSemester map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredSemester(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      firstMonday: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_monday'],
      )!,
      totalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_weeks'],
      )!,
    );
  }

  @override
  $SemesterRecordsTable createAlias(String alias) {
    return $SemesterRecordsTable(attachedDatabase, alias);
  }
}

class StoredSemester extends DataClass implements Insertable<StoredSemester> {
  final int id;
  final String name;
  final String firstMonday;
  final int totalWeeks;
  const StoredSemester({
    required this.id,
    required this.name,
    required this.firstMonday,
    required this.totalWeeks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['first_monday'] = Variable<String>(firstMonday);
    map['total_weeks'] = Variable<int>(totalWeeks);
    return map;
  }

  SemesterRecordsCompanion toCompanion(bool nullToAbsent) {
    return SemesterRecordsCompanion(
      id: Value(id),
      name: Value(name),
      firstMonday: Value(firstMonday),
      totalWeeks: Value(totalWeeks),
    );
  }

  factory StoredSemester.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredSemester(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      firstMonday: serializer.fromJson<String>(json['firstMonday']),
      totalWeeks: serializer.fromJson<int>(json['totalWeeks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'firstMonday': serializer.toJson<String>(firstMonday),
      'totalWeeks': serializer.toJson<int>(totalWeeks),
    };
  }

  StoredSemester copyWith({
    int? id,
    String? name,
    String? firstMonday,
    int? totalWeeks,
  }) => StoredSemester(
    id: id ?? this.id,
    name: name ?? this.name,
    firstMonday: firstMonday ?? this.firstMonday,
    totalWeeks: totalWeeks ?? this.totalWeeks,
  );
  StoredSemester copyWithCompanion(SemesterRecordsCompanion data) {
    return StoredSemester(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      firstMonday: data.firstMonday.present
          ? data.firstMonday.value
          : this.firstMonday,
      totalWeeks: data.totalWeeks.present
          ? data.totalWeeks.value
          : this.totalWeeks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredSemester(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firstMonday: $firstMonday, ')
          ..write('totalWeeks: $totalWeeks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, firstMonday, totalWeeks);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredSemester &&
          other.id == this.id &&
          other.name == this.name &&
          other.firstMonday == this.firstMonday &&
          other.totalWeeks == this.totalWeeks);
}

class SemesterRecordsCompanion extends UpdateCompanion<StoredSemester> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> firstMonday;
  final Value<int> totalWeeks;
  const SemesterRecordsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.firstMonday = const Value.absent(),
    this.totalWeeks = const Value.absent(),
  });
  SemesterRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String firstMonday,
    required int totalWeeks,
  }) : name = Value(name),
       firstMonday = Value(firstMonday),
       totalWeeks = Value(totalWeeks);
  static Insertable<StoredSemester> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? firstMonday,
    Expression<int>? totalWeeks,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (firstMonday != null) 'first_monday': firstMonday,
      if (totalWeeks != null) 'total_weeks': totalWeeks,
    });
  }

  SemesterRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? firstMonday,
    Value<int>? totalWeeks,
  }) {
    return SemesterRecordsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      firstMonday: firstMonday ?? this.firstMonday,
      totalWeeks: totalWeeks ?? this.totalWeeks,
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
    if (firstMonday.present) {
      map['first_monday'] = Variable<String>(firstMonday.value);
    }
    if (totalWeeks.present) {
      map['total_weeks'] = Variable<int>(totalWeeks.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemesterRecordsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firstMonday: $firstMonday, ')
          ..write('totalWeeks: $totalWeeks')
          ..write(')'))
        .toString();
  }
}

class $PeriodRecordsTable extends PeriodRecords
    with TableInfo<$PeriodRecordsTable, StoredPeriod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semester_records (id)',
    ),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    semesterId,
    weekday,
    number,
    startMinutes,
    endMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredPeriod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {semesterId, weekday, number};
  @override
  StoredPeriod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredPeriod(
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      )!,
    );
  }

  @override
  $PeriodRecordsTable createAlias(String alias) {
    return $PeriodRecordsTable(attachedDatabase, alias);
  }
}

class StoredPeriod extends DataClass implements Insertable<StoredPeriod> {
  final int semesterId;
  final int weekday;
  final int number;
  final int startMinutes;
  final int endMinutes;
  const StoredPeriod({
    required this.semesterId,
    required this.weekday,
    required this.number,
    required this.startMinutes,
    required this.endMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['semester_id'] = Variable<int>(semesterId);
    map['weekday'] = Variable<int>(weekday);
    map['number'] = Variable<int>(number);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    return map;
  }

  PeriodRecordsCompanion toCompanion(bool nullToAbsent) {
    return PeriodRecordsCompanion(
      semesterId: Value(semesterId),
      weekday: Value(weekday),
      number: Value(number),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
    );
  }

  factory StoredPeriod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredPeriod(
      semesterId: serializer.fromJson<int>(json['semesterId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      number: serializer.fromJson<int>(json['number']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'semesterId': serializer.toJson<int>(semesterId),
      'weekday': serializer.toJson<int>(weekday),
      'number': serializer.toJson<int>(number),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
    };
  }

  StoredPeriod copyWith({
    int? semesterId,
    int? weekday,
    int? number,
    int? startMinutes,
    int? endMinutes,
  }) => StoredPeriod(
    semesterId: semesterId ?? this.semesterId,
    weekday: weekday ?? this.weekday,
    number: number ?? this.number,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
  );
  StoredPeriod copyWithCompanion(PeriodRecordsCompanion data) {
    return StoredPeriod(
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      number: data.number.present ? data.number.value : this.number,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredPeriod(')
          ..write('semesterId: $semesterId, ')
          ..write('weekday: $weekday, ')
          ..write('number: $number, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(semesterId, weekday, number, startMinutes, endMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredPeriod &&
          other.semesterId == this.semesterId &&
          other.weekday == this.weekday &&
          other.number == this.number &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes);
}

class PeriodRecordsCompanion extends UpdateCompanion<StoredPeriod> {
  final Value<int> semesterId;
  final Value<int> weekday;
  final Value<int> number;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<int> rowid;
  const PeriodRecordsCompanion({
    this.semesterId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.number = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeriodRecordsCompanion.insert({
    required int semesterId,
    required int weekday,
    required int number,
    required int startMinutes,
    required int endMinutes,
    this.rowid = const Value.absent(),
  }) : semesterId = Value(semesterId),
       weekday = Value(weekday),
       number = Value(number),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes);
  static Insertable<StoredPeriod> custom({
    Expression<int>? semesterId,
    Expression<int>? weekday,
    Expression<int>? number,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (semesterId != null) 'semester_id': semesterId,
      if (weekday != null) 'weekday': weekday,
      if (number != null) 'number': number,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeriodRecordsCompanion copyWith({
    Value<int>? semesterId,
    Value<int>? weekday,
    Value<int>? number,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<int>? rowid,
  }) {
    return PeriodRecordsCompanion(
      semesterId: semesterId ?? this.semesterId,
      weekday: weekday ?? this.weekday,
      number: number ?? this.number,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodRecordsCompanion(')
          ..write('semesterId: $semesterId, ')
          ..write('weekday: $weekday, ')
          ..write('number: $number, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsRecordsTable extends SettingsRecords
    with TableInfo<$SettingsRecordsTable, StoredSettings> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentSemesterIdMeta = const VerificationMeta(
    'currentSemesterId',
  );
  @override
  late final GeneratedColumn<int> currentSemesterId = GeneratedColumn<int>(
    'current_semester_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semester_records (id)',
    ),
  );
  static const VerificationMeta _campusTimeZoneMeta = const VerificationMeta(
    'campusTimeZone',
  );
  @override
  late final GeneratedColumn<String> campusTimeZone = GeneratedColumn<String>(
    'campus_time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Asia/Shanghai'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, currentSemesterId, campusTimeZone];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredSettings> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_semester_id')) {
      context.handle(
        _currentSemesterIdMeta,
        currentSemesterId.isAcceptableOrUnknown(
          data['current_semester_id']!,
          _currentSemesterIdMeta,
        ),
      );
    }
    if (data.containsKey('campus_time_zone')) {
      context.handle(
        _campusTimeZoneMeta,
        campusTimeZone.isAcceptableOrUnknown(
          data['campus_time_zone']!,
          _campusTimeZoneMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredSettings map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredSettings(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentSemesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_semester_id'],
      ),
      campusTimeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campus_time_zone'],
      )!,
    );
  }

  @override
  $SettingsRecordsTable createAlias(String alias) {
    return $SettingsRecordsTable(attachedDatabase, alias);
  }
}

class StoredSettings extends DataClass implements Insertable<StoredSettings> {
  final int id;
  final int? currentSemesterId;
  final String campusTimeZone;
  const StoredSettings({
    required this.id,
    this.currentSemesterId,
    required this.campusTimeZone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || currentSemesterId != null) {
      map['current_semester_id'] = Variable<int>(currentSemesterId);
    }
    map['campus_time_zone'] = Variable<String>(campusTimeZone);
    return map;
  }

  SettingsRecordsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRecordsCompanion(
      id: Value(id),
      currentSemesterId: currentSemesterId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentSemesterId),
      campusTimeZone: Value(campusTimeZone),
    );
  }

  factory StoredSettings.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredSettings(
      id: serializer.fromJson<int>(json['id']),
      currentSemesterId: serializer.fromJson<int?>(json['currentSemesterId']),
      campusTimeZone: serializer.fromJson<String>(json['campusTimeZone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentSemesterId': serializer.toJson<int?>(currentSemesterId),
      'campusTimeZone': serializer.toJson<String>(campusTimeZone),
    };
  }

  StoredSettings copyWith({
    int? id,
    Value<int?> currentSemesterId = const Value.absent(),
    String? campusTimeZone,
  }) => StoredSettings(
    id: id ?? this.id,
    currentSemesterId: currentSemesterId.present
        ? currentSemesterId.value
        : this.currentSemesterId,
    campusTimeZone: campusTimeZone ?? this.campusTimeZone,
  );
  StoredSettings copyWithCompanion(SettingsRecordsCompanion data) {
    return StoredSettings(
      id: data.id.present ? data.id.value : this.id,
      currentSemesterId: data.currentSemesterId.present
          ? data.currentSemesterId.value
          : this.currentSemesterId,
      campusTimeZone: data.campusTimeZone.present
          ? data.campusTimeZone.value
          : this.campusTimeZone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredSettings(')
          ..write('id: $id, ')
          ..write('currentSemesterId: $currentSemesterId, ')
          ..write('campusTimeZone: $campusTimeZone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, currentSemesterId, campusTimeZone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredSettings &&
          other.id == this.id &&
          other.currentSemesterId == this.currentSemesterId &&
          other.campusTimeZone == this.campusTimeZone);
}

class SettingsRecordsCompanion extends UpdateCompanion<StoredSettings> {
  final Value<int> id;
  final Value<int?> currentSemesterId;
  final Value<String> campusTimeZone;
  const SettingsRecordsCompanion({
    this.id = const Value.absent(),
    this.currentSemesterId = const Value.absent(),
    this.campusTimeZone = const Value.absent(),
  });
  SettingsRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.currentSemesterId = const Value.absent(),
    this.campusTimeZone = const Value.absent(),
  });
  static Insertable<StoredSettings> custom({
    Expression<int>? id,
    Expression<int>? currentSemesterId,
    Expression<String>? campusTimeZone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentSemesterId != null) 'current_semester_id': currentSemesterId,
      if (campusTimeZone != null) 'campus_time_zone': campusTimeZone,
    });
  }

  SettingsRecordsCompanion copyWith({
    Value<int>? id,
    Value<int?>? currentSemesterId,
    Value<String>? campusTimeZone,
  }) {
    return SettingsRecordsCompanion(
      id: id ?? this.id,
      currentSemesterId: currentSemesterId ?? this.currentSemesterId,
      campusTimeZone: campusTimeZone ?? this.campusTimeZone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentSemesterId.present) {
      map['current_semester_id'] = Variable<int>(currentSemesterId.value);
    }
    if (campusTimeZone.present) {
      map['campus_time_zone'] = Variable<String>(campusTimeZone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRecordsCompanion(')
          ..write('id: $id, ')
          ..write('currentSemesterId: $currentSemesterId, ')
          ..write('campusTimeZone: $campusTimeZone')
          ..write(')'))
        .toString();
  }
}

class $CourseRecordsTable extends CourseRecords
    with TableInfo<$CourseRecordsTable, StoredCourse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semester_records (id)',
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
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    name,
    teacher,
    colorIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCourse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredCourse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCourse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
    );
  }

  @override
  $CourseRecordsTable createAlias(String alias) {
    return $CourseRecordsTable(attachedDatabase, alias);
  }
}

class StoredCourse extends DataClass implements Insertable<StoredCourse> {
  final int id;
  final int semesterId;
  final String name;
  final String teacher;
  final int colorIndex;
  const StoredCourse({
    required this.id,
    required this.semesterId,
    required this.name,
    required this.teacher,
    required this.colorIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    map['name'] = Variable<String>(name);
    map['teacher'] = Variable<String>(teacher);
    map['color_index'] = Variable<int>(colorIndex);
    return map;
  }

  CourseRecordsCompanion toCompanion(bool nullToAbsent) {
    return CourseRecordsCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      name: Value(name),
      teacher: Value(teacher),
      colorIndex: Value(colorIndex),
    );
  }

  factory StoredCourse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCourse(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      name: serializer.fromJson<String>(json['name']),
      teacher: serializer.fromJson<String>(json['teacher']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'name': serializer.toJson<String>(name),
      'teacher': serializer.toJson<String>(teacher),
      'colorIndex': serializer.toJson<int>(colorIndex),
    };
  }

  StoredCourse copyWith({
    int? id,
    int? semesterId,
    String? name,
    String? teacher,
    int? colorIndex,
  }) => StoredCourse(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    colorIndex: colorIndex ?? this.colorIndex,
  );
  StoredCourse copyWithCompanion(CourseRecordsCompanion data) {
    return StoredCourse(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      name: data.name.present ? data.name.value : this.name,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCourse(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('colorIndex: $colorIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, semesterId, name, teacher, colorIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCourse &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.name == this.name &&
          other.teacher == this.teacher &&
          other.colorIndex == this.colorIndex);
}

class CourseRecordsCompanion extends UpdateCompanion<StoredCourse> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<String> name;
  final Value<String> teacher;
  final Value<int> colorIndex;
  const CourseRecordsCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.name = const Value.absent(),
    this.teacher = const Value.absent(),
    this.colorIndex = const Value.absent(),
  });
  CourseRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    required String name,
    required String teacher,
    required int colorIndex,
  }) : semesterId = Value(semesterId),
       name = Value(name),
       teacher = Value(teacher),
       colorIndex = Value(colorIndex);
  static Insertable<StoredCourse> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<String>? name,
    Expression<String>? teacher,
    Expression<int>? colorIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (name != null) 'name': name,
      if (teacher != null) 'teacher': teacher,
      if (colorIndex != null) 'color_index': colorIndex,
    });
  }

  CourseRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<String>? name,
    Value<String>? teacher,
    Value<int>? colorIndex,
  }) {
    return CourseRecordsCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseRecordsCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('teacher: $teacher, ')
          ..write('colorIndex: $colorIndex')
          ..write(')'))
        .toString();
  }
}

class $ScheduleRecordsTable extends ScheduleRecords
    with TableInfo<$ScheduleRecordsTable, StoredSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_records (id)',
    ),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPeriodMeta = const VerificationMeta(
    'startPeriod',
  );
  @override
  late final GeneratedColumn<int> startPeriod = GeneratedColumn<int>(
    'start_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endPeriodMeta = const VerificationMeta(
    'endPeriod',
  );
  @override
  late final GeneratedColumn<int> endPeriod = GeneratedColumn<int>(
    'end_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weeksMeta = const VerificationMeta('weeks');
  @override
  late final GeneratedColumn<String> weeks = GeneratedColumn<String>(
    'weeks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    weekday,
    startPeriod,
    endPeriod,
    location,
    weeks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_period')) {
      context.handle(
        _startPeriodMeta,
        startPeriod.isAcceptableOrUnknown(
          data['start_period']!,
          _startPeriodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startPeriodMeta);
    }
    if (data.containsKey('end_period')) {
      context.handle(
        _endPeriodMeta,
        endPeriod.isAcceptableOrUnknown(data['end_period']!, _endPeriodMeta),
      );
    } else if (isInserting) {
      context.missing(_endPeriodMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('weeks')) {
      context.handle(
        _weeksMeta,
        weeks.isAcceptableOrUnknown(data['weeks']!, _weeksMeta),
      );
    } else if (isInserting) {
      context.missing(_weeksMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_period'],
      )!,
      endPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_period'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      weeks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weeks'],
      )!,
    );
  }

  @override
  $ScheduleRecordsTable createAlias(String alias) {
    return $ScheduleRecordsTable(attachedDatabase, alias);
  }
}

class StoredSchedule extends DataClass implements Insertable<StoredSchedule> {
  final int id;
  final int courseId;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final String location;
  final String weeks;
  const StoredSchedule({
    required this.id,
    required this.courseId,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required this.location,
    required this.weeks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['course_id'] = Variable<int>(courseId);
    map['weekday'] = Variable<int>(weekday);
    map['start_period'] = Variable<int>(startPeriod);
    map['end_period'] = Variable<int>(endPeriod);
    map['location'] = Variable<String>(location);
    map['weeks'] = Variable<String>(weeks);
    return map;
  }

  ScheduleRecordsCompanion toCompanion(bool nullToAbsent) {
    return ScheduleRecordsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      weekday: Value(weekday),
      startPeriod: Value(startPeriod),
      endPeriod: Value(endPeriod),
      location: Value(location),
      weeks: Value(weeks),
    );
  }

  factory StoredSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredSchedule(
      id: serializer.fromJson<int>(json['id']),
      courseId: serializer.fromJson<int>(json['courseId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startPeriod: serializer.fromJson<int>(json['startPeriod']),
      endPeriod: serializer.fromJson<int>(json['endPeriod']),
      location: serializer.fromJson<String>(json['location']),
      weeks: serializer.fromJson<String>(json['weeks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'courseId': serializer.toJson<int>(courseId),
      'weekday': serializer.toJson<int>(weekday),
      'startPeriod': serializer.toJson<int>(startPeriod),
      'endPeriod': serializer.toJson<int>(endPeriod),
      'location': serializer.toJson<String>(location),
      'weeks': serializer.toJson<String>(weeks),
    };
  }

  StoredSchedule copyWith({
    int? id,
    int? courseId,
    int? weekday,
    int? startPeriod,
    int? endPeriod,
    String? location,
    String? weeks,
  }) => StoredSchedule(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    weekday: weekday ?? this.weekday,
    startPeriod: startPeriod ?? this.startPeriod,
    endPeriod: endPeriod ?? this.endPeriod,
    location: location ?? this.location,
    weeks: weeks ?? this.weeks,
  );
  StoredSchedule copyWithCompanion(ScheduleRecordsCompanion data) {
    return StoredSchedule(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startPeriod: data.startPeriod.present
          ? data.startPeriod.value
          : this.startPeriod,
      endPeriod: data.endPeriod.present ? data.endPeriod.value : this.endPeriod,
      location: data.location.present ? data.location.value : this.location,
      weeks: data.weeks.present ? data.weeks.value : this.weeks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredSchedule(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('weekday: $weekday, ')
          ..write('startPeriod: $startPeriod, ')
          ..write('endPeriod: $endPeriod, ')
          ..write('location: $location, ')
          ..write('weeks: $weeks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    weekday,
    startPeriod,
    endPeriod,
    location,
    weeks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredSchedule &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.weekday == this.weekday &&
          other.startPeriod == this.startPeriod &&
          other.endPeriod == this.endPeriod &&
          other.location == this.location &&
          other.weeks == this.weeks);
}

class ScheduleRecordsCompanion extends UpdateCompanion<StoredSchedule> {
  final Value<int> id;
  final Value<int> courseId;
  final Value<int> weekday;
  final Value<int> startPeriod;
  final Value<int> endPeriod;
  final Value<String> location;
  final Value<String> weeks;
  const ScheduleRecordsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startPeriod = const Value.absent(),
    this.endPeriod = const Value.absent(),
    this.location = const Value.absent(),
    this.weeks = const Value.absent(),
  });
  ScheduleRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int courseId,
    required int weekday,
    required int startPeriod,
    required int endPeriod,
    required String location,
    required String weeks,
  }) : courseId = Value(courseId),
       weekday = Value(weekday),
       startPeriod = Value(startPeriod),
       endPeriod = Value(endPeriod),
       location = Value(location),
       weeks = Value(weeks);
  static Insertable<StoredSchedule> custom({
    Expression<int>? id,
    Expression<int>? courseId,
    Expression<int>? weekday,
    Expression<int>? startPeriod,
    Expression<int>? endPeriod,
    Expression<String>? location,
    Expression<String>? weeks,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (weekday != null) 'weekday': weekday,
      if (startPeriod != null) 'start_period': startPeriod,
      if (endPeriod != null) 'end_period': endPeriod,
      if (location != null) 'location': location,
      if (weeks != null) 'weeks': weeks,
    });
  }

  ScheduleRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? courseId,
    Value<int>? weekday,
    Value<int>? startPeriod,
    Value<int>? endPeriod,
    Value<String>? location,
    Value<String>? weeks,
  }) {
    return ScheduleRecordsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      weekday: weekday ?? this.weekday,
      startPeriod: startPeriod ?? this.startPeriod,
      endPeriod: endPeriod ?? this.endPeriod,
      location: location ?? this.location,
      weeks: weeks ?? this.weeks,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startPeriod.present) {
      map['start_period'] = Variable<int>(startPeriod.value);
    }
    if (endPeriod.present) {
      map['end_period'] = Variable<int>(endPeriod.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (weeks.present) {
      map['weeks'] = Variable<String>(weeks.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleRecordsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('weekday: $weekday, ')
          ..write('startPeriod: $startPeriod, ')
          ..write('endPeriod: $endPeriod, ')
          ..write('location: $location, ')
          ..write('weeks: $weeks')
          ..write(')'))
        .toString();
  }
}

class $LearningTaskRecordsTable extends LearningTaskRecords
    with TableInfo<$LearningTaskRecordsTable, StoredLearningTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningTaskRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueMinutesMeta = const VerificationMeta(
    'dueMinutes',
  );
  @override
  late final GeneratedColumn<int> dueMinutes = GeneratedColumn<int>(
    'due_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_records (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderMinutesBeforeMeta =
      const VerificationMeta('reminderMinutesBefore');
  @override
  late final GeneratedColumn<int> reminderMinutesBefore = GeneratedColumn<int>(
    'reminder_minutes_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1440),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    dueDate,
    dueMinutes,
    notes,
    courseId,
    isCompleted,
    reminderMinutesBefore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_task_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredLearningTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('due_minutes')) {
      context.handle(
        _dueMinutesMeta,
        dueMinutes.isAcceptableOrUnknown(data['due_minutes']!, _dueMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMinutesMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minutes_before')) {
      context.handle(
        _reminderMinutesBeforeMeta,
        reminderMinutesBefore.isAcceptableOrUnknown(
          data['reminder_minutes_before']!,
          _reminderMinutesBeforeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredLearningTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredLearningTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      dueMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_minutes'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      reminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_before'],
      ),
    );
  }

  @override
  $LearningTaskRecordsTable createAlias(String alias) {
    return $LearningTaskRecordsTable(attachedDatabase, alias);
  }
}

class StoredLearningTask extends DataClass
    implements Insertable<StoredLearningTask> {
  final int id;
  final String title;
  final String dueDate;
  final int dueMinutes;
  final String notes;
  final int? courseId;
  final bool isCompleted;
  final int? reminderMinutesBefore;
  const StoredLearningTask({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.dueMinutes,
    required this.notes,
    this.courseId,
    required this.isCompleted,
    this.reminderMinutesBefore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['due_date'] = Variable<String>(dueDate);
    map['due_minutes'] = Variable<int>(dueMinutes);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || courseId != null) {
      map['course_id'] = Variable<int>(courseId);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || reminderMinutesBefore != null) {
      map['reminder_minutes_before'] = Variable<int>(reminderMinutesBefore);
    }
    return map;
  }

  LearningTaskRecordsCompanion toCompanion(bool nullToAbsent) {
    return LearningTaskRecordsCompanion(
      id: Value(id),
      title: Value(title),
      dueDate: Value(dueDate),
      dueMinutes: Value(dueMinutes),
      notes: Value(notes),
      courseId: courseId == null && nullToAbsent
          ? const Value.absent()
          : Value(courseId),
      isCompleted: Value(isCompleted),
      reminderMinutesBefore: reminderMinutesBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutesBefore),
    );
  }

  factory StoredLearningTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredLearningTask(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      dueMinutes: serializer.fromJson<int>(json['dueMinutes']),
      notes: serializer.fromJson<String>(json['notes']),
      courseId: serializer.fromJson<int?>(json['courseId']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      reminderMinutesBefore: serializer.fromJson<int?>(
        json['reminderMinutesBefore'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'dueDate': serializer.toJson<String>(dueDate),
      'dueMinutes': serializer.toJson<int>(dueMinutes),
      'notes': serializer.toJson<String>(notes),
      'courseId': serializer.toJson<int?>(courseId),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'reminderMinutesBefore': serializer.toJson<int?>(reminderMinutesBefore),
    };
  }

  StoredLearningTask copyWith({
    int? id,
    String? title,
    String? dueDate,
    int? dueMinutes,
    String? notes,
    Value<int?> courseId = const Value.absent(),
    bool? isCompleted,
    Value<int?> reminderMinutesBefore = const Value.absent(),
  }) => StoredLearningTask(
    id: id ?? this.id,
    title: title ?? this.title,
    dueDate: dueDate ?? this.dueDate,
    dueMinutes: dueMinutes ?? this.dueMinutes,
    notes: notes ?? this.notes,
    courseId: courseId.present ? courseId.value : this.courseId,
    isCompleted: isCompleted ?? this.isCompleted,
    reminderMinutesBefore: reminderMinutesBefore.present
        ? reminderMinutesBefore.value
        : this.reminderMinutesBefore,
  );
  StoredLearningTask copyWithCompanion(LearningTaskRecordsCompanion data) {
    return StoredLearningTask(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueMinutes: data.dueMinutes.present
          ? data.dueMinutes.value
          : this.dueMinutes,
      notes: data.notes.present ? data.notes.value : this.notes,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      reminderMinutesBefore: data.reminderMinutesBefore.present
          ? data.reminderMinutesBefore.value
          : this.reminderMinutesBefore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredLearningTask(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinutes: $dueMinutes, ')
          ..write('notes: $notes, ')
          ..write('courseId: $courseId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    dueDate,
    dueMinutes,
    notes,
    courseId,
    isCompleted,
    reminderMinutesBefore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredLearningTask &&
          other.id == this.id &&
          other.title == this.title &&
          other.dueDate == this.dueDate &&
          other.dueMinutes == this.dueMinutes &&
          other.notes == this.notes &&
          other.courseId == this.courseId &&
          other.isCompleted == this.isCompleted &&
          other.reminderMinutesBefore == this.reminderMinutesBefore);
}

class LearningTaskRecordsCompanion extends UpdateCompanion<StoredLearningTask> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> dueDate;
  final Value<int> dueMinutes;
  final Value<String> notes;
  final Value<int?> courseId;
  final Value<bool> isCompleted;
  final Value<int?> reminderMinutesBefore;
  const LearningTaskRecordsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueMinutes = const Value.absent(),
    this.notes = const Value.absent(),
    this.courseId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
  });
  LearningTaskRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String dueDate,
    required int dueMinutes,
    required String notes,
    this.courseId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
  }) : title = Value(title),
       dueDate = Value(dueDate),
       dueMinutes = Value(dueMinutes),
       notes = Value(notes);
  static Insertable<StoredLearningTask> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? dueDate,
    Expression<int>? dueMinutes,
    Expression<String>? notes,
    Expression<int>? courseId,
    Expression<bool>? isCompleted,
    Expression<int>? reminderMinutesBefore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (dueDate != null) 'due_date': dueDate,
      if (dueMinutes != null) 'due_minutes': dueMinutes,
      if (notes != null) 'notes': notes,
      if (courseId != null) 'course_id': courseId,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
    });
  }

  LearningTaskRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? dueDate,
    Value<int>? dueMinutes,
    Value<String>? notes,
    Value<int?>? courseId,
    Value<bool>? isCompleted,
    Value<int?>? reminderMinutesBefore,
  }) {
    return LearningTaskRecordsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      dueMinutes: dueMinutes ?? this.dueMinutes,
      notes: notes ?? this.notes,
      courseId: courseId ?? this.courseId,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (dueMinutes.present) {
      map['due_minutes'] = Variable<int>(dueMinutes.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (reminderMinutesBefore.present) {
      map['reminder_minutes_before'] = Variable<int>(
        reminderMinutesBefore.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningTaskRecordsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinutes: $dueMinutes, ')
          ..write('notes: $notes, ')
          ..write('courseId: $courseId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore')
          ..write(')'))
        .toString();
  }
}

class $CountdownEventRecordsTable extends CountdownEventRecords
    with TableInfo<$CountdownEventRecordsTable, StoredCountdownEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountdownEventRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, targetDate, kind, isPinned];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'countdown_event_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCountdownEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredCountdownEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCountdownEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $CountdownEventRecordsTable createAlias(String alias) {
    return $CountdownEventRecordsTable(attachedDatabase, alias);
  }
}

class StoredCountdownEvent extends DataClass
    implements Insertable<StoredCountdownEvent> {
  final int id;
  final String title;
  final String targetDate;
  final String kind;
  final bool isPinned;
  const StoredCountdownEvent({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.kind,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['target_date'] = Variable<String>(targetDate);
    map['kind'] = Variable<String>(kind);
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  CountdownEventRecordsCompanion toCompanion(bool nullToAbsent) {
    return CountdownEventRecordsCompanion(
      id: Value(id),
      title: Value(title),
      targetDate: Value(targetDate),
      kind: Value(kind),
      isPinned: Value(isPinned),
    );
  }

  factory StoredCountdownEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCountdownEvent(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetDate: serializer.fromJson<String>(json['targetDate']),
      kind: serializer.fromJson<String>(json['kind']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'targetDate': serializer.toJson<String>(targetDate),
      'kind': serializer.toJson<String>(kind),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  StoredCountdownEvent copyWith({
    int? id,
    String? title,
    String? targetDate,
    String? kind,
    bool? isPinned,
  }) => StoredCountdownEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    targetDate: targetDate ?? this.targetDate,
    kind: kind ?? this.kind,
    isPinned: isPinned ?? this.isPinned,
  );
  StoredCountdownEvent copyWithCompanion(CountdownEventRecordsCompanion data) {
    return StoredCountdownEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      kind: data.kind.present ? data.kind.value : this.kind,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCountdownEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('kind: $kind, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, targetDate, kind, isPinned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCountdownEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetDate == this.targetDate &&
          other.kind == this.kind &&
          other.isPinned == this.isPinned);
}

class CountdownEventRecordsCompanion
    extends UpdateCompanion<StoredCountdownEvent> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> targetDate;
  final Value<String> kind;
  final Value<bool> isPinned;
  const CountdownEventRecordsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.kind = const Value.absent(),
    this.isPinned = const Value.absent(),
  });
  CountdownEventRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String targetDate,
    required String kind,
    this.isPinned = const Value.absent(),
  }) : title = Value(title),
       targetDate = Value(targetDate),
       kind = Value(kind);
  static Insertable<StoredCountdownEvent> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? targetDate,
    Expression<String>? kind,
    Expression<bool>? isPinned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetDate != null) 'target_date': targetDate,
      if (kind != null) 'kind': kind,
      if (isPinned != null) 'is_pinned': isPinned,
    });
  }

  CountdownEventRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? targetDate,
    Value<String>? kind,
    Value<bool>? isPinned,
  }) {
    return CountdownEventRecordsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      kind: kind ?? this.kind,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountdownEventRecordsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('kind: $kind, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }
}

class $ClassExceptionRecordsTable extends ClassExceptionRecords
    with TableInfo<$ClassExceptionRecordsTable, StoredClassException> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassExceptionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<int> scheduleId = GeneratedColumn<int>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedule_records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalDateMeta = const VerificationMeta(
    'originalDate',
  );
  @override
  late final GeneratedColumn<String> originalDate = GeneratedColumn<String>(
    'original_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCancelledMeta = const VerificationMeta(
    'isCancelled',
  );
  @override
  late final GeneratedColumn<bool> isCancelled = GeneratedColumn<bool>(
    'is_cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cancelled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleId,
    originalDate,
    targetDate,
    startMinutes,
    endMinutes,
    location,
    isCancelled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_exception_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredClassException> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('original_date')) {
      context.handle(
        _originalDateMeta,
        originalDate.isAcceptableOrUnknown(
          data['original_date']!,
          _originalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalDateMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('is_cancelled')) {
      context.handle(
        _isCancelledMeta,
        isCancelled.isAcceptableOrUnknown(
          data['is_cancelled']!,
          _isCancelledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCancelledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId, originalDate};
  @override
  StoredClassException map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredClassException(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_id'],
      )!,
      originalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_date'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      isCancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cancelled'],
      )!,
    );
  }

  @override
  $ClassExceptionRecordsTable createAlias(String alias) {
    return $ClassExceptionRecordsTable(attachedDatabase, alias);
  }
}

class StoredClassException extends DataClass
    implements Insertable<StoredClassException> {
  final int scheduleId;
  final String originalDate;
  final String targetDate;
  final int startMinutes;
  final int endMinutes;
  final String location;
  final bool isCancelled;
  const StoredClassException({
    required this.scheduleId,
    required this.originalDate,
    required this.targetDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.location,
    required this.isCancelled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<int>(scheduleId);
    map['original_date'] = Variable<String>(originalDate);
    map['target_date'] = Variable<String>(targetDate);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    map['location'] = Variable<String>(location);
    map['is_cancelled'] = Variable<bool>(isCancelled);
    return map;
  }

  ClassExceptionRecordsCompanion toCompanion(bool nullToAbsent) {
    return ClassExceptionRecordsCompanion(
      scheduleId: Value(scheduleId),
      originalDate: Value(originalDate),
      targetDate: Value(targetDate),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
      location: Value(location),
      isCancelled: Value(isCancelled),
    );
  }

  factory StoredClassException.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredClassException(
      scheduleId: serializer.fromJson<int>(json['scheduleId']),
      originalDate: serializer.fromJson<String>(json['originalDate']),
      targetDate: serializer.fromJson<String>(json['targetDate']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
      location: serializer.fromJson<String>(json['location']),
      isCancelled: serializer.fromJson<bool>(json['isCancelled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scheduleId': serializer.toJson<int>(scheduleId),
      'originalDate': serializer.toJson<String>(originalDate),
      'targetDate': serializer.toJson<String>(targetDate),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
      'location': serializer.toJson<String>(location),
      'isCancelled': serializer.toJson<bool>(isCancelled),
    };
  }

  StoredClassException copyWith({
    int? scheduleId,
    String? originalDate,
    String? targetDate,
    int? startMinutes,
    int? endMinutes,
    String? location,
    bool? isCancelled,
  }) => StoredClassException(
    scheduleId: scheduleId ?? this.scheduleId,
    originalDate: originalDate ?? this.originalDate,
    targetDate: targetDate ?? this.targetDate,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    location: location ?? this.location,
    isCancelled: isCancelled ?? this.isCancelled,
  );
  StoredClassException copyWithCompanion(ClassExceptionRecordsCompanion data) {
    return StoredClassException(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      originalDate: data.originalDate.present
          ? data.originalDate.value
          : this.originalDate,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      location: data.location.present ? data.location.value : this.location,
      isCancelled: data.isCancelled.present
          ? data.isCancelled.value
          : this.isCancelled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredClassException(')
          ..write('scheduleId: $scheduleId, ')
          ..write('originalDate: $originalDate, ')
          ..write('targetDate: $targetDate, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location, ')
          ..write('isCancelled: $isCancelled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleId,
    originalDate,
    targetDate,
    startMinutes,
    endMinutes,
    location,
    isCancelled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredClassException &&
          other.scheduleId == this.scheduleId &&
          other.originalDate == this.originalDate &&
          other.targetDate == this.targetDate &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.location == this.location &&
          other.isCancelled == this.isCancelled);
}

class ClassExceptionRecordsCompanion
    extends UpdateCompanion<StoredClassException> {
  final Value<int> scheduleId;
  final Value<String> originalDate;
  final Value<String> targetDate;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<String> location;
  final Value<bool> isCancelled;
  final Value<int> rowid;
  const ClassExceptionRecordsCompanion({
    this.scheduleId = const Value.absent(),
    this.originalDate = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.location = const Value.absent(),
    this.isCancelled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassExceptionRecordsCompanion.insert({
    required int scheduleId,
    required String originalDate,
    required String targetDate,
    required int startMinutes,
    required int endMinutes,
    required String location,
    required bool isCancelled,
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       originalDate = Value(originalDate),
       targetDate = Value(targetDate),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes),
       location = Value(location),
       isCancelled = Value(isCancelled);
  static Insertable<StoredClassException> custom({
    Expression<int>? scheduleId,
    Expression<String>? originalDate,
    Expression<String>? targetDate,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? location,
    Expression<bool>? isCancelled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (originalDate != null) 'original_date': originalDate,
      if (targetDate != null) 'target_date': targetDate,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (location != null) 'location': location,
      if (isCancelled != null) 'is_cancelled': isCancelled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassExceptionRecordsCompanion copyWith({
    Value<int>? scheduleId,
    Value<String>? originalDate,
    Value<String>? targetDate,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<String>? location,
    Value<bool>? isCancelled,
    Value<int>? rowid,
  }) {
    return ClassExceptionRecordsCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      originalDate: originalDate ?? this.originalDate,
      targetDate: targetDate ?? this.targetDate,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      location: location ?? this.location,
      isCancelled: isCancelled ?? this.isCancelled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<int>(scheduleId.value);
    }
    if (originalDate.present) {
      map['original_date'] = Variable<String>(originalDate.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (isCancelled.present) {
      map['is_cancelled'] = Variable<bool>(isCancelled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassExceptionRecordsCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('originalDate: $originalDate, ')
          ..write('targetDate: $targetDate, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location, ')
          ..write('isCancelled: $isCancelled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IndependentLessonRecordsTable extends IndependentLessonRecords
    with TableInfo<$IndependentLessonRecordsTable, StoredIndependentLesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndependentLessonRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    date,
    startMinutes,
    endMinutes,
    location,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'independent_lesson_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredIndependentLesson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredIndependentLesson map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredIndependentLesson(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      )!,
      endMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minutes'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
    );
  }

  @override
  $IndependentLessonRecordsTable createAlias(String alias) {
    return $IndependentLessonRecordsTable(attachedDatabase, alias);
  }
}

class StoredIndependentLesson extends DataClass
    implements Insertable<StoredIndependentLesson> {
  final int id;
  final int courseId;
  final String date;
  final int startMinutes;
  final int endMinutes;
  final String location;
  const StoredIndependentLesson({
    required this.id,
    required this.courseId,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.location,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['course_id'] = Variable<int>(courseId);
    map['date'] = Variable<String>(date);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    map['location'] = Variable<String>(location);
    return map;
  }

  IndependentLessonRecordsCompanion toCompanion(bool nullToAbsent) {
    return IndependentLessonRecordsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      date: Value(date),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
      location: Value(location),
    );
  }

  factory StoredIndependentLesson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredIndependentLesson(
      id: serializer.fromJson<int>(json['id']),
      courseId: serializer.fromJson<int>(json['courseId']),
      date: serializer.fromJson<String>(json['date']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
      location: serializer.fromJson<String>(json['location']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'courseId': serializer.toJson<int>(courseId),
      'date': serializer.toJson<String>(date),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
      'location': serializer.toJson<String>(location),
    };
  }

  StoredIndependentLesson copyWith({
    int? id,
    int? courseId,
    String? date,
    int? startMinutes,
    int? endMinutes,
    String? location,
  }) => StoredIndependentLesson(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    date: date ?? this.date,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    location: location ?? this.location,
  );
  StoredIndependentLesson copyWithCompanion(
    IndependentLessonRecordsCompanion data,
  ) {
    return StoredIndependentLesson(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      date: data.date.present ? data.date.value : this.date,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      endMinutes: data.endMinutes.present
          ? data.endMinutes.value
          : this.endMinutes,
      location: data.location.present ? data.location.value : this.location,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredIndependentLesson(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, courseId, date, startMinutes, endMinutes, location);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredIndependentLesson &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.date == this.date &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.location == this.location);
}

class IndependentLessonRecordsCompanion
    extends UpdateCompanion<StoredIndependentLesson> {
  final Value<int> id;
  final Value<int> courseId;
  final Value<String> date;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<String> location;
  const IndependentLessonRecordsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.date = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.location = const Value.absent(),
  });
  IndependentLessonRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int courseId,
    required String date,
    required int startMinutes,
    required int endMinutes,
    required String location,
  }) : courseId = Value(courseId),
       date = Value(date),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes),
       location = Value(location);
  static Insertable<StoredIndependentLesson> custom({
    Expression<int>? id,
    Expression<int>? courseId,
    Expression<String>? date,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? location,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (date != null) 'date': date,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (location != null) 'location': location,
    });
  }

  IndependentLessonRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? courseId,
    Value<String>? date,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<String>? location,
  }) {
    return IndependentLessonRecordsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      location: location ?? this.location,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndependentLessonRecordsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('date: $date, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }
}

abstract class _$PlannerStore extends GeneratedDatabase {
  _$PlannerStore(QueryExecutor e) : super(e);
  $PlannerStoreManager get managers => $PlannerStoreManager(this);
  late final $SemesterRecordsTable semesterRecords = $SemesterRecordsTable(
    this,
  );
  late final $PeriodRecordsTable periodRecords = $PeriodRecordsTable(this);
  late final $SettingsRecordsTable settingsRecords = $SettingsRecordsTable(
    this,
  );
  late final $CourseRecordsTable courseRecords = $CourseRecordsTable(this);
  late final $ScheduleRecordsTable scheduleRecords = $ScheduleRecordsTable(
    this,
  );
  late final $LearningTaskRecordsTable learningTaskRecords =
      $LearningTaskRecordsTable(this);
  late final $CountdownEventRecordsTable countdownEventRecords =
      $CountdownEventRecordsTable(this);
  late final $ClassExceptionRecordsTable classExceptionRecords =
      $ClassExceptionRecordsTable(this);
  late final $IndependentLessonRecordsTable independentLessonRecords =
      $IndependentLessonRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    semesterRecords,
    periodRecords,
    settingsRecords,
    courseRecords,
    scheduleRecords,
    learningTaskRecords,
    countdownEventRecords,
    classExceptionRecords,
    independentLessonRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('learning_task_records', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedule_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('class_exception_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('independent_lesson_records', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$SemesterRecordsTableCreateCompanionBuilder =
    SemesterRecordsCompanion Function({
      Value<int> id,
      required String name,
      required String firstMonday,
      required int totalWeeks,
    });
typedef $$SemesterRecordsTableUpdateCompanionBuilder =
    SemesterRecordsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> firstMonday,
      Value<int> totalWeeks,
    });

final class $$SemesterRecordsTableReferences
    extends
        BaseReferences<_$PlannerStore, $SemesterRecordsTable, StoredSemester> {
  $$SemesterRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PeriodRecordsTable, List<StoredPeriod>>
  _periodRecordsRefsTable(_$PlannerStore db) => MultiTypedResultKey.fromTable(
    db.periodRecords,
    aliasName: 'semester_records__id__period_records__semester_id',
  );

  $$PeriodRecordsTableProcessedTableManager get periodRecordsRefs {
    final manager = $$PeriodRecordsTableTableManager(
      $_db,
      $_db.periodRecords,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_periodRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SettingsRecordsTable, List<StoredSettings>>
  _settingsRecordsRefsTable(_$PlannerStore db) => MultiTypedResultKey.fromTable(
    db.settingsRecords,
    aliasName: 'semester_records__id__settings_records__current_semester_id',
  );

  $$SettingsRecordsTableProcessedTableManager get settingsRecordsRefs {
    final manager = $$SettingsRecordsTableTableManager(
      $_db,
      $_db.settingsRecords,
    ).filter((f) => f.currentSemesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _settingsRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CourseRecordsTable, List<StoredCourse>>
  _courseRecordsRefsTable(_$PlannerStore db) => MultiTypedResultKey.fromTable(
    db.courseRecords,
    aliasName: 'semester_records__id__course_records__semester_id',
  );

  $$CourseRecordsTableProcessedTableManager get courseRecordsRefs {
    final manager = $$CourseRecordsTableTableManager(
      $_db,
      $_db.courseRecords,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SemesterRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $SemesterRecordsTable> {
  $$SemesterRecordsTableFilterComposer({
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

  ColumnFilters<String> get firstMonday => $composableBuilder(
    column: $table.firstMonday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> periodRecordsRefs(
    Expression<bool> Function($$PeriodRecordsTableFilterComposer f) f,
  ) {
    final $$PeriodRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.periodRecords,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodRecordsTableFilterComposer(
            $db: $db,
            $table: $db.periodRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> settingsRecordsRefs(
    Expression<bool> Function($$SettingsRecordsTableFilterComposer f) f,
  ) {
    final $$SettingsRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settingsRecords,
      getReferencedColumn: (t) => t.currentSemesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettingsRecordsTableFilterComposer(
            $db: $db,
            $table: $db.settingsRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> courseRecordsRefs(
    Expression<bool> Function($$CourseRecordsTableFilterComposer f) f,
  ) {
    final $$CourseRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableFilterComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemesterRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $SemesterRecordsTable> {
  $$SemesterRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get firstMonday => $composableBuilder(
    column: $table.firstMonday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SemesterRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $SemesterRecordsTable> {
  $$SemesterRecordsTableAnnotationComposer({
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

  GeneratedColumn<String> get firstMonday => $composableBuilder(
    column: $table.firstMonday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => column,
  );

  Expression<T> periodRecordsRefs<T extends Object>(
    Expression<T> Function($$PeriodRecordsTableAnnotationComposer a) f,
  ) {
    final $$PeriodRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.periodRecords,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.periodRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> settingsRecordsRefs<T extends Object>(
    Expression<T> Function($$SettingsRecordsTableAnnotationComposer a) f,
  ) {
    final $$SettingsRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settingsRecords,
      getReferencedColumn: (t) => t.currentSemesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettingsRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.settingsRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> courseRecordsRefs<T extends Object>(
    Expression<T> Function($$CourseRecordsTableAnnotationComposer a) f,
  ) {
    final $$CourseRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemesterRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $SemesterRecordsTable,
          StoredSemester,
          $$SemesterRecordsTableFilterComposer,
          $$SemesterRecordsTableOrderingComposer,
          $$SemesterRecordsTableAnnotationComposer,
          $$SemesterRecordsTableCreateCompanionBuilder,
          $$SemesterRecordsTableUpdateCompanionBuilder,
          (StoredSemester, $$SemesterRecordsTableReferences),
          StoredSemester,
          PrefetchHooks Function({
            bool periodRecordsRefs,
            bool settingsRecordsRefs,
            bool courseRecordsRefs,
          })
        > {
  $$SemesterRecordsTableTableManager(
    _$PlannerStore db,
    $SemesterRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemesterRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemesterRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemesterRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> firstMonday = const Value.absent(),
                Value<int> totalWeeks = const Value.absent(),
              }) => SemesterRecordsCompanion(
                id: id,
                name: name,
                firstMonday: firstMonday,
                totalWeeks: totalWeeks,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String firstMonday,
                required int totalWeeks,
              }) => SemesterRecordsCompanion.insert(
                id: id,
                name: name,
                firstMonday: firstMonday,
                totalWeeks: totalWeeks,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SemesterRecordsTable, StoredSemester>(table),
                  $$SemesterRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                periodRecordsRefs = false,
                settingsRecordsRefs = false,
                courseRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (periodRecordsRefs) db.periodRecords,
                    if (settingsRecordsRefs) db.settingsRecords,
                    if (courseRecordsRefs) db.courseRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (periodRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredSemester,
                          $SemesterRecordsTable,
                          StoredPeriod,
                          $PeriodRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SemesterRecordsTableReferences
                              ._periodRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemesterRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).periodRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'semester_id',
                          typedResults: items,
                        ),
                      if (settingsRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredSemester,
                          $SemesterRecordsTable,
                          StoredSettings,
                          $SettingsRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SemesterRecordsTableReferences
                              ._settingsRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemesterRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).settingsRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'current_semester_id',
                          typedResults: items,
                        ),
                      if (courseRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredSemester,
                          $SemesterRecordsTable,
                          StoredCourse,
                          $CourseRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SemesterRecordsTableReferences
                              ._courseRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemesterRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'semester_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SemesterRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $SemesterRecordsTable,
      StoredSemester,
      $$SemesterRecordsTableFilterComposer,
      $$SemesterRecordsTableOrderingComposer,
      $$SemesterRecordsTableAnnotationComposer,
      $$SemesterRecordsTableCreateCompanionBuilder,
      $$SemesterRecordsTableUpdateCompanionBuilder,
      (StoredSemester, $$SemesterRecordsTableReferences),
      StoredSemester,
      PrefetchHooks Function({
        bool periodRecordsRefs,
        bool settingsRecordsRefs,
        bool courseRecordsRefs,
      })
    >;
typedef $$PeriodRecordsTableCreateCompanionBuilder =
    PeriodRecordsCompanion Function({
      required int semesterId,
      required int weekday,
      required int number,
      required int startMinutes,
      required int endMinutes,
      Value<int> rowid,
    });
typedef $$PeriodRecordsTableUpdateCompanionBuilder =
    PeriodRecordsCompanion Function({
      Value<int> semesterId,
      Value<int> weekday,
      Value<int> number,
      Value<int> startMinutes,
      Value<int> endMinutes,
      Value<int> rowid,
    });

final class $$PeriodRecordsTableReferences
    extends BaseReferences<_$PlannerStore, $PeriodRecordsTable, StoredPeriod> {
  $$PeriodRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemesterRecordsTable _semesterIdTable(_$PlannerStore db) => db
      .semesterRecords
      .createAlias('period_records__semester_id__semester_records__id');

  $$SemesterRecordsTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemesterRecordsTableTableManager(
      $_db,
      $_db.semesterRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PeriodRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $PeriodRecordsTable> {
  $$PeriodRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$SemesterRecordsTableFilterComposer get semesterId {
    final $$SemesterRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableFilterComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $PeriodRecordsTable> {
  $$PeriodRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemesterRecordsTableOrderingComposer get semesterId {
    final $$SemesterRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $PeriodRecordsTable> {
  $$PeriodRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  $$SemesterRecordsTableAnnotationComposer get semesterId {
    final $$SemesterRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $PeriodRecordsTable,
          StoredPeriod,
          $$PeriodRecordsTableFilterComposer,
          $$PeriodRecordsTableOrderingComposer,
          $$PeriodRecordsTableAnnotationComposer,
          $$PeriodRecordsTableCreateCompanionBuilder,
          $$PeriodRecordsTableUpdateCompanionBuilder,
          (StoredPeriod, $$PeriodRecordsTableReferences),
          StoredPeriod,
          PrefetchHooks Function({bool semesterId})
        > {
  $$PeriodRecordsTableTableManager(_$PlannerStore db, $PeriodRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> semesterId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int> endMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeriodRecordsCompanion(
                semesterId: semesterId,
                weekday: weekday,
                number: number,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int semesterId,
                required int weekday,
                required int number,
                required int startMinutes,
                required int endMinutes,
                Value<int> rowid = const Value.absent(),
              }) => PeriodRecordsCompanion.insert(
                semesterId: semesterId,
                weekday: weekday,
                number: number,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeriodRecordsTable, StoredPeriod>(table),
                  $$PeriodRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (semesterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.semesterId,
                        referencedTable: $$PeriodRecordsTableReferences
                            ._semesterIdTable(db),
                        referencedColumn: $$PeriodRecordsTableReferences
                            ._semesterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PeriodRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $PeriodRecordsTable,
      StoredPeriod,
      $$PeriodRecordsTableFilterComposer,
      $$PeriodRecordsTableOrderingComposer,
      $$PeriodRecordsTableAnnotationComposer,
      $$PeriodRecordsTableCreateCompanionBuilder,
      $$PeriodRecordsTableUpdateCompanionBuilder,
      (StoredPeriod, $$PeriodRecordsTableReferences),
      StoredPeriod,
      PrefetchHooks Function({bool semesterId})
    >;
typedef $$SettingsRecordsTableCreateCompanionBuilder =
    SettingsRecordsCompanion Function({
      Value<int> id,
      Value<int?> currentSemesterId,
      Value<String> campusTimeZone,
    });
typedef $$SettingsRecordsTableUpdateCompanionBuilder =
    SettingsRecordsCompanion Function({
      Value<int> id,
      Value<int?> currentSemesterId,
      Value<String> campusTimeZone,
    });

final class $$SettingsRecordsTableReferences
    extends
        BaseReferences<_$PlannerStore, $SettingsRecordsTable, StoredSettings> {
  $$SettingsRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemesterRecordsTable _currentSemesterIdTable(_$PlannerStore db) =>
      db.semesterRecords.createAlias(
        'settings_records__current_semester_id__semester_records__id',
      );

  $$SemesterRecordsTableProcessedTableManager? get currentSemesterId {
    final $_column = $_itemColumn<int>('current_semester_id');
    if ($_column == null) return null;
    final manager = $$SemesterRecordsTableTableManager(
      $_db,
      $_db.semesterRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currentSemesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SettingsRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $SettingsRecordsTable> {
  $$SettingsRecordsTableFilterComposer({
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

  ColumnFilters<String> get campusTimeZone => $composableBuilder(
    column: $table.campusTimeZone,
    builder: (column) => ColumnFilters(column),
  );

  $$SemesterRecordsTableFilterComposer get currentSemesterId {
    final $$SemesterRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentSemesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableFilterComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettingsRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $SettingsRecordsTable> {
  $$SettingsRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get campusTimeZone => $composableBuilder(
    column: $table.campusTimeZone,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemesterRecordsTableOrderingComposer get currentSemesterId {
    final $$SemesterRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentSemesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettingsRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $SettingsRecordsTable> {
  $$SettingsRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get campusTimeZone => $composableBuilder(
    column: $table.campusTimeZone,
    builder: (column) => column,
  );

  $$SemesterRecordsTableAnnotationComposer get currentSemesterId {
    final $$SemesterRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currentSemesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettingsRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $SettingsRecordsTable,
          StoredSettings,
          $$SettingsRecordsTableFilterComposer,
          $$SettingsRecordsTableOrderingComposer,
          $$SettingsRecordsTableAnnotationComposer,
          $$SettingsRecordsTableCreateCompanionBuilder,
          $$SettingsRecordsTableUpdateCompanionBuilder,
          (StoredSettings, $$SettingsRecordsTableReferences),
          StoredSettings,
          PrefetchHooks Function({bool currentSemesterId})
        > {
  $$SettingsRecordsTableTableManager(
    _$PlannerStore db,
    $SettingsRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> currentSemesterId = const Value.absent(),
                Value<String> campusTimeZone = const Value.absent(),
              }) => SettingsRecordsCompanion(
                id: id,
                currentSemesterId: currentSemesterId,
                campusTimeZone: campusTimeZone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> currentSemesterId = const Value.absent(),
                Value<String> campusTimeZone = const Value.absent(),
              }) => SettingsRecordsCompanion.insert(
                id: id,
                currentSemesterId: currentSemesterId,
                campusTimeZone: campusTimeZone,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsRecordsTable, StoredSettings>(table),
                  $$SettingsRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({currentSemesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (currentSemesterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.currentSemesterId,
                        referencedTable: $$SettingsRecordsTableReferences
                            ._currentSemesterIdTable(db),
                        referencedColumn: $$SettingsRecordsTableReferences
                            ._currentSemesterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SettingsRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $SettingsRecordsTable,
      StoredSettings,
      $$SettingsRecordsTableFilterComposer,
      $$SettingsRecordsTableOrderingComposer,
      $$SettingsRecordsTableAnnotationComposer,
      $$SettingsRecordsTableCreateCompanionBuilder,
      $$SettingsRecordsTableUpdateCompanionBuilder,
      (StoredSettings, $$SettingsRecordsTableReferences),
      StoredSettings,
      PrefetchHooks Function({bool currentSemesterId})
    >;
typedef $$CourseRecordsTableCreateCompanionBuilder =
    CourseRecordsCompanion Function({
      Value<int> id,
      required int semesterId,
      required String name,
      required String teacher,
      required int colorIndex,
    });
typedef $$CourseRecordsTableUpdateCompanionBuilder =
    CourseRecordsCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<String> name,
      Value<String> teacher,
      Value<int> colorIndex,
    });

final class $$CourseRecordsTableReferences
    extends BaseReferences<_$PlannerStore, $CourseRecordsTable, StoredCourse> {
  $$CourseRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemesterRecordsTable _semesterIdTable(_$PlannerStore db) => db
      .semesterRecords
      .createAlias('course_records__semester_id__semester_records__id');

  $$SemesterRecordsTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemesterRecordsTableTableManager(
      $_db,
      $_db.semesterRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScheduleRecordsTable, List<StoredSchedule>>
  _scheduleRecordsRefsTable(_$PlannerStore db) => MultiTypedResultKey.fromTable(
    db.scheduleRecords,
    aliasName: 'course_records__id__schedule_records__course_id',
  );

  $$ScheduleRecordsTableProcessedTableManager get scheduleRecordsRefs {
    final manager = $$ScheduleRecordsTableTableManager(
      $_db,
      $_db.scheduleRecords,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduleRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LearningTaskRecordsTable,
    List<StoredLearningTask>
  >
  _learningTaskRecordsRefsTable(_$PlannerStore db) =>
      MultiTypedResultKey.fromTable(
        db.learningTaskRecords,
        aliasName: 'course_records__id__learning_task_records__course_id',
      );

  $$LearningTaskRecordsTableProcessedTableManager get learningTaskRecordsRefs {
    final manager = $$LearningTaskRecordsTableTableManager(
      $_db,
      $_db.learningTaskRecords,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _learningTaskRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $IndependentLessonRecordsTable,
    List<StoredIndependentLesson>
  >
  _independentLessonRecordsRefsTable(_$PlannerStore db) =>
      MultiTypedResultKey.fromTable(
        db.independentLessonRecords,
        aliasName: 'course_records__id__independent_lesson_records__course_id',
      );

  $$IndependentLessonRecordsTableProcessedTableManager
  get independentLessonRecordsRefs {
    final manager = $$IndependentLessonRecordsTableTableManager(
      $_db,
      $_db.independentLessonRecords,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _independentLessonRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CourseRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $CourseRecordsTable> {
  $$CourseRecordsTableFilterComposer({
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

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$SemesterRecordsTableFilterComposer get semesterId {
    final $$SemesterRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableFilterComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scheduleRecordsRefs(
    Expression<bool> Function($$ScheduleRecordsTableFilterComposer f) f,
  ) {
    final $$ScheduleRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleRecords,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleRecordsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> learningTaskRecordsRefs(
    Expression<bool> Function($$LearningTaskRecordsTableFilterComposer f) f,
  ) {
    final $$LearningTaskRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.learningTaskRecords,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningTaskRecordsTableFilterComposer(
            $db: $db,
            $table: $db.learningTaskRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> independentLessonRecordsRefs(
    Expression<bool> Function($$IndependentLessonRecordsTableFilterComposer f)
    f,
  ) {
    final $$IndependentLessonRecordsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.independentLessonRecords,
          getReferencedColumn: (t) => t.courseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IndependentLessonRecordsTableFilterComposer(
                $db: $db,
                $table: $db.independentLessonRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CourseRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $CourseRecordsTable> {
  $$CourseRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemesterRecordsTableOrderingComposer get semesterId {
    final $$SemesterRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $CourseRecordsTable> {
  $$CourseRecordsTableAnnotationComposer({
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

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  $$SemesterRecordsTableAnnotationComposer get semesterId {
    final $$SemesterRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesterRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemesterRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.semesterRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scheduleRecordsRefs<T extends Object>(
    Expression<T> Function($$ScheduleRecordsTableAnnotationComposer a) f,
  ) {
    final $$ScheduleRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleRecords,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.scheduleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> learningTaskRecordsRefs<T extends Object>(
    Expression<T> Function($$LearningTaskRecordsTableAnnotationComposer a) f,
  ) {
    final $$LearningTaskRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.learningTaskRecords,
          getReferencedColumn: (t) => t.courseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LearningTaskRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.learningTaskRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> independentLessonRecordsRefs<T extends Object>(
    Expression<T> Function($$IndependentLessonRecordsTableAnnotationComposer a)
    f,
  ) {
    final $$IndependentLessonRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.independentLessonRecords,
          getReferencedColumn: (t) => t.courseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IndependentLessonRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.independentLessonRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CourseRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $CourseRecordsTable,
          StoredCourse,
          $$CourseRecordsTableFilterComposer,
          $$CourseRecordsTableOrderingComposer,
          $$CourseRecordsTableAnnotationComposer,
          $$CourseRecordsTableCreateCompanionBuilder,
          $$CourseRecordsTableUpdateCompanionBuilder,
          (StoredCourse, $$CourseRecordsTableReferences),
          StoredCourse,
          PrefetchHooks Function({
            bool semesterId,
            bool scheduleRecordsRefs,
            bool learningTaskRecordsRefs,
            bool independentLessonRecordsRefs,
          })
        > {
  $$CourseRecordsTableTableManager(_$PlannerStore db, $CourseRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> teacher = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
              }) => CourseRecordsCompanion(
                id: id,
                semesterId: semesterId,
                name: name,
                teacher: teacher,
                colorIndex: colorIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                required String name,
                required String teacher,
                required int colorIndex,
              }) => CourseRecordsCompanion.insert(
                id: id,
                semesterId: semesterId,
                name: name,
                teacher: teacher,
                colorIndex: colorIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CourseRecordsTable, StoredCourse>(table),
                  $$CourseRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                semesterId = false,
                scheduleRecordsRefs = false,
                learningTaskRecordsRefs = false,
                independentLessonRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scheduleRecordsRefs) db.scheduleRecords,
                    if (learningTaskRecordsRefs) db.learningTaskRecords,
                    if (independentLessonRecordsRefs)
                      db.independentLessonRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (semesterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.semesterId,
                            referencedTable: $$CourseRecordsTableReferences
                                ._semesterIdTable(db),
                            referencedColumn: $$CourseRecordsTableReferences
                                ._semesterIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scheduleRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredCourse,
                          $CourseRecordsTable,
                          StoredSchedule,
                          $ScheduleRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CourseRecordsTableReferences
                              ._scheduleRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'course_id',
                          typedResults: items,
                        ),
                      if (learningTaskRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredCourse,
                          $CourseRecordsTable,
                          StoredLearningTask,
                          $LearningTaskRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CourseRecordsTableReferences
                              ._learningTaskRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).learningTaskRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'course_id',
                          typedResults: items,
                        ),
                      if (independentLessonRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredCourse,
                          $CourseRecordsTable,
                          StoredIndependentLesson,
                          $IndependentLessonRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CourseRecordsTableReferences
                              ._independentLessonRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).independentLessonRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'course_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CourseRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $CourseRecordsTable,
      StoredCourse,
      $$CourseRecordsTableFilterComposer,
      $$CourseRecordsTableOrderingComposer,
      $$CourseRecordsTableAnnotationComposer,
      $$CourseRecordsTableCreateCompanionBuilder,
      $$CourseRecordsTableUpdateCompanionBuilder,
      (StoredCourse, $$CourseRecordsTableReferences),
      StoredCourse,
      PrefetchHooks Function({
        bool semesterId,
        bool scheduleRecordsRefs,
        bool learningTaskRecordsRefs,
        bool independentLessonRecordsRefs,
      })
    >;
typedef $$ScheduleRecordsTableCreateCompanionBuilder =
    ScheduleRecordsCompanion Function({
      Value<int> id,
      required int courseId,
      required int weekday,
      required int startPeriod,
      required int endPeriod,
      required String location,
      required String weeks,
    });
typedef $$ScheduleRecordsTableUpdateCompanionBuilder =
    ScheduleRecordsCompanion Function({
      Value<int> id,
      Value<int> courseId,
      Value<int> weekday,
      Value<int> startPeriod,
      Value<int> endPeriod,
      Value<String> location,
      Value<String> weeks,
    });

final class $$ScheduleRecordsTableReferences
    extends
        BaseReferences<_$PlannerStore, $ScheduleRecordsTable, StoredSchedule> {
  $$ScheduleRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseRecordsTable _courseIdTable(_$PlannerStore db) => db
      .courseRecords
      .createAlias('schedule_records__course_id__course_records__id');

  $$CourseRecordsTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<int>('course_id')!;

    final manager = $$CourseRecordsTableTableManager(
      $_db,
      $_db.courseRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ClassExceptionRecordsTable,
    List<StoredClassException>
  >
  _classExceptionRecordsRefsTable(_$PlannerStore db) =>
      MultiTypedResultKey.fromTable(
        db.classExceptionRecords,
        aliasName: 'schedule_records__id__class_exception_records__schedule_id',
      );

  $$ClassExceptionRecordsTableProcessedTableManager
  get classExceptionRecordsRefs {
    final manager = $$ClassExceptionRecordsTableTableManager(
      $_db,
      $_db.classExceptionRecords,
    ).filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _classExceptionRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScheduleRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $ScheduleRecordsTable> {
  $$ScheduleRecordsTableFilterComposer({
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

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPeriod => $composableBuilder(
    column: $table.startPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endPeriod => $composableBuilder(
    column: $table.endPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnFilters(column),
  );

  $$CourseRecordsTableFilterComposer get courseId {
    final $$CourseRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableFilterComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> classExceptionRecordsRefs(
    Expression<bool> Function($$ClassExceptionRecordsTableFilterComposer f) f,
  ) {
    final $$ClassExceptionRecordsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.classExceptionRecords,
          getReferencedColumn: (t) => t.scheduleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassExceptionRecordsTableFilterComposer(
                $db: $db,
                $table: $db.classExceptionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ScheduleRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $ScheduleRecordsTable> {
  $$ScheduleRecordsTableOrderingComposer({
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

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPeriod => $composableBuilder(
    column: $table.startPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endPeriod => $composableBuilder(
    column: $table.endPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnOrderings(column),
  );

  $$CourseRecordsTableOrderingComposer get courseId {
    final $$CourseRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $ScheduleRecordsTable> {
  $$ScheduleRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get startPeriod => $composableBuilder(
    column: $table.startPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endPeriod =>
      $composableBuilder(column: $table.endPeriod, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get weeks =>
      $composableBuilder(column: $table.weeks, builder: (column) => column);

  $$CourseRecordsTableAnnotationComposer get courseId {
    final $$CourseRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> classExceptionRecordsRefs<T extends Object>(
    Expression<T> Function($$ClassExceptionRecordsTableAnnotationComposer a) f,
  ) {
    final $$ClassExceptionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.classExceptionRecords,
          getReferencedColumn: (t) => t.scheduleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassExceptionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.classExceptionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ScheduleRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $ScheduleRecordsTable,
          StoredSchedule,
          $$ScheduleRecordsTableFilterComposer,
          $$ScheduleRecordsTableOrderingComposer,
          $$ScheduleRecordsTableAnnotationComposer,
          $$ScheduleRecordsTableCreateCompanionBuilder,
          $$ScheduleRecordsTableUpdateCompanionBuilder,
          (StoredSchedule, $$ScheduleRecordsTableReferences),
          StoredSchedule,
          PrefetchHooks Function({
            bool courseId,
            bool classExceptionRecordsRefs,
          })
        > {
  $$ScheduleRecordsTableTableManager(
    _$PlannerStore db,
    $ScheduleRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> courseId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> startPeriod = const Value.absent(),
                Value<int> endPeriod = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> weeks = const Value.absent(),
              }) => ScheduleRecordsCompanion(
                id: id,
                courseId: courseId,
                weekday: weekday,
                startPeriod: startPeriod,
                endPeriod: endPeriod,
                location: location,
                weeks: weeks,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int courseId,
                required int weekday,
                required int startPeriod,
                required int endPeriod,
                required String location,
                required String weeks,
              }) => ScheduleRecordsCompanion.insert(
                id: id,
                courseId: courseId,
                weekday: weekday,
                startPeriod: startPeriod,
                endPeriod: endPeriod,
                location: location,
                weeks: weeks,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleRecordsTable, StoredSchedule>(table),
                  $$ScheduleRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({courseId = false, classExceptionRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (classExceptionRecordsRefs) db.classExceptionRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.courseId,
                            referencedTable: $$ScheduleRecordsTableReferences
                                ._courseIdTable(db),
                            referencedColumn: $$ScheduleRecordsTableReferences
                                ._courseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (classExceptionRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredSchedule,
                          $ScheduleRecordsTable,
                          StoredClassException,
                          $ClassExceptionRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ScheduleRecordsTableReferences
                              ._classExceptionRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScheduleRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).classExceptionRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'schedule_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScheduleRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $ScheduleRecordsTable,
      StoredSchedule,
      $$ScheduleRecordsTableFilterComposer,
      $$ScheduleRecordsTableOrderingComposer,
      $$ScheduleRecordsTableAnnotationComposer,
      $$ScheduleRecordsTableCreateCompanionBuilder,
      $$ScheduleRecordsTableUpdateCompanionBuilder,
      (StoredSchedule, $$ScheduleRecordsTableReferences),
      StoredSchedule,
      PrefetchHooks Function({bool courseId, bool classExceptionRecordsRefs})
    >;
typedef $$LearningTaskRecordsTableCreateCompanionBuilder =
    LearningTaskRecordsCompanion Function({
      Value<int> id,
      required String title,
      required String dueDate,
      required int dueMinutes,
      required String notes,
      Value<int?> courseId,
      Value<bool> isCompleted,
      Value<int?> reminderMinutesBefore,
    });
typedef $$LearningTaskRecordsTableUpdateCompanionBuilder =
    LearningTaskRecordsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> dueDate,
      Value<int> dueMinutes,
      Value<String> notes,
      Value<int?> courseId,
      Value<bool> isCompleted,
      Value<int?> reminderMinutesBefore,
    });

final class $$LearningTaskRecordsTableReferences
    extends
        BaseReferences<
          _$PlannerStore,
          $LearningTaskRecordsTable,
          StoredLearningTask
        > {
  $$LearningTaskRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseRecordsTable _courseIdTable(_$PlannerStore db) => db
      .courseRecords
      .createAlias('learning_task_records__course_id__course_records__id');

  $$CourseRecordsTableProcessedTableManager? get courseId {
    final $_column = $_itemColumn<int>('course_id');
    if ($_column == null) return null;
    final manager = $$CourseRecordsTableTableManager(
      $_db,
      $_db.courseRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LearningTaskRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $LearningTaskRecordsTable> {
  $$LearningTaskRecordsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueMinutes => $composableBuilder(
    column: $table.dueMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  $$CourseRecordsTableFilterComposer get courseId {
    final $$CourseRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableFilterComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearningTaskRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $LearningTaskRecordsTable> {
  $$LearningTaskRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueMinutes => $composableBuilder(
    column: $table.dueMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  $$CourseRecordsTableOrderingComposer get courseId {
    final $$CourseRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearningTaskRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $LearningTaskRecordsTable> {
  $$LearningTaskRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueMinutes => $composableBuilder(
    column: $table.dueMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => column,
  );

  $$CourseRecordsTableAnnotationComposer get courseId {
    final $$CourseRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearningTaskRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $LearningTaskRecordsTable,
          StoredLearningTask,
          $$LearningTaskRecordsTableFilterComposer,
          $$LearningTaskRecordsTableOrderingComposer,
          $$LearningTaskRecordsTableAnnotationComposer,
          $$LearningTaskRecordsTableCreateCompanionBuilder,
          $$LearningTaskRecordsTableUpdateCompanionBuilder,
          (StoredLearningTask, $$LearningTaskRecordsTableReferences),
          StoredLearningTask,
          PrefetchHooks Function({bool courseId})
        > {
  $$LearningTaskRecordsTableTableManager(
    _$PlannerStore db,
    $LearningTaskRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningTaskRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningTaskRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LearningTaskRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<int> dueMinutes = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int?> courseId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
              }) => LearningTaskRecordsCompanion(
                id: id,
                title: title,
                dueDate: dueDate,
                dueMinutes: dueMinutes,
                notes: notes,
                courseId: courseId,
                isCompleted: isCompleted,
                reminderMinutesBefore: reminderMinutesBefore,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String dueDate,
                required int dueMinutes,
                required String notes,
                Value<int?> courseId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
              }) => LearningTaskRecordsCompanion.insert(
                id: id,
                title: title,
                dueDate: dueDate,
                dueMinutes: dueMinutes,
                notes: notes,
                courseId: courseId,
                isCompleted: isCompleted,
                reminderMinutesBefore: reminderMinutesBefore,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LearningTaskRecordsTable, StoredLearningTask>(
                    table,
                  ),
                  $$LearningTaskRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.courseId,
                        referencedTable: $$LearningTaskRecordsTableReferences
                            ._courseIdTable(db),
                        referencedColumn: $$LearningTaskRecordsTableReferences
                            ._courseIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LearningTaskRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $LearningTaskRecordsTable,
      StoredLearningTask,
      $$LearningTaskRecordsTableFilterComposer,
      $$LearningTaskRecordsTableOrderingComposer,
      $$LearningTaskRecordsTableAnnotationComposer,
      $$LearningTaskRecordsTableCreateCompanionBuilder,
      $$LearningTaskRecordsTableUpdateCompanionBuilder,
      (StoredLearningTask, $$LearningTaskRecordsTableReferences),
      StoredLearningTask,
      PrefetchHooks Function({bool courseId})
    >;
typedef $$CountdownEventRecordsTableCreateCompanionBuilder =
    CountdownEventRecordsCompanion Function({
      Value<int> id,
      required String title,
      required String targetDate,
      required String kind,
      Value<bool> isPinned,
    });
typedef $$CountdownEventRecordsTableUpdateCompanionBuilder =
    CountdownEventRecordsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> targetDate,
      Value<String> kind,
      Value<bool> isPinned,
    });

class $$CountdownEventRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $CountdownEventRecordsTable> {
  $$CountdownEventRecordsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CountdownEventRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $CountdownEventRecordsTable> {
  $$CountdownEventRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CountdownEventRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $CountdownEventRecordsTable> {
  $$CountdownEventRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);
}

class $$CountdownEventRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $CountdownEventRecordsTable,
          StoredCountdownEvent,
          $$CountdownEventRecordsTableFilterComposer,
          $$CountdownEventRecordsTableOrderingComposer,
          $$CountdownEventRecordsTableAnnotationComposer,
          $$CountdownEventRecordsTableCreateCompanionBuilder,
          $$CountdownEventRecordsTableUpdateCompanionBuilder,
          (
            StoredCountdownEvent,
            BaseReferences<
              _$PlannerStore,
              $CountdownEventRecordsTable,
              StoredCountdownEvent
            >,
          ),
          StoredCountdownEvent,
          PrefetchHooks Function()
        > {
  $$CountdownEventRecordsTableTableManager(
    _$PlannerStore db,
    $CountdownEventRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountdownEventRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CountdownEventRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CountdownEventRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> targetDate = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
              }) => CountdownEventRecordsCompanion(
                id: id,
                title: title,
                targetDate: targetDate,
                kind: kind,
                isPinned: isPinned,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String targetDate,
                required String kind,
                Value<bool> isPinned = const Value.absent(),
              }) => CountdownEventRecordsCompanion.insert(
                id: id,
                title: title,
                targetDate: targetDate,
                kind: kind,
                isPinned: isPinned,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CountdownEventRecordsTable,
                    StoredCountdownEvent
                  >(table),
                  BaseReferences<
                    _$PlannerStore,
                    $CountdownEventRecordsTable,
                    StoredCountdownEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CountdownEventRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $CountdownEventRecordsTable,
      StoredCountdownEvent,
      $$CountdownEventRecordsTableFilterComposer,
      $$CountdownEventRecordsTableOrderingComposer,
      $$CountdownEventRecordsTableAnnotationComposer,
      $$CountdownEventRecordsTableCreateCompanionBuilder,
      $$CountdownEventRecordsTableUpdateCompanionBuilder,
      (
        StoredCountdownEvent,
        BaseReferences<
          _$PlannerStore,
          $CountdownEventRecordsTable,
          StoredCountdownEvent
        >,
      ),
      StoredCountdownEvent,
      PrefetchHooks Function()
    >;
typedef $$ClassExceptionRecordsTableCreateCompanionBuilder =
    ClassExceptionRecordsCompanion Function({
      required int scheduleId,
      required String originalDate,
      required String targetDate,
      required int startMinutes,
      required int endMinutes,
      required String location,
      required bool isCancelled,
      Value<int> rowid,
    });
typedef $$ClassExceptionRecordsTableUpdateCompanionBuilder =
    ClassExceptionRecordsCompanion Function({
      Value<int> scheduleId,
      Value<String> originalDate,
      Value<String> targetDate,
      Value<int> startMinutes,
      Value<int> endMinutes,
      Value<String> location,
      Value<bool> isCancelled,
      Value<int> rowid,
    });

final class $$ClassExceptionRecordsTableReferences
    extends
        BaseReferences<
          _$PlannerStore,
          $ClassExceptionRecordsTable,
          StoredClassException
        > {
  $$ClassExceptionRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScheduleRecordsTable _scheduleIdTable(_$PlannerStore db) =>
      db.scheduleRecords.createAlias(
        'class_exception_records__schedule_id__schedule_records__id',
      );

  $$ScheduleRecordsTableProcessedTableManager get scheduleId {
    final $_column = $_itemColumn<int>('schedule_id')!;

    final manager = $$ScheduleRecordsTableTableManager(
      $_db,
      $_db.scheduleRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClassExceptionRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $ClassExceptionRecordsTable> {
  $$ClassExceptionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => ColumnFilters(column),
  );

  $$ScheduleRecordsTableFilterComposer get scheduleId {
    final $$ScheduleRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.scheduleRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleRecordsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassExceptionRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $ClassExceptionRecordsTable> {
  $$ClassExceptionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScheduleRecordsTableOrderingComposer get scheduleId {
    final $$ScheduleRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.scheduleRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.scheduleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassExceptionRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $ClassExceptionRecordsTable> {
  $$ClassExceptionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<bool> get isCancelled => $composableBuilder(
    column: $table.isCancelled,
    builder: (column) => column,
  );

  $$ScheduleRecordsTableAnnotationComposer get scheduleId {
    final $$ScheduleRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.scheduleRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.scheduleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassExceptionRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $ClassExceptionRecordsTable,
          StoredClassException,
          $$ClassExceptionRecordsTableFilterComposer,
          $$ClassExceptionRecordsTableOrderingComposer,
          $$ClassExceptionRecordsTableAnnotationComposer,
          $$ClassExceptionRecordsTableCreateCompanionBuilder,
          $$ClassExceptionRecordsTableUpdateCompanionBuilder,
          (StoredClassException, $$ClassExceptionRecordsTableReferences),
          StoredClassException,
          PrefetchHooks Function({bool scheduleId})
        > {
  $$ClassExceptionRecordsTableTableManager(
    _$PlannerStore db,
    $ClassExceptionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassExceptionRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ClassExceptionRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClassExceptionRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> scheduleId = const Value.absent(),
                Value<String> originalDate = const Value.absent(),
                Value<String> targetDate = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int> endMinutes = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<bool> isCancelled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassExceptionRecordsCompanion(
                scheduleId: scheduleId,
                originalDate: originalDate,
                targetDate: targetDate,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
                isCancelled: isCancelled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int scheduleId,
                required String originalDate,
                required String targetDate,
                required int startMinutes,
                required int endMinutes,
                required String location,
                required bool isCancelled,
                Value<int> rowid = const Value.absent(),
              }) => ClassExceptionRecordsCompanion.insert(
                scheduleId: scheduleId,
                originalDate: originalDate,
                targetDate: targetDate,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
                isCancelled: isCancelled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ClassExceptionRecordsTable,
                    StoredClassException
                  >(table),
                  $$ClassExceptionRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scheduleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scheduleId,
                        referencedTable: $$ClassExceptionRecordsTableReferences
                            ._scheduleIdTable(db),
                        referencedColumn: $$ClassExceptionRecordsTableReferences
                            ._scheduleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ClassExceptionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $ClassExceptionRecordsTable,
      StoredClassException,
      $$ClassExceptionRecordsTableFilterComposer,
      $$ClassExceptionRecordsTableOrderingComposer,
      $$ClassExceptionRecordsTableAnnotationComposer,
      $$ClassExceptionRecordsTableCreateCompanionBuilder,
      $$ClassExceptionRecordsTableUpdateCompanionBuilder,
      (StoredClassException, $$ClassExceptionRecordsTableReferences),
      StoredClassException,
      PrefetchHooks Function({bool scheduleId})
    >;
typedef $$IndependentLessonRecordsTableCreateCompanionBuilder =
    IndependentLessonRecordsCompanion Function({
      Value<int> id,
      required int courseId,
      required String date,
      required int startMinutes,
      required int endMinutes,
      required String location,
    });
typedef $$IndependentLessonRecordsTableUpdateCompanionBuilder =
    IndependentLessonRecordsCompanion Function({
      Value<int> id,
      Value<int> courseId,
      Value<String> date,
      Value<int> startMinutes,
      Value<int> endMinutes,
      Value<String> location,
    });

final class $$IndependentLessonRecordsTableReferences
    extends
        BaseReferences<
          _$PlannerStore,
          $IndependentLessonRecordsTable,
          StoredIndependentLesson
        > {
  $$IndependentLessonRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseRecordsTable _courseIdTable(_$PlannerStore db) => db
      .courseRecords
      .createAlias('independent_lesson_records__course_id__course_records__id');

  $$CourseRecordsTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<int>('course_id')!;

    final manager = $$CourseRecordsTableTableManager(
      $_db,
      $_db.courseRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IndependentLessonRecordsTableFilterComposer
    extends Composer<_$PlannerStore, $IndependentLessonRecordsTable> {
  $$IndependentLessonRecordsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  $$CourseRecordsTableFilterComposer get courseId {
    final $$CourseRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableFilterComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndependentLessonRecordsTableOrderingComposer
    extends Composer<_$PlannerStore, $IndependentLessonRecordsTable> {
  $$IndependentLessonRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  $$CourseRecordsTableOrderingComposer get courseId {
    final $$CourseRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndependentLessonRecordsTableAnnotationComposer
    extends Composer<_$PlannerStore, $IndependentLessonRecordsTable> {
  $$IndependentLessonRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  $$CourseRecordsTableAnnotationComposer get courseId {
    final $$CourseRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courseRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndependentLessonRecordsTableTableManager
    extends
        RootTableManager<
          _$PlannerStore,
          $IndependentLessonRecordsTable,
          StoredIndependentLesson,
          $$IndependentLessonRecordsTableFilterComposer,
          $$IndependentLessonRecordsTableOrderingComposer,
          $$IndependentLessonRecordsTableAnnotationComposer,
          $$IndependentLessonRecordsTableCreateCompanionBuilder,
          $$IndependentLessonRecordsTableUpdateCompanionBuilder,
          (StoredIndependentLesson, $$IndependentLessonRecordsTableReferences),
          StoredIndependentLesson,
          PrefetchHooks Function({bool courseId})
        > {
  $$IndependentLessonRecordsTableTableManager(
    _$PlannerStore db,
    $IndependentLessonRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndependentLessonRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$IndependentLessonRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IndependentLessonRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> courseId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int> endMinutes = const Value.absent(),
                Value<String> location = const Value.absent(),
              }) => IndependentLessonRecordsCompanion(
                id: id,
                courseId: courseId,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int courseId,
                required String date,
                required int startMinutes,
                required int endMinutes,
                required String location,
              }) => IndependentLessonRecordsCompanion.insert(
                id: id,
                courseId: courseId,
                date: date,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                location: location,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $IndependentLessonRecordsTable,
                    StoredIndependentLesson
                  >(table),
                  $$IndependentLessonRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.courseId,
                        referencedTable:
                            $$IndependentLessonRecordsTableReferences
                                ._courseIdTable(db),
                        referencedColumn:
                            $$IndependentLessonRecordsTableReferences
                                ._courseIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IndependentLessonRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PlannerStore,
      $IndependentLessonRecordsTable,
      StoredIndependentLesson,
      $$IndependentLessonRecordsTableFilterComposer,
      $$IndependentLessonRecordsTableOrderingComposer,
      $$IndependentLessonRecordsTableAnnotationComposer,
      $$IndependentLessonRecordsTableCreateCompanionBuilder,
      $$IndependentLessonRecordsTableUpdateCompanionBuilder,
      (StoredIndependentLesson, $$IndependentLessonRecordsTableReferences),
      StoredIndependentLesson,
      PrefetchHooks Function({bool courseId})
    >;

class $PlannerStoreManager {
  final _$PlannerStore _db;
  $PlannerStoreManager(this._db);
  $$SemesterRecordsTableTableManager get semesterRecords =>
      $$SemesterRecordsTableTableManager(_db, _db.semesterRecords);
  $$PeriodRecordsTableTableManager get periodRecords =>
      $$PeriodRecordsTableTableManager(_db, _db.periodRecords);
  $$SettingsRecordsTableTableManager get settingsRecords =>
      $$SettingsRecordsTableTableManager(_db, _db.settingsRecords);
  $$CourseRecordsTableTableManager get courseRecords =>
      $$CourseRecordsTableTableManager(_db, _db.courseRecords);
  $$ScheduleRecordsTableTableManager get scheduleRecords =>
      $$ScheduleRecordsTableTableManager(_db, _db.scheduleRecords);
  $$LearningTaskRecordsTableTableManager get learningTaskRecords =>
      $$LearningTaskRecordsTableTableManager(_db, _db.learningTaskRecords);
  $$CountdownEventRecordsTableTableManager get countdownEventRecords =>
      $$CountdownEventRecordsTableTableManager(_db, _db.countdownEventRecords);
  $$ClassExceptionRecordsTableTableManager get classExceptionRecords =>
      $$ClassExceptionRecordsTableTableManager(_db, _db.classExceptionRecords);
  $$IndependentLessonRecordsTableTableManager get independentLessonRecords =>
      $$IndependentLessonRecordsTableTableManager(
        _db,
        _db.independentLessonRecords,
      );
}
