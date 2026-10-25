import 'package:timezone/timezone.dart' as tz;

import '../storage/planner_store.dart';
import '../timetable/model.dart';
import '../tasks/model.dart';
import '../events/model.dart';
import 'model.dart';

/// The application boundary for local learning data. The same operations
/// drive the UI and tests that close and reopen the real local database.
class SemesterPlanner {
  SemesterPlanner(this._store);
  final PlannerStore _store;

  Future<PlannerState> load() => _store.readState();

  Future<int> saveEvent(CountdownEventDraft draft, {int? id}) async {
    draft.validate();
    return _store.saveEvent(draft, id: id);
  }

  Future<void> setEventPinned(int id, bool pinned) =>
      _store.setEventPinned(id, pinned);

  Future<void> deleteEvent(int id) => _store.deleteEvent(id);

  Future<void> setTaskCompleted(int id, bool completed) =>
      _store.setTaskCompleted(id, completed);

  Future<void> deleteTask(int id) => _store.deleteTask(id);

  Future<int> saveTask(LearningTaskDraft draft, {int? id}) =>
      _store.transaction(() async {
        draft.validate();
        if (draft.courseId != null &&
            !(await load()).courses.any((c) => c.id == draft.courseId)) {
          throw const InputProblem('关联课程不存在，请重新选择。');
        }
        return _store.saveTask(draft, id: id);
      });

  Future<int> saveCourse(CourseDraft draft, {bool allowConflicts = false}) =>
      _store.transaction(() async {
        final state = await load();
        final semester = state.semesters
            .where((s) => s.id == draft.semesterId)
            .firstOrNull;
        if (semester == null) throw const InputProblem('学期不存在，请返回后重试。');
        draft.validate(semester);
        final conflicts = courseConflicts(draft, semester, state.courses);
        if (conflicts.isNotEmpty && !allowConflicts) {
          throw CourseConflict(conflicts);
        }
        return _store.saveCourse(draft);
      });

  Future<int> saveSemester(
    SemesterDraft draft, {
    int? id,
    bool makeCurrent = false,
  }) => _store.transaction(() async {
    draft.validate();
    if (id != null) {
      final state = await load();
      for (final course in state.courses.where((c) => c.semesterId == id)) {
        try {
          course.validate(draft);
        } on InputProblem {
          throw InputProblem('此修改会使“${course.name}”的已有上课安排失效，请保留其节次与教学周。');
        }
      }
    }
    return _store.save(draft, id: id, makeCurrent: makeCurrent);
  });

  Future<void> updateCourseDetails(
    int id, {
    required String name,
    required String teacher,
    required int colorIndex,
  }) async {
    validateCourseDetails(name, colorIndex);
    await _store.updateCourseDetails(
      id,
      name: name,
      teacher: teacher,
      colorIndex: colorIndex,
    );
  }

  Future<void> setCurrentSemester(int id) => _store.selectCurrent(id);

  Future<void> setCampusTimeZone(String zone) async {
    if (!tz.timeZoneDatabase.locations.containsKey(zone)) {
      throw const InputProblem('请选择有效的 IANA 校园时区，例如 Asia/Shanghai。');
    }
    await _store.writeTimeZone(zone);
  }
}
