import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/importing/model.dart';
import 'package:unipocket/importing/school_xlsx.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  test('学校真实格式读取节次、多课程、分段单双周及未排课备注', () {
    final parsed = parseSchoolTimetable(
      File('test/fixtures/hbkj_schedule.xlsx').readAsBytesSync(),
    );
    expect(parsed.termName, '河北科技师范学院2026年秋季学期课表');
    expect(parsed.periods, hasLength(12));
    expect(parsed.periods.first.startMinutes, 480);
    expect(parsed.periods.last.endMinutes, 1260);
    final course = parsed.candidates.singleWhere((c) => c.name == '计算机组成原理');
    final thursday = course.schedules.singleWhere(
      (s) => s.weekday == 4 && s.startPeriod == 1,
    );
    expect(thursday.endPeriod, 2);
    expect(thursday.location, 'A614');
    expect(thursday.weeks, {2, 4, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16});
    final monday = course.schedules.singleWhere((s) => s.weekday == 1);
    expect(monday.weeks, {9, 11, 12, 13, 14, 15});
    expect(course.sourceLabel, contains('E6'));
    expect(parsed.candidates.where((c) => c.schedules.isEmpty), hasLength(3));
    expect(
      parsed.candidates
          .where((c) => c.schedules.isEmpty)
          .every((c) => c.errors.isNotEmpty),
      isTrue,
    );
  });

  test('真实 SQLite 首次导入、部分重复补齐、旧预览并发提交和再次导入不增加安排', () async {
    final parsed = parseSchoolTimetable(
      File('test/fixtures/hbkj_schedule.xlsx').readAsBytesSync(),
    );
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(
      SemesterDraft(
        name: '学校学期',
        firstMonday: DateTime.utc(2026, 8, 31),
        totalWeeks: 20,
        periods: {for (var d = 1; d <= 7; d++) d: parsed.periods},
      ),
    );
    final course = parsed.candidates.singleWhere((c) => c.name == '计算机组成原理');
    await planner.saveCourse(
      course.copyWith(schedules: [course.schedules.first]).toCourse(semester),
    );
    final draft = ImportDraft(semesterId: semester, candidates: [course]);
    final preview = await planner.previewImport(draft);
    expect(preview.rows.single.duplicateScheduleCount, 1);
    expect(preview.conflicts, isEmpty);
    final stale = await planner.previewImport(draft);
    await store.customStatement(
      "CREATE TRIGGER fail_append BEFORE INSERT ON schedule_records WHEN NEW.weekday = 4 BEGIN SELECT RAISE(ABORT, 'append failure'); END",
    );
    await expectLater(preview.commit(), throwsA(anything));
    expect((await planner.load()).courses.single.schedules, hasLength(1));
    await store.customStatement('DROP TRIGGER fail_append');
    await preview.commit();
    await stale.commit();
    final state = await planner.load();
    expect(state.courses, hasLength(1));
    expect(state.courses.single.schedules, hasLength(course.schedules.length));
    final repeated = await planner.previewImport(draft);
    expect(repeated.rows.single.candidate.selected, isFalse);
    expect(repeated.conflicts, isEmpty);
    expect(repeated.canSubmit, isFalse);
    expect(
      repeated.rows.single.duplicateScheduleCount,
      course.schedules.length,
    );
  });

  test(
    '实际学校原件可预览、取消、失败回滚、重试，关闭重开后重复导入不变',
    () async {
      final file = File(
        'class_schedule_template/Hebei Normal University of Science & Technology/xskb.xlsx',
      );
      final parsed = parseSchoolTimetable(file.readAsBytesSync());
      expect(
        parsed.candidates.where((c) => c.schedules.isNotEmpty),
        hasLength(10),
      );
      final directory = Directory.systemTemp.createTempSync('school-import-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final database = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(database));
      var planner = SemesterPlanner(store);
      final semester = await planner.saveSemester(
        SemesterDraft(
          name: '实际样例验证',
          firstMonday: DateTime.utc(2026, 8, 31),
          totalWeeks: 20,
          periods: {for (var d = 1; d <= 7; d++) d: parsed.periods},
        ),
      );
      final draft = ImportDraft(
        semesterId: semester,
        candidates: [
          for (final c in parsed.candidates)
            c.errors.isEmpty ? c : c.copyWith(selected: false),
        ],
      );
      final cancelled = await planner.previewImport(draft);
      expect(cancelled.canSubmit, isTrue);
      expect((await planner.load()).courses, isEmpty);
      await store.customStatement(
        "CREATE TRIGGER fail_school BEFORE INSERT ON schedule_records WHEN NEW.weekday = 5 BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
      );
      await expectLater(
        cancelled.commit(allowConflicts: true),
        throwsA(anything),
      );
      expect((await planner.load()).courses, isEmpty);
      await store.customStatement('DROP TRIGGER fail_school');
      await cancelled.commit(allowConflicts: true);
      final imported = await planner.load();
      expect(imported.courses, hasLength(10));
      final count = imported.courses.fold<int>(
        0,
        (n, c) => n + c.schedules.length,
      );
      await store.close();
      store = PlannerStore(NativeDatabase(database));
      addTearDown(store.close);
      planner = SemesterPlanner(store);
      final again = await planner.previewImport(draft);
      expect(again.canSubmit, isFalse);
      expect(again.rows.every((r) => !r.candidate.selected), isTrue);
      final restored = await planner.load();
      expect(restored.courses, hasLength(10));
      expect(
        restored.courses.fold<int>(0, (n, c) => n + c.schedules.length),
        count,
      );
    },
    skip: !File(
      'class_schedule_template/Hebei Normal University of Science & Technology/xskb.xlsx',
    ).existsSync(),
  );

  test('不支持文件明确拒绝，局部错误保留单元格位置，课程合并格与内联文本仍可读取', () {
    final bytes = File('test/fixtures/hbkj_schedule.xlsx').readAsBytesSync();
    expect(
      () => parseSchoolTimetable(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<InputProblem>()),
    );
    final badHeader = changeXml(
      bytes,
      'xl/sharedStrings.xml',
      (s) => s.replaceAll('河北科技师范学院', '其他学校'),
    );
    expect(() => parseSchoolTimetable(badHeader), throwsA(isA<InputProblem>()));
    final badWeeks = changeXml(
      bytes,
      'xl/sharedStrings.xml',
      (s) => s.replaceAll('2-4(双)', '不明周次'),
    );
    final invalid = parseSchoolTimetable(badWeeks);
    expect(
      invalid.candidates.singleWhere((c) => c.name == '计算机组成原理').errors.join(),
      contains('H6'),
    );
    final merged = changeXml(
      bytes,
      'xl/worksheets/sheet1.xml',
      (s) => s.replaceFirst(
        '</mergeCells>',
        '<mergeCell ref="E6:E7"/></mergeCells>',
      ),
    );
    expect(
      parseSchoolTimetable(merged).candidates.length,
      parseSchoolTimetable(bytes).candidates.length,
    );
  });

  test('目标学期节次不同须核对，不能把学校上午课程静默改到别的时间', () async {
    final parsed = parseSchoolTimetable(
      File('test/fixtures/hbkj_schedule.xlsx').readAsBytesSync(),
    );
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(
      SemesterDraft(
        name: '不同作息',
        firstMonday: DateTime.utc(2026, 8, 31),
        totalWeeks: 20,
        periods: {
          for (var d = 1; d <= 7; d++)
            d: [
              for (final p in parsed.periods)
                PeriodTime(p.startMinutes + 1, p.endMinutes + 1),
            ],
        },
      ),
    );
    final preview = await planner.previewImport(
      ImportDraft(
        semesterId: semester,
        candidates: [parsed.candidates.singleWhere((c) => c.name == '计算机组成原理')],
      ),
    );
    expect(preview.canSubmit, isFalse);
    expect(preview.rows.single.errors.join(), contains('节次时间'));
    expect((await planner.load()).courses, isEmpty);
  });
}

Uint8List changeXml(
  Uint8List bytes,
  String path,
  String Function(String) edit,
) {
  final source = ZipDecoder().decodeBytes(bytes);
  final result = Archive();
  for (final file in source) {
    final content = file.name == path
        ? utf8.encode(edit(utf8.decode(file.content as List<int>)))
        : file.content as List<int>;
    result.addFile(ArchiveFile(file.name, content.length, content));
  }
  return Uint8List.fromList(ZipEncoder().encode(result)!);
}
