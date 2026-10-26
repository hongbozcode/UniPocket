import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/importing/import_page.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import '../test/support/import_fixture.dart';
import '../test/support/semester_fixture.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_import_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 测试候选预览纠错、排除、冲突确认、事务失败重试和新进程恢复', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot('16-android-$name');
    }

    try {
      if (!restore) {
        final current = await planner.saveSemester(semesterDraft('原当前学期'));
        final target = await planner.saveSemester(semesterDraft('测试导入目标'));
        await planner.saveCourse(testCandidate('测试原有课程').toCourse(target));
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(),
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [Locale('zh', 'CN')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ImportPreviewPage(
              planner: planner,
              sourceName: '测试候选数据 · 非学校解析结果',
              initialSemesterId: current,
              loadCandidates: () async => [
                testCandidate('', id: 'correct', errors: ['还缺一个课程名称，请补充一下。']),
                testCandidate('测试错误项', id: 'exclude', start: 99),
                testCandidate(
                  '测试重复项',
                  id: 'duplicate',
                  duplicate: '由测试适配器明确标记，默认跳过',
                ),
              ],
            ),
          ),
        );
        await waitFor(tester, find.byType(DropdownButtonFormField<int>));
        await binding.convertFlutterSurfaceToImage();
        await capture('preview');
        await tapVisible(tester, find.byType(DropdownButtonFormField<int>));
        await tapVisible(tester, find.text('测试导入目标').last);
        await tapVisible(
          tester,
          find.byKey(const ValueKey('edit-import-correct')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('import-name')),
          '测试导入数学',
        );
        await tapVisible(tester, find.byKey(const ValueKey('import-reviewed')));
        await capture('correction');
        await tapVisible(
          tester,
          find.byKey(const ValueKey('apply-import-correction')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('select-import-exclude')),
        );
        await capture('excluded');
        await tapVisible(
          tester,
          find.byKey(const ValueKey('import-conflicts')),
        );
        await capture('conflicts');
        await tapVisible(tester, find.byKey(const ValueKey('confirm-import')));
        await capture('confirmation');
        await tapVisible(
          tester,
          find.byKey(const ValueKey('keep-reviewing-import')),
        );
        expect((await planner.load()).courses, hasLength(1));
        await store.customStatement(
          '''CREATE TRIGGER fail_acceptance_import BEFORE INSERT ON schedule_records
          WHEN NEW.course_id <> 1 BEGIN SELECT RAISE(ABORT, 'test write failure'); END''',
        );
        await tapVisible(tester, find.byKey(const ValueKey('confirm-import')));
        await tapVisible(tester, find.byKey(const ValueKey('save-import')));
        await capture('rollback-result');
        await waitFor(tester, find.textContaining('这次没能保存'));
        await capture('rollback');
        expect((await planner.load()).courses.single.name, '测试原有课程');
        await store.customStatement('DROP TRIGGER fail_acceptance_import');
        await tapVisible(tester, find.byKey(const ValueKey('confirm-import')));
        await tapVisible(tester, find.byKey(const ValueKey('save-import')));
        await waitFor(tester, find.text('课表已更新'));
        await capture('success');
        final state = await planner.load();
        expect(state.currentSemesterId, current);
        expect(state.courses, hasLength(2));
        expect(state.courses.every((c) => c.semesterId == target), isTrue);
        await planner.setCurrentSemester(target);
      }
      final state = await planner.load();
      expect(state.courses.map((c) => c.name), ['测试原有课程', '测试导入数学']);
      expect(state.courses.every((c) => c.schedules.length == 1), isTrue);
      await tester.pumpWidget(
        UniPocketApp(planner: planner, clock: () => DateTime.utc(2026, 8, 31)),
      );
      await waitFor(tester, find.text('UniPocket'));
      if (restore) await binding.convertFlutterSurfaceToImage();
      await capture(restore ? 'home-restored' : 'home');
      await tapVisible(tester, find.text('课表'));
      await waitFor(tester, find.text('测试导入目标'));
      await capture(restore ? 'timetable-restored' : 'timetable');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
