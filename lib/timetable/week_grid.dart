import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../ui/course_palette.dart';
import '../ui/design.dart';
import 'model.dart';

/// Seven campus calendar days share one period axis. A course spans its actual
/// start/end periods; conflicts get separate lanes so neither course is hidden.
class WeekGrid extends StatefulWidget {
  const WeekGrid({
    required this.timetable,
    required this.week,
    required this.today,
    required this.onEdit,
    this.onOccurrence,
    super.key,
  });
  final Timetable timetable;
  final int week;
  final DateTime today;
  final ValueChanged<Course> onEdit;
  final ValueChanged<ClassOccurrence>? onOccurrence;

  @override
  State<WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends State<WeekGrid> {
  final _horizontal = ScrollController();

  // Only lessons matching the destination day's configured periods belong on
  // its period axis. Free-time moves remain fully visible in a dated list.
  (int, int)? _periods(ClassOccurrence occurrence) {
    final periods =
        widget.timetable.semester.periods[occurrence.date.weekday] ?? [];
    final start = periods.indexWhere(
      (p) => p.startMinutes == occurrence.startMinutes,
    );
    final end = periods.indexWhere(
      (p) => p.endMinutes == occurrence.endMinutes,
    );
    return start >= 0 && end >= start ? (start + 1, end + 1) : null;
  }

  void _open(ClassOccurrence occurrence) => widget.onOccurrence != null
      ? widget.onOccurrence!(occurrence)
      : widget.onEdit(occurrence.course);
  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  Widget _periodLabel(int start, int end) {
    final times = {
      for (final periods in widget.timetable.semester.periods.values)
        if (periods.length >= start)
          (
            periods[start - 1].startMinutes,
            periods.length >= end ? periods[end - 1].endMinutes : null,
          ),
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          start == end ? '$start' : '$start–$end',
          style: const TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (times.length == 1 && times.single.$2 != null) ...[
          const SizedBox(height: 4),
          Text(
            PeriodTime.format(times.single.$1),
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              color: Color(0xff73819a),
            ),
          ),
          Container(
            width: 1,
            height: 8,
            margin: const EdgeInsets.symmetric(vertical: 3),
            color: const Color(0xffb6c0d1),
          ),
          Text(
            PeriodTime.format(times.single.$2!),
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              color: Color(0xff73819a),
            ),
          ),
        ] else if (times.isNotEmpty)
          const Text(
            '按星期',
            style: TextStyle(fontSize: 10, color: Color(0xff73819a)),
          ),
      ],
    );
  }

  Widget _course(ClassOccurrence occurrence) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context);
      final locationHeight = scale.scale(9) * 1.2;
      final lines =
          ((box.maxHeight - 14 - locationHeight) / (scale.scale(12) * 1.15))
              .floor()
              .clamp(1, 3);
      final label =
          '${occurrence.course.name}，${weekdayNames[occurrence.date.weekday - 1]}，'
          '${occurrence.isRescheduled ? '已调课，原课次 ${dateText(occurrence.originalDate)}，' : ''}'
          '${occurrence.isIndependent ? '独立补课，' : ''}'
          '${PeriodTime.format(occurrence.startMinutes)}–${PeriodTime.format(occurrence.endMinutes)}，${occurrence.location}';
      return Semantics(
        label: label,
        button: true,
        child: Tooltip(
          message: label,
          child: Material(
            color: courseTint(occurrence.course.colorIndex),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _open(occurrence),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${occurrence.isIndependent
                          ? '补 · '
                          : occurrence.isRescheduled
                          ? '调 · '
                          : ''}${occurrence.course.name}',
                      maxLines: lines,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      occurrence.location.isEmpty
                          ? '地点未填'
                          : occurrence.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 0,
                        height: 1.2,
                        color: Color(0xff52617a),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final all = widget.timetable.inWeek(widget.week);
    final occurrences = all.where((o) => _periods(o) != null).toList();
    final flexible = all.where((o) => _periods(o) == null).toList();
    final lanes = <ClassOccurrence, int>{};
    final laneCounts = <int, int>{};
    for (var day = 1; day <= 7; day++) {
      final ends = <int>[];
      for (final occurrence in occurrences.where(
        (o) => o.date.weekday == day,
      )) {
        var lane = ends.indexWhere((end) => end <= occurrence.startMinutes);
        if (lane < 0) {
          lane = ends.length;
          ends.add(0);
        }
        ends[lane] = occurrence.endMinutes;
        lanes[occurrence] = lane;
      }
      laneCounts[day] = math.max(1, ends.length);
    }
    final mostLanes = laneCounts.values.reduce(math.max);
    final periods = widget.timetable.semester.periods.values
        .map((p) => p.length)
        .reduce(math.max);
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    double labelWidth(String text, double size) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style
              .copyWith(fontSize: size, height: 1.2),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final axisWidth = math.max(
      42.0,
      math.max(labelWidth('00:00', 10), labelWidth('$periods–$periods', 12)) +
          8,
    );
    final headerHeight = math.max(52.0, 44 * scale);
    final periodHeight = math.max(56.0, 56 * scale);
    final height = headerHeight + periods * periodHeight;
    final monday = widget.timetable.mondayOf(widget.week);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumDay = scale > 1.3
            ? 84 * mostLanes
            : mostLanes > 1
            ? 64 * mostLanes
            : 0;
        final width = math.max(
          constraints.maxWidth,
          axisWidth + minimumDay * 7,
        );
        final dayWidth = (width - axisWidth) / 7;
        final scrolls = width > constraints.maxWidth + 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scrolls)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  mostLanes > 1 ? '本周含冲突课程，横向滑动查看全部课程' : '横向滑动查看七天',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff73819a),
                  ),
                ),
              ),
            Scrollbar(
              controller: _horizontal,
              thumbVisibility: scrolls,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(bottom: scrolls ? 12 : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    key: const ValueKey('week-grid'),
                    width: width,
                    height: height,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: Color(0xfffcfdff)),
                        ),
                        for (var day = 1; day <= 7; day++)
                          if (dateText(monday.add(Duration(days: day - 1))) ==
                              dateText(widget.today))
                            Positioned(
                              left: axisWidth + (day - 1) * dayWidth,
                              top: 0,
                              width: dayWidth,
                              height: height,
                              child: const ColoredBox(color: Color(0xfff5f1ff)),
                            ),
                        for (var day = 0; day <= 7; day++)
                          Positioned(
                            left: axisWidth + day * dayWidth - .5,
                            top: 0,
                            bottom: 0,
                            child: const SizedBox(
                              width: 1,
                              child: ColoredBox(color: Color(0xffe9edf5)),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          top: headerHeight,
                          right: 0,
                          child: const SizedBox(
                            height: 1,
                            child: ColoredBox(color: Color(0xffe9edf5)),
                          ),
                        ),
                        for (var start = 1; start <= periods; start += 2) ...[
                          Positioned(
                            left: 0,
                            top: headerHeight + (start - 1) * periodHeight,
                            width: axisWidth,
                            height:
                                math.min(2, periods - start + 1) * periodHeight,
                            child: _periodLabel(
                              start,
                              math.min(start + 1, periods),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top:
                                headerHeight +
                                math.min(start + 1, periods) * periodHeight -
                                1,
                            right: 0,
                            child: const SizedBox(
                              height: 1,
                              child: ColoredBox(color: Color(0xffe9edf5)),
                            ),
                          ),
                        ],
                        Positioned(
                          left: 0,
                          top: 0,
                          width: axisWidth,
                          height: headerHeight,
                          child: const Center(
                            child: Text(
                              '节次',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xff73819a),
                              ),
                            ),
                          ),
                        ),
                        for (var day = 1; day <= 7; day++)
                          Positioned(
                            left: axisWidth + (day - 1) * dayWidth,
                            top: 0,
                            width: dayWidth,
                            height: headerHeight,
                            child: Builder(
                              builder: (_) {
                                final date = monday.add(
                                  Duration(days: day - 1),
                                );
                                final today =
                                    dateText(date) == dateText(widget.today);
                                return Semantics(
                                  label:
                                      '${weekdayNames[day - 1]} ${dateText(date)}${today ? ' 今天' : ''}',
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        [
                                          '一',
                                          '二',
                                          '三',
                                          '四',
                                          '五',
                                          '六',
                                          '日',
                                        ][day - 1],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: today
                                              ? const Color(0xffded4ff)
                                              : null,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${date.day}',
                                          softWrap: false,
                                          maxLines: 1,
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: today
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: today
                                                ? primaryBlue
                                                : inkColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        for (final occurrence in occurrences)
                          Positioned(
                            left:
                                axisWidth +
                                (occurrence.date.weekday - 1) * dayWidth +
                                lanes[occurrence]! *
                                    (dayWidth /
                                        laneCounts[occurrence.date.weekday]!) +
                                1,
                            top:
                                headerHeight +
                                (_periods(occurrence)!.$1 - 1) * periodHeight +
                                2,
                            width:
                                dayWidth /
                                    laneCounts[occurrence.date.weekday]! -
                                2,
                            height:
                                (_periods(occurrence)!.$2 -
                                        _periods(occurrence)!.$1 +
                                        1) *
                                    periodHeight -
                                4,
                            child: _course(occurrence),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (flexible.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '节次外调课',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '以下时间与每日节次不完全相同，按实际时间上课。',
                style: TextStyle(fontSize: 12, color: Color(0xff73819a)),
              ),
              for (final occurrence in flexible)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Material(
                    color: courseTint(occurrence.course.colorIndex),
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(occurrence.course.name),
                      subtitle: Text(
                        '${dateText(occurrence.date)} · ${weekdayNames[occurrence.date.weekday - 1]}\n'
                        '${PeriodTime.format(occurrence.startMinutes)}–${PeriodTime.format(occurrence.endMinutes)} · ${occurrence.location.isEmpty ? '地点未填写' : occurrence.location}\n'
                        '${occurrence.isIndependent ? '独立补课' : '已调课 · 原课次 ${dateText(occurrence.originalDate)}'}',
                      ),
                      onTap: () => _open(occurrence),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
