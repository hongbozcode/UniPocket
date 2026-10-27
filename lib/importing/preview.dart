import 'dart:convert';

import '../semesters/model.dart';
import '../timetable/model.dart';
import 'model.dart';
import 'messages.dart';

/// Pure preview uses the same course validation and effective occurrences as
/// manual entry, and is run again inside the commit transaction.
ImportAssessment assessImport(PlannerState state, ImportDraft draft) {
  final semester = state.semesters
      .where((s) => s.id == draft.semesterId)
      .firstOrNull;
  if (semester == null) throw const InputProblem('这个学期找不到了，请重新选择。');
  final ids = draft.candidates.map((c) => c.id).toSet();
  if (ids.length != draft.candidates.length || ids.any((id) => id.isEmpty)) {
    throw const InputProblem('课表信息不完整，请重新读取后再试。');
  }
  final rows = <ImportRow>[];
  final compared = [...state.courses];
  final conflicts = <String>[];
  final known = <String>{
    for (final course in state.courses.where(
      (c) => c.semesterId == draft.semesterId,
    ))
      for (final schedule in course.schedules)
        _scheduleKey(course.name, course.teacher, schedule),
  };
  for (var i = 0; i < draft.candidates.length; i++) {
    var candidate = draft.candidates[i];
    final schedules = <ScheduleDraft>[];
    final withinCandidate = <String>{};
    var duplicates = 0;
    for (final schedule in candidate.schedules) {
      final key = _scheduleKey(candidate.name, candidate.teacher, schedule);
      if (candidate.schoolIdentity &&
          (known.contains(key) || !withinCandidate.add(key))) {
        duplicates++;
      } else {
        schedules.add(schedule);
      }
    }
    if (candidate.schoolIdentity && duplicates > 0) {
      candidate = candidate.copyWith(
        selected: candidate.selectionOverride ?? schedules.isNotEmpty,
        duplicateDescription: '$duplicates 个完全相同的安排已在课表中，将自动跳过。',
      );
    }
    final course = candidate.toCourse(semester.id);
    final errors = [...candidate.errors];
    if (candidate.sourcePeriods != null) {
      for (final schedule in candidate.schedules) {
        final target = semester.periods[schedule.weekday] ?? [];
        final source = candidate.sourcePeriods!;
        if (schedule.startPeriod < 1 ||
            schedule.endPeriod > target.length ||
            schedule.endPeriod > source.length) {
          continue;
        }
        for (var p = schedule.startPeriod - 1; p < schedule.endPeriod; p++) {
          if (source[p].startMinutes != target[p].startMinutes ||
              source[p].endMinutes != target[p].endMinutes) {
            errors.add('这个学期的节次时间与学校文件不同，请先核对学期设置。');
            break;
          }
        }
      }
    }
    try {
      course.validate(semester);
    } on InputProblem catch (error) {
      errors.add(importGuidance(error.message));
    }
    rows.add(
      ImportRow(
        candidate,
        errors.toSet().toList(),
        schedulesToSave: schedules,
        duplicateScheduleCount: duplicates,
      ),
    );
    if (candidate.selected && errors.isEmpty && schedules.isNotEmpty) {
      final effectiveCourse = candidate
          .copyWith(schedules: schedules)
          .toCourse(semester.id);
      conflicts.addAll(
        courseConflicts(
          effectiveCourse,
          semester,
          compared,
          state.classExceptions,
          state.independentLessons,
        ).map((other) => '${candidate.name} 与 $other'),
      );
      // Distinct transient IDs keep candidate courses independent from saved
      // courses and their exceptions. They are never persisted.
      compared.add(Course.fromDraft(-i - 1, effectiveCourse));
      if (candidate.schoolIdentity) {
        known.addAll(
          schedules.map(
            (s) => _scheduleKey(candidate.name, candidate.teacher, s),
          ),
        );
      }
    }
  }
  return ImportAssessment(rows, conflicts);
}

String _scheduleKey(String name, String teacher, ScheduleDraft s) =>
    jsonEncode([
      name.trim(),
      teacher.trim(),
      s.weekday,
      s.startPeriod,
      s.endPeriod,
      s.location.trim(),
      s.weeks.toList()..sort(),
    ]);
