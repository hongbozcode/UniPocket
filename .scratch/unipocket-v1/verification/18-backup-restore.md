# 任务 18：完整本地备份与覆盖恢复

日期：2026-10-27。分支：`codex/dev18`。实施前基线：`6501f982f0fc02fb6db424fc5f42520b5a3a3c60`。

实现：`0fc7265`；审查修复：`8aeb354`。任务文件与本记录随同一分支交付，Status 保留 triage 含义。

## 实现与文件边界

- `SemesterPlanner.exportBackup()` 导出全部 14 张应用表的完整一致快照，保留记录身份、关联、提醒配置、同名成员和重复签项、点名／抽签轮次、收藏与最近使用。应用设置包含当前学期与校园时区；系统权限和原生闹钟缓存不写入备份。没有合并、自动备份或上传。
- 备份格式为版本 1 的 UTF-8 JSON，扩展名 `.unipocket`，包含标识、数据 schema、导出时间和全部表。当前只接受 schema 14，缺表／字段、错误类型、非法日期、未知时区、断开的关联、非法工具成员／轮次等明确拒绝。文件上限 50 MB；超限导出明确失败，不生成无法恢复的备份。没有新增依赖或数据库 schema 变更。
- 解析与编码通过 Flutter `compute` 执行。数据库校验在一个必定回滚的事务中试写并检查外键、领域规则及轮次；事务内数据不对外可见，校验不会提交或改变原记录。校验通过后才显示包含文件名、时间、摘要与覆盖影响的确认对话框。
- 确认后的替换重新运行同样的完整校验和全部写入，单个 SQLite 事务提交；中途失败完整回滚。SQL 表／字段标识符仅取自编译的 Drift schema，文件值通过参数写入，不执行备份提供的 SQL。
- 恢复开始时同步增加恢复代次，旧点名／抽签临时结果在进入数据库事务前失效，避免旧完成请求排队到恢复后污染备份轮次。成功后从已提交数据重新读取当前手机权限并重建三个独立提醒 scope；不补发过去提醒，通知失败与数据恢复结果分别反馈。
- Android `ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT` 只访问用户选中的文档，不请求全盘存储权限。读取和写入在线程中进行，有取消、失败、重复操作和 Activity 销毁处理。备份进行中暂时阻止设置页操作和主导航切换。
- Web 构建兼容；系统文件导出与恢复入口仅开放 Android，Web 保留浏览器站点数据风险说明。

## 视觉与操作

已实际读取[设置效果图](../../../docs/design/resources/core-pages/04-设置.png)、[历史设置截图](../../../docs/design/resources/screenshots/settings.png)和[视觉规范](../../../docs/product/design.md)。复用浅蓝白底、白色圆角分组、文件夹贴纸、主蓝导出图标、淡紫恢复图标与红色覆盖说明。进度、校验错误、覆盖确认及成功反馈随本任务补齐，没有重建设计手册或复杂动效。

正常 Flutter binding 的实际截图：[设置页](evidence/18-android-settings.png)、[数据与备份分组](evidence/18-android-settings-backup.png)、[校验后的覆盖确认](evidence/18-android-manual-confirm.png)。Android 系统操作：[保存位置](evidence/18-android-system-save.png)、[选择刚导出的备份](evidence/18-android-system-pick.png)。

界面测试覆盖 320／393 宽、双倍文字、长文件名、取消选择、错误后重选、取消覆盖、确认成功与导出成功；保留安全区域并可滚动到末项。旧通知测试在双倍文字下改为先滚动到系统设置入口，再断言通知状态，避免依赖屏幕首次构建了所有卡片。

## 验证

| 检查 | 结果与本地日志 |
| --- | --- |
| TDD 首轮 | `build/task18-red-initial.log` 缺少导出／预览 API 而失败；实现后干净文件数据库恢复与轮次续抽通过。 |
| 完整领域与失败完整性 | `test/backup_restore_test.dart` 使用真实 SQLite，覆盖手动创建学期／历史学期、课程安排、调课、停课、独立补课、关联／完成／历史任务、事件、工具列表和轮次、收藏及最近使用；12 类损坏文件、取消及实际 SQLite trigger 中途失败不改变原完整快照。 |
| 审查竞态回归 | `build/task18-red-concurrent-draw.log` 复现旧完成请求在恢复开始后仍成功；`8aeb354` 修复后，点名和抽签并发旧完成均拒绝，完整备份数据不变。 |
| 定向回归 | `build/task18-review-fix-tests.log`，11 项通过（数据库、备份界面、旧通知界面）。 |
| 完整回归 | `build/task18-full-tests-final2.log`，172 项通过。首次完整回归发现两个旧通知界面的滚动假设失效，修正后全量重跑通过。 |
| 静态分析 | `build/task18-analyze-final2.log`，`No issues found!`。 |
| Android 主入口构建 | `build/task18-android-build-final.log`，`flutter build apk --debug --no-pub --target=lib/main.dart` 成功。 |
| Web 主入口构建 | `build/task18-web-build-final.log`，`flutter build web --no-pub --no-web-resources-cdn --target=lib/main.dart` 成功。 |
| 两轴审查 | `6501f98...0fc7265` 初审后，补充并发回归并修复；对 `8aeb354` 复审后 Standards 0 项，Spec 0 项未解决问题。 |
| 差异 | `git diff --check` 通过。 |

测试日志位于忽略的 `build/`，截图和结构化验收摘要随记录提交。日志中的 Drift 多数据库实例提示来自互相独立的源／目标测试数据库；SVG filter 和工具链已知构建提示保留，不宣称无警告构建。

## Android 实际文件、新进程与干净安装

### 系统文件与轮次

使用已有 Android 16 / API 36 模拟器 `emulator-5554`，专用数据库 `unipocket_task18_20261027_delivery2`；没有清除用户普通数据库或任务 17 数据。通过应用完整导出并在系统 Downloads 保存，再通过系统文件选择器选回，在空数据库确认恢复。导出文件大小 6236 字节，源数据来自手动领域 fixture，完全不依赖学校解析器。

```powershell
flutter drive --no-pub --keep-app-running -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/backup_restore_flow_test.dart --dart-define=ACCEPTANCE_DATABASE=unipocket_task18_20261027_delivery2
```

创建日志 `build/task18-android-create-final.log`，进程 PID 8058，全部表与源快照一致。新进程日志 `build/task18-android-reopen.log`，PID 8331，同命令加 `--dart-define=ACCEPTANCE_RESTORE=true`；验证恢复前点名／抽签各已抽 1 项，重启后各继续抽成 2 项，关联、独立补课及工具收藏仍正确。两个阶段都通过，始终使用 `--keep-app-running` 保留数据库。

最早一轮因集成测试对持续进度条调用 `pumpAndSettle` 而停在确认前，修正测试等待后使用新数据库完整重跑。自动截图绑定曾保留旧渲染帧，未将这些画面作为视觉证据；本记录使用正常应用与系统截图。

人工复核入口使用正常 Flutter binding，同样不写入正式数据库，也不自动填充样例：

```powershell
flutter run --no-pub --no-resident -d emulator-5554 --target=tool/backup_preview.dart
```

### 真实干净安装恢复

复用已安装系统镜像，在忽略的 `build/task18-avd/` 创建专用 `task18-clean` AVD（独立空数据磁盘，端口 5556，隐藏运行）。未安装或升级 SDK，也未修改原有 AVD。首次检查应用包不存在，安装正常 Flutter 包后显示[空数据首页](evidence/18-clean-install-empty.png)，当前校园时区为 Asia/Shanghai，系统通知默认关闭。

把旧设备通过系统选择器导出的文件迁移到新设备 Downloads，从正式设置页选择文件并[确认覆盖](evidence/18-clean-install-confirm.png)。恢复成功后校园时区变为备份中的 Asia/Tokyo，但仍显示[当前设备通知关闭](evidence/18-clean-install-success-blocked.png)，原生 pending 缓存为空；旧设备已开启的权限没有被恢复。

随后只在新设备允许通知，重启应用进程。重新导出的[成功反馈](evidence/18-clean-install-reexport.png)对应文件与旧设备原备份的 14 表逐字段完全一致；[重启后的正常首页](evidence/18-clean-install-home-restored.png)显示恢复的数据。结构化核对结果见[干净安装验收摘要](evidence/18-clean-install-verification.json)：2 学期、42 节次、1 设置、1 课程、1 安排、3 任务、2 事件、2 调停课、1 独立补课、各 1 个转盘／点名／签池／分组列表、3 个工具使用记录。

原生 `local_reminders.xml` 和 `dumpsys alarm` 核对共 5 条未来提醒：1 DDL、3 个有效课程实例（含调课与独立补课，停课排除）、1 事件；历史任务、历史事件和已完成任务没有补发。实际日期采用下一周的手动样例；核对所有原生提醒标题与备份一致，时间均晚于验收时刻。本地明细为 `build/task18-clean-reminders.xml`、`task18-clean-alarms.txt`、`task18-clean-package.txt`，摘要已随本记录保存。

验收结束后已关闭仅本任务创建的 `emulator-5556`，核对绝对路径后删除临时 AVD 数据磁盘，启动日志保留为 `build/task18-clean-emulator.log`。原 `emulator-5554` 保留；已安装并启动最终 `lib/main.dart` APK，未卸载或清除已有应用数据。

## 验收边界

- 干净安装和通知重建来自真实 Android 模拟器运行，不代表实体 Android 手机的通知送达验收；任务 7–9 的实体设备检查仍待用户执行。
- 本次验证手动录入的完整领域数据。真实学校导入数据与备份迁移联验、整版发布验收由任务 19 完成。
- 当前备份按 schema 14 恢复，未来数据库版本需明确设计格式兼容策略；不宣称跨未知版本自动迁移。
