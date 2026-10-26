# 任务 14 检查记录

补录日期：2026-10-26。范围：[随机分组](../issues/14-random-groups.md)。本记录依据当前代码、测试、现存运行日志及已提交截图整理；本次补录没有重新运行应用测试、构建或 Android 集成。

实现前基线：`735d195ca8a613ba12ef6f6531cdb7df25dbe799`；实现提交：`3bb4479`；修正提交：`bc8eb47`；Android 截图提交及本次补录前 HEAD：`7182795`。

## 实现与范围

- 工具页提供随机分组入口，支持多份名单命名保存、读取、切换和编辑。每位成员具有独立身份及可选学号／备注，同名成员分别保留，不与点名、抽签或转盘共享列表。
- 分组前采用 Fisher–Yates 洗牌，再循环分配成员。按组数分组时人数最多差 1；按人数上限计算所需组数后均衡分配，10 人上限 4 得到 4／3／3。每位成员恰好出现一次，没有指定同组或避开同组规则。
- 空名单可保存但不能分组；名单名称、成员姓名与身份、非正整数参数、组数超过人数均有错误反馈。修正提交补齐长名单离屏空姓名的明确错误提示，原数据保留。
- 分组期间锁定名单编辑、参数与重复触发；显式取消、返回及进入后台清理未完成结果。完成后清除临时名签，保留本页结果；离页后重新进入不恢复分组结果，名单持久保存。
- SQLite schema 12 升至 13，新增独立分组名单表；迁移测试覆盖既有学习数据、转盘、点名及签池轮次保留。

## 视觉与反馈覆盖

现有实现使用[随机分组源图](../../../docs/design/resources/random-tools/02-随机分组-v2-水平标签.png)、[HTML 样板](../../../docs/design/qa/live-v2-groups.png)及已有分组插画资源，采用洗牌后逐张发牌反馈。完成后姓名标签水平排列，姓名和识别信息可换行；分组纸卡可纵向滚动。

界面测试覆盖 320／393 逻辑宽、1／2 倍文字、上下安全区、长名单名与长姓名；40 人分 20 组可滚动到末组。10 人的动效测试覆盖 800ms 洗牌及随后发牌，1865ms 完成且临时名签清理。这里记录既有实现与测试覆盖，本次没有重新进行视觉验收。

## 已有验证证据

以下为补录时核对的此前运行结果，日志位于本地 `build/`，可能随构建清理；关键 Android 截图已提交至仓库。

| 检查 | 结果与证据 |
| --- | --- |
| 真实 SQLite 与可控随机源 | [业务测试](../../../test/groups_test.dart)覆盖文件数据库重开、多名单、同名身份、跨工具独立、schema 12 迁移、洗牌调用及分配结果、每人一次、人数边界和非法输入。 |
| 界面与动效 | [界面测试](../../../test/groups_ui_test.dart)覆盖长文本、缩放、取消、后台、系统返回、播放锁定、重新进入及大名单滚动；[动效测试](../../../test/groups_motion_test.dart)覆盖反馈时序与临时状态清理。 |
| 全量回归 | `build/task14-full-tests-final.log`：139 项通过，末行为 `All tests passed!`。 |
| Android 集成 | `build/task14-android-create-reviewed.log` 与 `build/task14-android-restore-reviewed.log` 均通过；[集成脚本](../../../integration_test/groups_flow_test.dart)覆盖从工具入口建名单、同名成员、10 人上限 4 得到 4／3／3、取消编辑、非法组数、按组数分配、多名单，以及新进程读取名单和身份信息后再次分组。 |
| Android 构建 | `build/task14-android-build.log` 记录 debug APK 构建成功。 |
| Web 构建 | `build/task14-web-build.log` 记录 `lib/main.dart` 构建成功；日志同时含 CupertinoIcons 字体查找警告，不能据此声称构建无警告。 |

## Android 截图索引

- [工具入口](evidence/14-android-tools.png)、[无名单](evidence/14-android-empty.png)、[成员编辑](evidence/14-android-editor.png)、[等待分组](evidence/14-android-ready.png)。
- [10 人上限 4 的结果](evidence/14-android-result.png)、[非法组数](evidence/14-android-invalid.png)、[按组数分配](evidence/14-android-count-result.png)。
- [多名单选择](evidence/14-android-picker.png)、[第二份空名单](evidence/14-android-empty-list.png)。
- [新进程恢复名单](evidence/14-android-process-restored.png)、[恢复后再次分组](evidence/14-android-result-restored.png)、[恢复后的名单选择](evidence/14-android-picker-restored.png)、[恢复后的工具入口](evidence/14-android-tools-restored.png)。

## 补录结论与边界

任务 14 的 5 项验收条件均有现有代码、测试及运行证据支持，已回填任务文件。任务 12、13 的既有验收与审查记录保留，本次同步补齐各自任务文件的勾选及完成说明。

本次未恢复完整的历史两轴审查报告，也未补做两轴代码审查；修正提交本身不作为两轴审查全部通过的证明。未重新运行静态分析、测试、构建、Android 集成或浏览器交互验收；未宣称实体手机、固定帧率或整版发布验收完成。
