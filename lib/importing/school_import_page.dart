import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../semesters/semester_editor.dart';
import '../ui/design.dart';
import 'import_page.dart';
import 'import_widgets.dart';
import 'school_file.dart';
import 'school_xlsx.dart';

class SchoolImportPage extends StatefulWidget {
  const SchoolImportPage({
    required this.planner,
    this.pickFile = pickSchoolFile,
    super.key,
  });
  final SemesterPlanner planner;
  final Future<SchoolFile?> Function() pickFile;
  @override
  State<SchoolImportPage> createState() => _SchoolImportPageState();
}

class _SchoolImportPageState extends State<SchoolImportPage> {
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await widget.pickFile();
      if (!mounted || file == null) return;
      if (!file.name.toLowerCase().endsWith('.xlsx')) {
        throw const InputProblem('请选择学校导出的 .xlsx 文件。');
      }
      final parsed = await compute(parseSchoolTimetable, file.bytes);
      if (!mounted) return;
      var state = await widget.planner.load();
      if (!mounted) return;
      if (state.semesters.isEmpty) {
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => SemesterEditor(
              planner: widget.planner,
              campusNow: state.campusTime(DateTime.now().toUtc()),
              campusTimeZone: state.campusTimeZone,
              currentSemesterId: state.currentSemesterId,
              suggestedPeriods: parsed.periods,
              suggestedName: parsed.termName,
            ),
          ),
        );
        if (!mounted || saved != true) return;
        state = await widget.planner.load();
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ImportPreviewPage(
            planner: widget.planner,
            sourceName: '$schoolName · ${file.name}',
            initialSemesterId: state.currentSemesterId,
            schoolPeriods: parsed.periods,
            loadCandidates: () async => parsed.candidates,
          ),
        ),
      );
    } on InputProblem catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PlatformException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == 'file_too_large'
              ? '文件太大了，请选择 10 MB 以内的学校课表。'
              : '没能打开这个文件，请重新选择一次。',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = '没能打开这个文件，请重新选择一次。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('导入学校课表')),
    body: SafeArea(
      child: PageContent(
        children: [
          const PageHeading('把课表装进口袋', '选择学校导出的文件，核对后再加入课表。', art: 'book'),
          SurfaceCard(
            color: lavenderSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  schoolName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  '支持学校导出的 xskb.xlsx 课表，无需修改模板。',
                  style: TextStyle(height: 1.7),
                ),
                const SizedBox(height: 10),
                const Text(
                  '先选择目标学期，再核对课程和上课安排。重复安排会自动跳过，时间重叠会另行提示。',
                  style: TextStyle(fontSize: 13, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ImportNotice(
            '只在本机读取',
            message: '文件不会上传。没有排课时间的备注课程会列为待核对，可补齐或跳过。',
          ),
          const SizedBox(height: 24),
          if (_busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            const Text('正在读取学校课表…', semanticsLabel: '正在读取学校课表'),
            const SizedBox(height: 16),
          ],
          if (_error != null) ...[
            ImportNotice(_error!, error: true),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            key: const ValueKey('pick-school-file'),
            onPressed: _busy ? null : _pick,
            icon: const DesignIcon('folder', color: Colors.white),
            label: const Text('选择 XLSX 课表'),
          ),
        ],
      ),
    ),
  );
}
