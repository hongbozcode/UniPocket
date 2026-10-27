import 'dart:math';
import 'dart:typed_data';

import '../backup/archive.dart';
import '../backup/store.dart';

import 'package:timezone/timezone.dart' as tz;

import '../storage/planner_store.dart';
import '../importing/model.dart';
import '../importing/preview.dart';
import '../timetable/model.dart';
import '../timetable/course_change.dart';
import '../tasks/model.dart';
import '../events/model.dart';
import '../reminders/notifications.dart';
import '../reminders/course_reminders.dart';
import '../reminders/event_reminders.dart';
import 'model.dart';
import '../random_tools/wheel_list.dart';
import '../random_tools/roll_call.dart';
import '../random_tools/lottery.dart';
import '../random_tools/groups.dart';
import '../random_tools/tool_library.dart';

/// The application boundary for local learning data. The same operations
/// drive the UI and tests that close and reopen the real local database.
class SemesterPlanner {
  SemesterPlanner(
    this._store, {
    this.notifications = const UnsupportedNotifications(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final PlannerStore _store;
  final LocalNotifications notifications;
  final DateTime Function() _clock;
  NotificationAccess notificationAccess = NotificationAccess.unavailable;
  bool reminderSyncFailed = false;
  Future<void>? _notificationQueue;
  int _restoreGeneration = 0;

  Future<Uint8List> exportBackup() async =>
      encodeBackup(await _store.backupSnapshot(_clock()));

  Future<BackupPreview> previewBackup(Uint8List bytes) async {
    final data = await decodeBackup(bytes);
    try {
      await _store.applyBackup(data, validateOnly: true);
    } catch (_) {
      throw const FormatException('备份校验失败：文件版本、内容或数据关系不完整，当前数据未改变');
    }
    final tables = data['tables'] as Map<String, dynamic>;
    int count(String name) => (tables[name] as List).length;
    return BackupPreview(
      createdAt: DateTime.parse(data['createdAt'] as String),
      summary:
          '${count('semester_records')} 个学期 · ${count('course_records')} 门课程 · '
          '${count('learning_task_records')} 个任务 · ${count('countdown_event_records')} 个事件',
      restore: () async {
        await _store.applyBackup(data);
        _restoreGeneration++;
        await refreshReminders();
      },
    );
  }

  Future<List<WheelList>> loadWheelLists() => _store.readWheelLists();

  Future<ToolLibrary> loadToolLibrary() => _store.readToolLibrary();

  Future<void> setToolFavorite(RandomTool tool, bool favorite) =>
      _store.writeToolFavorite(tool, favorite);

  Future<void> recordToolUse(RandomTool tool) => _store.recordToolUse(tool);

  Future<List<GroupList>> loadGroupLists() => _store.readGroupLists();

  Future<List<List<GroupMember>>> makeGroups(
    int id, {
    required GroupMode mode,
    required int amount,
    Random? random,
  }) async {
    final list = await _store.readGroupList(id);
    if (list.members.isEmpty) throw const FormatException('请先添加名单成员');
    if (amount < 1) throw const FormatException('请输入大于 0 的整数');
    if (mode == GroupMode.count && amount > list.members.length) {
      throw const FormatException('组数不能超过名单人数');
    }
    final shuffled = List<GroupMember>.of(list.members);
    final source = random ?? Random();
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = source.nextInt(i + 1);
      final member = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = member;
    }
    final count = mode == GroupMode.count
        ? amount
        : 1 + (shuffled.length - 1) ~/ amount;
    final groups = List.generate(count, (_) => <GroupMember>[]);
    for (var i = 0; i < shuffled.length; i++) {
      groups[i % count].add(shuffled[i]);
    }
    return List.unmodifiable(
      groups.map((g) => List<GroupMember>.unmodifiable(g)),
    );
  }

  Future<GroupList> saveGroupList({
    int? id,
    required String name,
    required List<GroupMember> members,
  }) {
    if (name.trim().isEmpty) throw const FormatException('请为名单命名');
    if (members.any((m) => m.name.trim().isEmpty || m.id < 1) ||
        members.map((m) => m.id).toSet().length != members.length) {
      throw const FormatException('成员姓名不能为空，成员身份必须独立');
    }
    return _store.writeGroupList(
      id: id,
      name: name.trim(),
      members: [
        for (final m in members)
          GroupMember(id: m.id, name: m.name.trim(), detail: m.detail.trim()),
      ],
    );
  }

  Future<List<LotteryPool>> loadLotteryPools() => _store.readLotteryPools();

  Future<LotteryDraw> prepareLottery(int id, {Random? random}) async {
    final generation = _restoreGeneration;
    final pool = await _store.readLotteryPool(id);
    final candidates = pool.candidates;
    if (candidates.isEmpty) throw StateError('没有剩余签项，请主动开始新一轮');
    final index = candidates[(random ?? Random()).nextInt(candidates.length)];
    return LotteryDraw(pool.items[index], () {
      if (generation != _restoreGeneration) throw StateError('数据已恢复，请重新抽签');
      return _store.commitLottery(pool, index);
    });
  }

  Future<LotteryPool> resetLottery(int id, {bool? repeat}) =>
      _store.resetLottery(id, repeat: repeat);

  Future<LotteryPool> saveLotteryPool({
    int? id,
    required String name,
    required List<String> items,
  }) {
    if (name.trim().isEmpty) throw const FormatException('请为签池命名');
    final entries = items.map((s) => s.trim()).toList();
    if (entries.any((s) => s.isEmpty)) {
      throw const FormatException('签文不能为空，请输入或移除空签');
    }
    return _store.writeLotteryPool(id: id, name: name.trim(), items: entries);
  }

  Future<List<RollCallList>> loadRollCallLists() => _store.readRollCallLists();

  Future<RollCallDraw> prepareRollCall(int id, {Random? random}) async {
    final generation = _restoreGeneration;
    final list = await _store.readRollCallList(id);
    final candidates = list.candidates;
    if (candidates.isEmpty) throw StateError('没有剩余成员，请主动开始新一轮');
    final member = candidates[(random ?? Random()).nextInt(candidates.length)];
    return RollCallDraw(member, () {
      if (generation != _restoreGeneration) throw StateError('数据已恢复，请重新点名');
      return _store.commitRollCall(list, member.id);
    });
  }

  /// Mode changes explicitly begin a fresh round, after UI confirmation.
  Future<RollCallList> resetRollCall(int id, {bool? repeat}) =>
      _store.resetRollCall(id, repeat: repeat);

  Future<RollCallList> saveRollCallList({
    int? id,
    required String name,
    required List<RollCallMember> members,
  }) {
    if (name.trim().isEmpty) throw const FormatException('请为名单命名');
    if (members.any((m) => m.name.trim().isEmpty || m.id < 1) ||
        members.map((m) => m.id).toSet().length != members.length) {
      throw const FormatException('成员姓名不能为空，成员身份必须独立');
    }
    return _store.writeRollCallList(
      id: id,
      name: name.trim(),
      members: [
        for (final m in members)
          RollCallMember(
            id: m.id,
            name: m.name.trim(),
            detail: m.detail.trim(),
          ),
      ],
    );
  }

  Future<WheelList> saveWheelList({
    int? id,
    required String name,
    required List<String> items,
  }) {
    final title = name.trim();
    if (title.isEmpty) throw const FormatException('请为转盘列表命名');
    final entries = items.map((s) => s.trim()).toList();
    if (entries.any((s) => s.isEmpty)) {
      throw const FormatException('选项文字不能为空；空列表可以保存，但不能转动');
    }
    return _store.writeWheelList(id: id, name: title, items: entries);
  }

  /// Serializes platform reconciliation and always reads committed SQLite data.
  /// Platform failure never turns a successful data save into a reported failure.
  Future<void> refreshReminders() {
    if (notifications is UnsupportedNotifications) {
      notificationAccess = NotificationAccess.unsupported;
      return Future.value();
    }
    Future<void> reconcile() async {
      try {
        final state = await load();
        notificationAccess = await notifications.status();
        final reminders = <LocalReminder>[];
        if (notificationAccess == NotificationAccess.enabled) {
          for (final task in state.tasks) {
            final at = taskReminderAt(task, state.campusTimeZone);
            if (!task.isCompleted &&
                at != null &&
                at.isAfter(_clock().toUtc())) {
              reminders.add(
                LocalReminder(
                  key: 'task:${task.id}',
                  at: at,
                  title: task.title,
                  body:
                      '${task.dueDate.month}月${task.dueDate.day}日 '
                      '${PeriodTime.format(task.dueMinutes)} 截止，记得按时完成。',
                ),
              );
            }
          }
        }
        var failed = false;
        final scopes = {
          'ddl': reminders,
          'course': notificationAccess == NotificationAccess.enabled
              ? futureCourseReminders(state, _clock())
              : <LocalReminder>[],
          'event': notificationAccess == NotificationAccess.enabled
              ? futureEventReminders(state, _clock())
              : <LocalReminder>[],
        };
        for (final entry in scopes.entries) {
          try {
            await notifications.replace(entry.key, entry.value);
          } catch (_) {
            failed = true;
          }
        }
        reminderSyncFailed = failed;
        if (failed) notificationAccess = NotificationAccess.unavailable;
      } catch (_) {
        reminderSyncFailed = true;
        notificationAccess = NotificationAccess.unavailable;
      }
    }

    final next = _notificationQueue?.then((_) => reconcile()) ?? reconcile();
    _notificationQueue = next;
    return next;
  }

  String taskReminderStatus(LearningTask task, String zone) {
    if (reminderSyncFailed) return '提醒更新失败，请重试';
    if (task.isCompleted) return '任务已完成，提醒已取消';
    if (task.reminderMinutesBefore == null) return '此项提醒已关闭';
    final at = taskReminderAt(task, zone)!;
    if (!at.isAfter(_clock().toUtc())) return '提醒时间已过，不会补发';
    return reminderAvailability;
  }

  String eventReminderStatus(
    CountdownEventDraft event,
    String zone, {
    bool preview = false,
  }) {
    if (reminderSyncFailed) return '提醒更新失败，请重试';
    final at = eventReminderAt(event, zone);
    if (at == null) return '此项提醒已关闭';
    if (!at.isAfter(_clock().toUtc())) return '提醒时间已过，不会补发';
    if (preview && notificationAccess == NotificationAccess.enabled) {
      return '通知已开启，保存后将按此时间提醒你。';
    }
    return reminderAvailability;
  }

  String get reminderAvailability => switch (notificationAccess) {
    NotificationAccess.enabled => '未来提醒已安排，送达时间受系统影响',
    NotificationAccess.blocked => '设备通知已关闭，提醒未启用',
    NotificationAccess.unsupported => '当前平台不支持本地通知',
    NotificationAccess.unavailable => '无法读取设备通知状态，请重试',
  };

  String courseReminderStatus(Course course, PlannerState state) {
    if (reminderSyncFailed) return '提醒更新失败，请重试';
    if (course.reminderMinutesBefore == null) return '此课程提醒已关闭';
    if (course.semesterId != state.currentSemesterId) {
      return '非当前学期，不安排课程提醒';
    }
    final times = currentCourseOccurrences(state)
        .where((o) => o.course.id == course.id)
        .map((o) => courseReminderAt(o, state.campusTimeZone)!)
        .toList();
    final past = times.where((at) => !at.isAfter(_clock().toUtc())).length;
    final prefix = past == 0 ? '' : '$past 次提醒时间已过，不会补发。';
    if (times.length == past) return '$prefix暂无未来课程提醒';
    return '$prefix${times.length - past} 次未来课程提醒。$reminderAvailability';
  }

  Future<void> requestNotificationPermission() async {
    try {
      await notifications.requestPermission();
      await refreshReminders();
    } catch (_) {
      notificationAccess = NotificationAccess.unavailable;
      reminderSyncFailed = true;
    }
  }

  Future<PlannerState> load() => _store.readState();

  Future<ImportPreview> previewImport(ImportDraft draft) async {
    final assessment = assessImport(await load(), draft);
    return ImportPreview(
      assessment,
      (allowConflicts) => _refreshAfter(
        _store.transaction(() async {
          final state = await load();
          final fresh = assessImport(state, draft);
          if (fresh.rows.any(
            (r) => r.candidate.selected && r.errors.isNotEmpty,
          )) {
            throw const InputProblem('先勾选要导入的课程，再补好待核对的信息。');
          }
          if (fresh.conflicts.isNotEmpty &&
              (!allowConflicts ||
                  fresh.conflicts.join('\n') !=
                      assessment.conflicts.join('\n'))) {
            throw CourseConflict(fresh.conflicts);
          }
          final ids = <int>[];
          final courses = [...state.courses];
          for (final row in fresh.rows.where(
            (r) => r.candidate.selected && r.schedulesToSave.isNotEmpty,
          )) {
            final candidate = row.candidate;
            final course = candidate
                .copyWith(schedules: row.schedulesToSave)
                .toCourse(draft.semesterId);
            final existing = candidate.schoolIdentity
                ? courses
                      .where(
                        (c) =>
                            c.semesterId == draft.semesterId &&
                            c.name.trim() == candidate.name.trim() &&
                            c.teacher.trim() == candidate.teacher.trim(),
                      )
                      .firstOrNull
                : null;
            if (existing == null) {
              final id = await _store.saveCourse(course);
              ids.add(id);
              courses.add(Course.fromDraft(id, course));
            } else {
              await _store.appendImportedSchedules(
                existing.id,
                row.schedulesToSave,
              );
              ids.add(existing.id);
            }
          }
          return ids.toSet().toList();
        }),
      ),
    );
  }

  Future<T> _refreshAfter<T>(Future<T> change) async {
    final result = await change;
    await refreshReminders();
    return result;
  }

  Future<CourseChangeImpact> previewCourseChange(
    int id,
    CourseDraft draft,
  ) async => courseChangeImpact(await load(), id, draft);

  Future<void> applyCourseChange(
    CourseChangeImpact preview, {
    required Map<(int, DateTime), OrphanChoice> choices,
    bool allowConflicts = false,
  }) => _refreshAfter(
    _store.transaction(() async {
      final state = await load();
      final impact = courseChangeImpact(
        state,
        preview.course.id,
        preview.draft,
      );
      if (impact.revision != preview.revision) {
        throw const InputProblem('课程或调停课已变更，请重新预览影响。');
      }
      final keys = impact.orphaned.map((e) => e.key).toSet();
      if (choices.length != keys.length || !keys.every(choices.containsKey)) {
        throw const InputProblem('请为每一项失去关联的例外选择保留为独立补课或删除。');
      }
      final candidate = Course.fromDraft(impact.course.id, impact.draft);
      final originalIds = impact.course.schedules
          .cast<ClassSchedule>()
          .map((s) => s.id)
          .toSet();
      final timetable = Timetable(
        impact.semester,
        [
          for (final c in state.courses)
            if (c.id == candidate.id) candidate else c,
        ],
        [
          for (final e in state.classExceptions)
            if (!originalIds.contains(e.scheduleId)) e,
          ...impact.retained,
        ],
        [
          ...state.independentLessons,
          for (var i = 0; i < impact.orphaned.length; i++)
            if (choices[impact.orphaned[i].key] == OrphanChoice.keepIndependent)
              IndependentLesson(
                id: -i - 1,
                courseId: candidate.id,
                date: impact.orphaned[i].targetDate,
                startMinutes: impact.orphaned[i].startMinutes,
                endMinutes: impact.orphaned[i].endMinutes,
                location: impact.orphaned[i].location,
              ),
        ],
      );
      final conflicts = effectiveCourseConflicts(timetable, candidate.id);
      if (conflicts.isNotEmpty && !allowConflicts) {
        throw CourseConflict(conflicts);
      }
      await _store.applyCourseChange(impact, choices);
    }),
  );

  Future<CourseDeletionImpact> previewCourseDeletion(int id) async {
    final state = await load();
    return _deletionImpact(state, id);
  }

  CourseDeletionImpact _deletionImpact(PlannerState state, int id) {
    final course = state.courses.where((c) => c.id == id).firstOrNull;
    if (course == null) throw const InputProblem('课程不存在，请返回后重试。');
    final ids = course.schedules.cast<ClassSchedule>().map((s) => s.id).toSet();
    return CourseDeletionImpact(
      course: course,
      exceptionCount: state.classExceptions
          .where((e) => ids.contains(e.scheduleId))
          .length,
      independentCount: state.independentLessons
          .where((l) => l.courseId == id)
          .length,
      taskCount: state.tasks.where((t) => t.courseId == id).length,
      revision: courseRevision(state, course, includeTasks: true),
    );
  }

  Future<void> deleteCourse(CourseDeletionImpact preview) => _refreshAfter(
    _store.transaction(() async {
      final impact = _deletionImpact(await load(), preview.course.id);
      if (impact.revision != preview.revision) {
        throw const InputProblem('课程或关联数据已变更，请重新确认删除影响。');
      }
      await _store.deleteCourse(impact.course.id);
    }),
  );

  Future<void> saveIndependentLesson(
    IndependentLesson lesson, {
    bool allowConflicts = false,
  }) => _refreshAfter(
    _store.transaction(() async {
      lesson.validate();
      final state = await load();
      if (!state.independentLessons.any(
        (l) => l.id == lesson.id && l.courseId == lesson.courseId,
      )) {
        throw const InputProblem('独立补课不存在，请返回后重试。');
      }
      final course = state.courses.singleWhere((c) => c.id == lesson.courseId);
      final semester = state.semesters.singleWhere(
        (s) => s.id == course.semesterId,
      );
      final conflicts =
          Timetable(
                semester,
                state.courses,
                state.classExceptions,
                state.independentLessons,
              )
              .onDate(lesson.date)
              .where(
                (o) =>
                    o.independentLessonId != lesson.id &&
                    lesson.startMinutes < o.endMinutes &&
                    o.startMinutes < lesson.endMinutes,
              )
              .map(
                (o) =>
                    '${o.course.name} · ${PeriodTime.format(o.startMinutes)}–${PeriodTime.format(o.endMinutes)}',
              )
              .toList();
      if (conflicts.isNotEmpty && !allowConflicts) {
        throw CourseConflict(conflicts);
      }
      await _store.saveIndependentLesson(lesson);
    }),
  );

  Future<void> deleteIndependentLesson(int id) =>
      _refreshAfter(_store.deleteIndependentLesson(id));

  Future<void> saveClassException(
    ClassExceptionDraft draft, {
    bool allowConflicts = false,
  }) => _refreshAfter(
    _store.transaction(() async {
      draft.validate();
      final state = await load();
      final course = state.courses
          .where(
            (c) => c.schedules.any(
              (s) => s is ClassSchedule && s.id == draft.scheduleId,
            ),
          )
          .firstOrNull;
      if (course == null) throw const InputProblem('原上课安排不存在，请返回后重试。');
      final semester = state.semesters.singleWhere(
        (s) => s.id == course.semesterId,
      );
      final original = Timetable(semester, [course])
          .onDate(draft.originalDate)
          .where((o) => (o.schedule as ClassSchedule).id == draft.scheduleId);
      if (original.isEmpty) throw const InputProblem('原日期没有此上课实例，请重新选择。');
      if (!draft.isCancelled && !allowConflicts) {
        final conflicts =
            Timetable(
                  semester,
                  state.courses,
                  state.classExceptions,
                  state.independentLessons,
                )
                .onDate(draft.targetDate)
                .where(
                  (o) =>
                      !(o.schedule is ClassSchedule &&
                          (o.schedule as ClassSchedule).id ==
                              draft.scheduleId &&
                          o.originalDate == draft.originalDate) &&
                      draft.startMinutes < o.endMinutes &&
                      o.startMinutes < draft.endMinutes,
                )
                .map(
                  (o) =>
                      '${o.course.name} · ${PeriodTime.format(o.startMinutes)}–${PeriodTime.format(o.endMinutes)}',
                )
                .toList();
        if (conflicts.isNotEmpty) throw CourseConflict(conflicts);
      }
      await _store.saveClassException(draft);
    }),
  );

  Future<int> saveEvent(CountdownEventDraft draft, {int? id}) async {
    draft.validate();
    return _refreshAfter(_store.saveEvent(draft, id: id));
  }

  Future<void> setEventPinned(int id, bool pinned) =>
      _store.setEventPinned(id, pinned);

  Future<void> deleteEvent(int id) => _refreshAfter(_store.deleteEvent(id));

  Future<void> setTaskCompleted(int id, bool completed) async {
    await _store.setTaskCompleted(id, completed);
    await refreshReminders();
  }

  Future<void> deleteTask(int id) async {
    await _store.deleteTask(id);
    await refreshReminders();
  }

  Future<int> saveTask(LearningTaskDraft draft, {int? id}) async {
    final saved = await _store.transaction(() async {
      draft.validate();
      if (draft.courseId != null &&
          !(await load()).courses.any((c) => c.id == draft.courseId)) {
        throw const InputProblem('关联课程不存在，请重新选择。');
      }
      return _store.saveTask(draft, id: id);
    });
    await refreshReminders();
    return saved;
  }

  Future<int> saveCourse(CourseDraft draft, {bool allowConflicts = false}) =>
      _refreshAfter(
        _store.transaction(() async {
          final state = await load();
          final semester = state.semesters
              .where((s) => s.id == draft.semesterId)
              .firstOrNull;
          if (semester == null) throw const InputProblem('学期不存在，请返回后重试。');
          draft.validate(semester);
          final conflicts = courseConflicts(
            draft,
            semester,
            state.courses,
            state.classExceptions,
            state.independentLessons,
          );
          if (conflicts.isNotEmpty && !allowConflicts) {
            throw CourseConflict(conflicts);
          }
          return _store.saveCourse(draft);
        }),
      );

  Future<int> saveSemester(
    SemesterDraft draft, {
    int? id,
    bool makeCurrent = false,
  }) => _refreshAfter(
    _store.transaction(() async {
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
    }),
  );

  Future<void> updateCourseDetails(
    int id, {
    required String name,
    required String teacher,
    required int colorIndex,
    required int? reminderMinutesBefore,
  }) async {
    validateCourseDetails(name, colorIndex);
    validateCourseReminder(reminderMinutesBefore);
    await _store.updateCourseDetails(
      id,
      name: name,
      teacher: teacher,
      colorIndex: colorIndex,
      reminderMinutesBefore: reminderMinutesBefore,
    );
    await refreshReminders();
  }

  Future<void> setCurrentSemester(int id) =>
      _refreshAfter(_store.selectCurrent(id));

  Future<void> setCampusTimeZone(String zone) async {
    if (!tz.timeZoneDatabase.locations.containsKey(zone)) {
      throw const InputProblem('请选择有效的 IANA 校园时区，例如 Asia/Shanghai。');
    }
    await _store.writeTimeZone(zone);
    await refreshReminders();
  }
}

DateTime? taskReminderAt(LearningTaskDraft task, String zone) {
  if (task.reminderMinutesBefore == null) return null;
  final date = task.dueDate;
  return tz.TZDateTime(
    tz.getLocation(zone),
    date.year,
    date.month,
    date.day,
    task.dueMinutes ~/ 60,
    task.dueMinutes % 60,
  ).toUtc().subtract(Duration(minutes: task.reminderMinutesBefore!));
}
