import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('从首次运行界面创建学期，重新打开应用后仍可看到', (tester) async {
    await tester.runAsync(() async {
      final directory = Directory.systemTemp.createTempSync('unipocket-ui-');
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      addTearDown(() async {
        await store.close();
        directory.deleteSync(recursive: true);
      });
      await tester.pumpWidget(UniPocketApp(planner: SemesterPlanner(store)));
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('课表'), findsOneWidget);
      expect(find.text('工具'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
      await tester.tap(find.text('创建学期'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('semester-name')),
        '2026 秋季学期',
      );
      await tester.enterText(
        find.byKey(const ValueKey('first-monday')),
        '2026-08-31',
      );
      await tester.enterText(find.byKey(const ValueKey('total-weeks')), '20');
      final save = find.byKey(const ValueKey('save-semester'));
      await tester.scrollUntilVisible(
        save,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('2026 秋季学期'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      await tester.pumpWidget(UniPocketApp(planner: SemesterPlanner(store)));
      await tester.pumpAndSettle();
      expect(find.text('2026 秋季学期'), findsOneWidget);
      expect(find.textContaining('Asia/Shanghai'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  for (final width in [320.0, 393.0]) {
    testWidgets('${width.toInt()} 宽度和双倍文字下，长学期名、导航、表单和时区仍可访问', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.runAsync(() async {
        final store = PlannerStore(NativeDatabase.memory());
        final planner = SemesterPlanner(store);
        await planner.saveSemester(
          SemesterDraft(
            name: '这是一个用于检查窄屏及大字体下完整显示的很长的秋季学期名称',
            firstMonday: DateTime.utc(2026, 8, 31),
            totalWeeks: 20,
            periods: {
              1: [const PeriodTime(480, 525)],
            },
          ),
        );
        try {
          await tester.pumpWidget(UniPocketApp(planner: planner));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final label in ['课表', '工具', '设置']) {
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.text('节次时间'));
          await tester.pumpAndSettle();
          final save = find.byKey(const ValueKey('save-semester'));
          await tester.scrollUntilVisible(
            save,
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('main-navigation')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('校园时区'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('校园时区'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('timezone-search')),
            '东京',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Asia/Tokyo'));
          await tester.pumpAndSettle();
          expect((await planner.load()).campusTimeZone, 'Asia/Tokyo');
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await store.close();
        }
      });
    });
  }

  for (final invalid in [
    ('first-monday', '2026-02-30', '请输入有效日期，例如 2026-08-31'),
    ('total-weeks', 'abc', '请输入大于 0 的整数'),
  ]) {
    testWidgets('滚到保存按钮后，${invalid.$1} 的错误仍明确显示且不写入数据', (tester) async {
      tester.view.physicalSize = const Size(320, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.runAsync(() async {
        final store = PlannerStore(NativeDatabase.memory());
        final planner = SemesterPlanner(store);
        try {
          await tester.pumpWidget(UniPocketApp(planner: planner));
          await tester.pumpAndSettle();
          await tester.tap(find.text('创建学期'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('semester-name')),
            '输入校验学期',
          );
          await tester.enterText(find.byKey(ValueKey(invalid.$1)), invalid.$2);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          final save = find.byKey(const ValueKey('save-semester'));
          await tester.scrollUntilVisible(
            save,
            350,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.byKey(const ValueKey('first-monday')), findsNothing);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(find.textContaining(invalid.$3), findsWidgets);
          expect(find.textContaining('请检查本机存储空间'), findsNothing);
          expect((await planner.load()).semesters, isEmpty);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await store.close();
        }
      });
    });
  }
}
