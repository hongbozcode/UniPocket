# 任务 2 检查记录

日期：2026-10-25。范围：[手动录课与今日／周课表](../issues/02-manual-timetable.md)，不代表整版功能完成。

## 实现范围

- 课程名称、教师及独立识别色；录课时显示带颜色的选择项和实时预览，新课程默认分配未使用的颜色。前六种沿用参考配色，用完后继续分配新色相，不循环复用。同一课程的全部安排共用课程颜色，编辑后保持一致。
- 教学周提供全部周、单周、双周、连续范围及逐周选择；保存前校验所有输入，含已滚出屏幕的字段。
- 首页快捷录课并按校园时区显示当前学期的今日课程；周课表支持切周、回本周、今日列表及课程详情。
- 普通字号下 320／393 宽度完整呈现七天，跨节课程合并为连续色块，日期与今天整列高亮；大字号或存在冲突时允许横向滚动，冲突课程使用独立列道，不互相遮挡。网格内过长文字省略后仍可点击查看完整详情。
- 首页按参考图使用蓝色圆形添加按钮、两行问候、太阳贴纸、白色今日课程容器、下一节／进行中标签和书本贴纸。周课表保留学期与时区、分段切换、周切换圆钮、回本周胶囊；底部选中导航采用蓝色文字和淡紫整块胶囊。
- 编辑基本信息保留安排与身份；课程重复安排修改、删除及其影响仍由任务 06 交付。学期变更若使已有课程节次或教学周失效，会明确阻止保存。
- Drift schema 1 → 2 增加课程与上课安排表，保留原学期和设置；新增课程与全部安排在一个事务中提交。

## 已运行的验证

| 检查 | 结果及边界 |
| --- | --- |
| `flutter analyze` | 通过，无静态分析问题。 |
| `flutter test` | 21 条通过：8 条应用行为测试、13 条界面测试；包含任务 1 的原有回归。 |
| 真实 SQLite 重开 | 多安排、教师、颜色、地点和任意周选择保留；关闭文件数据库后重新打开读取。 |
| 周一基准与校园时间 | 周日／周一边界、校园午夜前后、非教学周、不同星期节次与当前学期隔离通过。 |
| 冲突确认 | 相同星期、相交教学周及真实时间重叠触发提示；不同周不误报。返回修改不写入，确认后两门课程重开仍在。 |
| 数据完整性 | 空名称、缺少安排、非法星期／节次、空周及越界周不写入；课程基本信息编辑保留安排；破坏已有课程的学期修改不写入。 |
| 数据库升级 | 从任务 1 的 schema 1 SQL 夹具及已有数据启动，保留学期、节次、当前学期与校园时区，随后可正常录课。 |
| 界面操作 | 从首页录课到真实 SQLite，再重开并编辑基本信息；连续周、单双周与任意周交互、冲突取消／确认、空周错误通过。 |
| 布局与可达性 | 320／393 普通字号下七天同屏；双倍文字、安全区域、长学期／课程／地点、表单滚动保存与课表横向滚动均通过。 |
| 课程颜色 | 新增默认色不与已有课程循环复用，覆盖第七门课程；每门课程与其全部安排共用识别色，添加界面可预览。 |
| 独立节次时间回归 | 周一有两节、周二仅一节且时间不同，时间轴显示“按星期”，课程详情显示真实的 10:00–10:45；回归先失败后通过。 |
| `flutter build web --no-web-resources-cdn` | 通过；本次未做浏览器运行或 Web 升级数据验收。 |
| Android API 36 模拟器 | 真实表单录入、多安排、多地点、单双周、冲突确认、切周与今日视图通过；新进程恢复通过，见下。 |
| 正式 Android 调试构建 | `flutter build apk --debug` 通过，构建目标为正式 `main.dart`；已保留数据安装并打开正式应用。 |

真实 SQLite 使用异步文件操作。测试等待用户可见的保存结果，不以一次 `pumpAndSettle` 代替磁盘完成；Android 与 Widget 测试复用滚动后点击的操作辅助函数。

## Android 两阶段验收

- 设备：`Medium_Phone_API_36.0`，Android 16 / API 36 模拟器。Flutter 3.47.7 / Dart 3.13.5；已有 SDK、JDK 和依赖可用，未新增依赖或安装工具链。
- 入口：`integration_test/timetable_flow_test.dart`。通过应用业务入口预置专用学期，课程通过真实界面录入。正式 `main.dart` 不含预置数据。
- 时钟是明确的外部测试边界，固定为 `2026-10-19T00:00:00Z`，校园时区 `Asia/Shanghai`，用于两阶段一致显示第 1 周周一；截图日期不表示拍摄日期。
- 两阶段均使用 `--keep-app-running` 和数据库 `unipocket_timetable_20261025_d`。第一阶段进程 6954，通过后只执行 `adb shell am force-stop com.hongbozcode.unipocket`，不清空数据；第二阶段新进程 7158。
- 新进程恢复“高等数学与数学分析”及确认保留的冲突课程，两课颜色不同；教师、两处地点、周一 1–2 节单周和周三第 3 节双周均一致。切换到第 2 周、返回今日视图通过。
- 验证期间未改变模拟器网络或手机时区；本次不以已联网环境的运行宣称完成独立断网验收。任务 1 的离线与手机时区变更记录独立保留。

```powershell
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/timetable_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_timetable_20261025_d
adb -s emulator-5554 shell am force-stop com.hongbozcode.unipocket
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/timetable_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_timetable_20261025_d --dart-define=ACCEPTANCE_RESTORE=true
```

重复验收时使用新的数据库名，两阶段保持同名。

运行证据（实际 Flutter Android 界面）：

- [录入后的今日课程](evidence/02-android-today-saved.png)
- [冲突确认弹窗](evidence/02-android-conflict.png)
- [保存后的第 2 周课表](evidence/02-android-week-saved.png)
- [新进程恢复后的今日课程](evidence/02-android-process-restored.png)
- [新进程恢复后的第 2 周课表](evidence/02-android-week-restored.png)

## 源图细节对照

- 参考：现行[首页与周课表效果图](../../../docs/design/resources/core-pages/01-首页与周课表.png)、[首页样板截图](../../../docs/design/resources/screenshots/home.png)与[课表样板截图](../../../docs/design/resources/screenshots/timetable.png)。
- 使用独立入口 `integration_test/timetable_visual_test.dart`，固定校园日期 2026-10-23（周五，第 8 周），五门示例课程、八节课，用于对齐参考图状态。示例仅存于专用验收数据库 `unipocket_reference_20261025_d`，不进入正式数据库。
- 对照视口为 **393×852 逻辑尺寸**；模拟器暂时使用 1179×2556 / density 480，采集后已恢复原 1080×2400 / density 420。逐轮对照中修正了过宽网格、跨节续课重复块、配置说明占位、课程卡片密度、圆钮背景及导航选中态。
- 最终实际界面：[首页](evidence/02-reference-home.png)、[周课表](evidence/02-reference-week-final.png)、[录课颜色预览](evidence/02-course-color-preview.png)。已逐项核查七天列宽、连续色块、日期高亮、圆角、图标、贴纸、周切换、颜色选择与导航胶囊。课表最终图是原始采集 PNG 的同字节独立命名副本，SHA-256 一致，便于避免同路径多次采集的预览缓存。
- 对照范围是本任务已实现区域，不宣称整张效果图逐像素一致。DDL、倒计时、常用工具和导入快捷项仍属后续任务，未复制成虚假操作；正式 Android 保留系统安全区域。字体使用设备中文字体，窄网格的长地点可省略并在详情完整显示。

## 两轴代码审查

基线：任务开始时的 `285901f5ecbe890055287810e5d52fbb55b53d23`。规范轴和规格轴由独立子代理并行审查。

### Standards

初审 0 项发现。未发现违反项目文档约定的实现，也无须在本次整改的代码异味。业务校验与存储分离，保存使用事务，测试使用真实 SQLite 和共同应用入口；颜色按课程保存，界面复用既有 SVG 与参考布局。

### Spec

初审 1 项 P2，已修复并复核：两节一组的时间轴原来忽略仅有一节的星期，可能错误显示其他星期的时间范围。现纳入全部具有起始节次的星期，时间不同或缺结束节次时显示“按星期”；新界面回归验证提示和详情真实时间，先失败后通过。

最终未关闭：Standards 0 项，Spec 0 项。最终小范围导航／时间轴改动与证据更新已完成增量复核，无新增未关闭发现。

## 明确边界

- 未实现课程删除、重复安排编辑、调停课、DDL、提醒及 XLSX 导入；真实学校 XLSX 样例仍待提供。
- 尚未做 Android 真机、发布签名、通知送达或整版发布验收。
- 沿用既有蓝紫色变量、课程浅色与 SVG 资源；未修改 HTML 手册、维护源或历史截图。Android 截图与 HTML 设计参考分别保留。
- SVG 阴影滤镜沿用 Flutter 中的简化表现。Web 构建的字体裁剪提示及 Gradle 的 Java 原生接口提示未阻断构建，不作为运行验收证据。
