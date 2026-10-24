import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('创建学期后，关闭并重新打开 SQLite 仍保留完整配置', () async {
    final directory = await Directory.systemTemp.createTemp('unipocket-test-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      final planner = SemesterPlanner(store);
      expect((await planner.load()).semesters, isEmpty);
      await planner.saveSemester(
        SemesterDraft(
          name: '2026 秋季学期',
          firstMonday: DateTime.utc(2026, 8, 31),
          totalWeeks: 20,
          periods: {
            1: [const PeriodTime(480, 525), const PeriodTime(535, 580)],
            2: [const PeriodTime(540, 585)],
          },
        ),
      );
      await planner.setCampusTimeZone('Asia/Tokyo');
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      final restored = await SemesterPlanner(store).load();
      expect(restored.semesters, hasLength(1));
      expect(restored.currentSemester?.name, '2026 秋季学期');
      expect(restored.currentSemester?.firstMonday, DateTime.utc(2026, 8, 31));
      expect(restored.currentSemester?.totalWeeks, 20);
      expect(restored.currentSemester?.periods[1]?.last.endMinutes, 580);
      expect(restored.currentSemester?.periods[2]?.single.startMinutes, 540);
      expect(restored.campusTimeZone, 'Asia/Tokyo');
    } finally {
      await store.close();
      await directory.delete(recursive: true);
    }
  });

  test('无效学期配置有明确反馈，且不会留下半份学期', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final monday = DateTime.utc(2026, 8, 31);
    final invalid = [
      SemesterDraft(
        name: ' ',
        firstMonday: monday,
        totalWeeks: 20,
        periods: {
          1: [const PeriodTime(480, 525)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: DateTime.utc(2026, 9, 1),
        totalWeeks: 20,
        periods: {
          1: [const PeriodTime(480, 525)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: monday,
        totalWeeks: 0,
        periods: {
          1: [const PeriodTime(480, 525)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: monday,
        totalWeeks: 20,
        periods: {
          1: [const PeriodTime(525, 480)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: monday,
        totalWeeks: 20,
        periods: {
          1: [const PeriodTime(-1, 525)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: monday,
        totalWeeks: 20,
        periods: {
          1: [const PeriodTime(480, 1440)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: monday,
        totalWeeks: 20,
        periods: {
          1: [const PeriodTime(480, 525), const PeriodTime(500, 545)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: monday,
        totalWeeks: 20,
        periods: {
          8: [const PeriodTime(480, 525)],
        },
      ),
      SemesterDraft(
        name: '秋',
        firstMonday: monday,
        totalWeeks: 20,
        periods: {},
      ),
    ];
    for (final draft in invalid) {
      await expectLater(
        planner.saveSemester(draft),
        throwsA(
          isA<InputProblem>().having((e) => e.message, '明确错误', isNotEmpty),
        ),
      );
      expect((await planner.load()).semesters, isEmpty);
    }
  });

  test('校园时区可独立配置，无效时区不会覆盖已保存的设置', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    expect((await planner.load()).campusTimeZone, 'Asia/Shanghai');
    final instant = DateTime.utc(2026, 9, 6, 17, 30);
    expect((await planner.load()).campusTime(instant).day, 7);
    await planner.setCampusTimeZone('America/New_York');
    final state = await planner.load();
    expect(state.campusTime(instant).day, 6);
    expect(state.campusTime(instant).hour, 13);
    expect(state.campusTime(instant.toLocal()).day, 6);
    await expectLater(
      planner.setCampusTimeZone('Invalid/Nowhere'),
      throwsA(isA<InputProblem>()),
    );
    expect((await planner.load()).campusTimeZone, 'America/New_York');
  });

  test('切换当前学期保留历史，编辑旧学期不会改变当前选择或其他节次', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    SemesterDraft draft(String name, int weeks, int start) => SemesterDraft(
      name: name,
      firstMonday: DateTime.utc(2026, 8, 31),
      totalWeeks: weeks,
      periods: {
        1: [PeriodTime(start, start + 45)],
        7: [const PeriodTime(900, 945)],
      },
    );
    final autumn = await planner.saveSemester(draft('秋季', 20, 480));
    final spring = await planner.saveSemester(draft('春季', 18, 600));
    expect((await planner.load()).currentSemesterId, autumn);
    await planner.setCurrentSemester(spring);
    await planner.saveSemester(draft('秋季修订', 21, 510), id: autumn);
    final state = await planner.load();
    expect(state.semesters, hasLength(2));
    expect(state.currentSemester?.name, '春季');
    expect(state.currentSemester?.periods[1]?.single.startMinutes, 600);
    final history = state.semesters.singleWhere((s) => s.id == autumn);
    expect(history.name, '秋季修订');
    expect(history.totalWeeks, 21);
    expect(history.periods[1]?.single.startMinutes, 510);
    expect(history.periods[7]?.single.endMinutes, 945);
    await expectLater(
      planner.setCurrentSemester(99999),
      throwsA(isA<InputProblem>()),
    );
    expect((await planner.load()).currentSemesterId, spring);
    await expectLater(
      planner.saveSemester(draft('错误修改', 0, 480), id: autumn),
      throwsA(isA<InputProblem>()),
    );
    expect(
      (await planner.load()).semesters.singleWhere((s) => s.id == autumn).name,
      '秋季修订',
    );
  });
}
