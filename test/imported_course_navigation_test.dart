import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/importing/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/import_fixture.dart';
import 'support/semester_fixture.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('首页两门重叠课程分别进入详情、编辑并返回，不会卡住或重复创建课程', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('测试导入目标'));
    await planner.saveCourse(testCandidate('测试原有课程').toCourse(semester));
    final preview = await planner.previewImport(
      ImportDraft(semesterId: semester, candidates: [testCandidate('测试导入数学')]),
    );
    await preview.commit(allowConflicts: true);
    await tester.pumpWidget(
      UniPocketApp(planner: planner, clock: () => DateTime.utc(2026, 8, 31)),
    );
    await tester.pumpAndSettle();
    expect(find.text('测试原有课程'), findsOneWidget);
    expect(find.text('测试导入数学'), findsOneWidget);
    await tapVisible(tester, find.text('测试导入数学'));
    expect(find.text('课程详情'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('course-name')))
          .controller!
          .text,
      '测试导入数学',
    );
    await tester.enterText(
      find.byKey(const ValueKey('course-teacher')),
      '测试教师',
    );
    await tapVisible(tester, find.byKey(const ValueKey('save-course')));
    expect(find.text('今日课程'), findsOneWidget);
    await tapVisible(tester, find.text('测试原有课程'));
    expect(find.text('课程详情'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('course-name')))
          .controller!
          .text,
      '测试原有课程',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('今日课程'), findsOneWidget);
    expect((await planner.load()).courses, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
