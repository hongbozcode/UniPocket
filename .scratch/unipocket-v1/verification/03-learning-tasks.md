# 任务 3 检查记录

日期：2026-10-25。范围：[学习任务完整管理](../issues/03-learning-tasks.md)，不代表整版交付或真机发布验收。

## 实现范围

- 学习任务支持标题、截止日期时间、备注、可选课程、编辑、删除确认、完成和撤销。仅选日期默认 23:59 并明确显示，可分别修改日期和时间；编辑保留完成状态。
- 截止时间保存校园日历日期与当天分钟，不依赖手机时区。逾期由校园时间计算，不自动完成；任务页每 30 秒刷新、首页每分钟刷新，回到前台重新读取。
- 首页显示最早截止的前三项未完成任务，包含醒目标识的逾期事项；提供快捷创建、空状态、完整列表和课表入口，无学期也能创建独立任务。
- 完整列表支持未完成／已完成、全部课程／指定课程／独立任务筛选。未完成按已逾期、今天、接下来分组，同组按截止时间排序；课程包含已有历史学期。
- 沿用共同应用入口 `SemesterPlanner`、真实 SQLite 与现有依赖。Drift schema 2 → 3 新增任务表，课程外键删除后置空，为任务 06 保留任务独立存在的约束；本任务不交付课程删除。
- 未修改首版范围、视觉手册维护源或历史图片。

## 已运行的验证

| 检查 | 实际结果与边界 |
| --- | --- |
| `flutter analyze` | 通过，无静态分析问题。 |
| `flutter test` | 审查修复后 32 条通过，含任务 1、2 回归；新增 4 条应用行为测试及 7 条界面测试。 |
| SQLite 文件重开 | 独立任务身份、标题、默认 23:59、未完成状态保留。 |
| 应用行为 | 课程关联／解除、编辑备注和截止时间、完成／撤销、删除；空标题、越界分钟、无效课程及不存在任务不产生错误写入。 |
| 校园截止边界 | 截止瞬间未逾期，之后 1 毫秒即逾期；上海午夜、纽约夏令时结束日、切换学期保留任务通过；逾期不自动完成。 |
| 数据库升级 | 从 schema 2 升级，保留学期、课程、安排、当前学期及校园时区；可关联原课程。原 schema 1 升级回归也通过。 |
| 界面操作 | 无学期创建、snackbar 撤销、修改标题／备注、日期和时间选择器修改、选择关联课程、课程及状态筛选、删除取消／确认。 |
| 布局与可达性 | 320／393 宽度 × 1／2 倍文字，含上下安全区域、长课程名、长任务标题、8 项任务、末项编辑与滚动保存，无溢出或不可达操作。 |
| 停留时逾期 | 控制外部时钟跨过截止时间，刷新后出现已逾期，任务仍未完成。 |
| 跨页面撤销 | 完成任务后返回首页，所属提示移除；重新进入已完成列表仍可撤销，数据库状态恢复，无已销毁状态回调。回归先失败后通过。 |
| Web 构建 | `flutter build web --no-web-resources-cdn` 通过；未做浏览器运行与升级数据验收。 |
| 正式 Android 构建 | `flutter build apk --debug --target=lib/main.dart` 通过；已保留应用数据安装并打开正式入口。 |

TDD 先确认任务保存与界面入口测试失败，再实现对应纵向流程。沿用首版规格中已确认的应用行为层与真实数据库测试边界，不模拟内部存储。

## Android 两阶段验收

- 设备：现有 Android 16 / API 36 模拟器 `emulator-5554`；Flutter 3.47.7 / Dart 3.13.5。SDK、JDK 和依赖可用，无需补装；Chrome 缺失不影响 Android 验证。
- 入口：`integration_test/learning_tasks_flow_test.dart`。三项源图示例任务与课程由应用业务入口写入专用数据库；第四项独立任务通过真实表单创建、编辑、完成、撤销并再次完成。
- 两阶段使用 `--keep-app-running`，之间仅结束应用进程并保留数据。布局对照阶段数据库 `unipocket_tasks_20261025_c`，进程 9280 → 9457，两阶段通过；审查修复后以 `unipocket_tasks_20261025_d` 再验收，进程 9879 → 10102，两阶段通过，并验证完成后返回首页的提示生命周期。
- 新进程恢复课程关联、任务、备注、23:59 和完成状态；随后撤销完成、取消／确认删除，从课表再次进入列表，均通过。正式 `main.dart` 不含预置数据。
- 固定外部时钟 `2026-10-23T04:00:00Z`，校园时间为 10 月 23 日 12:00，用于匹配源图分组。截图日期是测试数据，不是拍摄日期。

```powershell
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/learning_tasks_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_tasks_20261025_d
adb -s emulator-5554 shell am force-stop com.hongbozcode.unipocket
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/learning_tasks_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_tasks_20261025_d --dart-define=ACCEPTANCE_RESTORE=true
```

重复验收时使用新的数据库名，两阶段保持同名。

## 源图对照与运行证据

参考：[学习任务与倒计时效果图](../../../docs/design/resources/core-pages/02-学习任务与倒计时.png)的任务区域与[历史任务截图](../../../docs/design/resources/screenshots/tasks.png)。复用既有变量与 SVG；本任务不交付倒计时。

- [最终 393×852 任务列表](evidence/03-reference-tasks.png)：浅蓝白背景、蓝色圆钮、两行标题、铅笔贴纸、淡紫筛选、三组卡片、课程标签、圆形完成控件、书本与底部说明；对照后收紧留白，参考状态可在该视口完整呈现。
- [已完成列表](evidence/03-android-completed.png)：完成图标、文字、划线；支持撤销。
- [任务编辑表单](evidence/03-android-editor.png)：默认时间、课程关联、备注与删除入口。
- [新进程恢复列表](evidence/03-android-process-restored.png)、[完成状态恢复](evidence/03-android-completed-restored.png)与[课表入口](evidence/03-android-from-timetable.png)。

均为实际 Flutter Android 截图，等待页面过渡完成后采集。临时参数 1179×2556 / density 480，采集完成恢复原 1080×2400 / density 420。设备中文字体与 SVG 阴影沿用平台表现，不宣称逐像素一致；窄屏和大字号优先保证文字及操作可达。

## 两轴代码审查

基线为任务开始时 `10a7ff536ac116eea6af733dfc34e64700249e4a`，初审实现提交 `d86a197`。两个独立子代理分别审查。

### Standards

未发现文档标准硬性违反；领域术语、真实 SQLite、迁移保留数据、资源复用与验收边界符合项目约定。

1 项 P3 判断性维护建议：`lib/app.dart` 与 `lib/tasks/tasks_page.dart` 的完成／撤销交互有重复。两个页面当前分别持有加载、busy、错误与提示生命周期，保留局部处理；后续共同调整交互时可在任务 UI 模块提取共享行为，不为此增加通用业务层。该建议非阻断。

### Spec

初审 1 项 P2，已修复并由规格审查代理增量复核通过：任务页原使用全局提示，返回首页后点击遗留“撤销”可能调用已销毁状态。现使用页面专属 `ScaffoldMessenger`，关闭时移除所属提示，并检查 `mounted`；新增真实数据库界面回归与 Android 导航检查。

最终：Standards 0 项硬性违反、1 项 P3 维护建议；Spec 未关闭 0 项，无新增发现。

## 明确边界

- 提醒属于任务 07；课程删除与调停课、倒计时、学校 XLSX 均不属于任务 3，学校真实样例仍待提供。
- 本次未改变模拟器网络或手机时区，不宣称新增断网或手机时区变更实测；尚未进行 Android 真机、通知、发布签名或整版发布验收。
- Flutter SVG 的既有 filter 简化提示、Gradle Java 原生接口提示与 Web 字体裁剪提示未阻断测试或构建。
