# 任务 17：真实学校 XLSX 导入与重复导入验证

日期：2026-10-27。分支：`codex/dev17`。实施前基线：`42826533ab15428b921697d500c79863469508df`。

实现：`09c335d`；审查修复：`f15bd79`。任务与本记录随同一分支交付。

## 实际学校依据

- 用户提供 `class_schedule_template/Hebei Normal University of Science & Technology/xskb.xlsx` 和 `效果示例.jpg`；已实际读取两者。文件标题为“河北科技师范学院2026年秋季学期课表”，不是从目录英文名猜测学校。
- 原件 SHA-256：`B00675902E9472ED3253298BD9CDCD4B04EF0C45917C02C8AFA608E27E6B7E04`。原件目录保持 Git 忽略，不提交学生个人资料。版本化样例 `test/fixtures/hbkj_schedule.xlsx` 保留真实结构、课程、地点和周次，替换学生资料、教师名单及作者元数据，详见同目录说明。
- 工作表 `xskb`：C2 为标题，B5／D5 为节次／时间，E5:K5 为星期一至日；C6:C17 为 1–12 节，D6:D17 为起止时间，E6:K17 为课程格。E18:K18 的重复备注只处理一次，C3 的学生信息不进入领域数据。
- 一个课程格内按课程名与教师／周次／地点成组；同一课程的分号片段可以表达不同周次。支持单周、双周、连续周及离散周；先合并同节次同地点的周次，再合并相邻且周次、地点相同的节次。不额外推断原件没有的理论／实验分类、课程编号或学期周一日期。
- 解析 OOXML 工作表关系、共享字符串与内联字符串；纵向合并的课程格覆盖对应节次；来源记录为 `xskb!E6` 等单元格位置。不匹配的标题、表头、节次或不完整压缩文件明确失败，局部课程／周次错误保留原文及位置供修正或排除。
- 原件得到 10 门有安排的课程与 3 门无上课时间的备注课程。备注须补齐安排并核对识别问题，或取消勾选。不能把备注静默丢弃或臆造时间。

## 确认规则与保存

用户在本轮明确选择“采用这套规则”：

- 同一课程：课程名＋完整教师名单，均只去除首尾空白；同名而教师名单不同分别保留，不自行重排教师或模糊合并。
- 同一安排：目标学期内上述课程身份＋星期＋起止节次＋去除首尾空白的地点＋排序后的精确教学周集合。不把仅有时间重叠、地点不同或周次不同的安排视为完全重复。
- 已有数据库、本批课程之间以及纠错后的同一课程内部都参与去重。全部重复默认不选中；部分重复显示跳过数量，只保存新安排。已有同名同教师课程直接追加新安排，保留原课程、提醒配置、原安排及其调停课关联；无 schema 变更，仍为 14。
- 重复过滤后的新安排独立检查时间冲突；冲突须明确确认。事务内重查最新数据，旧预览不能制造重复或顺带批准新增冲突。失败全部回滚，取消预览不写入课程；已存在课程追加安排失败也不改变原安排。
- 学校文件的节次时间与目标学期不同时提示核对，不能静默换算到错误作息。可进入学期设置，主动从文件填写每天 12 节时间，保存前可修改；新建学期仍需确认第 1 教学周周一等信息。

## 界面与平台

参考[首页与周课表源图](../../../docs/design/resources/core-pages/01-首页与周课表.png)、[视觉规范](../../../docs/product/design.md)，复用蓝白底、淡紫摘要、白色圆角课程卡、课程色和书本／文件夹／警告图标。学校手机截图用于核对真实课表含义，UniPocket 界面继续采用项目源图视觉。

正式应用的空状态和课表页都有“导入学校课表”。Android 使用系统文档选择器读取用户选中的文件，无存储全盘权限；取消不写入，重复触发禁用，文件读取有 10 MB 上限。原生读取在线程中进行，解析通过 `compute` 执行，页面展示读取进度及错误。后续复用任务 16 的目标学期、逐项编辑、排除、冲突确认、保存防重和结果反馈。

依赖为现有缓存可解析版本 `archive 3.6.1`、`xml 7.0.1`，未安装或升级 Flutter／Android 工具。没有网络解析、数据上传、任意学校识别或旧 XLS 支持。

## 验证

| 检查 | 实际结果与本地日志 |
| --- | --- |
| TDD | `build/task17-red-parser.log`、`task17-red-dedup.log` 记录缺少实现的失败；`task17-red-correction-dedup.log` 记录纠错产生相同安排时重复计数为 0 的失败，修复后为 1 且只写一个安排。 |
| 学校与导入定向测试 | 最终 `build/task17-review-fix-tests.log`，18 项通过，包含真实学校原件、脱敏实际格式、部分重复、旧预览、候选内部重复、追加失败保留原数据、完整回滚及新数据库连接恢复。 |
| 完整回归 | 最终 `build/task17-full-tests-final.log`，164 项通过。 |
| 静态分析 | `build/task17-analyze-final.log`，`No issues found!`。 |
| 界面 | `build/task17-ui-progress.log`：正式空状态／已有课表入口、取消选择、读取进度、错误后重选、320 宽双倍文字及预览取消通过。继承的导入界面回归覆盖纠错、排除、目标学期切换、冲突与事务失败反馈。 |
| Android 正式构建 | `build/task17-android-build-final.log`，主入口 `lib/main.dart` debug APK 构建成功，包含原生选择器与生命周期修复。 |
| Web 构建兼容性 | `build/task17-web-build-final.log`，`flutter build web --no-pub --no-web-resources-cdn --target=lib/main.dart` 成功；系统文件选择仅适配 Android。 |
| 差异 | `git diff --check` 通过。 |

首次全量 163 项通过后，审查新增纠错内部去重回归，最终全量为 164 项。日志在忽略的 `build/`；截图随本记录提交。已知 SVG filter、Gradle/JDK native-access、SDK XML 及 Web 字体提示按原日志保留，不宣称无警告构建。

### Android 真实文件与新进程

使用现有 Android 16 / API 36 x86_64 模拟器。用户真实原件复制到模拟器 Downloads，实际通过系统文档选择器选择；未在生产资源中内置个人文件。专用数据库 `unipocket_task17_20261027_delivery`，未清除普通应用数据库。

最终验收命令必须加 `--keep-app-running`。最早两次未加该参数，Flutter 驱动结束后卸载应用，不能作为同库恢复证据；已弃用该重复结论。最终的创建日志为 `build/task17-android-create-final.log`，恢复日志为 `build/task17-android-repeat-final.log`，恢复阶段加 `ACCEPTANCE_RESTORE=true` 并强制检查打开前已有 10 门课程。

```powershell
flutter drive --no-pub --keep-app-running -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/school_import_flow_test.dart --dart-define=ACCEPTANCE_DATABASE=unipocket_task17_20261027_delivery
```

恢复阶段使用同一命令并加 `--dart-define=ACCEPTANCE_RESTORE=true`，系统选择器中仍选择同一原件。创建进程 PID 5378，恢复进程 PID 5875，两阶段均通过。创建阶段排除三门无安排备注后，确认保存 10 门课程、30 个安排；恢复日志明确记录 `TASK17_INITIAL_COURSES=10`，全部已有安排默认跳过，备注排除后无可导入内容且保存按钮禁用，课程与安排数量保持不变。最初恢复测试的末项尚未构建时直接定位按钮失败，改为滚动到稳定 Key 后重跑通过。

截图：[系统选择器](evidence/17-android-system-picker.png)、[导入入口](evidence/17-android-file-entry.png)、[真实学校预览](evidence/17-android-school-preview.png)、[排除未排课备注](evidence/17-android-unresolved-excluded.png)、[冲突与导入确认](evidence/17-android-confirmation.png)、[成功结果](evidence/17-android-success.png)。自动验收中的通知为受控边界，成功页通知可用性提示不代表实体手机通知验收。

同库恢复：[重复安排默认跳过](evidence/17-android-repeat-preview.png)、[排除备注后无新增内容](evidence/17-android-repeat-skipped.png)。

自动测试结束后切换正常 Flutter binding 的独立手动入口，使用同一验收数据库：

```powershell
flutter run --no-pub --no-resident -d emulator-5554 --target=tool/school_import_preview.dart
```

该工具固定展示 2026-10-27 08:15 校园时间，以便人工检查第 9 周与今日课表；正式主入口没有固定时钟。自动测试包不能作为手动交互交付包。

正常手动应用 PID 6093，`build/task17-manual-preview-final.log` 确认编译安装与启动。另以真实设备数据库副本独立查询，确认 1 个学期、10 门课程、30 个安排。临时把现有模拟器密度由 420 调整为 440，以 1080 像素宽检查约 393 个逻辑像素的首页、周课表和课程详情；实际点击课表导航、JavaWeb 课程并返回，未出现导航停留或溢出。完成后已恢复原密度，模拟器保留正常手动应用。

手动截图：[恢复后的首页](evidence/17-android-home-restored-393.png)、[第 9 周课表](evidence/17-android-timetable-restored-393.png)、[导入课程详情](evidence/17-android-imported-course-detail.png)。长课程名在网格中省略，详情可查看完整课程、地点、节次和教学周；320 宽双倍文字的导入表单另由 Flutter 界面测试覆盖。

## Standards

最终 0 项未解决问题。首次发现 Activity 销毁后慢文件读取可能重复回复 MethodChannel；成功和失败回调均增加结果身份检查后复审通过。

## Spec

最终 0 项未解决问题。首次发现纠错可使同一课程内两条安排完全相同；已增加候选内去重及先失败后通过的真实 SQLite 行为回归。

两轴最终审查范围 `git diff 42826533ab15428b921697d500c79863469508df...f15bd79`。Standards 0 项，Spec 0 项，两轴均无最高严重问题。规则已同步任务文件及首版规格。

证据限于真实 SQLite、Flutter 界面和 Android 模拟器；实体手机及整版导入／备份／恢复验收仍属于任务 19，未在本任务宣称完成。

## 跟进：课程下方紫色空白

2026-10-27，基线 `7268ce9`。用户指出周二“职业教育学”下方第 9–12 节无课却显示紫色。

实际原因是 `WeekGrid` 为“今天”所在列绘制从表头到课表底部的淡紫背景，并非额外课程数据。现将背景高度限制在日期表头，保留今天的日期圆点及文字标记，所有空课时使用统一底色。

- 新增 `test/week_grid_highlight_test.dart`，从真实 Flutter 渲染结果比较今日最后一个空课时与相邻日期相同位置的像素；修复前分别为 `#f5f1ff` 与 `#fcfdff`，失败记录 `build/task17-highlight-red.log`，修复后相等。
- `build/task17-highlight-tests.log`：该视觉回归及既有课表界面测试共 9 项通过，覆盖 320／393 宽、双倍文字、课程详情与编辑。
- `build/task17-highlight-analyze.log`：`No issues found!`；`build/task17-highlight-android.log`：正常手动包重新编译、安装、启动成功。
- 在原验收数据库中实际进入课表并滚动到第 9–12 节，确认空白底色一致；未改变已导入课程或安排。模拟器保留修复后的正常手动应用。

[Android 修复后的空课时](evidence/17-android-empty-periods-fixed.png)。先前恢复截图保留为历史证据，以本次截图作为空课时底色的最新依据。
