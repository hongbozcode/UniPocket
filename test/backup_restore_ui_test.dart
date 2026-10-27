import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:unipocket/backup/backup_card.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/semester_fixture.dart';

Future<void> awaitBackup(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> tapBackup(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(tz.initializeTimeZones);
  const channel = MethodChannel('unipocket/backup-file');
  for (final width in [320.0, 393.0]) {
    testWidgets('$width 宽双倍文字，取消选择、无效文件、覆盖取消及成功反馈可达', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });
      await tester.runAsync(() async {
        final store = PlannerStore(NativeDatabase.memory());
        final planner = SemesterPlanner(
          store,
          clock: () => DateTime.utc(2026, 10, 27),
        );
        final id = await planner.saveSemester(semesterDraft('备份中的学期'));
        final bytes = await planner.exportBackup();
        await planner.saveSemester(semesterDraft('本机最新学期'), id: id);
        Object? picked;
        Uint8List? exported;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'save') {
              exported = (call.arguments as Map)['bytes'] as Uint8List;
              return true;
            }
            return picked;
          },
        );
        var restored = false;
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: appTheme(),
              locale: const Locale('zh', 'CN'),
              supportedLocales: const [Locale('zh', 'CN')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Scaffold(
                body: SafeArea(
                  child: PageContent(
                    children: [
                      BackupCard(
                        planner: planner,
                        onRestored: () async => restored = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tapBackup(tester, find.byKey(const ValueKey('restore-backup')));
          await awaitBackup(
            tester,
            find.byKey(const ValueKey('restore-backup')),
          );
          await Future<void>.delayed(const Duration(milliseconds: 40));
          await tester.pump();
          expect((await planner.load()).semesters.single.name, '本机最新学期');
          picked = {
            'name': 'broken.unipocket',
            'bytes': Uint8List.fromList([1]),
          };
          await tapBackup(tester, find.byKey(const ValueKey('restore-backup')));
          await awaitBackup(tester, find.textContaining('文件不是完整'));
          expect(find.byKey(const ValueKey('restore-confirm')), findsNothing);
          picked = {'name': '一个很长的完整备份文件名称.unipocket', 'bytes': bytes};
          await tapBackup(tester, find.byKey(const ValueKey('restore-backup')));
          await awaitBackup(tester, find.text('覆盖本机全部数据？'));
          await tapBackup(tester, find.text('取消'));
          expect((await planner.load()).semesters.single.name, '本机最新学期');
          await tapBackup(tester, find.byKey(const ValueKey('restore-backup')));
          await awaitBackup(tester, find.text('覆盖本机全部数据？'));
          await tapBackup(
            tester,
            find.byKey(const ValueKey('restore-confirm')),
          );
          await awaitBackup(tester, find.textContaining('完整恢复成功'));
          expect(restored, isTrue);
          expect((await planner.load()).semesters.single.name, '备份中的学期');
          await tapBackup(tester, find.byKey(const ValueKey('export-backup')));
          await awaitBackup(tester, find.text('完整备份已导出到所选位置'));
          expect(exported, bytes);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
          await tester.pumpWidget(const SizedBox.shrink());
          await store.close();
        }
      });
    });
  }
}
