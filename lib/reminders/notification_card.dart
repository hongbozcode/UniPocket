import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'notifications.dart';

/// The lavender reminder group from the settings reference, with real OS state.
class NotificationCard extends StatefulWidget {
  const NotificationCard({
    required this.planner,
    this.onStatusChanged,
    super.key,
  });
  final SemesterPlanner planner;
  final VoidCallback? onStatusChanged;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with WidgetsBindingObserver {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh({bool request = false, bool settings = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (settings) await widget.planner.notifications.openSettings();
      if (request) {
        await widget.planner.requestNotificationPermission();
      } else {
        await widget.planner.refreshReminders();
      }
    } catch (_) {
      if (mounted) _error = '无法打开系统设置，请从手机设置中管理 UniPocket 通知。';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onStatusChanged?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = widget.planner.notificationAccess;
    final (label, tint, foreground) = switch (access) {
      NotificationAccess.enabled => (
        '通知已开启',
        const Color(0xffd6f4e8),
        const Color(0xff198568),
      ),
      NotificationAccess.blocked => (
        '设备通知已关闭',
        const Color(0xffffedf0),
        const Color(0xffb32643),
      ),
      NotificationAccess.unsupported => (
        '当前平台不支持本地通知',
        const Color(0xffeaf0f8),
        const Color(0xff52617a),
      ),
      NotificationAccess.unavailable => (
        '通知状态暂不可用',
        const Color(0xffeaf0f8),
        const Color(0xff52617a),
      ),
    };
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return SurfaceCard(
      color: lavenderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final inline =
                  box.maxWidth >= 290 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 20 &&
                  access == NotificationAccess.enabled;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const DesignIcon('bell', color: Color(0xff8b62e6)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '通知权限',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (inline) badge,
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  if (!inline) ...[const SizedBox(height: 12), badge],
                ],
              );
            },
          ),
          const Divider(height: 28, color: Color(0xffdfd5f6)),
          const Text(
            '课程默认提前 10 分钟，DDL 默认提前 1 天。可在具体课程或任务中调整或关闭。',
            style: TextStyle(color: Color(0xff52617a), fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            '数据保存在本机。通知关闭不影响管理；省电、关机或系统限制可能延迟送达。',
            style: TextStyle(color: Color(0xff73819a), fontSize: 12),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            ProblemBanner(_error!),
          ],
          if (widget.planner.reminderSyncFailed) ...[
            const SizedBox(height: 8),
            const Text(
              '提醒更新失败，学习数据已保留。可重试更新提醒。',
              style: TextStyle(color: Color(0xffb32643)),
            ),
          ],
          if (access != NotificationAccess.unsupported) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (access == NotificationAccess.blocked)
                  TextButton(
                    onPressed: _busy ? null : () => _refresh(request: true),
                    child: const Text('允许通知'),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => _refresh(settings: true),
                  child: const Text('系统通知设置'),
                ),
                TextButton(
                  onPressed: _busy ? null : _refresh,
                  child: const Text('刷新提醒状态'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
