import 'package:unipocket/events/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/timetable/model.dart';

import 'semester_fixture.dart';

final discoveryInstant = DateTime.utc(2026, 10, 26, 0);

Future<void> seedDiscoveryHome(SemesterPlanner planner) async {
  final semester = await planner.saveSemester(
    semesterDraft('2026 秋季学期'),
    makeCurrent: true,
  );
  await planner.saveCourse(
    CourseDraft(
      semesterId: semester,
      name: '高等数学',
      schedules: [
        ScheduleDraft(
          weekday: 1,
          startPeriod: 2,
          endPeriod: 3,
          location: '教学楼 A201',
          weeks: {9},
        ),
      ],
    ),
  );
  await planner.saveTask(
    LearningTaskDraft(title: '物理实验报告', dueDate: DateTime.utc(2026, 10, 25)),
  );
  await planner.saveTask(
    LearningTaskDraft(title: '高数习题 第五章', dueDate: DateTime.utc(2026, 10, 26)),
  );
  await planner.saveEvent(
    CountdownEventDraft(
      title: '期中考试',
      targetDate: DateTime.utc(2026, 11, 9),
      isPinned: true,
    ),
  );
}
