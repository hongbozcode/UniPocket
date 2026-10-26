# 任务 16：导入候选结果的预览、纠错与原子提交

日期：2026-10-26。分支：`codex/dev16`。实施前基线：`538dbbf2b76e1885c1d914fa4256d7faafebe03e`。

实现提交：`33da5cb`；用户追加的人性化提示、排版优化与审查修复：`759d9ef`。

## 范围与行为

- `ImportPreviewPage` 接收候选加载函数、来源名称及可选初始学期；这是任务 17 的解析器接入位置。本任务不在正式应用中提供测试候选入口，也不提供学校文件选择或 XLSX 解析。
- 目标学期可以切换，按对应节次和教学周重新检查；导入不会自动更改当前学期。课程名称、教师、多个上课安排、星期、起止节次、地点与教学周可修正；识别问题须明确核对，或取消勾选该课程。未处理错误始终阻止提交。
- 候选标识、来源说明、识别错误与重复说明由解析器提供。重复标记默认不选中；用户可查看说明并主动恢复选择。本模块不推断课程身份、学校行号或精确去重键，不承诺对任意 XLSX 自动去重。
- 时间冲突使用既有有效上课实例逻辑，包含已有课程、调停课、独立补课及本次候选之间的冲突。预览与提交事务均检查；冲突变化须重新确认，之前的确认不能批准后来新增的冲突。
- 选中课程及安排在一个真实 SQLite 事务内保存；任一写入失败全部回滚。取消不写入。同一预览正在提交或提交成功后再次触发，返回同一提交结果；失败后允许重试。提醒只在事务成功后统一刷新，沿用原通知范围。
- 数据沿用现有课程和安排结构，schema 保持 14，无新增依赖、迁移、学校模板假设或 Android 原生修改。

## 人性化提示与版式

参考[首页与周课表源图](../../../docs/design/resources/core-pages/01-首页与周课表.png)、[课表历史截图](../../../docs/design/resources/screenshots/timetable.png)及[视觉规范](../../../docs/product/design.md)，复用蓝白底、淡紫摘要、白色圆角卡片、课程色和书本／警告／完成图标。

- 顶部依次是“核对一下课表”、来源、目标学期和选中／待核对／跳过数量，避免堆叠长段说明。
- 课程卡把名称、状态与勾选放在一起，安排使用局部浅色区域；连续教学周压缩为区间。
- 待核对信息用浅黄色温和提示；来源与全部错误放入详情。重复及已跳过课程默认收起，可展开查看、修改或重新勾选。
- 冲突独立展开，确认弹窗逐条展示，使用“保留并导入”；普通确认使用“确认导入”。
- 保存失败提示“这次没能保存，请再试一次。没有加入任何新课程，原来的课表还在。”，紧邻提交操作；保存期间按钮显示旋转进度和“正在加入课表…”。成功后明确显示课程数量与目标学期。
- 界面测试覆盖 320 宽、双倍字号、上下安全区、长课程名、滚动末项及 393 宽流程。未观察到溢出；HTML 截图仅作参考，不作为 Android 实现证据。

## 验证

| 检查 | 实际结果 |
| --- | --- |
| 任务定向测试 | 5 项业务测试与 5 项界面测试通过；最新界面日志 `build/task16-ui-final.log`。 |
| 完整回归 | `build/task16-full-tests-final.log`，155 项通过。 |
| 静态分析 | `build/task16-analyze-final.log`，`No issues found!`。 |
| 数据持久化 | 真实 SQLite 文件关闭重开后，目标学期、课程、安排与当前学期保持正确；同一预览并发／再次提交仅写入一次。 |
| 原子回滚 | 业务测试在第二门课程写入时用 SQLite trigger 触发失败，验证第一门课程和安排也回滚，已有课程保留；移除故障后同一预览可重试。Android 在安排写入失败后验证无孤立课程，重试成功。 |
| UI 失败与防重 | 加载失败重试、切换学期、取消确认、跳过错误、冲突确认和写入失败反馈通过。真实 SQLite 事务占用测试验证保存按钮原位进度及重复点击防重。 |
| 多安排编辑 | 两条原周一安排，把首条改为周三后删除；余下安排显示与保存均为周一。先运行失败测试，再用稳定身份 Key 修复并通过。 |
| Android 创建 | `build/task16-android-delivery.log` 通过；实际预览、纠错、排除、冲突确认、失败回滚、重试与课表展示均通过。 |
| Android 新进程恢复 | `build/task16-android-restore.log` 通过，同一文件数据库重开后课程、安排、首页与课表保留；创建进程 PID 5459，恢复进程 PID 5677。 |
| Web 构建 | `flutter build web --no-pub --no-web-resources-cdn --target=lib/main.dart` 通过，日志 `build/task16-web-build.log`。 |
| Android 主入口构建 | `flutter build apk --debug --no-pub --target=lib/main.dart` 通过，日志 `build/task16-android-build.log`。 |
| 差异检查 | 实现相对基线、最终任务文件及检查记录均执行 `git diff --check`。 |

Android 使用现有 Android 16 / API 36 x86_64 模拟器与独立数据库 `unipocket_task16_20261026_delivery`；测试数据始终标注“测试候选数据 · 非学校解析结果”。未清除普通应用数据库，没有安装或升级工具。保存失败反馈最初被弹窗焦点恢复拉回的滚动位置遮挡，最终改为在提交操作附近展示并复验通过。

`build/` 日志为本地忽略文件，截图随本记录版本控制。现有 SVG filter、Gradle/JDK native-access、SDK XML 和 Web 字体提示按实际日志保留，不宣称无警告构建。

## Standards

0 项未解决问题。首次建议把纯候选检查与提交回调分开，已拆为 `ImportAssessment` 与绑定真实提交操作的 `ImportPreview`，移除虚假回调及自引用闭包。最终复审通过。

## Spec

0 项未解决问题。审查发现的多安排星期状态复用、长列表保存反馈不可见均已修复并增加行为测试。错误详情、重复说明、恢复选择、编辑、冲突确认及任务 17 边界保留。

两轴最终审查范围为 `git diff 538dbbf2b76e1885c1d914fa4256d7faafebe03e...759d9ef`；Standards 0 项，Spec 0 项，两轴均无最高严重问题。

## Android 最终截图

- [导入预览](evidence/16-android-preview.png)、[修改课程信息](evidence/16-android-correction.png)。
- [跳过错误项与重复项](evidence/16-android-excluded.png)、[时间重叠详情](evidence/16-android-conflicts.png)、[确认导入](evidence/16-android-confirmation.png)。
- [写入失败回滚反馈](evidence/16-android-rollback.png)、[导入成功](evidence/16-android-success.png)。
- [导入后首页](evidence/16-android-home.png)、[导入后课表](evidence/16-android-timetable.png)。
- [新进程首页恢复](evidence/16-android-home-restored.png)、[新进程课表恢复](evidence/16-android-timetable-restored.png)。

## 学校模板与验收边界

用户提供的 `class_schedule_template/Hebei Normal University of Science & Technology/` 中已有 `xskb.xlsx` 与 `效果示例.jpg`，本次仅确认文件存在，未读取或解析学校内容。该目录保持 Git 忽略；没有把学校资料或个人课表提交到远程。任务 17 应使用真实文件确定字段、课程身份、合并单元格、来源定位与精确去重。

本任务证据来自真实 SQLite、Flutter 界面测试及 Android 模拟器，不代表实际学校适配、实体手机验收或整版发布验收。Web 仅作构建兼容性检查。

## 交付

用户已授权推送现有远程 `git@github.com:hongbozcode/UniPocket.git` 的 `codex/dev16` 分支。实现、提示与布局调整、任务验收勾选及本记录和截图在同一分支交付；最终提交与远程对齐结果在交付回复中报告。重跑 Android 首次阶段应使用新的 `ACCEPTANCE_DATABASE`，恢复阶段使用同名数据库并加 `ACCEPTANCE_RESTORE=true`。

## 后续：模拟器手动点击停留首页

2026-10-26，用户反馈点击“测试导入数学”没有进入详情。跟进基线 `acf9a6a`，修正提交 `d8206ec`。

**实际原因与对照验证：** 模拟器里仍安装着 `integration_test/import_preview_flow_test.dart` 生成的自动验收包。重新启动会自动运行测试；`adb logcat -d -s flutter` 显示 `All tests passed!` 后，实际鼠标点击触发的是 `Test finished.` 的测试查找器输出。截图表面的首页画面仍保留，真实点击由测试绑定处理，没有正常导航。同一份 SQLite 数据使用正常 `WidgetsFlutterBinding` 运行后，实际鼠标点击“测试导入数学”和“测试原有课程”均打开对应详情并能返回首页。

原验收只检查导入后首页／课表展示，未覆盖这两个课程入口；本次新增真实 SQLite 界面测试，覆盖导入、进入详情、编辑教师、保存、进入另一门课程及返回，验证始终只有两门课程。Android 集成也加入两个详情的点击及返回检查。

| 后续检查 | 结果 |
| --- | --- |
| 完整回归 | `build/task16-click-full-tests.log`，156 项通过。 |
| 静态分析 | `build/task16-click-analyze.log`，`No issues found!`。 |
| Android 详情导航 | `build/task16-click-android-final.log` 通过，同一验收数据库中的两门课程可分别进入详情并返回。 |
| 同一数据库人工对照 | 正常入口加载 `unipocket_task16_20261026_delivery`，通过桌面模拟器实际鼠标点击两门课程并返回；测试包与正常包的课程数据相同。 |
| 独立手动预览 | `build/task16-manual-preview-final.log`：正常入口编译、安装并启动成功；默认专用数据库首次初始化成功，实际点击导入课程进入详情并返回。 |
| 后续复审 | `git diff acf9a6a...d8206ec`：Standards 0 项，Spec 0 项。 |

补充截图：[导入课程详情](evidence/16-android-imported-course-detail.png)、[原有课程详情](evidence/16-android-existing-course-detail.png)。这两张来自自动导航补验；人工点击的结果另通过桌面模拟器观察确认。

### 人工体验与自动验收分别运行

人工预览使用正常 Flutter binding，默认读取独立数据库 `unipocket_import_manual_preview`。仅在空库时以一个事务创建示例学期和两门冲突课程，重启复用已有数据；不向正式应用数据库灌入样例。界面标注“导入演示学期（测试数据）”，展示时钟固定为 2026-08-31 08:15 校园时间，以便看到今日课程；导入课程使用淡紫色区分。

```powershell
flutter run --no-pub --no-resident -d emulator-5554 --target=tool/import_preview.dart
```

需要用原验收数据库做对照时，可以显式增加 `--dart-define=IMPORT_PREVIEW_DATABASE=unipocket_task16_20261026_delivery`。正式应用仍用 `lib/main.dart`，不含手动演示入口或固定时钟。

`flutter drive ... --target=integration_test/import_preview_flow_test.dart` 是自动验收流程。运行结束后应重新运行正常入口，再让用户手动体验；不能把 `--keep-app-running` 保留下来的测试包当作正常应用。此次已恢复正常预览包，模拟器保持打开供用户操作。
