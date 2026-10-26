import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/importing/model.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/semester_fixture.dart';
import 'support/import_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('明确标注的测试候选在确认前不写入，确认一次后重开保留目标学期内容', () async {
    final directory = await Directory.systemTemp.createTemp('import-preview-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      final current = await planner.saveSemester(semesterDraft('当前学期'));
      final target = await planner.saveSemester(semesterDraft('导入目标'));
      final preview = await planner.previewImport(
        ImportDraft(semesterId: target, candidates: [testCandidate('测试数学')]),
      );
      expect(preview.canSubmit, isTrue);
      expect((await planner.load()).courses, isEmpty);
      final first = preview.commit();
      final second = preview.commit();
      expect(await first, await second);
      await preview.commit();
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      final state = await planner.load();
      expect(state.currentSemesterId, current);
      expect(state.courses.single.semesterId, target);
      expect(state.courses.single.name, '测试数学');
      expect(state.courses.single.schedules.single.location, '测试教室');
    } finally {
      await store.close();
      await directory.delete(recursive: true);
    }
  });

  test('识别错误与非法安排必须修正或排除；解析器标出的重复默认跳过', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    final bad = testCandidate('待核对', errors: ['教师信息无法识别']);
    final draft = ImportDraft(
      semesterId: semester,
      candidates: [
        testCandidate('测试有效'),
        bad,
        testCandidate('超出节次', start: 99),
        testCandidate('适配器识别的重复', duplicate: '测试重复说明'),
      ],
    );
    final blocked = await planner.previewImport(draft);
    expect(blocked.rows.last.candidate.selected, isFalse);
    expect(blocked.rows[2].errors, isNotEmpty);
    await expectLater(blocked.commit(), throwsA(isA<InputProblem>()));
    expect((await planner.load()).courses, isEmpty);
    final corrected = await planner.previewImport(
      ImportDraft(
        semesterId: semester,
        candidates: [
          draft.candidates[0],
          bad.copyWith(
            name: '已核对',
            schedules: testCandidate('x', day: 2).schedules,
            errors: [],
          ),
          draft.candidates[2].copyWith(selected: false),
          draft.candidates[3],
        ],
      ),
    );
    expect(corrected.canSubmit, isTrue);
    await corrected.commit();
    expect((await planner.load()).courses.map((c) => c.name), ['测试有效', '已核对']);
  });

  test('提交中第二项 SQLite 写入失败时全部回滚，修复外部故障后可重试', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    await planner.saveCourse(testCandidate('原有课程', day: 3).toCourse(semester));
    final preview = await planner.previewImport(
      ImportDraft(
        semesterId: semester,
        candidates: [testCandidate('第一项'), testCandidate('第二项', day: 2)],
      ),
    );
    // Inject an actual SQLite disk/write boundary failure after one course and
    // its schedule have already been inserted, without mocking business code.
    await store.customStatement(
      '''CREATE TRIGGER fail_import BEFORE INSERT ON course_records
      WHEN NEW.name = '第二项' BEGIN SELECT RAISE(ABORT, 'test write failure'); END''',
    );
    await expectLater(preview.commit(), throwsA(anything));
    final failed = await planner.load();
    expect(failed.courses.single.name, '原有课程');
    expect(failed.courses.single.schedules, hasLength(1));
    await store.customStatement('DROP TRIGGER fail_import');
    await preview.commit();
    expect((await planner.load()).courses.map((c) => c.name), [
      '原有课程',
      '第一项',
      '第二项',
    ]);
  });

  test('候选相互冲突及预览后新增的冲突在事务中重新核对，须显式确认', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    final preview = await planner.previewImport(
      ImportDraft(
        semesterId: semester,
        candidates: [testCandidate('A'), testCandidate('B')],
      ),
    );
    expect(preview.conflicts.single, contains('A'));
    await expectLater(preview.commit(), throwsA(isA<InputProblem>()));
    expect((await planner.load()).courses, isEmpty);
    await preview.commit(allowConflicts: true);
    final stale = await planner.previewImport(
      ImportDraft(
        semesterId: semester,
        candidates: [testCandidate('C', day: 2)],
      ),
    );
    expect(stale.conflicts, isEmpty);
    await planner.saveCourse(testCandidate('后来添加', day: 2).toCourse(semester));
    await expectLater(stale.commit(), throwsA(isA<InputProblem>()));
    expect((await planner.load()).courses, hasLength(3));
  });

  test('已有冲突的确认不能顺带批准预览后新增的冲突', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    await planner.saveCourse(testCandidate('原有冲突').toCourse(semester));
    final draft = ImportDraft(
      semesterId: semester,
      candidates: [testCandidate('候选')],
    );
    final preview = await planner.previewImport(draft);
    expect(preview.conflicts, isNotEmpty);
    await planner.saveCourse(
      testCandidate('后来新增冲突').toCourse(semester),
      allowConflicts: true,
    );
    await expectLater(
      preview.commit(allowConflicts: true),
      throwsA(isA<InputProblem>()),
    );
    expect((await planner.load()).courses, hasLength(2));
    final refreshed = await planner.previewImport(draft);
    await refreshed.commit(allowConflicts: true);
    expect((await planner.load()).courses, hasLength(3));
  });
}
