import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ui/design.dart';
import 'model.dart';

enum EventAction { edit, pin, delete }

class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.campusNow,
    required this.onEdit,
    this.onAction,
    super.key,
  });
  final CountdownEvent event;
  final DateTime campusNow;
  final VoidCallback onEdit;
  final ValueChanged<EventAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final days = event.daysRemaining(campusNow);
    final color = event.isPinned
        ? lavenderSoft
        : days == 0 || event.kind == EventKind.exam
        ? const Color(0xfffff4d2)
        : const Color(0xffe6f5ed);
    return ClipPath(
      clipper: _NoteClipper(torn: event.isPinned),
      child: Material(
        color: color,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: .10,
                  child: Image.asset(
                    'docs/design/resources/materials/paper-grain.png',
                    repeat: ImageRepeat.repeat,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 10, 14),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final art =
                        box.maxWidth > 300 &&
                        MediaQuery.textScalerOf(context).scale(14) < 21;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: onAction == null ? 0 : 48,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.isPinned) ...[
                                const Padding(
                                  padding: EdgeInsets.only(top: 3, bottom: 7),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DesignIcon(
                                        'pin',
                                        size: 18,
                                        color: Color(0xff7451c8),
                                      ),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '已置顶',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff6240b0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Padding(
                                padding: EdgeInsets.only(
                                  top: event.isPinned ? 7 : 0,
                                ),
                                child: Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (days > 0)
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$days',
                                            style: const TextStyle(
                                              fontSize: 48,
                                              height: 1.1,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: ' 天',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Text(
                                      event.countdownText(campusNow),
                                      style: TextStyle(
                                        fontSize: days == 0 ? 32 : 26,
                                        fontWeight: FontWeight.w800,
                                        height: 1.3,
                                      ),
                                    ),
                                  const SizedBox(height: 9),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const DesignIcon(
                                        'clock',
                                        size: 17,
                                        color: Color(0xff52617a),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${event.targetDate.year}年${event.targetDate.month}月${event.targetDate.day}日 ${weekdayNames[event.targetDate.weekday - 1]}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.5,
                                            color: Color(0xff52617a),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (art)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                ),
                                child: SvgPicture.asset(
                                  'docs/design/resources/illustrations/${event.isPinned || event.kind == EventKind.exam
                                      ? 'calendar'
                                      : days == 0
                                      ? 'pencil'
                                      : 'flag'}.svg',
                                  width: event.isPinned ? 90 : 74,
                                  height: event.isPinned ? 90 : 74,
                                  excludeFromSemantics: true,
                                ),
                              ),
                          ],
                        ),
                        if (event.isPinned) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '按校园日期计算',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xff67758d),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            if (onAction != null)
              Positioned(
                top: 8,
                right: 6,
                child: PopupMenuButton<EventAction>(
                  tooltip: '更多：${event.title}',
                  icon: const DesignIcon(
                    'more',
                    size: 21,
                    color: Color(0xff52617a),
                  ),
                  onSelected: onAction,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: EventAction.edit,
                      child: Text('编辑'),
                    ),
                    PopupMenuItem(
                      value: EventAction.pin,
                      child: Text(event.isPinned ? '取消置顶' : '置顶'),
                    ),
                    const PopupMenuItem(
                      value: EventAction.delete,
                      child: Text('删除'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteClipper extends CustomClipper<Path> {
  const _NoteClipper({required this.torn});
  final bool torn;

  @override
  Path getClip(Size size) {
    if (!torn) {
      return Path()..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)),
      );
    }
    final path = Path()
      ..moveTo(0, 22)
      ..quadraticBezierTo(0, 0, 22, 0)
      ..lineTo(size.width - 22, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 22)
      ..lineTo(size.width, size.height - 5);
    for (var x = size.width; x > 0; x -= 12) {
      path
        ..lineTo((x - 6).clamp(0, size.width), size.height - 2)
        ..lineTo((x - 12).clamp(0, size.width), size.height - 5);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_NoteClipper oldClipper) => torn != oldClipper.torn;
}
