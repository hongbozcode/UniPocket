import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/events/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/semester_fixture.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_events_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');
const phoneOffset = String.fromEnvironment('ACCEPTANCE_PHONE_OFFSET');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 倒计时源图对照、表单管理与手机时区变化后的新进程恢复', (tester) async {
    Future<void> capture(String name) async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    DateTime clock() => DateTime.utc(2026, 10, 23, 4).toLocal();
    try {
      if (phoneOffset.isNotEmpty) {
        expect(clock().timeZoneOffset.inMinutes, int.parse(phoneOffset));
      }
      if (!restore) {
        await planner.saveSemester(semesterDraft('2026 秋季学期'));
        await planner.saveEvent(
          CountdownEventDraft(
            title: '期中考试',
            targetDate: DateTime(2026, 11, 6),
            isPinned: true,
          ),
        );
        await planner.saveEvent(
          CountdownEventDraft(
            title: '社团展示日',
            targetDate: DateTime(2026, 10, 30),
            kind: EventKind.custom,
          ),
        );
        await planner.saveEvent(
          CountdownEventDraft(
            title: '课程展示',
            targetDate: DateTime(2026, 10, 23),
            kind: EventKind.custom,
          ),
        );
        await planner.saveEvent(
          CountdownEventDraft(title: '上学期考试', targetDate: DateTime(2026, 7, 1)),
        );
      }
      await tester.pumpWidget(UniPocketApp(planner: planner, clock: clock));
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('查看全部倒计时'));
      await waitFor(tester, find.text('把重要的日子，\n装进口袋'));
      await capture(
        restore ? '04-android-process-restored' : '04-reference-events',
      );
      final state = await planner.load();
      expect(state.campusTimeZone, 'Asia/Shanghai');
      expect(state.events.first.daysRemaining(state.campusTime(clock())), 14);
      expect(state.events.first.isPinned, isTrue);
      expect(state.events[2].countdownText(state.campusTime(clock())), '就是今天');
      expect(state.tasks, isEmpty);

      if (!restore) {
        await tapVisible(tester, find.byTooltip('创建倒计时'));
        await tester.enterText(
          find.byKey(const ValueKey('event-title')),
          '毕业旅行',
        );
        await tapVisible(tester, find.text('自定义'));
        await tapVisible(tester, find.byKey(const ValueKey('event-date')));
        await tapVisible(tester, find.text('24'));
        await tapVisible(tester, find.text('确定'));
        await tapVisible(tester, find.byType(SwitchListTile));
        await capture('04-android-editor');
        await tapVisible(tester, find.text('保存事件'));
        await waitFor(tester, find.text('毕业旅行'));
        await tapVisible(tester, find.text('毕业旅行'));
        await tester.enterText(
          find.byKey(const ValueKey('event-title')),
          '毕业旅行计划',
        );
        await tapVisible(tester, find.text('保存事件'));
        await waitFor(tester, find.text('毕业旅行计划'));
        await tapVisible(tester, find.byTooltip('更多：毕业旅行计划'));
        await tapVisible(tester, find.text('取消置顶'));
        await tester.pumpAndSettle();
        expect((await planner.load()).events.last.isPinned, isFalse);
      } else {
        expect(state.events.last.title, '毕业旅行计划');
        expect(state.events.last.kind, EventKind.custom);
        expect(state.events.last.targetDate, DateTime.utc(2026, 10, 24));
        expect(state.events.last.isPinned, isFalse);
        await tapVisible(tester, find.text('毕业旅行计划'));
        await tapVisible(tester, find.text('删除事件'));
        await tapVisible(tester, find.text('取消'));
        expect((await planner.load()).events, hasLength(5));
        await tapVisible(tester, find.text('删除事件'));
        await tapVisible(tester, find.text('确认删除'));
        await waitFor(tester, find.text('进行中  3'));
        expect((await planner.load()).events, hasLength(4));
        await capture('04-reference-events');
      }
      await tapVisible(tester, find.text('历史'));
      await waitFor(tester, find.text('上学期考试'));
      expect(find.text('已过去 114 天'), findsOneWidget);
      await capture(
        restore ? '04-android-history-restored' : '04-android-history',
      );
      await tapVisible(tester, find.byTooltip('返回'));
      await tapVisible(tester, find.text('课表'));
      await tapVisible(tester, find.byTooltip('倒计时'));
      await waitFor(tester, find.text('把重要的日子，\n装进口袋'));
      await capture(restore ? '04-android-from-timetable' : '04-android-saved');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
