import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../semesters/model.dart';
import '../timetable/model.dart';
import 'model.dart';

const schoolName = '河北科技师范学院';
const maxSchoolFileBytes = 10 * 1024 * 1024;

class SchoolTimetable {
  SchoolTimetable(this.termName, this.periods, this.candidates);
  final String termName;
  final List<PeriodTime> periods;
  final List<ImportCandidate> candidates;
}

/// Adapter for the supplied xskb export, not a general school recognizer.
/// No student identity or invented course number enters the planner.
SchoolTimetable parseSchoolTimetable(Uint8List bytes) {
  try {
    return _parse(bytes);
  } on InputProblem {
    rethrow;
  } catch (_) {
    throw const InputProblem('这份文件没能读出来，请选择学校导出的 XLSX 课表。');
  }
}

SchoolTimetable _parse(Uint8List bytes) {
  if (bytes.length > maxSchoolFileBytes) {
    throw const InputProblem('文件太大了，请选择 10 MB 以内的学校课表。');
  }
  final archive = ZipDecoder().decodeBytes(bytes, verify: true);
  if (archive.files.length > 200 ||
      archive.files.fold<int>(0, (sum, f) => sum + f.size) > 30 * 1024 * 1024) {
    throw const InputProblem('文件内容过大，请重新导出课表后再试。');
  }
  XmlDocument read(String path) {
    final file = archive.findFile(path);
    if (file == null || !file.isFile || file.size > 5 * 1024 * 1024) {
      throw const InputProblem('文件结构不完整，请重新导出学校课表。');
    }
    return XmlDocument.parse(utf8.decode(file.content as List<int>));
  }

  final workbook = read('xl/workbook.xml');
  final sheet = workbook
      .elements('sheet')
      .where((s) => s.getAttribute('name') == 'xskb')
      .firstOrNull;
  if (sheet == null) throw const InputProblem('没有找到 xskb 工作表，请选择学校原始导出文件。');
  final relation = read('xl/_rels/workbook.xml.rels')
      .elements('Relationship')
      .where((r) => r.getAttribute('Id') == sheet.getAttribute('r:id'))
      .firstOrNull;
  final target = relation?.getAttribute('Target');
  if (target == null || target.contains('..') || target.contains('://')) {
    throw const InputProblem('工作表位置无法识别，请重新导出课表。');
  }
  final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
  final xml = read(path);
  final strings = archive.findFile('xl/sharedStrings.xml') == null
      ? <String>[]
      : read('xl/sharedStrings.xml')
            .elements('si')
            .map((si) => si.elements('t').map((t) => t.innerText).join())
            .toList();
  final cells = <String, String>{};
  for (final c in xml.elements('c')) {
    final ref = c.getAttribute('r');
    if (ref == null) continue;
    final value = c.child('v')?.innerText ?? '';
    if (c.child('f') != null) {
      throw InputProblem('$ref 含公式，请选择学校直接导出的课表。');
    }
    cells[ref] = switch (c.getAttribute('t')) {
      's' => strings[int.parse(value)],
      'inlineStr' => c.elements('t').map((t) => t.innerText).join(),
      _ => value,
    };
  }
  // A merged course block belongs to each covered period, then coalesces below.
  for (final merge in xml.elements('mergeCell')) {
    final refs = merge.getAttribute('ref')!.split(':');
    final a = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(refs.first)!;
    final b = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(refs.last)!;
    final first = int.parse(a[2]!);
    final last = int.parse(b[2]!);
    if (a[1] == b[1] && 'EFGHIJK'.contains(a[1]!) && first >= 6 && last <= 17) {
      for (var row = first + 1; row <= last; row++) {
        cells['${a[1]}$row'] = cells[refs.first] ?? '';
      }
    } else if (first >= 6 && first <= 17 && a[1] != b[1]) {
      throw const InputProblem('发现跨星期合并的课程格，请核对学校导出格式。');
    }
  }
  final title = cells['C2'] ?? '';
  if (!RegExp('^$schoolName\\d{4}年[春秋]季学期课表\$').hasMatch(title) ||
      cells['B5'] != '节次' ||
      cells['D5'] != '时间') {
    throw const InputProblem('目前支持河北科技师范学院的 xskb 课表，请核对文件。');
  }
  const days = ['一', '二', '三', '四', '五', '六', '日'];
  for (var day = 0; day < 7; day++) {
    if (cells['${'EFGHIJK'[day]}5'] != '星期${days[day]}') {
      throw const InputProblem('星期表头与学校样例不同，请核对导出文件。');
    }
  }
  final periods = <PeriodTime>[];
  final groups = <String, _CourseBlock>{};
  var errorIndex = 0;
  void error(String ref, String raw, String message) {
    final key = 'error-${errorIndex++}';
    groups[key] = _CourseBlock(key, '待核对课程', '', [ref])
      ..errors.add('$message\n原文：$raw');
  }

  for (var row = 6; row <= 17; row++) {
    final period = row - 5;
    if (double.tryParse(cells['C$row'] ?? '') != period) {
      throw InputProblem('C$row 的节次无法识别，请重新导出课表。');
    }
    final times = RegExp(r'^(\d{2}):(\d{2})\s+(\d{2}):(\d{2})$')
        .firstMatch((cells['D$row'] ?? '').trim());
    if (times == null) throw InputProblem('D$row 的上课时间无法识别。');
    final start = int.parse(times[1]!) * 60 + int.parse(times[2]!);
    final end = int.parse(times[3]!) * 60 + int.parse(times[4]!);
    if (start >= end ||
        end >= 1440 ||
        (periods.isNotEmpty && start < periods.last.endMinutes)) {
      throw InputProblem('D$row 的上课时间顺序不正确。');
    }
    periods.add(PeriodTime(start, end));
    for (var day = 1; day <= 7; day++) {
      final ref = '${'EFGHIJK'[day - 1]}$row';
      final raw = (cells[ref] ?? '').trim();
      if (raw.isEmpty) continue;
      final lines = raw
          .split(RegExp(r'[\r\n]+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      for (var line = 0; line < lines.length; line += 2) {
        if (line + 1 >= lines.length) {
          error(ref, lines[line], '缺少教师、教学周或地点，请补齐或跳过。');
          continue;
        }
        final name = lines[line].trim();
        for (final detail in lines[line + 1].split(RegExp('[;；]'))) {
          final match = RegExp(r'^\s*([^\[\]]+)\[([^\]]+)周\]\s*(.*?)\s*$')
              .firstMatch(detail);
          if (match == null) {
            error(ref, '$name\n$detail', '教师和教学周没能识别，请核对。');
            continue;
          }
          final teacher = match[1]!.trim();
          final key = jsonEncode([name, teacher]);
          final group = groups.putIfAbsent(
            key,
            () => _CourseBlock(key, name, teacher, []),
          );
          group.refs.add(ref);
          try {
            group.schedules.add(
              ScheduleDraft(
                weekday: day,
                startPeriod: period,
                endPeriod: period,
                location: match[3]!.trim(),
                weeks: _weeks(match[2]!),
              ),
            );
          } on FormatException {
            group.errors.add('$ref：教学周“${match[2]}”无法识别，请核对。');
          }
        }
      }
    }
  }
  final remarks = <String>{
    for (final column in 'EFGHIJK'.split(''))
      if ((cells['${column}18'] ?? '').trim().isNotEmpty) cells['${column}18']!,
  };
  for (final raw in remarks) {
    for (final note
        in raw.split(RegExp('[;；]')).where((s) => s.trim().isNotEmpty)) {
      final match = RegExp(r'^理论课程[:：](.+?)【(.*?)】$').firstMatch(note.trim());
      if (match == null) {
        error('E18:K18', note, '备注没有完整的上课安排，请核对。');
      } else {
        final key = 'remark-${errorIndex++}';
        groups[key] = _CourseBlock(key, match[1]!, match[2]!, ['E18:K18'])
          ..errors.add('备注中没有上课时间，请补齐安排或跳过。原文：$note');
      }
    }
  }
  return SchoolTimetable(title, List.unmodifiable(periods), [
    for (final (index, group) in groups.values.indexed)
      ImportCandidate(
        id: group.key,
        sourceLabel: 'xskb!${group.refs.toSet().join('、')}',
        name: group.name,
        teacher: group.teacher,
        colorIndex: index % 6,
        schoolIdentity: true,
        sourcePeriods: List.unmodifiable(periods),
        schedules: _coalesce(group.schedules),
        errors: group.errors,
      ),
  ]);
}

Set<int> _weeks(String text) {
  final result = <int>{};
  for (final part in text.split(RegExp('[,，、]'))) {
    final m = RegExp(r'^(\d+)(?:-(\d+))?(?:[（(](单|双)[）)])?$')
        .firstMatch(part.trim());
    if (m == null) throw const FormatException();
    final start = int.parse(m[1]!);
    final end = int.parse(m[2] ?? m[1]!);
    if (start < 1 || end < start || end > 60) throw const FormatException();
    for (var week = start; week <= end; week++) {
      if (m[3] == null || (m[3] == '单' ? week.isOdd : week.isEven)) {
        result.add(week);
      }
    }
  }
  if (result.isEmpty) throw const FormatException();
  return result;
}

List<ScheduleDraft> _coalesce(List<ScheduleDraft> input) {
  // Union the file's semicolon-separated weeks for a single period first.
  final periods = <String, ScheduleDraft>{};
  for (final s in input) {
    final key = jsonEncode([s.weekday, s.startPeriod, s.location]);
    periods[key] = ScheduleDraft(
      weekday: s.weekday,
      startPeriod: s.startPeriod,
      endPeriod: s.endPeriod,
      location: s.location,
      weeks: {...?periods[key]?.weeks, ...s.weeks},
    );
  }
  final sorted = periods.values.toList()
    ..sort(
      (a, b) => a.weekday != b.weekday
          ? a.weekday.compareTo(b.weekday)
          : a.startPeriod.compareTo(b.startPeriod),
    );
  final result = <ScheduleDraft>[];
  for (final s in sorted) {
    final previous = result.lastOrNull;
    if (previous != null &&
        previous.weekday == s.weekday &&
        previous.endPeriod + 1 == s.startPeriod &&
        previous.location == s.location &&
        previous.weeks.length == s.weeks.length &&
        previous.weeks.containsAll(s.weeks)) {
      result[result.length - 1] = ScheduleDraft(
        weekday: s.weekday,
        startPeriod: previous.startPeriod,
        endPeriod: s.endPeriod,
        location: s.location,
        weeks: s.weeks,
      );
    } else {
      result.add(s);
    }
  }
  return result;
}

class _CourseBlock {
  _CourseBlock(this.key, this.name, this.teacher, this.refs);
  final String key;
  final String name;
  final String teacher;
  final List<String> refs;
  final schedules = <ScheduleDraft>[];
  final errors = <String>[];
}

extension _LocalXml on XmlNode {
  Iterable<XmlElement> elements(String name) =>
      descendants.whereType<XmlElement>().where((e) => e.name.local == name);
  XmlElement? child(String name) => children
      .whereType<XmlElement>()
      .where((e) => e.name.local == name)
      .firstOrNull;
}
