# 任务 5：单次调课与停课验收

日期：2026-10-25。范围为 [05-class-exceptions](../issues/05-class-exceptions.md)，业务与测试边界以首版规格为准。课程提醒联动由任务 08 交付。

## 实现与自动验证

| 检查 | 实际结果 |
| --- | --- |
| 单次调课 | 从首页、今日或周网格点击具体课次，选择日期、开始／结束时间和地点；支持跨周、自由时间及学期外补课。以原安排身份＋原日期保存关联，再次调整不改变最初关联。 |
| 其他课次 | 原日期只移除被调整的课次；目标周原有课程、同课程其他安排及后续周课次保留。 |
| 单次停课 | 确认页说明只取消一个原课次及其调课；不删除课程与重复安排。取消编辑不写入，已停课记录仍可从本学期课程详情管理。 |
| 一致展示 | 首页、今日和周课表共用有效实例计算。与目标日节次吻合的调课按目标节次进入网格；其余在“节次外调课”中完整显示实际日期、时间、地点和原课次。 |
| 冲突 | 调课按目标日有效实例检查重叠；返回修改／确认前不写入，确认可保留。同一安排在目标日原有的另一个课次参与冲突检查；后续录课也使用有效课次，停课不继续占用原时段。 |
| 持久化与校验 | 真实文件 SQLite 关闭重开后，跨周调整、再次调课、停课及原关联保留。无效时间或不存在的原课次不破坏已有记录。 |
| 数据库升级 | schema 4 → 5 增加调停课表；保留学期、每日节次、当前学期、课程与安排、任务完成状态和关联、事件置顶及校园时区。旧 schema 1／2／3 升级回归通过。 |
| 校园时间 | 日期以校园日历解释；无节次日／学期外调课仍可查看，更改手机时区不移动校园课次。 |
| 布局 | 320／393 逻辑宽度 × 1／2 倍文字、安全区域、长课程名和地点、错误反馈、滚动保存及停课确认均通过，无布局异常。 |
| 测试 | `flutter test --no-pub`：51 项通过；任务 5 新增 4 项应用行为／真实数据库测试及 6 项界面测试。 |
| 静态检查 | `flutter analyze --no-pub` 无问题；`git diff --check` 通过。 |
| 正式构建 | `flutter build apk --debug --no-pub --target=lib/main.dart` 与 `flutter build web --no-pub --no-web-resources-cdn` 通过。Android 安装并打开正式入口，保留原有应用数据。 |

遵循 TDD：跨周调课、有效冲突与停课、界面入口、学期外可见性分别先运行失败测试再实现；沿用已确认的应用行为入口与真实数据库边界。

## Android 两阶段验收

- 使用现有 Flutter 3.47.7／Dart 3.13.5、Android 模拟器 `emulator-5554`，没有安装环境或新增依赖。
- 测试入口 `integration_test/class_exceptions_flow_test.dart`，数据仅进入专用验收数据库，正式入口没有预置课程。
- 创建阶段：手机时区 Asia/Shanghai；真实日期选择器将 10 月 23 日高等数学调至 10 月 26 日，先返回冲突修改、再确认保留冲突；停课前取消编辑、再确认大学英语单次停课。随后用真实时间选择器把已调课次改至 10:00–11:40，原关联仍为 10 月 23 日。
- 两阶段间只结束进程，保留应用数据；设备改为 Pacific/Honolulu。恢复阶段断言设备偏移为 −600 分钟，校园时区仍为 Asia/Shanghai，首页与今日无原课次、目标周保留原课和补课、下一周的英语仍正常存在，停课记录可管理。
- 第一轮数据库 `unipocket_exceptions_20261025_a`：进程 13543 → 13803，两阶段通过。源图样例颜色与截图帧更新修正后，最终数据库 `unipocket_exceptions_20261025_b`：进程 13998 → 14193，两阶段通过，以下证据来自最终轮。
- 截图视口 1179×2556／density 480，即 393×852 逻辑尺寸；外部时钟固定为校园 2026-10-23 07:00 以对照参考图示例，示例日期不是拍摄日期。
- 验收后恢复设备原始 1080×2400／density 420、GMT 与自动时区值 1。

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/class_exceptions_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_exceptions_20261025_b --dart-define=ACCEPTANCE_PHONE_OFFSET=480
adb -s emulator-5554 shell am force-stop com.hongbozcode.unipocket
adb -s emulator-5554 shell cmd alarm set-timezone Pacific/Honolulu
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/class_exceptions_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_exceptions_20261025_b --dart-define=ACCEPTANCE_RESTORE=true --dart-define=ACCEPTANCE_PHONE_OFFSET=-600
```

复现时先记录设备设置，关闭自动时区并设为 Asia/Shanghai；每轮更换数据库名，两阶段保持同名，结束后恢复原设置。保留 `--keep-app-running`，避免测试驱动卸载应用。

## 源参考图与运行证据

依据 [首页与周课表效果图](../../../docs/design/resources/core-pages/01-首页与周课表.png)、[历史周课表截图](../../../docs/design/resources/screenshots/timetable.png)和现有视觉规范。复用浅蓝底、白色圆角卡片、淡紫选择态、原课程识别色及日历／时钟 SVG；调课保留课程颜色并增加文字标识。源参考未展开调停课表单，该状态沿用现有卡片与表单组件补齐。

- [首页源图对照](evidence/05-reference-home.png)、[周课表源图对照](evidence/05-reference-week.png)。
- [调课表单](evidence/05-android-editor.png)、[冲突确认](evidence/05-android-conflict.png)、[停课确认](evidence/05-android-cancel-confirmation.png)。
- [保存后的首页](evidence/05-android-home-saved.png)、[目标周原课与冲突补课](evidence/05-android-week-conflict.png)、[调整时间后的周课表](evidence/05-android-week-saved.png)。
- [新进程恢复](evidence/05-android-process-restored.png)。

以上为 Flutter Android 实际运行截图；源图笔触、字体及阴影与平台渲染存在差异，不宣称逐像素一致。放大文字和自由时间调课优先完整显示内容与操作。

## 两轴代码审查

用户确认基线 `08c1e84fd9c275e52e454d35780feeaad00110e9`；实现提交 `da67ac7`。审查命令 `git diff 08c1e84fd9c275e52e454d35780feeaad00110e9...HEAD`，两名独立子代理分别审查以下两轴。

### Standards

未发现文档标准硬性违反，也未发现需要修复的明确代码异味。

- `docs/architecture.md`：业务校验与有效课次计算位于应用行为层／领域模型，SQLite 表、迁移和写入集中在存储模块，没有新增空远程层或机械转发层。
- `GLOSSARY.md`：课程、上课安排、具体课次与单次调停课保持区分；原关联使用安排身份与原日期，目标日期不替代原课次身份。
- 首版规格的 Testing Decisions：新增测试通过公开应用操作使用真实 SQLite，覆盖文件重开、迁移、冲突确认前不写入及非法输入不破坏已有数据。
- `docs/product/design.md`：复用已有配色、SVG、卡片及表单组件；具备文字状态、校园时区、安全区域、滚动和长文本适配。已检视 Android 周课表与调课表单截图，符合现有蓝紫浅色视觉体系。

Standards：0 项硬性违反、0 项明确维护问题；本轴无未关闭问题。

### Spec

未发现需要修复的规格偏差（0 项）。

- “跨周，保留原实例关联，不改变其他课次及目标周原有课程”：以原安排 ID＋原日期保存例外；再次调课仍使用最初关联，目标周原课次保留。
- “单次停课仅取消该次显示”：由同一例外记录表达；没有删除课程或重复安排。
- “首页、今日视图和周课表一致显示有效实例”：通过共同的 `Timetable` 计算实现。节次外调课提供日期、实际时间和地点列表；冲突确认前不写入，确认后可保存。
- “取消编辑不改变数据，变更重启后仍保留”：已有真实 SQLite 文件重开、界面操作和 Android 两阶段测试覆盖；升级保留原有课程、任务、事件及校园时区。
- 对照源图和最终 Android 截图：保留课程识别色、浅蓝背景、白色圆角课表、淡紫切换与导航；新增表单复用现有卡片和资源。未发现本次变更引入的明确视觉偏差。

没有发现无关功能扩张。重复安排影响处理和提醒联动分别属于任务 6、8，不计为任务 5 缺项。

Spec：0 项发现，无未关闭问题。

两轴合计：Standards 0 项、Spec 0 项，各轴均无未关闭问题。

## 明确边界

任务 5 不交付重复安排变更影响处理或系统提醒；未做真机通知或整版发布验收。Android 行为证据来自模拟器，Web 仅做构建检查。既有 SVG filter 简化与 Gradle Java 原生接口提示未阻断验收。
