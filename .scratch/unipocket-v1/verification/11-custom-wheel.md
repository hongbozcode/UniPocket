# 任务 11 检查记录

日期：2026-10-26。范围：[自定义转盘](../issues/11-custom-wheel.md)。分支：`codex/dev11`。用户确认的审查基线：`9a3cb58adca03b872056839c5ba7ddd151d7aa8e`。实现提交：`c609c67`；审查修正：`d36e9fe`。

## 实现与范围

- 工具页新增转盘入口，与已交付的骰子／硬币并列。支持新建、命名、切换和编辑多组转盘；只保存到转盘专用表，不与其他工具共享。没有提前实现任务 15 的搜索、收藏或最近使用。
- 每一项按原顺序独立保存，重复文字在编辑时和转盘页明确提示，不合并、不加隐藏权重。空行不作为选项并在表单说明；空列表可保存、不能转动。单项绘制完整圆面并正确落位。
- 每次触发只调用一次 `Random.nextInt(选项数)`。待揭晓结果同时决定旋转终点及最终文字，动画期间不会重抽；主操作、列表切换和编辑禁用。固定顶部指针对准获选扇区中心，图像语义由实际角度计算。
- 返回销毁动画和待揭晓状态；显式取消、进入后台也清除未完成反馈。结果不作为历史持久化，重新进入等待转动，已保存列表保留。
- SQLite schema 9 升级到 10，仅新增转盘列表表。名称与有序选项 JSON 由事务保存；原学习数据和提醒配置不清除。表单保存失败保留输入，读取失败提供重试，不用空数据覆盖原列表。
- 本轮未安装环境、未新增依赖，`pubspec.lock` 未改变。复用现有 Flutter 3.47.7／Dart 3.13.5、Drift、Android SDK 和模拟器。依据项目规则，通过 Context7 核对 [Drift 官方迁移文档](https://drift.simonbinder.eu/migrations)。

## 视觉与动作

依据：[转盘源图](../../../docs/design/resources/random-tools/01-转盘.png)、[HTML 样板截图](../../../docs/design/qa/live-v2-wheel.png)、[视觉规范](../../../docs/product/design.md)，以及 `docs/design/motion-demo.js`／`motion-demo.css` 中的转盘场景。用户明确要求按源动效还原，覆盖本任务默认简化反馈的约束；未修改 HTML 手册或其生成源。

- 浅蓝白底、蓝紫外圈与中心、六种浅色扇区、白色分界、固定顶部蓝色指针、淡紫纸感结果便笺和蓝色主操作。入口使用现有转盘 SVG；三项工具共用卡片样式和结果纸张裁剪器。
- 转盘随可用宽度缩放，文字沿各扇区半径逐字排列并随盘旋转；获选项到顶部时正向可读。长文字在盘上截短，完整内容在下方图例和结果卡换行展示，均为实际文字。指针下预留文字空间。
- 使用源码的约 3100ms、六个完整旋转圈数，以及 `cubic-bezier(.18,.72,.2,1)` 减速曲线。指针围绕顶部固定支点按 0／−11／9／−7／4／0 度关键帧小幅摆动，结束恢复正向。停稳后才揭晓文字结果。
- 补齐新建、命名、编辑、空列表、重复项提示、读取／保存错误以及列表选择器。当前列表同时用选中语义、颜色及勾选图标表示。

## 已运行验证

| 检查 | 结果与范围 |
| --- | --- |
| TDD | 按规格已确认的应用操作／真实 SQLite 边界先运行持久化接口缺失与工具入口缺失的失败用例，再完成对应实现；仅控制随机源。 |
| 持久化 | 文件数据库关闭重开后，多列表名称、选项顺序及重复项均保留，编辑不生成额外列表；schema 9 升级保留原课程、调停课、任务和设置。 |
| 行为与适配 | 空列表、单选项、全部候选、重复点击、返回取消、显式取消、编辑取消、长名称和长选项通过；覆盖 320／393 逻辑宽、1／2 倍文字和上下安全区，操作及完整文本可滚动访问。 |
| 绘制与落位 | 六候选各采集 10 个转动阶段及停稳帧；采样固定指针下真实像素颜色，核对最终扇区与候选一致；3.0 秒时仍未揭晓，3.1 秒完成。帧图在 `build/wheel-preview/`，是宿主 Flutter 绘制证据，不作为 Android 截图。 |
| 全量回归 | `flutter test --no-pub --reporter expanded` 共 108 项通过，包含既有 100 项及本任务 8 项。日志：`build/task11-full-tests.log`。 |
| 审查修正回归 | 提取共用工具卡片／纸张裁剪器并补勾选图标后，转盘界面、逐帧绘制和骰子／硬币界面共 12 项再次通过。 |
| 静态检查 | 最终功能及审查修正代码 `flutter analyze --no-pub` 无问题。 |
| 构建 | 正式 `lib/main.dart` 入口 Android debug APK 与 Web 构建通过，Web 使用 `--no-web-resources-cdn`。没有执行浏览器交互验收。 |
| Android 集成 | 现有 API 36 模拟器通过工具入口、新建命名、六候选落位、重复文字提示、多列表编辑及进程重启恢复。最终两阶段使用同一专用数据库 `unipocket_wheel_20261026_b`，期间仅结束进程，保留应用数据。 |

最终 Android 流程：

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/wheel_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_wheel_20261026_b
adb shell am force-stop com.hongbozcode.unipocket
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/wheel_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_wheel_20261026_b --dart-define=ACCEPTANCE_RESTORE=true
```

截图为 1179×2556／density 480，即 393 逻辑宽；验收后恢复设备原始屏幕设置并以正常随机源的正式入口 APK 替换测试入口。没有卸载应用或清除原数据。320 宽和双倍文字的覆盖来自宿主界面测试；本轮未宣称实体设备性能、固定帧率或整版发布验收已经完成。

## Android 截图

- [工具入口](evidence/11-android-tools.png)、[空状态](evidence/11-android-empty.png)、[等待转动](evidence/11-android-ready.png)。
- [食堂一楼](evidence/11-android-result-1.png)、[食堂二楼](evidence/11-android-result-2.png)、[面馆](evidence/11-android-result-3.png)、[盖饭](evidence/11-android-result-4.png)、[轻食](evidence/11-android-result-5.png)、[饺子](evidence/11-android-result-6.png)。
- [重复文字提示](evidence/11-android-duplicates.png)、[重启恢复后转动](evidence/11-android-process-restored.png)、[当前列表勾选](evidence/11-android-picker.png)、[编辑后的第二列表恢复](evidence/11-android-list-restored.png)。

截图来自实际 Flutter Android 运行；源图和 HTML 仅作为视觉及动作依据。已检查最终面馆截图，指针、文字方向及结果一致，未遮挡扇区文字。

## 审查

按 `code-review` 技能，以 `9a3cb58` 为固定基线，由两个独立子代理分别完成 Standards 与 Spec 审查；两轴均复查 `d36e9fe` 的修正。子代理进行了静态检查，没有重跑测试或构建。

## Standards

复查 `c609c67..d36e9fe` 及相对 `9a3cb58` 的完整改动，原问题均已解决：

- 列表选择器增加勾选图标，选中状态不再仅靠颜色表达。
- 三种工具入口共用私有 `_ToolCard`，重复卡片结构已消除。
- 转盘、骰子和硬币共用 `ResultPaperClipper`，纸张裁剪逻辑不再分叉。

未发现新增的规范违规或值得报告的 baseline smell。本轮为静态复查，未重跑测试或构建。

Standards：剩余硬性问题 0 项、判断性 smell 0 项，无阻断项。

## Spec

复查 `c609c67..d36e9fe`，0 项问题，无需求回归。

选择器新增勾选图标，让当前列表的选中状态同时具有图标反馈，符合视觉规范。`_ToolCard` 提取保留了三个工具的入口、素材、配色和随机源传递；`ResultPaperClipper` 与原撕边路径等价。集成测试仅新增选择器截图，未改变业务行为。

原需求审查结论保持：Spec 无阻断项。本轮为静态复查，未重跑测试。

Standards 0 项／Spec 0 项，两轴均无阻断项。
