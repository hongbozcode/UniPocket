import 'package:unipocket/events/model.dart';
import 'package:unipocket/random_tools/groups.dart';
import 'package:unipocket/random_tools/roll_call.dart';
import 'package:unipocket/random_tools/tool_library.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/timetable/course_change.dart';
import 'package:unipocket/timetable/model.dart';

import 'semester_fixture.dart';

/// Hand-entered domain data, independent of the school import adapter.
Future<void> seedBackupFixture(
  SemesterPlanner planner, {
  DateTime? firstMonday,
}) async {
  await planner.setCampusTimeZone('Asia/Tokyo');
  final monday = firstMonday ?? DateTime.utc(2026, 8, 31);
  DateTime day(int offset) => monday.add(Duration(days: offset));
  final originalSemester = semesterDraft('备份验收秋季');
  final semester = await planner.saveSemester(
    SemesterDraft(
      name: originalSemester.name,
      firstMonday: monday,
      totalWeeks: originalSemester.totalWeeks,
      periods: originalSemester.periods,
    ),
    makeCurrent: true,
  );
  await planner.saveSemester(semesterDraft('保留历史学期'));
  final courseId = await planner.saveCourse(
    CourseDraft(
      semesterId: semester,
      name: '高等数学',
      teacher: '陈老师',
      colorIndex: 2,
      reminderMinutesBefore: 15,
      schedules: [
        ScheduleDraft(
          weekday: 1,
          startPeriod: 1,
          endPeriod: 2,
          location: 'A201',
          weeks: {1, 2, 3, 4},
        ),
      ],
    ),
  );
  var course = (await planner.load()).courses.single;
  final schedule = course.schedules.single as ClassSchedule;
  for (final day in [31, 7, 14]) {
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: schedule.id,
        originalDate: monday.add(Duration(days: day == 31 ? 0 : day)),
        targetDate: monday.add(Duration(days: day == 31 ? 1 : day + 1)),
        startMinutes: 660,
        endMinutes: 720,
        location: '补课教室',
        isCancelled: day == 14,
      ),
    );
  }
  final impact = await planner.previewCourseChange(
    courseId,
    CourseDraft(
      semesterId: semester,
      name: course.name,
      teacher: course.teacher,
      colorIndex: 2,
      reminderMinutesBefore: 15,
      schedules: [
        ClassSchedule(
          id: schedule.id,
          weekday: 1,
          startPeriod: 1,
          endPeriod: 2,
          location: 'A201',
          weeks: {1, 3, 4},
        ),
      ],
    ),
  );
  await planner.applyCourseChange(
    impact,
    choices: {impact.orphaned.single.key: OrphanChoice.keepIndependent},
  );
  await planner.saveTask(
    LearningTaskDraft(
      title: '关联数学作业',
      dueDate: day(3),
      courseId: courseId,
      notes: '完整备注',
      reminderMinutesBefore: 30,
    ),
  );
  await planner.saveTask(LearningTaskDraft(title: '过去任务', dueDate: day(-30)));
  final done = await planner.saveTask(
    LearningTaskDraft(
      title: '已完成任务',
      dueDate: day(4),
      reminderMinutesBefore: null,
    ),
  );
  await planner.setTaskCompleted(done, true);
  await planner.saveEvent(
    CountdownEventDraft(
      title: '未来考试',
      targetDate: day(5),
      isPinned: true,
      reminderMinutes: 600,
    ),
  );
  await planner.saveEvent(
    CountdownEventDraft(
      title: '历史事件',
      targetDate: day(-30),
      kind: EventKind.custom,
    ),
  );
  await planner.saveWheelList(name: '午饭', items: ['面条', '米饭', '面条']);
  final roll = await planner.saveRollCallList(
    name: '同名点名名单',
    members: [
      const RollCallMember(id: 1, name: '小林', detail: '001'),
      const RollCallMember(id: 2, name: '小林', detail: '002'),
      const RollCallMember(id: 3, name: '小王'),
    ],
  );
  await (await planner.prepareRollCall(roll.id)).complete();
  final pool = await planner.saveLotteryPool(
    name: '签池',
    items: ['好好学习', '天天向上', '好好学习'],
  );
  await (await planner.prepareLottery(pool.id)).complete();
  await planner.saveGroupList(
    name: '分组名单',
    members: [
      const GroupMember(id: 1, name: '同学'),
      const GroupMember(id: 2, name: '同学', detail: '002'),
    ],
  );
  await planner.setToolFavorite(RandomTool.lottery, true);
  await planner.recordToolUse(RandomTool.wheel);
  await planner.recordToolUse(RandomTool.rollCall);
}
