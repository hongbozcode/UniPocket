import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../ui/design.dart';
import '../reminders/notification_card.dart';
import '../reminders/event_reminders.dart';
import 'model.dart';

Future<bool> confirmEventDeletion(
  BuildContext context,
  CountdownEvent event,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这项事件？'),
        content: Text('“${event.title}”将从本机删除，并取消未来提醒。此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    ) ==
    true;

class EventEditor extends StatefulWidget {
  const EventEditor({
    required this.planner,
    required this.state,
    required this.clock,
    this.event,
    super.key,
  });
  final SemesterPlanner planner;
  final PlannerState state;
  final DateTime Function() clock;
  final CountdownEvent? event;

  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  late final _title = TextEditingController(text: widget.event?.title);
  final _scroll = ScrollController();
  late DateTime _date =
      widget.event?.targetDate ?? DateTime.utc(_now.year, _now.month, _now.day);
  late EventKind _kind = widget.event?.kind ?? EventKind.exam;
  late bool _pinned = widget.event?.isPinned ?? false;
  late bool _reminderEnabled =
      widget.event == null || widget.event!.reminderMinutes != null;
  late int _reminderMinutes = widget.event?.reminderMinutes ?? 540;
  var _busy = false;
  String? _error;
  DateTime get _now => widget.state.campusTime(widget.clock().toUtc());

  @override
  void dispose() {
    _title.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = CountdownEventDraft(
        title: _title.text,
        targetDate: _date,
        kind: _kind,
        isPinned: _pinned,
        reminderMinutes: _reminderEnabled ? _reminderMinutes : null,
      );
      await widget.planner.saveEvent(draft, id: widget.event?.id);
      if (mounted) {
        Navigator.pop(
          context,
          '事件已保存到本机。${widget.planner.eventReminderStatus(draft, widget.state.campusTimeZone)}',
        );
      }
    } on InputProblem catch (error) {
      _showProblem(error.message);
    } catch (_) {
      _showProblem('事件保存失败，请重试。原记录保持不变。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmEventDeletion(context, widget.event!) || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.planner.deleteEvent(widget.event!.id);
      if (mounted) {
        Navigator.pop(
          context,
          widget.planner.reminderSyncFailed
              ? '事件已删除。提醒取消失败，请在设置中重试。'
              : '事件已删除，未来提醒已取消',
        );
      }
    } catch (_) {
      _showProblem('删除失败，原记录仍在，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = _now;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      currentDate: DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: '事件日期 · ${widget.state.campusTimeZone}',
    );
    if (date != null && mounted) {
      setState(() => _date = DateTime.utc(date.year, date.month, date.day));
    }
  }

  Future<void> _pickReminderTime() async {
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderMinutes ~/ 60,
        minute: _reminderMinutes % 60,
      ),
      helpText: '事件当天几点提醒 · 校园时间',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _reminderMinutes = chosen.hour * 60 + chosen.minute);
    }
  }

  void _showProblem(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Widget _reminderCard() {
    final draft = CountdownEventDraft(
      title: _title.text,
      targetDate: _date,
      reminderMinutes: _reminderEnabled ? _reminderMinutes : null,
    );
    final at = eventReminderAt(draft, widget.state.campusTimeZone);
    final status = widget.planner.eventReminderStatus(
      draft,
      widget.state.campusTimeZone,
      preview: true,
    );
    return SurfaceCard(
      color: lavenderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            key: const ValueKey('event-reminder-enabled'),
            title: const Text(
              '当天提醒我',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('默认上午 9 点提醒一次，也可以改时间'),
            value: _reminderEnabled,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          if (at != null) ...[
            TextButton.icon(
              key: const ValueKey('event-reminder-time'),
              onPressed: _pickReminderTime,
              icon: const DesignIcon('bell', size: 20),
              label: Text('当天 ${PeriodTime.format(_reminderMinutes)}'),
            ),
            Text(
              '提醒时间：${dateText(_date)} ${PeriodTime.format(_reminderMinutes)} · 校园时间',
              style: const TextStyle(fontSize: 12, color: Color(0xff52617a)),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: const TextStyle(fontSize: 12, color: Color(0xff52617a)),
            ),
          ] else
            const Text('已关闭提醒，倒计时仍会保留。'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final days = _date
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.event == null ? '创建倒计时' : '编辑倒计时')),
        body: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: _busy,
            child: PageContent(
              controller: _scroll,
              children: [
                Text(
                  '校园时间 · ${widget.state.campusTimeZone}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff73819a),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ProblemBanner(_error!),
                if (_busy) const LinearProgressIndicator(),
                TextField(
                  key: const ValueKey('event-title'),
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: '事件标题',
                    hintText: '例如：期中考试、社团展示日',
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 20),
                const Text(
                  '事件类型',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final kind in EventKind.values)
                      ChoiceChip(
                        label: Text(kind == EventKind.exam ? '考试' : '自定义'),
                        selected: _kind == kind,
                        onSelected: (_) => setState(() => _kind = kind),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SurfaceCard(
                  color: lavenderSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '目标日期',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey('event-date'),
                        onPressed: _pickDate,
                        icon: const DesignIcon('calendar', size: 20),
                        label: Text(dateText(_date)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days < 0
                            ? '此日期已过去，保存后进入历史，仍可编辑。'
                            : days == 0
                            ? '就是今天 · 今天结束后将保留在历史。'
                            : '还有 $days 天 · 按校园日历日期计算。',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff52617a),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '可选择 1900 至 2200 年；手机时区变化不会改变目标日期。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff52617a),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _reminderCard(),
                const SizedBox(height: 16),
                NotificationCard(
                  planner: widget.planner,
                  onStatusChanged: () {
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                SurfaceCard(
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('置顶事件'),
                    subtitle: const Text('在进行中列表和首页优先展示'),
                    value: _pinned,
                    onChanged: (value) => setState(() => _pinned = value),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_busy ? '正在保存…' : '保存事件'),
                ),
                if (widget.event != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('删除事件'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
