import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../ui/design.dart';
import 'course_editor.dart';
import 'model.dart';

class OccurrenceCard extends StatelessWidget {
  const OccurrenceCard(this.occurrence, {required this.onTap, super.key});
  final ClassOccurrence occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: courseColors[occurrence.course.colorIndex],
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              occurrence.course.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${PeriodTime.format(occurrence.startMinutes)}–${PeriodTime.format(occurrence.endMinutes)} · 第 ${occurrence.schedule.startPeriod}–${occurrence.schedule.endPeriod} 节',
            ),
            const SizedBox(height: 4),
            Text(occurrence.location.isEmpty ? '地点未填写' : occurrence.location),
            if (occurrence.course.teacher.isNotEmpty)
              Text('教师 · ${occurrence.course.teacher}'),
          ],
        ),
      ),
    ),
  );
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({
    required this.state,
    required this.campusNow,
    required this.onAdd,
    required this.onEdit,
    required this.onManage,
    super.key,
  });
  final PlannerState state;
  final DateTime campusNow;
  final VoidCallback onAdd;
  final ValueChanged<Course> onEdit;
  final VoidCallback onManage;

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late int _week = _currentWeek;
  var _today = false;
  final _horizontal = ScrollController();
  Timetable get _timetable => widget.state.timetable!;
  int get _actualWeek => _timetable.weekOf(widget.campusNow);
  int get _currentWeek => _actualWeek.clamp(1, _timetable.semester.totalWeeks);

  @override
  void didUpdateWidget(TimetablePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentSemesterId != widget.state.currentSemesterId) {
      _week = _currentWeek;
    }
    _week = _week.clamp(1, _timetable.semester.totalWeeks);
  }

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  Widget _grid() {
    final occurrences = _timetable.inWeek(_week);
    final periods = _timetable.semester.periods;
    final count = periods.values.fold(
      0,
      (maximum, day) => math.max(maximum, day.length),
    );
    final monday = _timetable.mondayOf(_week);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '横向滑动查看七天 · 点击课程查看详情',
          style: TextStyle(color: Color(0xff52617a)),
        ),
        const SizedBox(height: 12),
        Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 16),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(120),
              columnWidths: const {0: FixedColumnWidth(64)},
              border: TableBorder.all(
                color: const Color(0xffdfe5f0),
                borderRadius: BorderRadius.circular(12),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('节次'),
                    ),
                    for (var day = 1; day <= 7; day++)
                      Builder(
                        builder: (_) {
                          final date = monday.add(Duration(days: day - 1));
                          final today =
                              dateText(date) == dateText(widget.campusNow);
                          return Container(
                            color: today ? lavenderSoft : Colors.white,
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              '${weekdayNames[day - 1]}\n${date.month}/${date.day}${today ? '\n今天' : ''}',
                              style: TextStyle(
                                fontWeight: today
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                for (var period = 1; period <= count; period++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('第\n$period\n节'),
                      ),
                      for (var day = 1; day <= 7; day++)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if ((periods[day]?.length ?? 0) >= period)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    PeriodTime.format(
                                      periods[day]![period - 1].startMinutes,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff52617a),
                                    ),
                                  ),
                                ),
                              for (final occurrence in occurrences)
                                if (occurrence.date.weekday == day &&
                                    occurrence.schedule.startPeriod <= period &&
                                    occurrence.schedule.endPeriod >= period)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Material(
                                      color:
                                          courseColors[occurrence
                                              .course
                                              .colorIndex],
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () =>
                                            widget.onEdit(occurrence.course),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                occurrence.course.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (occurrence
                                                      .schedule
                                                      .startPeriod ==
                                                  period) ...[
                                                Text(
                                                  '第 ${occurrence.schedule.startPeriod}–${occurrence.schedule.endPeriod} 节',
                                                ),
                                                Text(
                                                  '${PeriodTime.format(occurrence.startMinutes)}–${PeriodTime.format(occurrence.endMinutes)}',
                                                ),
                                                Text(
                                                  occurrence.location.isEmpty
                                                      ? '地点未填写'
                                                      : occurrence.location,
                                                ),
                                              ] else
                                                const Text('续课'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              if ((periods[day]?.length ?? 0) < period)
                                const Text('未设节次'),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _timetable.courses;
    final today = _timetable.onDate(widget.campusNow);
    return PageContent(
      children: [
        PageHeading(
          '我的课表',
          '${_timetable.semester.name}\n校园时间 · ${widget.state.campusTimeZone}',
          art: 'book',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('添加课程'),
            ),
            TextButton(
              onPressed: widget.onManage,
              child: const Text('切换／管理学期'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('周课表'),
              selected: !_today,
              onSelected: (_) => setState(() => _today = false),
            ),
            ChoiceChip(
              label: const Text('今日'),
              selected: _today,
              onSelected: (_) => setState(() => _today = true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_today) ...[
          Text(
            '${dateText(widget.campusNow)} · ${weekdayNames[widget.campusNow.weekday - 1]}',
          ),
          const SizedBox(height: 16),
          if (today.isEmpty) const SurfaceCard(child: Text('今天没有课程，可以从容安排时间。')),
          for (final occurrence in today)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OccurrenceCard(
                occurrence,
                onTap: () => widget.onEdit(occurrence.course),
              ),
            ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: '上一周',
                onPressed: _week > 1 ? () => setState(() => _week--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '第 $_week 周',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                tooltip: '下一周',
                onPressed: _week < _timetable.semester.totalWeeks
                    ? () => setState(() => _week++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: () => setState(() => _week = _currentWeek),
                child: const Text('回到本周'),
              ),
            ],
          ),
          Text(
            '${dateText(_timetable.mondayOf(_week))} — ${dateText(_timetable.mondayOf(_week).add(const Duration(days: 6)))}',
          ),
          if (_actualWeek < 1 || _actualWeek > _timetable.semester.totalWeeks)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('今天不在本学期内；回到本周将显示最近的教学周。'),
            ),
          const SizedBox(height: 16),
          if (_timetable.inWeek(_week).isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: SurfaceCard(child: Text('本周暂无课程，可添加课程或查看其他教学周。')),
            ),
          _grid(),
        ],
        const SizedBox(height: 24),
        const Text(
          '本学期课程',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          const SurfaceCard(child: Text('还没有录入课程，点击“添加课程”开始。')),
        for (final course in courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: courseColors[course.colorIndex],
              child: ListTile(
                title: Text(course.name),
                subtitle: Text(
                  '${course.teacher.isEmpty ? '教师未填写' : course.teacher}\n${course.schedules.length} 个上课安排',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onEdit(course),
              ),
            ),
          ),
      ],
    );
  }
}
