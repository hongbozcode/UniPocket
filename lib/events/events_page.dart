import 'dart:async';

import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../ui/design.dart';
import 'event_editor.dart';
import 'event_widgets.dart';
import 'model.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({required this.planner, required this.clock, super.key});
  final SemesterPlanner planner;
  final DateTime Function() clock;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with WidgetsBindingObserver {
  PlannerState? _state;
  var _history = false;
  var _busy = false;
  String? _error;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state = await widget.planner.load();
      if (mounted) {
        setState(() {
          _state = state;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '无法读取倒计时，请重试。现有记录保持不变。');
    }
  }

  Future<void> _edit([CountdownEvent? event]) async {
    if (_busy || !mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final saved = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(
          planner: widget.planner,
          state: _state!,
          clock: widget.clock,
          event: event,
        ),
      ),
    );
    if (saved != null) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(saved)));
      }
    }
  }

  Future<void> _action(CountdownEvent event, EventAction action) async {
    if (_busy || !mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (action == EventAction.edit) {
      await _edit(event);
      return;
    }
    if (action == EventAction.delete &&
        !await confirmEventDeletion(context, event)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (action == EventAction.pin) {
        await widget.planner.setEventPinned(event.id, !event.isPinned);
      } else {
        await widget.planner.deleteEvent(event.id);
      }
      await _load();
      if (action == EventAction.delete && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.planner.reminderSyncFailed
                  ? '事件已删除。提醒取消失败，请在设置中重试。'
                  : '事件已删除，未来提醒已取消',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = '修改失败，原记录保持不变，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _tabs(DateTime now) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xffeaf0f8),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        for (final history in [false, true])
          Expanded(
            child: Semantics(
              selected: _history == history,
              child: Material(
                color: _history == history
                    ? const Color(0xffd6c1fc)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => setState(() => _history = history),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Text(
                      history
                          ? '历史'
                          : '进行中  ${selectEvents(_state!.events, now).length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _history == history
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _history == history
                            ? const Color(0xff301985)
                            : const Color(0xff52617a),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final now = state?.campusTime(widget.clock().toUtc());
    final events = state == null
        ? <CountdownEvent>[]
        : selectEvents(state.events, now!, history: _history);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(),
            Expanded(
              child: state == null && _error == null
                  ? const Center(child: CircularProgressIndicator())
                  : PageContent(
                      children: [
                        Row(
                          children: [
                            RoundDesignButton(
                              icon: 'back',
                              label: '返回',
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                '倒计时',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            RoundDesignButton(
                              icon: 'plus',
                              label: '创建倒计时',
                              onPressed: state == null || _busy
                                  ? null
                                  : () => _edit(),
                              primary: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          ProblemBanner(_error!),
                          TextButton(
                            onPressed: _load,
                            child: const Text('重新读取'),
                          ),
                        ],
                        if (state != null) ...[
                          PageHeading(
                            '把重要的日子，\n装进口袋',
                            '校园时间  ${state.campusTimeZone}',
                            bottomSpacing: 18,
                          ),
                          _tabs(now!),
                          const SizedBox(height: 16),
                          if (events.isEmpty)
                            SurfaceCard(
                              color: lavenderSoft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _history ? '还没有历史事件' : '还没有进行中的事件',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _history
                                        ? '过去的日期会留在这里，记录不会自动删除。'
                                        : '把下一场考试或值得期待的日子装进口袋。',
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => _edit(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('添加事件'),
                                  ),
                                ],
                              ),
                            ),
                          for (final event in events)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: EventCard(
                                event: event,
                                campusNow: now,
                                onEdit: () => _edit(event),
                                onAction: _busy
                                    ? null
                                    : (action) => _action(event, action),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            '校园时间 ${state.campusTimeZone}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xff73819a),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
