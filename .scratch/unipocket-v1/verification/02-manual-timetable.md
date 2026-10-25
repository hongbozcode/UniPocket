# 任务 2 检查记录

日期：2026-10-25。范围：[手动录课与今日／周课表](../issues/02-manual-timetable.md)，不代表整版功能完成。

## 实现范围

- 课程名称、教师及六种识别色；每门课程可保存多个独立星期、节次、地点和教学周的上课安排。
- 教学周提供全部周、单周、双周、连续范围及逐周选择；保存前校验所有输入，含已滚出屏幕的字段。
- 首页快捷录课并按校园时区显示当前学期的今日课程；周课表支持切周、回本周、今日列表及课程详情。
- 七天网格横向滚动，完整课程名可换行；多个节次的课程在首节展示完整信息、后续节次标明续课。冲突课程分别展示。
- 编辑基本信息保留安排与身份；课程重复安排修改、删除及其影响仍由任务 06 交付。学期变更若使已有课程节次或教学周失效，会明确阻止保存。
- Drift schema 1 → 2 增加课程与上课安排表，保留原学期和设置；新增课程与全部安排在一个事务中提交。

## 已运行的验证

| 检查 | 结果及边界 |
| --- | --- |
| `flutter analyze` | 通过，无静态分析问题。 |
| `flutter test` | 17 条通过：8 条应用行为测试、9 条界面测试；包含任务 1 的原有回归。 |
| 真实 SQLite 重开 | 多安排、教师、颜色、地点和任意周选择保留；关闭文件数据库后重新打开读取。 |
| 周一基准与校园时间 | 周日／周一边界、校园午夜前后、非教学周、不同星期节次与当前学期隔离通过。 |
| 冲突确认 | 相同星期、相交教学周及真实时间重叠触发提示；不同周不误报。返回修改不写入，确认后两门课程重开仍在。 |
| 数据完整性 | 空名称、缺少安排、非法星期／节次、空周及越界周不写入；课程基本信息编辑保留安排；破坏已有课程的学期修改不写入。 |
| 数据库升级 | 从任务 1 的 schema 1 SQL 夹具及已有数据启动，保留学期、节次、当前学期与校园时区，随后可正常录课。 |
| 界面操作 | 从首页录课到真实 SQLite，再重开并编辑基本信息；连续周、单双周与任意周交互、冲突取消／确认、空周错误通过。 |
| 布局与可达性 | 320／393 宽度、双倍文字、安全区域、长学期／课程／地点、表单滚动保存与课表横向滚动均通过。 |
| `flutter build web --no-web-resources-cdn` | 通过；本次未做浏览器运行或 Web 升级数据验收。 |
| Android API 36 模拟器 | 真实表单录入、多安排、多地点、单双周、冲突确认、切周与今日视图通过；新进程恢复通过，见下。 |

真实 SQLite 使用异步文件操作。测试等待用户可见的保存结果，不以一次 `pumpAndSettle` 代替磁盘完成；Android 与 Widget 测试复用滚动后点击的操作辅助函数。

## Android 两阶段验收

- 设备：`Medium_Phone_API_36.0`，Android 16 / API 36 模拟器。Flutter 3.47.7 / Dart 3.13.5；已有 SDK、JDK 和依赖可用，未新增依赖或安装工具链。
- 入口：`integration_test/timetable_flow_test.dart`。通过应用业务入口预置专用学期，课程通过真实界面录入。正式 `main.dart` 不含预置数据。
- 时钟是明确的外部测试边界，固定为 `2026-10-19T00:00:00Z`，校园时区 `Asia/Shanghai`，用于两阶段一致显示第 1 周周一；截图日期不表示拍摄日期。
- 两阶段均使用 `--keep-app-running` 和数据库 `unipocket_timetable_20261025_c`。第一阶段进程 5455，通过后只执行 `adb shell am force-stop com.hongbozcode.unipocket`，不清空数据；第二阶段新进程 5651。
- 新进程恢复“高等数学与数学分析”及确认保留的冲突课程；教师、两处地点、周一 1–2 节单周和周三第 3 节双周均一致。切换到第 2 周、返回今日视图通过。
- 验证期间未改变模拟器网络或手机时区；本次不以已联网环境的运行宣称完成独立断网验收。任务 1 的离线与手机时区变更记录独立保留。

```powershell
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/timetable_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_timetable_20261025_c
adb -s emulator-5554 shell am force-stop com.hongbozcode.unipocket
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/timetable_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_timetable_20261025_c --dart-define=ACCEPTANCE_RESTORE=true
```

重复验收时使用新的数据库名，两阶段保持同名。

运行证据（实际 Flutter Android 界面）：

- [录入后的今日课程](evidence/02-android-today-saved.png)
- [冲突确认弹窗](evidence/02-android-conflict.png)
- [保存后的第 2 周课表](evidence/02-android-week-saved.png)
- [新进程恢复后的今日课程](evidence/02-android-process-restored.png)
- [新进程恢复后的第 2 周课表](evidence/02-android-week-restored.png)

## 两轴代码审查

基线：任务开始时的 `285901f5ecbe890055287810e5d52fbb55b53d23`。审查进行中，最终结果将在修复及复核后补齐。

## 明确边界

- 未实现课程删除、重复安排编辑、调停课、DDL、提醒及 XLSX 导入；真实学校 XLSX 样例仍待提供。
- 尚未做 Android 真机、发布签名、通知送达或整版发布验收。
- 沿用既有蓝紫色变量、课程浅色与 SVG 资源；未修改 HTML 手册、维护源或历史截图。Android 截图与 HTML 设计参考分别保留。
- SVG 阴影滤镜沿用 Flutter 中的简化表现。Web 构建的字体裁剪提示及 Gradle 的 Java 原生接口提示未阻断构建，不作为运行验收证据。
