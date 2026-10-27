import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/importing/import_page.dart';
import 'package:unipocket/importing/school_file.dart';
import 'package:unipocket/importing/school_import_page.dart';
import 'package:unipocket/importing/school_xlsx.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  testWidgets('选择真实格式文件、取消、错误反馈与窄屏双倍字号预览', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final bytes = File('test/fixtures/hbkj_schedule.xlsx').readAsBytesSync();
    final parsed = parseSchoolTimetable(bytes);
    await planner.saveSemester(
      SemesterDraft(
        name: '目标学期',
        firstMonday: DateTime.utc(2026, 8, 31),
        totalWeeks: 20,
        periods: {for (var day = 1; day <= 7; day++) day: parsed.periods},
      ),
    );
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selection = Completer<SchoolFile?>();
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: SchoolImportPage(
          planner: planner,
          pickFile: () => selection.future,
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pick-school-file')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('pick-school-file')));
    await tester.tap(find.byKey(const ValueKey('pick-school-file')));
    await tester.pump();
    expect(find.text('正在读取学校课表…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('pick-school-file')))
          .onPressed,
      isNull,
    );
    selection.complete(null);
    await tester.pumpAndSettle();
    expect((await planner.load()).courses, isEmpty);
    selection = Completer<SchoolFile?>();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pick-school-file')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('pick-school-file')));
    await tester.tap(find.byKey(const ValueKey('pick-school-file')));
    await tester.pump();
    selection.complete(SchoolFile('broken.xlsx', Uint8List.fromList([1])));
    await tester.runAsync(
      () => waitSchool(tester, find.textContaining('没能读出来')),
    );
    selection = Completer<SchoolFile?>();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pick-school-file')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('pick-school-file')));
    await tester.tap(find.byKey(const ValueKey('pick-school-file')));
    await tester.pump();
    selection.complete(SchoolFile('学校课表.xlsx', bytes));
    await tester.runAsync(
      () => waitSchool(tester, find.byType(ImportPreviewPage)),
    );
    await tester.pumpAndSettle();
    expect(find.text('核对一下课表'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect((await planner.load()).courses, isEmpty);
    await tapVisible(tester, find.byKey(const ValueKey('cancel-import')));
    expect(find.byType(SchoolImportPage), findsOneWidget);
    expect((await planner.load()).courses, isEmpty);
  });

  testWidgets('正式应用空状态与已有课表均能进入学校导入', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UniPocketApp(planner: planner));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('导入学校课表'));
    expect(find.byType(SchoolImportPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final parsed = parseSchoolTimetable(
      File('test/fixtures/hbkj_schedule.xlsx').readAsBytesSync(),
    );
    await planner.saveSemester(
      SemesterDraft(
        name: '目标学期',
        firstMonday: DateTime.utc(2026, 8, 31),
        totalWeeks: 20,
        periods: {for (var d = 1; d <= 7; d++) d: parsed.periods},
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(UniPocketApp(planner: planner));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('课表').last);
    expect(tester.takeException(), isNull);
    await tapVisible(
      tester,
      find.byWidgetPredicate(
        (w) => w is RoundDesignButton && w.label == '导入学校课表',
      ),
    );
    expect(find.byType(SchoolImportPage), findsOneWidget);
  });
}

Future<void> waitSchool(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}
