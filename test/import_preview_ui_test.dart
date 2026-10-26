import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/importing/import_page.dart';
import 'package:unipocket/importing/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/import_fixture.dart';
import 'support/semester_fixture.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  testWidgets('预览纠错排除后确认一次写入目标学期，窄屏放大与长文字可滚动', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('测试目标学期'));
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('zh', 'CN')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(2),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: child!,
        ),
        home: ImportPreviewPage(
          planner: planner,
          sourceName: '明确标注的测试候选数据',
          initialSemesterId: semester,
          loadCandidates: () async => [
            testCandidate('待修正', id: 'edit', errors: ['测试识别错误，请核对']),
            testCandidate('这是一门很长名称的测试课程需要完整展示', id: 'exclude', start: 99),
            testCandidate('测试重复', duplicate: '由测试适配器标记为重复'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('edit-import-edit')));
    await tester.enterText(
      find.byKey(const ValueKey('import-name')),
      '已修正的测试课程',
    );
    await tapVisible(tester, find.byKey(const ValueKey('import-reviewed')));
    await tapVisible(tester, find.text('应用修改'));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('select-import-exclude')),
    );
    expect((await planner.load()).courses, isEmpty);
    await tapVisible(tester, find.text('确认导入 1 项'));
    await tapVisible(tester, find.text('保存到目标学期'));
    expect(find.text('导入完成'), findsOneWidget);
    expect((await planner.load()).courses.single.name, '已修正的测试课程');
    expect(tester.takeException(), isNull);
  });

  testWidgets('加载进度、失败重试、切换目标学期与取消确认都不写入', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final first = await planner.saveSemester(semesterDraft('当前秋季'));
    final second = await planner.saveSemester(semesterDraft('目标春季'));
    final pending = Completer<List<ImportCandidate>>();
    var retry = false;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => ImportPreviewPage(
                    planner: planner,
                    sourceName: '测试候选',
                    initialSemesterId: first,
                    loadCandidates: () => retry
                        ? Future.value([testCandidate('测试课程')])
                        : pending.future,
                  ),
                ),
              ),
              child: const Text('打开测试预览'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开测试预览'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('正在加载与检查候选结果…'), findsOneWidget);
    pending.completeError(Exception('test parser boundary failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('解析结果加载失败'), findsOneWidget);
    retry = true;
    await tapVisible(tester, find.text('重试'));
    await tapVisible(tester, find.byType(DropdownButtonFormField<int>));
    await tapVisible(tester, find.text('目标春季').last);
    await tapVisible(tester, find.text('确认导入 1 项'));
    expect(find.textContaining('目标春季'), findsWidgets);
    await tapVisible(tester, find.text('继续核对'));
    expect((await planner.load()).courses, isEmpty);
    await tapVisible(tester, find.text('取消导入'));
    expect(find.text('打开测试预览'), findsOneWidget);
    expect((await planner.load()).courses, isEmpty);
    expect((await planner.load()).currentSemesterId, first);
    expect(second, isNot(first));
    expect(tester.takeException(), isNull);
  });

  testWidgets('时间冲突单独确认；数据库失败显示无部分写入并可重试', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('测试目标'));
    await planner.saveCourse(testCandidate('原有课程').toCourse(semester));
    await store.customStatement(
      '''CREATE TRIGGER fail_ui_import BEFORE INSERT ON course_records
      WHEN NEW.name = '测试候选' BEGIN SELECT RAISE(ABORT, 'test write failure'); END''',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: ImportPreviewPage(
          planner: planner,
          sourceName: '测试候选数据',
          initialSemesterId: semester,
          loadCandidates: () async => [testCandidate('测试候选')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('时间冲突 · 需要单独确认'));
    await tapVisible(tester, find.text('确认导入 1 项'));
    await tapVisible(tester, find.text('继续核对'));
    expect((await planner.load()).courses, hasLength(1));
    await tapVisible(tester, find.text('确认导入 1 项'));
    await tapVisible(tester, find.text('保留冲突并保存'));
    expect(find.textContaining('导入失败，未保存任何'), findsOneWidget);
    expect((await planner.load()).courses, hasLength(1));
    await store.customStatement('DROP TRIGGER fail_ui_import');
    await tapVisible(tester, find.text('确认导入 1 项'));
    await tapVisible(tester, find.text('保留冲突并保存'));
    expect(find.text('导入完成'), findsOneWidget);
    expect((await planner.load()).courses, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
