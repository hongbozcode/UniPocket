import 'package:timezone/timezone.dart' as tz;

import '../storage/planner_store.dart';
import 'model.dart';

/// The application boundary for semester configuration. The same operations
/// drive the UI and tests that close and reopen the real local database.
class SemesterPlanner {
  SemesterPlanner(this._store);
  final PlannerStore _store;

  Future<PlannerState> load() => _store.readState();

  Future<int> saveSemester(
    SemesterDraft draft, {
    int? id,
    bool makeCurrent = false,
  }) async {
    draft.validate();
    return _store.save(draft, id: id, makeCurrent: makeCurrent);
  }

  Future<void> setCurrentSemester(int id) => _store.selectCurrent(id);

  Future<void> setCampusTimeZone(String zone) async {
    if (!tz.timeZoneDatabase.locations.containsKey(zone)) {
      throw const InputProblem('请选择有效的 IANA 校园时区，例如 Asia/Shanghai。');
    }
    await _store.writeTimeZone(zone);
  }
}
