import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../ui/design.dart';
import 'model.dart';
import 'planner.dart';
import 'semester_editor.dart';

class SemesterManagement extends StatefulWidget {
  const SemesterManagement({required this.planner, super.key});
  final SemesterPlanner planner;
  @override
  State<SemesterManagement> createState() => _SemesterManagementState();
}

class _SemesterManagementState extends State<SemesterManagement> {
  PlannerState? _state;
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
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
      if (mounted) setState(() => _error = '读取学期失败，请重试。');
    }
  }

  Future<void> _edit([Semester? semester]) async {
    final state = _state!;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SemesterEditor(
          planner: widget.planner,
          campusNow: state.campusTime(DateTime.now().toUtc()),
          campusTimeZone: state.campusTimeZone,
          currentSemesterId: state.currentSemesterId,
          semester: semester,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _activate(Semester semester) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.planner.setCurrentSemester(semester.id);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = '切换失败，当前学期保持不变，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('学期管理')),
    body: SafeArea(
      top: false,
      child: _state == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : PageContent(
              children: [
                const PageHeading('保留每一段学习时光', '创建新学期或切换当前学期，历史配置会一直保留。'),
                if (_error != null) ...[
                  ProblemBanner(_error!),
                  TextButton(onPressed: _load, child: const Text('重新读取')),
                ],
                if (_state != null) ...[
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('新增学期'),
                  ),
                  const SizedBox(height: 20),
                  if (_state!.semesters.isEmpty)
                    const SurfaceCard(child: Text('还没有学期，先创建一个吧。')),
                  for (final semester in _state!.semesters)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SurfaceCard(
                        color: semester.id == _state!.currentSemesterId
                            ? lavenderSoft
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              semester.id == _state!.currentSemesterId
                                  ? '当前学期'
                                  : '其他学期 · 已保留',
                              style: const TextStyle(color: primaryBlue),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              semester.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${dateText(semester.firstMonday)} 起 · 共 ${semester.totalWeeks} 周',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _edit(semester),
                                  child: const Text('编辑配置'),
                                ),
                                if (semester.id != _state!.currentSemesterId)
                                  FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _activate(semester),
                                    child: const Text('设为当前学期'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    ),
  );
}

class CampusTimeZonePicker extends StatefulWidget {
  const CampusTimeZonePicker({required this.currentZone, super.key});
  final String currentZone;
  @override
  State<CampusTimeZonePicker> createState() => _CampusTimeZonePickerState();
}

class _CampusTimeZonePickerState extends State<CampusTimeZonePicker> {
  static const _common = {
    'Asia/Shanghai': '中国 · 上海',
    'Asia/Hong_Kong': '中国 · 香港',
    'Asia/Tokyo': '日本 · 东京',
    'Asia/Singapore': '新加坡',
    'Europe/London': '英国 · 伦敦',
    'America/New_York': '美国 · 纽约',
    'America/Los_Angeles': '美国 · 洛杉矶',
    'Australia/Sydney': '澳大利亚 · 悉尼',
    'UTC': '协调世界时',
  };
  late final List<String> _zones = [
    ..._common.keys.where(tz.timeZoneDatabase.locations.containsKey),
    ...(tz.timeZoneDatabase.locations.keys
        .where((zone) => !_common.containsKey(zone))
        .toList()
      ..sort()),
  ];
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final zones = _zones
        .where(
          (zone) => '$zone ${_common[zone] ?? ''}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('校园时区')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('校园日期和时间始终按此时区解释，不会随手机时区自动改变。此设置对所有学期生效。'),
                      const SizedBox(height: 16),
                      TextField(
                        key: const ValueKey('timezone-search'),
                        decoration: const InputDecoration(
                          labelText: '搜索时区或城市',
                          hintText: '例如：上海、Asia/Tokyo',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: zones.isEmpty
                      ? const Center(child: Text('未找到时区，请换一个名称搜索。'))
                      : ListView.builder(
                          itemCount: zones.length,
                          itemBuilder: (context, index) {
                            final zone = zones[index];
                            return ListTile(
                              title: Text(zone),
                              subtitle: _common[zone] == null
                                  ? null
                                  : Text(_common[zone]!),
                              trailing: zone == widget.currentZone
                                  ? const Icon(
                                      Icons.check,
                                      semanticLabel: '当前时区',
                                    )
                                  : null,
                              onTap: () => Navigator.pop(context, zone),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
