# 任务 12 检查记录

日期：2026-10-26。范围：[随机点名与持久化抽取轮次](../issues/12-random-roll-call.md)。最终分支：`codex/dev12`（用户在实施期间更正了最初的 dev11 要求）。实现前基线：`6d81fee5cd3a999bcd1f73d443bcb8968e410311`；实现提交：`f11b442`；审查修正：`98d09c9`。

## 实现与范围

- 工具页新增随机点名，与转盘、骰子和硬币并列。支持新建、命名保存、切换、编辑多份点名名单；成员单独录入姓名及可选学号／备注，同名成员不合并。没有填写识别信息时显示成员编号，不虚构学号。
- 点名使用独立存储，不共享转盘或其他工具名单。空名单可以保存，不能抽取。编辑前说明清除结果和本轮记录的影响，取消确认或取消编辑保留原进度。
- 可重复模式每次使用完整名单；不重复模式按成员身份排除已抽成员。每次触发调用一次 `Random.nextInt(有效候选数)`，没有权重或指定结果；装饰滚动不再消耗随机源。
- 触发时选定待揭晓成员，反馈完成后才通过事务提交。本次操作重复完成共享同一个 Future；取消后不能提交。数据库修订号同时阻止旧反馈覆盖名单修改、新轮次或另一已完成抽取。
- 每份名单分别保存重复模式、轮次、已抽身份序列及结果。离开页面或重启后恢复；不重复抽完不会自动重置，需主动开始新一轮。切换模式明确确认后开始新一轮。
- 播放期间禁用编辑、名单切换、模式切换、重置及重复触发。显式取消、顶部返回、系统返回和进入后台均取消未完成抽取。成功的系统返回立即取消，不等待路由退出动画结束；已进入事务提交的短暂阶段锁定退出。
- SQLite schema 10 升至 11，仅新增点名名单表。编辑、重置与完成抽取均通过真实数据库事务写入，既有学习数据和转盘保留；读取／保存错误提供反馈及重试，失败不以空名单覆盖原数据。
- 本轮没有安装环境或新增依赖，`pubspec.lock` 未改变。使用现有 Flutter 3.47.7／Dart 3.13.5、Drift 和 Android API 36 模拟器。通过 Context7 核对 [Drift 事务](https://drift.simonbinder.eu/dart_api/transactions)及[条件写入](https://drift.simonbinder.eu/dart_api/writes)文档。

## 视觉与动作

依据：[工具箱与点名源图](../../../docs/design/resources/core-pages/03-随机工具箱与点名.png)、[当前 HTML 点名样板截图](../../../docs/design/qa/live-v2-draw.png)、[视觉规范](../../../docs/product/design.md)，以及 `docs/design/motion-demo.js` 的 draw 分支和 `motion-demo.css`。用户要求按源图及源码还原动作；没有修改 HTML 手册或其生成源。

- 复用口袋 SVG、成员／返回／随机／勾选图标；浅蓝白背景、淡蓝名单按钮、淡紫模式选中态和结果卡、白色进度／已抽卡、蓝色主操作与浅色边框。
- 采用源码的 1400ms、20 行纵向滚动和 `cubic-bezier(.18,.72,.2,1)` 减速曲线，停止后揭晓同一成员的姓名和身份信息。减少动效设置下缩短反馈。
- 姓名、备注、名单名称及已抽记录均为真实文字，可换行；结果和已抽记录可选择复制。按整份名单的最大文本高度预留空间，使等待、滚动和落定的结果卡与进度位置稳定；字号及宽度改变时重新布局。每帧仅更新滚动位移，不重新测量整份名单。
- 多名单选择器同时提供选中语义及勾选标志。补齐无名单、空名单、耗尽、读取／保存失败、编辑影响确认、重置及切换模式确认状态。

## 已运行验证

| 检查 | 结果与证据范围 |
| --- | --- |
| TDD | 名单持久化接口、轮次接口和工具入口分别先失败再实现；审查发现的末段系统返回及长文本高度问题也先复现失败后修正。 |
| 真实 SQLite | 多名单和同名身份独立保存；文件数据库关闭重开续轮；重复候选范围、取消、重复提交、并发旧反馈、修改后旧结果失效、耗尽和主动重置。schema 10 迁移保留原学习数据、设置及转盘。 |
| 界面 | 320／393 逻辑宽、1／2 倍文字、上下安全区；空名单、长姓名／备注、名单选择、确认取消、编辑保存／取消、重复模式、新轮次、显式取消、后台取消及播放锁定。 |
| 动作与审查回归 | 0／150／450／900／1300／1399ms 绘制帧有变化；1400ms 后才提交姓名与备注。1300ms 系统返回不写入；长文本等待／播放／落定高度一致。8 项界面和动效回归通过。帧图位于 `build/roll-call-preview/`，仅作宿主运动证据，宿主测试字体不作为中文排版依据。 |
| 最终全量回归 | `flutter test --no-pub --reporter expanded`：120 项通过。日志：`build/task12-full-tests-final.log`。 |
| 静态检查 | 审查修正后 `flutter analyze --no-pub` 无问题；`git diff --check` 通过。 |
| 构建 | 正式 `lib/main.dart` 入口 Android debug APK 与 Web 构建通过；Web 使用 `--no-web-resources-cdn`。未做浏览器交互验收。 |
| Android 集成 | API 36 模拟器通过工具入口、真实表单、同名成员、多名单、取消编辑、1200ms 滚动末段系统返回不消耗，以及停止进程后恢复并继续抽取。最终两阶段使用同一专用数据库 `unipocket_roll_20261026_c`，没有卸载或清除应用数据。 |

最终 Android 流程：

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/roll_call_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_roll_20261026_c
adb shell am force-stop com.hongbozcode.unipocket
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/roll_call_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_roll_20261026_c --dart-define=ACCEPTANCE_RESTORE=true
```

截图采集为 1179×2556／density 480，即 393 逻辑宽。验收后恢复模拟器原始 1080×2400／density 420，并用正常随机源的正式入口 APK 替换测试入口。320 宽和双倍文字覆盖来自宿主界面测试；没有宣称实体手机验收、固定帧率或整版发布验收完成。

## Android 截图

- [工具入口](evidence/12-android-tools.png)、[无名单](evidence/12-android-empty.png)、[等待点名](evidence/12-android-ready.png)。
- [抽中林晓及对应学号](evidence/12-android-result.png)、[完整已抽记录](evidence/12-android-history.png)、[修改名单影响确认](evidence/12-android-edit-confirm.png)、[第二份空名单](evidence/12-android-empty-list.png)。
- [进程恢复后的原结果和轮次](evidence/12-android-process-restored.png)、[继续抽中剩余成员](evidence/12-android-resumed-result.png)、[多名单与当前勾选](evidence/12-android-picker.png)、[恢复后的工具入口](evidence/12-android-tools-restored.png)。

截图来自实际 Flutter Android 运行；已对照源图检查主色、插画、模式、结果、进度和已抽卡，完整内容可滚动访问。源图和 HTML 截图不作为 Android 行为证据。

## 审查

按 `code-review` 技能从固定基线 `6d81fee` 分别进行 Standards 与 Spec 审查，两个独立子代理复核 `f11b442..98d09c9`。子代理仅做静态审查，未运行测试或构建；测试和平台验收由主代理执行。

## Standards

原 2 项规范问题均已解决：成功系统返回立即取消；整份名单预留稳定文本空间。未发现剩余规范违规或值得报告的判断性代码异味。

Standards：剩余问题 0 项，无阻断项。

## Spec

原系统返回取消竞态已解决，1300ms 回归覆盖此前遗漏窗口。长文本仍完整展示及可复制；未改变抽取规则、身份对应或提交时序。未发现新增缺失、范围扩张或行为错误。

Spec：剩余问题 0 项，无阻断项。

Standards 0 项／Spec 0 项，两轴均无阻断项。
