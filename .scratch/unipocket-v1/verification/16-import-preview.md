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
