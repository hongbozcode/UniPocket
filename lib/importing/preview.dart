import '../semesters/model.dart';
import '../timetable/model.dart';
import 'model.dart';

/// Pure preview uses the same course validation and effective occurrences as
/// manual entry, and is run again inside the commit transaction.
ImportPreview buildImportPreview(
  PlannerState state,
  ImportDraft draft,
  Future<List<int>> Function(bool) save,
) {
  final semester = state.semesters
      .where((s) => s.id == draft.semesterId)
      .firstOrNull;
  if (semester == null) throw const InputProblem('请选择有效的目标学期。');
  final ids = draft.candidates.map((c) => c.id).toSet();
  if (ids.length != draft.candidates.length || ids.any((id) => id.isEmpty)) {
    throw const InputProblem('候选标识无效，请重新加载解析结果。');
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
      errors.add(error.message);
    }
    rows.add(ImportRow(candidate, errors));
    if (candidate.selected && errors.isEmpty) {
      conflicts.addAll(
        courseConflicts(
          course,
          semester,
          compared,
          state.classExceptions,
          state.independentLessons,
        ).map(
          (other) => '${candidate.sourceLabel} · ${candidate.name} ↔ $other',
        ),
      );
      // Distinct transient IDs keep candidate courses independent from saved
      // courses and their exceptions. They are never persisted.
      compared.add(Course.fromDraft(-i - 1, course));
    }
  }
  return ImportPreview(save, draft: draft, rows: rows, conflicts: conflicts);
}
