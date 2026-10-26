# 任务 13 检查记录

日期：2026-10-26。范围：[抽签与持久化签池轮次](../issues/13-lottery-pool.md)。分支：`codex/dev13`。实现前基线：`672783b7246753d57c7f441e9dd83e5c2cf2a004`；实现提交：`4fbc7a7`；审查修正：`397b137`。

## 实现与范围

- 工具页新增抽签入口，支持新建、命名保存、切换和编辑多个独立签池，不共享点名或转盘列表。签项逐张输入，可包含换行，不限制为示例长度。重复签文即时提示，每张签独立保留，分别占一份机会。
- 不重复模式从本轮剩余签项中等概率选择；重复模式每次使用完整签池，展示完整签池内容，不显示耗尽进度。每次触发只调用一次 `Random.nextInt(候选数)`，装饰动作不消耗随机源。
- 每份签池分别持久化模式、轮次、已抽位置序列和结果。相同签文按位置区分；离页与重启保留进度，耗尽后必须主动开始新一轮。编辑前、重置及模式切换均说明重置影响，取消编辑或确认保留原进度。
- 触发即选定临时结果，1600ms 反馈完成后才写入；同一抽取重复完成共享一次事务。签池修订号防止旧反馈覆盖编辑、新轮次或另一已完成抽取。取消后不能提交，完成或取消后清理临时结果。
- 播放中锁定编辑、签池选择、模式切换、重置及重复触发；显式取消、顶部返回、系统返回与进入后台取消未提交抽取。系统返回立即取消，不等待路由退出动画；短暂的事务提交阶段锁定退出。
- 空签池可保存但不能抽取；无签池、耗尽、读取／保存失败及重试均有可见状态。读取失败不清空原数据，修改失败不替换原签池或轮次。
- SQLite schema 11 升至 12，仅新增签池表。真实迁移测试保留学期、课程、DDL、调停课、转盘以及点名轮次；既有迁移测试继续通过。未新增依赖、未安装环境，`pubspec.lock` 未改变；使用现有 Flutter 3.47.7／Dart 3.13.5 和 API 36 模拟器。

## 视觉与动作

依据：[抽签源图](../../../docs/design/resources/random-tools/03-抽签.png)、[当前 HTML 样板截图](../../../docs/design/qa/lottery-v3-result.png)、[视觉规范](../../../docs/product/design.md)，以及 `docs/design/motion-demo.js` 的 lottery 分支和 `motion-demo.css`。

- 复用桃色签袋 PNG、浅黄／淡紫白边星星、抽签／返回／随机图标及低强度纸纹。浅蓝白底、淡蓝签池按钮、淡紫模式选中态、桃色场景、白色进度卡和蓝色主操作与参考对应。
- 按源码采用 850ms 摇袋、750ms 升签，以及 `cubic-bezier(.18,.72,.2,1)` 曲线。摇袋角度依次为 0／−9／8／−5／3／0 度；纸签从下方 154px 升起，越过终点 7px 后回落，最终保持 −4° 倾斜。纸签下部由袋身遮挡，取消和新一轮恢复初始姿态；减少动效设置下缩短反馈。
- 短签文按字竖排，五字签文完整露在袋口上方；长签文按源码横排，在纸签内的 92px 区域滚动，并在下方以随文字缩放的完整文本提供选择复制。纸签内文字属于固定尺寸场景，完整文本承担放大阅读。
- 320／393 逻辑宽、1／2 倍文字、上下安全区域、长签池名、多行长签文、空签池与滚动可达性均有界面回归。没有修改 HTML 手册、生成源或任务 triage 状态。

## 已运行验证

| 检查 | 结果与证据范围 |
| --- | --- |
| TDD | 签池／轮次接口和工具界面先失败再实现；审查发现的纸签长文问题先以缺少实际签文的界面断言复现失败，再补齐滚动并通过。 |
| 真实 SQLite | 多签池、重复签文独立、文件数据库关闭重开续轮；重复模式完整候选、取消、重复完成、并发旧反馈、编辑／重置使旧反馈失效、耗尽与主动重置、非法输入不破坏数据。schema 11 迁移保留学习数据及原点名进度。 |
| 界面 | 320／393 宽与 1／2 倍文字四种组合，完整多行签文及纸签实际拖动、空签池、编辑确认／取消／保存、模式切换确认、重复模式无耗尽条；显式取消、后台取消及播放期间锁定。 |
| 动效帧 | 0／150／450／850／900／1200／1599ms 绘制帧有变化；1600ms 前没有持久化，结束后仅写入一次。五字短签覆盖。帧图位于 `build/lottery-preview/`，宿主测试字体不作为中文排版验收依据。 |
| 最终全量回归 | `flutter test --no-pub --reporter expanded`：129 项通过；日志 `build/task13-full-tests-final.log`。 |
| 静态检查 | 修正后 `flutter analyze --no-pub` 无问题；`git diff --check` 通过。 |
| 构建 | 正式 `lib/main.dart` 入口 Android debug APK 与 Web 构建通过；Web 使用 `--no-web-resources-cdn`。没有浏览器交互验收。 |
| Android 集成 | API 36 模拟器从工具入口建立同文签项及多行长签文，保存多签池、取消编辑、反馈末段系统返回不消耗；保留数据停止进程后恢复结果与轮次，再继续抽取长签文、实际拖动纸签内文本并切换重复模式。 |

最终 Android 两阶段使用专用数据库 `unipocket_lottery_20261026_c`，期间没有卸载应用或清除数据：

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/lottery_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_lottery_20261026_c
adb shell am force-stop com.hongbozcode.unipocket
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/lottery_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_lottery_20261026_c --dart-define=ACCEPTANCE_RESTORE=true
```

截图为 1179×2556／density 480，即 393 逻辑宽。验收后恢复模拟器原始 1080×2400／density 420，并用正常随机源的正式入口 APK 替换测试入口。320 宽与双倍文字来自宿主测试，不代表实体手机验收；没有宣称固定帧率或整版发布验收完成。

## Android 截图

- [工具入口](evidence/13-android-tools.png)、[无签池](evidence/13-android-empty.png)、[逐张编辑与重复提示](evidence/13-android-editor.png)、[等待抽签](evidence/13-android-ready.png)。
- [五字签文与本轮进度](evidence/13-android-result.png)、[编辑重置确认](evidence/13-android-edit-confirm.png)、[第二份空签池](evidence/13-android-empty-pool.png)。
- [进程恢复原结果](evidence/13-android-process-restored.png)、[继续抽中长签文](evidence/13-android-long-result.png)、[纸签内实际滚动](evidence/13-android-slip-scrolled.png)、[完整长文与已抽记录](evidence/13-android-full-text.png)。
- [多签池选择](evidence/13-android-picker.png)、[可重复模式](evidence/13-android-repeat.png)、[恢复后的工具入口](evidence/13-android-tools-restored.png)。

截图来自实际 Flutter Android 运行，已逐一对照源图与 HTML 样板检查；源图和 HTML 截图不作为应用行为证据。

## 审查

按 `code-review` 技能，从固定基线 `672783b` 对 `4fbc7a7` 进行 Standards／Spec 两个独立子代理审查，再复核 `397b137`。子代理只做静态审查，测试和平台验收由主代理执行。

## Standards

原 1 项 P2 规范问题已解决：长签文现在在纸签内展示实际文字并支持滚动，下方完整文本保留；五字竖排间距已修正并补充验证。未发现剩余明确规范违规。

保留 1 项非阻断维护建议：抽签与点名的反馈生命周期存在重复逻辑，未来修改取消竞态需同步维护。本次保留既有点名行为，未跨工具重构；两个工具的数据仍独立。

Standards：规范问题 0 项，非阻断维护建议 1 项。

## Spec

原长签文 P2 已解决。未发现新的缺失、范围扩张或行为错误。

Spec：剩余 0 项，无阻断项。

两轴均无阻断项；Standards 保留 1 项非阻断维护建议，Spec 0 项。
