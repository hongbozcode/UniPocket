# 任务 7 检查记录

日期：2026-10-25。范围：[DDL 提醒与通知权限反馈](../issues/07-ddl-notifications.md)。用户确认本次暂用模拟器，真机验收后续完成；本记录不代表整版发布验收。

## 实现范围

- DDL 默认提前 1440 分钟（1 天），每项一个提醒；可调整为 0 至 525600 分钟或关闭，0 表示截止时提醒。配置随任务保存在真实 SQLite，Drift schema 6 → 7；旧版任务保留内容和完成状态，并获得默认提醒配置。
- 保存、编辑、完成、撤销和删除经共同应用入口 `SemesterPlanner` 更新未来提醒。校园日期与分钟按校园时区解释并转换为绝对时刻；改变手机时区不参与计算，改变校园时区会重算。
- 过去及恰好到达的提醒不补发；表单预览及保存反馈明确提示。完成和关闭取消提醒，撤销只重建仍在未来的提醒。切换当前学期不会移除独立 DDL 的提醒。
- 数据提交与系统提醒分开：通知权限关闭或系统调用失败不回滚已保存数据；保存、完成、撤销和删除的反馈区分两种结果，可从提醒卡重试。
- Android 使用现有 SDK 的 `AlarmManager`、通知渠道和运行时权限，通过一个 Flutter 平台通道接入，没有新增依赖或安装开发环境。`LocalNotifications` 按业务范围替换提醒，DDL 范围不会清空未来课程／事件范围；当前没有预建其业务接入。
- 闹钟使用 `setAndAllowWhileIdle`，不请求精确闹钟特殊权限；系统允许批量与延迟投递。私有缓存仅用于系统投递，SQLite 是业务真相；清除、重算按真实数据进行。系统重启、应用替换和手动改系统时钟后，接收器只重建仍在未来的缓存提醒。
- 实际通知状态同时检查应用通知许可和学习提醒渠道，提供“允许通知”、系统通知设置及刷新入口。应用回到前台重新查询。Web 明确显示不支持本地通知，学习数据仍可使用。

## 已运行的验证

| 检查 | 结果与边界 |
| --- | --- |
| `flutter doctor -v` | 既有 Flutter 3.47.7 / Dart 3.13.5、Android SDK 36 和 JDK 可用，无需安装。Chrome 缺失不影响 Android 与 Web 构建。 |
| `flutter analyze --no-pub` | 通过。 |
| `flutter test --no-pub` | 70 条通过，含任务 1–6 回归、新增 4 条真实 SQLite 提醒行为测试及 4 组界面测试。 |
| 真实 SQLite 与受控外部边界 | 默认提前一天、文件重开、编辑替换、完成／撤销、关闭、删除、提醒时间已过和截止边界、通知禁用、系统调用失败后仍保存、失败重试及无效配置拒绝写入。 |
| 数据库升级与校园时间 | 从既有 schema 5 升级，原任务、课程和完成状态保留；纽约夏令时结束日的提醒转换使用独立预期时刻。已有 schema 1–4 升级测试继续通过。 |
| 布局与可达性 | 320／393 宽度 × 1／2 倍文字，上下安全区域、长标题、提醒开关、提前分钟数、保存和设置入口通过，无溢出。原任务表单测试随新增内容改为滚动后访问备注。 |
| 提示生命周期 | 保存结果由返回后的所属页面展示；进入表单前移除遗留提示，避免遮挡删除。任务页完成／撤销提示仍随所属页面关闭。 |
| Android 构建 | 正式 `lib/main.dart` 调试 APK 构建通过；原生 Kotlin 通道及通知接收器也由 Android 集成测试编译执行。 |
| Web 构建 | `flutter build web --no-pub --no-web-resources-cdn` 通过；未新增浏览器运行验收。 |

## Android 模拟器验收

- 设备：已有 Android 16 / API 36 `emulator-5554`。专用数据库：`unipocket_ddl_20261025_a`，正式入口不预置验收数据。
- 初始进程 `16971`：通过真实表单将“论文终稿”的提前提醒改为 30 分钟，系统记录的未来闹钟同步变化；实际系统通知设置入口正常。
- 将应用退到后台后使用 `am kill` 结束进程（不是强行停止）。测试提醒计划在校园时间 16:47，系统窗口允许延迟约 1 分 47 秒；16:49:06 查询到 `learning_reminders` 渠道中的“任务7·送达验收”，接收器进程为 `17231`。对应的系统通知记录见[送达记录](evidence/07-android-delivery.txt)。模拟器系统界面时区为 UTC，通知内的校园时间仍为 Asia/Shanghai。
- 关闭应用通知权限后，新进程 `17389` 读取同一数据库，30 分钟配置保留；应用显示真实关闭状态，仍可保存“权限关闭仍保存”任务，DDL 未来闹钟已清除。原生系统设置的关闭状态另行采集。
- 全程使用 `--keep-app-running` 保留应用数据，没有用卸载重装代替恢复；通知权限属于当前模拟设备，没有写入数据库或跨设备恢复。

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/ddl_notifications_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_ddl_20261025_a
adb -s emulator-5554 shell pm revoke com.hongbozcode.unipocket android.permission.POST_NOTIFICATIONS
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/ddl_notifications_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_ddl_20261025_a --dart-define=ACCEPTANCE_RESTORE=true --dart-define=ACCEPTANCE_BLOCKED=true
```

## 源图与运行证据

依据：[学习任务效果图](../../../docs/design/resources/core-pages/02-学习任务与倒计时.png)、[设置效果图](../../../docs/design/resources/core-pages/04-设置.png)及对应历史运行截图。新增提醒组沿用浅蓝白背景、淡紫圆角卡、紫色铃铛、绿色状态胶囊与蓝色操作，常规宽度同行、大字号换行。任务列表布局保持源图的既有实现。

- [任务提醒表单](evidence/07-android-editor-restored.png)：单项配置、校园提醒时刻及当前设备通知状态。
- [设置提醒卡](evidence/07-android-settings.png)：真实开启状态、默认时间、系统设置与刷新入口。
- [通知关闭反馈](evidence/07-android-permission-blocked.png)、[真实系统设置](evidence/07-android-system-settings.png)与[系统关闭状态](evidence/07-android-system-blocked.png)。

均为实际 Flutter Android 或 Android 系统运行证据。采集参数 1179×2556 / density 480（393 逻辑宽）；结束后恢复原 1080×2400 / density 420。复用项目 `bell.svg`，系统通知小图标是同一路径的白色 Android Vector 版本，没有新增第三方素材。

## 两轴代码审查

固定基线：`0797ca4b833efb86ca55ea54961fbf53a0152698`（开始实现前的当前 HEAD）。实现提交后按 `code-review` 技能进行 Standards 与 Spec 两个独立子代理审查，结果将在完成后补充。

## 明确边界

- 真机送达、真机权限关闭和真机系统设置入口未验收，用户已确认后续完成；任务第 5 条验收项因此保持未勾选。
- 模拟器实际投递成功不保证所有厂商、省电策略、关机或强行停止下准时送达。实现不申请精确闹钟特殊权限，也不承诺准点。系统重启重建接收器已实现，但本次未执行整机重启验收。
- 课程与倒计时提醒、备份恢复属于后续任务；学校 XLSX 仍等待真实样例。没有修改首版范围或重建视觉手册。
- 既有 SVG filter 简化、Gradle Java 原生接口和 Web 字体裁剪提示未阻断验证。
