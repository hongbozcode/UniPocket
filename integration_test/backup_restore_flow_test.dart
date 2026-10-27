import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:unipocket/backup/backup_card.dart';
import 'package:unipocket/random_tools/tool_library.dart';
import 'package:unipocket/reminders/android_notifications.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import '../test/support/backup_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  testWidgets('Android 系统导出完整文件、干净库恢复、关系轮次和真实未来提醒重建', (tester) async {
    const database = String.fromEnvironment(
      'ACCEPTANCE_DATABASE',
      defaultValue: 'unipocket_task18_acceptance',
    );
    const reopen = bool.fromEnvironment('ACCEPTANCE_RESTORE');
    final target = PlannerStore.open(name: database);
    final planner = SemesterPlanner(
      target,
      notifications: const AndroidNotifications(namespace: 'task18'),
    );
    Future<void> show(SemesterPlanner value) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            appBar: AppBar(title: const Text('数据与备份')),
            body: SafeArea(
              child: PageContent(
                children: [BackupCard(planner: value, onRestored: () async {})],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> wait(Finder finder) async {
      for (var i = 0; i < 900 && finder.evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(finder, findsWidgets);
    }

    Future<void> tap(String key) async {
      final finder = find.byKey(ValueKey(key));
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(finder);
      await tester.pump();
    }

    await binding.convertFlutterSurfaceToImage();
    try {
      if (!reopen) {
        expect((await planner.load()).semesters, isEmpty);
        final source = PlannerStore.open(name: '${database}_source');
        final original = SemesterPlanner(source);
        try {
          final now = DateTime.now().toUtc();
          final today = DateTime.utc(now.year, now.month, now.day);
          final nextMonday = today.add(Duration(days: 8 - today.weekday));
          await seedBackupFixture(original, firstMonday: nextMonday);
          final expected = jsonDecode(
            utf8.decode(await original.exportBackup()),
          )['tables'];
          await show(original);
          await binding.takeScreenshot('18-android-backup-ready');
          await tap('export-backup');
          debugPrint('TASK18_SAVE_DOCUMENT');
          await wait(find.text('完整备份已导出到所选位置'));
          await binding.takeScreenshot('18-android-export-success');
          await tester.pumpWidget(const SizedBox.shrink());
          await show(planner);
          await tap('restore-backup');
          debugPrint('TASK18_PICK_DOCUMENT');
          await wait(find.text('覆盖本机全部数据？'));
          await tester.pump(const Duration(milliseconds: 400));
          expect((await planner.load()).semesters, isEmpty);
          await binding.takeScreenshot('18-android-restore-confirm');
          await tap('restore-confirm');
          await wait(find.textContaining('完整恢复成功'));
          final actual = jsonDecode(
            utf8.decode(await planner.exportBackup()),
          )['tables'];
          expect(actual, expected);
          await binding.takeScreenshot('18-android-restore-success');
        } finally {
          await source.close();
        }
      } else {
        final state = await planner.load();
        expect(state.semesters, hasLength(2));
        expect(state.classExceptions, hasLength(2));
        expect(state.independentLessons, hasLength(1));
        expect(state.tasks, hasLength(3));
        final list = (await planner.loadRollCallLists()).single;
        expect(list.drawn, hasLength(1));
        expect(
          (await (await planner.prepareRollCall(list.id)).complete()).drawn,
          hasLength(2),
        );
        final pool = (await planner.loadLotteryPools()).single;
        expect(pool.drawn, hasLength(1));
        expect(
          (await (await planner.prepareLottery(pool.id)).complete()).drawn,
          hasLength(2),
        );
        expect(
          (await planner.loadToolLibrary()).tools(filter: ToolFilter.favorites),
          [RandomTool.lottery],
        );
        await planner.refreshReminders();
        await show(planner);
        await binding.takeScreenshot('18-android-process-restored');
      }
      await planner.refreshReminders();
      expect(planner.reminderSyncFailed, isFalse);
      debugPrint('TASK18_NOTIFICATION_ACCESS=${planner.notificationAccess}');
      debugPrint('TASK18_DB=$database');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await target.close();
    }
  });
}
