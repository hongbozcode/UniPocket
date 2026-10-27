import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'documents.dart';

class BackupCard extends StatefulWidget {
  const BackupCard({
    required this.planner,
    required this.onRestored,
    this.documents = const BackupDocuments(),
    this.onBusyChanged,
    super.key,
  });
  final SemesterPlanner planner;
  final Future<void> Function() onRestored;
  final BackupDocuments documents;
  final ValueChanged<bool>? onBusyChanged;

  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  String? _progress;
  String? _result;
  bool _error = false;
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _run(bool restore) async {
    if (_progress != null) return;
    widget.onBusyChanged?.call(true);
    setState(() {
      _progress = restore ? '正在读取备份文件…' : '正在整理完整备份…';
      _result = null;
      _error = false;
    });
    try {
      // Let the progress frame render before any work or platform dialog.
      await Future<void>.delayed(Duration.zero);
      if (restore) {
        final document = await widget.documents.pick();
        if (document == null || !mounted) return;
        setState(() => _progress = '正在校验完整性与数据关系…');
        final preview = await widget.planner.previewBackup(document.bytes);
        if (!mounted) return;
        setState(() => _progress = '等待确认覆盖');
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('覆盖本机全部数据？'),
            scrollable: true,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(document.name),
                const SizedBox(height: 12),
                Text(
                  '备份时间：${preview.createdAt.toLocal().toString().split('.').first}',
                ),
                const SizedBox(height: 12),
                Text(preview.summary),
                const SizedBox(height: 12),
                const Text('校验已通过。确认后将替换当前全部学期、课程、任务、事件、工具列表、抽取轮次、收藏和设置，无法撤销。'),
                const SizedBox(height: 12),
                const Text('仅重建未来提醒，不补发过去提醒；通知权限以当前手机状态为准。'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                key: const ValueKey('restore-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认覆盖恢复'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        setState(() => _progress = '正在恢复数据并重建未来提醒…');
        await preview.restore(confirmOverwrite: true);
        await widget.onRestored();
        if (mounted) {
          setState(
            () => _result =
                '完整恢复成功。${widget.planner.reminderAvailability}。过去提醒不会补发。',
          );
        }
      } else {
        final bytes = await widget.planner.exportBackup();
        if (!mounted) return;
        setState(() => _progress = '请选择备份保存位置…');
        final date = DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .split('.')
            .first;
        final saved = await widget.documents.save(
          bytes,
          'UniPocket-$date.unipocket',
        );
        if (saved && mounted) setState(() => _result = '完整备份已导出到所选位置');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = true;
          _result = error is FormatException
              ? error.message
              : error is PlatformException
              ? '文件操作失败，请检查文件或保存位置后重试。'
              : restore
              ? '恢复失败，当前数据未改变，请重新选择完整备份。'
              : '导出失败，请重试。';
        });
      }
    } finally {
      widget.onBusyChanged?.call(false);
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _progress == null,
    child: Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SvgPicture.asset(
                  'docs/design/resources/illustrations/folder.svg',
                  width: 52,
                  height: 52,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '学习数据保存在本机',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          ListTile(
            key: const ValueKey('export-backup'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: const DesignIcon('export'),
            title: const Text('导出完整备份'),
            subtitle: const Text('保存到你选择的位置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _supported && _progress == null ? () => _run(false) : null,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          ListTile(
            key: const ValueKey('restore-backup'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: const DesignIcon('restore', color: Color(0xff8755e9)),
            title: const Text('从文件恢复'),
            subtitle: const Text(
              '恢复前校验，确认后覆盖本机数据',
              style: TextStyle(color: Color(0xffb32643)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _supported && _progress == null ? () => _run(true) : null,
          ),
          if (_progress != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(_progress!),
                  ],
                ),
              ),
            ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Semantics(
                liveRegion: true,
                child: _error ? ProblemBanner(_result!) : Text(_result!),
              ),
            ),
          if (!_supported)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('请在 Android 应用中使用系统文件选择器导出和恢复备份。'),
            ),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text('网页数据保存在当前浏览器的此站点中。清除站点数据或结束隐私浏览可能会丢失记录。'),
            ),
        ],
      ),
    ),
  );
}
