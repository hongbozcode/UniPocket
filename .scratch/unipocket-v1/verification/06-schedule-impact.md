# 任务 6：重复安排变更与课程删除影响处理验收

日期：2026-10-25。范围为 [06-schedule-impact](../issues/06-schedule-impact.md)，业务与测试边界遵循首版规格。课程提醒清理由任务 08 联动完成。

## 实现与自动验证

| 检查 | 实际结果 |
| --- | --- |
| 重复安排编辑 | 课程详情可修改星期、起止节次、地点、任意教学周，添加或移除安排。已有安排保留身份，原日期仍属于该安排时保留调课／停课关联。 |
| 影响预览 | 保存前展示保留的例外与每项失去关联的例外；没有默认处理方式，全部明确选择后才能确认。返回修改或系统返回不写入。 |
| 独立补课 | 失联例外可保留为具体日期、时间、地点的独立补课，仍属于课程；后续重复安排变更不移动它。首页、今日、周网格／节次外列表有文字标识，可编辑或取消。原停课转为补课前，界面明确说明会新增一次上课。 |
| 删除课程 | 确认前展示安排、调停课、独立补课和关联 DDL 数量。确认后删除该课程及其安排／例外／补课；关联 DDL 解除课程关联，标题、截止时间、备注和完成状态保留。其他课程与任务不受影响。 |
| 冲突与旧预览 | 按最终有效课次检查重复安排、已有调课和独立补课的重叠；未确认不写入，确认可保存。预览后相关安排、例外、补课或删除涉及的任务关联变化时要求重新确认。 |
| 持久化与事务 | 真实 SQLite 文件重开后关系和独立补课保留。存储边界通过真实 SQLite 触发器模拟写入失败，验证修改／删除事务回滚，不留下部分清理或补课。 |
| 数据库升级 | schema 5 → 6 增加独立补课表，保留旧调停课及课程、节次、任务、事件、校园时区。schema 1／2／3／4 回归通过。 |
| 布局 | 320／393 逻辑宽度 × 1／2 倍文字、安全区域、长课程名／地点、缺少选择的错误状态、滚动确认及独立补课编辑／取消均通过。进入课程详情时收起上轮提示，底部操作可点击。 |
| 测试 | `flutter test --no-pub`：62 项通过，任务 6 新增 6 项应用行为／数据库测试与 5 项界面测试。沿用已确认的公开应用操作与真实数据库测试边界。 |
| 静态检查 | `flutter analyze --no-pub` 无问题；`git diff --check` 通过。 |
| 正式构建 | `flutter build apk --debug --no-pub --target=lib/main.dart`、`flutter build web --no-pub --no-web-resources-cdn` 通过。正式 Android 入口覆盖安装并打开，保留原有应用数据。 |

## Android 两阶段验收

- 使用已有 Flutter 3.47.7／Dart 3.13.5 和模拟器 `emulator-5554`；没有安装环境或新增依赖。
- 入口为 `integration_test/schedule_impact_flow_test.dart`，共享用户操作流程位于 `test/support/schedule_impact_flow.dart`。示例数据只进入专用数据库 `unipocket_impact_20261025_a`。
- 创建阶段：课程详情中移除一个重复安排，先取消影响确认、验证原数据不变，再逐项将失联调课保留为独立补课、删除失联停课。冲突提示先返回修改再确认保留；有效调课与停课仍保留。通过独立补课表单修改地点，再取消并确认删除大学英语，保留其两项 DDL（一个已完成、一个未完成）。
- 两阶段之间仅结束应用进程，保留数据；手机时区从 Asia/Shanghai 改为 Pacific/Honolulu。创建进程 15270，恢复进程 15515，两阶段通过。
- 恢复阶段：同一数据库中独立补课、有效例外、原重复安排及课程关联一致；已删除课程消失，其 DDL 保留全文、状态及解除关联的结果；未删除课程的任务仍有关联。独立补课仍可从周课表进入编辑，取消编辑不改数据。
- 截图视口为 1179×2556／density 480，即 393×852 逻辑尺寸；外部时钟固定为校园 2026-10-26 07:00，界面示例日期不是拍摄日期。
- 验收后恢复设备原始 1080×2400／density 420、GMT 与自动时区值 1，并安装正式应用入口。

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/schedule_impact_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_impact_20261025_a
adb -s emulator-5554 shell am force-stop com.hongbozcode.unipocket
adb -s emulator-5554 shell cmd alarm set-timezone Pacific/Honolulu
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/schedule_impact_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_impact_20261025_a --dart-define=ACCEPTANCE_RESTORE=true
```

复现前记录设备设置，关闭自动时区并设为 Asia/Shanghai；每轮更换验收数据库名，两阶段保持同名。使用 `--keep-app-running`，避免驱动卸载应用，结束后恢复原设置。

## 源参考图与实际运行截图

依据 [首页与周课表源图](../../../docs/design/resources/core-pages/01-首页与周课表.png)、[历史周课表样板](../../../docs/design/resources/screenshots/timetable.png)及 [视觉规范](../../../docs/product/design.md)。复用浅蓝白底、蓝色主操作、淡紫选择态、白色圆角卡片、课程识别色和现有 SVG。源图未展开重复安排影响与删除确认状态，本任务按同一视觉体系补齐，不修改手册或新增素材。

- [变更前首页](evidence/06-android-home-before.png)、[变更前周课表](evidence/06-android-week-before.png)。
- [影响汇总与有效例外](evidence/06-android-impact-summary.png)、[调课转独立补课选择](evidence/06-android-orphan-move-choice.png)、[失联停课处理](evidence/06-android-orphan-cancellation-choice.png)。
- [最终课次冲突确认](evidence/06-android-conflict.png)、[重复课次与独立补课](evidence/06-android-week-independent.png)、[独立补课编辑](evidence/06-android-independent-editor.png)。
- [课程删除影响确认](evidence/06-android-delete-impact.png)、[删除后保留的 DDL](evidence/06-android-ddl-retained.png)、[新进程恢复](evidence/06-android-process-restored.png)。

以上均为 Flutter Android 模拟器实际截图。冲突课次通过横向滚动分栏，长内容和新增表单通过纵向滚动完整阅读；字体、笔触及平台阴影不宣称逐像素一致。

## 两轴审查

审查基线由用户确认为 `81da4107d4758f1c2dbab240dc99dcfc9b292146`，实现提交为 `4dee4dd`。审查命令为 `git diff 81da4107d4758f1c2dbab240dc99dcfc9b292146...HEAD`。两名独立子代理分别审查以下两轴。

### Standards

未发现项目文档标准的硬性违反。业务规则集中在应用行为层，SQLite 写入集中在存储模块；测试通过公开应用操作和真实数据库验证。运行截图沿用源参考的浅蓝背景、蓝紫圆角卡片、课程识别色及现有 SVG，新增确认状态未发现明确视觉偏差。

初审提出两项 P3 维护建议，均已修正：

- 独立补课复用例外校验时构造虚拟原安排身份，属于可能 Feature Envy；现提取共享日期与起止时间校验，由两种领域对象分别调用。
- 新增课程分支重复构造课程草稿，属于 Duplicated Code；现新增与修改统一使用 `_draft()`。

原审查代理已复核两项修正并确认关闭，未发现新问题；修正后全量 62 项测试和静态检查再次通过。

Standards：0 项硬性违反、0 项未关闭维护问题。

### Spec

未发现需要修复的规格偏差，0 项发现。

- “修改重复安排时保留已有例外并展示影响”：依据原安排身份与原课次日期划分有效／失联例外；修改节次或地点仍保留有效关联。
- “失去原始课次关联的例外由用户选择独立补课或删除，不静默丢弃”：逐项要求显式选择，未选完整则拒绝保存；停课转补课明确说明将新增一次上课。
- “删除课程前说明影响……关联任务解除课程关联后保留”：确认展示安排、例外、独立补课和任务数量，事务清理课程关系，DDL 解除关联并保留内容及完成状态。
- “取消影响确认不改变数据；冲突可提示后确认保留”：预览无写入，取消退出不提交；冲突按最终有效课次计算，确认后才写入。
- 真实 SQLite 验证关系变更、文件重开、旧库升级、失败回滚和旧预览失效；Android 截图展示保留、选择、确认及进程恢复状态。独立补课有文字标识及管理入口，未发现本次变更引入的明确视觉偏差。

没有发现无关功能扩张。课程提醒清理属于任务 08，不计作本任务缺项。

Spec：0 项发现，无未关闭问题。

两轴最终未关闭发现：Standards 0 项、Spec 0 项，各轴均无未关闭问题。

## 验证边界

任务 6 不交付系统提醒清理或通知验证，交由任务 08。Android 证据来自模拟器，没有用模拟器替代真机发布验收；Web 只验证构建。已有 SVG filter 简化提示、Gradle Java 原生接口提示及 Web 的可选 Cupertino 字体提示未阻断测试或构建。
