# 任务 4：倒计时事件完整管理验收

日期：2026-10-25。范围为 [04-countdown-events](../issues/04-countdown-events.md)；业务以首版规格为准，系统提醒留给任务 09。

## 已实现与自动验证

| 检查 | 实际结果 |
| --- | --- |
| 应用行为与持久化 | 考试／自定义事件新增、编辑、删除、置顶和取消置顶；真实文件 SQLite 关闭重开后保留日期、类型和置顶状态，删除仍生效。 |
| 校园日期 | 上海跨午夜、跨年、纽约夏令时开始的 23 小时日及结束的 25 小时日均按日历日期计数；当天“就是今天”，过去事件保留历史。 |
| 排序与范围 | 进行中先置顶、同组按临近日期、同日按稳定身份排序；历史按日期倒序。首页展示前三项，提供完整列表；切换学期不丢失事件。 |
| DDL 独立 | 事件操作不创建学习任务；创建 DDL 不创建事件，编辑删除事件保留已有任务。 |
| 数据库迁移 | schema 3 → 4 新增事件表，原学期、当前学期、课程与教学周、已完成任务及课程关联、备注、校园时区保留。原 schema 1／2 升级回归通过。 |
| 界面操作 | 无学期可从首页快捷创建，从首页与有／无学期的课表进入；真实日期选择器、类型选择、置顶开关、空标题反馈、删除取消／确认及更多菜单均通过。 |
| 日期反馈 | 选择过去日期时说明保存到历史；当天提示结束后转入历史；选择器与业务入口统一限制 1900–2200 年。 |
| 布局与可达性 | 320／393 逻辑宽度 × 1／2 倍文字，上下安全区域、长标题、8 项事件、末项编辑与滚动保存、历史删除均可达，无布局异常。 |
| 停留时跨午夜 | 可控时钟跨过校园午夜后，定时刷新将过去事件转入历史，明天事件显示“就是今天”；重新进入首页与列表结果一致，数据库仍保留两项记录。 |
| 全量测试 | `flutter test --no-pub`：41 项通过；本任务新增 3 项应用行为／数据库测试和 6 项界面测试。 |
| 静态检查 | `flutter analyze --no-pub` 无问题；`git diff --check` 通过。 |
| 正式构建 | `flutter build apk --debug --no-pub --target=lib/main.dart` 和 `flutter build web --no-pub --no-web-resources-cdn` 均通过；Android 安装正式入口并打开，保留已有应用数据。 |

遵循 TDD：校园日历与新增存储入口、置顶删除入口、界面入口分别先运行失败测试再实现；沿用首版规格已确认的应用行为层与真实数据库边界，仅控制外部时钟。

## Android 两阶段验收

- 使用现有 Android 16 / API 36 模拟器 `emulator-5554`，Flutter 3.47.7 / Dart 3.13.5；无需安装环境或新增依赖。
- 入口 `integration_test/countdown_events_flow_test.dart`，使用专用数据库；示例事件只由测试准备，正式 `main.dart` 不含预置数据。
- 创建阶段使用手机时区 Asia/Shanghai（UTC+8）：真实表单创建自定义事件、选择日期、置顶、修改标题并取消置顶，历史保留。
- 两阶段间仅 `am force-stop` 结束进程，保留数据；手机时区改为 Pacific/Honolulu（UTC−10）。恢复阶段明确断言设备偏移 −600 分钟，再验证校园时区仍为 Asia/Shanghai，期中考试仍为 14 天，课程展示仍为“就是今天”，编辑及取消置顶均恢复，DDL 为空；随后验证删除取消／确认、历史与课表入口。
- 初轮数据库 `unipocket_events_20261025_a`：进程 11240 → 11481，两阶段通过；布局收紧后数据库 `unipocket_events_20261025_b`：进程 11672 → 11892，两阶段通过，恢复阶段运行最终卡片和菜单布局。
- 外部时钟固定于 `2026-10-23T04:00:00Z`，转换为设备本地时间后交给应用；示例日期用于视觉对照，不是拍摄日期。
- 截图采用 1179×2556 / density 480，逻辑视口 393×852；验收后已恢复原 1080×2400 / density 420、GMT 和自动时区值 1。

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/countdown_events_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_events_20261025_b --dart-define=ACCEPTANCE_PHONE_OFFSET=480
adb -s emulator-5554 shell am force-stop com.hongbozcode.unipocket
adb -s emulator-5554 shell cmd alarm set-timezone Pacific/Honolulu
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/countdown_events_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_events_20261025_b --dart-define=ACCEPTANCE_RESTORE=true --dart-define=ACCEPTANCE_PHONE_OFFSET=-600
```

复现时先记录设备原时区与自动时区值，关闭自动时区并设为 Asia/Shanghai；每轮使用新数据库名，两阶段同名，完成后恢复原设置。保留 `--keep-app-running`，避免驱动结束时卸载应用。

## 源图对照与证据

参考 [学习任务与倒计时效果图](../../../docs/design/resources/core-pages/02-学习任务与倒计时.png)右侧和[历史倒计时截图](../../../docs/design/resources/screenshots/events.png)。复用现有配色、SVG 及细纸纹，置顶纸卡加入撕边；当天自定义事件使用现有铅笔贴纸，未来自定义事件使用旗帜。排序遵循规格中的临近日期顺序。

- [最终三张事件卡片](evidence/04-reference-events.png)：两行标题、日历贴纸、淡紫分段栏、紫色置顶卡、大数字、奶黄当天卡和薄荷未来卡，常规字号下三项及底部时区完整可见。
- [事件编辑表单](evidence/04-android-editor.png)：真实日期、类型选择及置顶开关。
- [新进程恢复](evidence/04-android-process-restored.png)：从上海改为夏威夷手机时区后恢复五项记录（四项进行中、一项历史）。
- [历史保留](evidence/04-android-history.png)、[新进程历史恢复](evidence/04-android-history-restored.png)：保留目标日期及“已过去”天数。
- [保存后列表](evidence/04-android-saved.png)、[课表入口](evidence/04-android-from-timetable.png)。

以上为 Flutter Android 实际运行截图。原图的绘制笔触、字体和阴影与平台渲染存在差异，不宣称逐像素一致；放大文字时优先完整显示内容和操作。

## 两轴代码审查

基线经用户确认：`b6327f78c0c610b666bb8e28c12a0ebea1e6a76e`；实现提交 `0c7631a`。独立子代理分别审查 Standards 与 Spec。

### Standards

未发现文档标准硬性违反，也未发现需要修复的明确代码异味。

- 符合 `docs/architecture.md`：沿用应用业务入口与真实 SQLite，界面、日期规则和存储分别组织，没有新增空远程层或通用框架。
- 符合 `GLOSSARY.md`：倒计时事件以目标日期为核心，与学习任务（DDL）独立，不引入完成状态。
- 符合 `docs/product/design.md`：复用已有 SVG 与纸纹资源，支持文字换行、安全区域、窄屏及文字放大；操作具有名称与状态文字。
- 测试通过公开应用入口使用真实数据库，覆盖文件重新打开及旧版本迁移，没有模拟内部调用顺序。

Standards：0 项硬性违反、0 项明确维护问题。

### Spec

未发现需要修复的规格偏差（0 项）。

- 任务 4 的创建、编辑、删除、置顶、历史、空状态、首页／课表入口及快捷添加均已实现。
- 天数使用校园日期归一到 UTC 日期后计算，避免夏令时与手机时区影响；当天文案和历史筛选符合规格。
- 数据库升级保留已有学习数据；事件独立存储，不自动产生 DDL。
- 已检视真实 SQLite、文件重开、午夜、时区、长文本、字号与 Android 两阶段验证代码。
- 最终 Android 截图保留源图的蓝紫配色、大数字、彩纸及贴纸；普通事件按临近日期排序符合权威规格，源图示例顺序不应覆盖此规则。

Spec：0 项发现，无未关闭问题；系统提醒仍属于任务 09。

两轴合计：Standards 0 项、Spec 0 项，各轴均无未关闭问题。

## 明确边界

本任务不交付任务 09 的系统提醒，也未做真机通知或整版发布验收。Web 仅进行构建检查，未新增浏览器端运行或迁移验收。Flutter SVG 的既有 filter 简化、Gradle Java 原生接口和 Web 字体裁剪提示未阻断运行；不将模拟器验收表述为真机结果。
