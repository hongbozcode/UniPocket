import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../semesters/model.dart';
import '../ui/course_palette.dart';
import '../ui/design.dart';
import 'model.dart';
import 'week_grid.dart';

class OccurrenceCard extends StatelessWidget {
  const OccurrenceCard(
    this.occurrence, {
    required this.onTap,
    this.featured = false,
    this.status,
    super.key,
  });
  final ClassOccurrence occurrence;
  final VoidCallback onTap;
  final bool featured;
  final String? status;

  @override
  Widget build(BuildContext context) => Material(
    color: featured ? courseTint(occurrence.course.colorIndex) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: featured
          ? BorderSide.none
          : const BorderSide(color: Color(0xffe9edf5)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, box) {
            final showArt =
                featured &&
                box.maxWidth > 250 &&
                MediaQuery.textScalerOf(context).scale(14) < 22;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!featured)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: courseTint(occurrence.course.colorIndex),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DesignIcon(
                        'book',
                        color: courseAccent(occurrence.course.colorIndex),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                          ],
                          Expanded(
                            child: Text(
                              occurrence.course.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (occurrence.isRescheduled || occurrence.isIndependent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            occurrence.isIndependent
                                ? '独立补课'
                                : '已调课 · 原课次 ${dateText(occurrence.originalDate)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DesignIcon(
                            'clock',
                            size: 15,
                            color: Color(0xff73819a),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${PeriodTime.format(occurrence.startMinutes)}–${PeriodTime.format(occurrence.endMinutes)}${featured ? '' : ' · ${occurrence.location.isEmpty ? '地点未填写' : occurrence.location}'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff52617a),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (featured) ...[
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DesignIcon(
                              'location',
                              size: 15,
                              color: Color(0xff73819a),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                occurrence.location.isEmpty
                                    ? '地点未填写'
                                    : occurrence.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff52617a),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (showArt)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SvgPicture.asset(
                      'docs/design/resources/illustrations/book.svg',
                      width: 64,
                      height: 64,
                      excludeFromSemantics: true,
                    ),
                  ),
                if (!featured)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xff93a0b5),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class TodayCourses extends StatelessWidget {
  const TodayCourses({
    required this.occurrences,
    required this.campusNow,
    required this.onEdit,
    this.onOccurrence,
    this.emptyText = '今天没有课程，可以从容安排时间。',
    super.key,
  });
  final List<ClassOccurrence> occurrences;
  final DateTime campusNow;
  final ValueChanged<Course> onEdit;
  final ValueChanged<ClassOccurrence>? onOccurrence;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final minutes = campusNow.hour * 60 + campusNow.minute;
    final next = occurrences.where((o) => o.endMinutes > minutes).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (occurrences.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              emptyText,
              style: const TextStyle(color: Color(0xff73819a), fontSize: 13),
            ),
          ),
        for (final occurrence in occurrences)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OccurrenceCard(
              occurrence,
              onTap: () => onOccurrence != null
                  ? onOccurrence!(occurrence)
                  : onEdit(occurrence.course),
              featured: identical(occurrence, next),
              status: identical(occurrence, next)
                  ? (occurrence.startMinutes <= minutes ? '进行中' : '下一节')
                  : null,
            ),
          ),
      ],
    );
  }
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({
    required this.state,
    required this.campusNow,
    required this.onAdd,
    required this.onEdit,
    this.onOccurrence,
    required this.onManage,
    this.onTasks,
    this.onEvents,
    super.key,
  });
  final PlannerState state;
  final DateTime campusNow;
  final VoidCallback onAdd;
  final ValueChanged<Course> onEdit;
  final ValueChanged<ClassOccurrence>? onOccurrence;
  final VoidCallback onManage;
  final VoidCallback? onTasks;
  final VoidCallback? onEvents;
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late int _week = _currentWeek;
  var _today = false;
  Timetable get _timetable => widget.state.timetable!;
  int get _actualWeek => _timetable.weekOf(widget.campusNow);
  int get _currentWeek => _actualWeek.clamp(
    _timetable.firstVisibleWeek,
    _timetable.lastVisibleWeek,
  );

  @override
  void didUpdateWidget(TimetablePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentSemesterId != widget.state.currentSemesterId) {
      _week = _currentWeek;
    }
    _week = _week.clamp(
      _timetable.firstVisibleWeek,
      _timetable.lastVisibleWeek,
    );
  }

  Widget _modeSwitch() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xffeaf0fa),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final mode in [('周课表', false), ('今日', true)])
          Semantics(
            selected: _today == mode.$2,
            button: true,
            child: Material(
              color: _today == mode.$2
                  ? const Color(0xffd6c1fc)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => setState(() => _today = mode.$2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    mode.$1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _today == mode.$2
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _semester() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: widget.onManage,
        child: Text(
          _timetable.semester.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        '校园时间  ${widget.state.campusTimeZone}',
        style: const TextStyle(fontSize: 11, color: Color(0xff73819a)),
      ),
    ],
  );

  Widget _weeks() {
    final previous = RoundDesignButton(
      icon: 'left',
      label: '上一周',
      onPressed: _week > _timetable.firstVisibleWeek
          ? () => setState(() => _week--)
          : null,
    );
    final next = RoundDesignButton(
      icon: 'right',
      label: '下一周',
      onPressed: _week < _timetable.lastVisibleWeek
          ? () => setState(() => _week++)
          : null,
    );
    final label = Text(
      _week >= 1 && _week <= _timetable.semester.totalWeeks
          ? '第 $_week 周'
          : '${dateText(_timetable.mondayOf(_week))} · 学期外',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
    final back = OutlinedButton(
      onPressed: () => setState(() => _week = _currentWeek),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: Color(0xff9bb2ff)),
      ),
      child: const Text('回到本周', style: TextStyle(fontSize: 11)),
    );
    return MediaQuery.textScalerOf(context).scale(12) > 17 ||
            _week < 1 ||
            _week > _timetable.semester.totalWeeks
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [previous, label, next, back],
          )
        : Row(
            children: [
              previous,
              const SizedBox(width: 10),
              label,
              const SizedBox(width: 4),
              next,
              const Spacer(),
              back,
            ],
          );
  }

  @override
  Widget build(BuildContext context) => PageContent(
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              '课表',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          if (widget.onTasks != null) ...[
            RoundDesignButton(
              icon: 'task',
              label: '学习任务',
              onPressed: widget.onTasks,
            ),
            const SizedBox(width: 8),
          ],
          if (widget.onEvents != null) ...[
            RoundDesignButton(
              icon: 'calendar',
              label: '倒计时',
              onPressed: widget.onEvents,
            ),
            const SizedBox(width: 8),
          ],
          RoundDesignButton(
            icon: 'plus',
            label: '添加课程',
            onPressed: widget.onAdd,
            primary: true,
          ),
        ],
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, box) =>
            box.maxWidth > 330 &&
                MediaQuery.textScalerOf(context).scale(12) < 17
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _semester()),
                  const SizedBox(width: 10),
                  _modeSwitch(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _semester(),
                  const SizedBox(height: 12),
                  _modeSwitch(),
                ],
              ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_today) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(
                  '${dateText(widget.campusNow)} · ${weekdayNames[widget.campusNow.weekday - 1]}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff73819a),
                  ),
                ),
              ),
              TodayCourses(
                occurrences: _timetable.onDate(widget.campusNow),
                campusNow: widget.campusNow,
                onEdit: widget.onEdit,
                onOccurrence: widget.onOccurrence,
              ),
            ] else ...[
              _weeks(),
              if (_actualWeek < 1 ||
                  _actualWeek > _timetable.semester.totalWeeks)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '今天不在常规教学周内；回到本周将显示最近的可查看周，调课仍按实际日期显示。',
                    style: TextStyle(fontSize: 12, color: Color(0xff73819a)),
                  ),
                ),
              const SizedBox(height: 12),
              if (_timetable.inWeek(_week).isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '本周暂无课程，可添加课程或查看其他教学周。',
                    style: TextStyle(fontSize: 12, color: Color(0xff73819a)),
                  ),
                ),
              WeekGrid(
                timetable: _timetable,
                week: _week,
                today: widget.campusNow,
                onEdit: widget.onEdit,
                onOccurrence: widget.onOccurrence,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final index
                      in _timetable.courses.map((c) => c.colorIndex).toSet())
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: courseTint(index),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Text(
                    '课程颜色区分 · 点击课程查看详情',
                    style: TextStyle(fontSize: 10, color: Color(0xff73819a)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: const Border(),
        collapsedShape: const Border(),
        title: const Text(
          '本学期课程',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        children: [
          if (_timetable.courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('还没有录入课程，点击右上角添加。'),
            ),
          for (final course in _timetable.courses)
            ListTile(
              leading: Container(
                width: 12,
                height: 32,
                decoration: BoxDecoration(
                  color: courseTint(course.colorIndex),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              title: Text(course.name),
              subtitle: Text(
                '${course.teacher.isEmpty ? '教师未填写' : course.teacher} · ${course.schedules.length} 个上课安排',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => widget.onEdit(course),
            ),
        ],
      ),
      TextButton(onPressed: widget.onManage, child: const Text('切换／管理学期')),
    ],
  );
}
