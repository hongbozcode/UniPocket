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
  for (var i = 0; i < draft.candidates.length; i++) {
    final candidate = draft.candidates[i];
    final course = candidate.toCourse(semester.id);
    final errors = [...candidate.errors];
    try {
      course.validate(semester);
    } on InputProblem catch (error) {
      errors.add(importGuidance(error.message));
    }
    rows.add(ImportRow(candidate, errors.toSet().toList()));
    if (candidate.selected && errors.isEmpty) {
      conflicts.addAll(
        courseConflicts(
          course,
          semester,
          compared,
          state.classExceptions,
          state.independentLessons,
        ).map((other) => '${candidate.name} 与 $other'),
      );
      // Distinct transient IDs keep candidate courses independent from saved
      // courses and their exceptions. They are never persisted.
      compared.add(Course.fromDraft(-i - 1, course));
    }
  }
  return ImportAssessment(rows, conflicts);
}
