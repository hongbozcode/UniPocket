import '../semesters/model.dart';
import '../timetable/model.dart';

/// Already parsed data. IDs, source labels and duplicate decisions belong to
/// the parser; this module does not infer school identities or file positions.
class ImportCandidate {
  ImportCandidate({
    required this.id,
    required this.sourceLabel,
    required this.name,
    this.teacher = '',
    this.colorIndex = 0,
    this.reminderMinutesBefore = 10,
    required List<ScheduleDraft> schedules,
    List<String> errors = const [],
    this.duplicateDescription,
    bool? selected,
  }) : schedules = List.unmodifiable(schedules),
       errors = List.unmodifiable(errors),
       selected = selected ?? duplicateDescription == null;

  final String id;
  final String sourceLabel;
  final String name;
  final String teacher;
  final int colorIndex;
  final int? reminderMinutesBefore;
  final List<ScheduleDraft> schedules;
  final List<String> errors;
  final String? duplicateDescription;
  final bool selected;

  ImportCandidate copyWith({
    String? name,
    String? teacher,
    List<ScheduleDraft>? schedules,
    List<String>? errors,
    bool? selected,
  }) => ImportCandidate(
    id: id,
    sourceLabel: sourceLabel,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    colorIndex: colorIndex,
    reminderMinutesBefore: reminderMinutesBefore,
    schedules: schedules ?? this.schedules,
    errors: errors ?? this.errors,
    duplicateDescription: duplicateDescription,
    selected: selected ?? this.selected,
  );

  CourseDraft toCourse(int semesterId) => CourseDraft(
    semesterId: semesterId,
    name: name,
    teacher: teacher,
    colorIndex: colorIndex,
    reminderMinutesBefore: reminderMinutesBefore,
    schedules: schedules,
  );
}

class ImportDraft {
  ImportDraft({
    required this.semesterId,
    required List<ImportCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);
  final int semesterId;
  final List<ImportCandidate> candidates;
}

class ImportRow {
  ImportRow(this.candidate, List<String> errors)
    : errors = List.unmodifiable(errors);
  final ImportCandidate candidate;
  final List<String> errors;
}

class ImportPreview {
  ImportPreview(
    this._save, {
    required this.draft,
    required List<ImportRow> rows,
    required List<String> conflicts,
  }) : rows = List.unmodifiable(rows),
       conflicts = List.unmodifiable(conflicts);
  final ImportDraft draft;
  final List<ImportRow> rows;
  final List<String> conflicts;
  final Future<List<int>> Function(bool) _save;
  Future<List<int>>? _submission;

  int get selectedCount => rows.where((r) => r.candidate.selected).length;
  bool get canSubmit =>
      selectedCount > 0 &&
      rows.every((r) => !r.candidate.selected || r.errors.isEmpty);

  /// One successful submission per preview, including simultaneous taps.
  /// Failure releases the attempt so the same preview can be retried.
  Future<List<int>> commit({bool allowConflicts = false}) {
    if (!canSubmit) {
      return Future.error(const InputProblem('请先修正或排除错误项，并至少选择一项。'));
    }
    return _submission ??= _attempt(allowConflicts);
  }

  Future<List<int>> _attempt(bool allowConflicts) async {
    try {
      return List.unmodifiable(await _save(allowConflicts));
    } catch (_) {
      _submission = null;
      rethrow;
    }
  }
}
