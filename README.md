# UniPocket

面向大学生的校园学习与生活工具。首版以离线学习管理、学校课表导入、随机工具及本地备份为核心，Android 优先。

## 现行依据

- [首版规格](.scratch/unipocket-v1/spec.md)：当前范围、用户故事、实施与测试决定；本地任务跟踪器中的权威实现依据。
- [产品定位](docs/product/overview.md)：用户、需求与长期目标。
- [视觉规范与资源索引 · AI 文档版](docs/product/design.md)：视觉表现与资源使用依据；区分通用规则和复杂动效参考。
- [设计手册 · HTML 可视化版](docs/design/index.html)：效果图与样板截图对照、交互说明、动效播放和可下载素材。
- [后续路线图](docs/product/roadmap.md)：首版以外的能力与尚未决定的方案。
- [架构方向](docs/architecture.md)：已定约束、技术候选与后端演进原则。
- [领域术语](GLOSSARY.md)：课程、上课安排、任务及抽取轮次等定义。

## 维护与验证

- [代理说明](AGENTS.md)：项目工作约定，以及任务跟踪、分类和领域文档入口。
- [手册维护说明](docs/design/README.md)：设计文档维护源、生成方式和检查范围。
- [视觉手册规格](.scratch/visual-design-library/spec.md)：手册的需求、交付边界与验收约定。
- [设计检查记录](docs/design/verification.md)：已验证内容、证据与限制。

## 历史资料

- [产品讨论记录](.scratch/product-design/discussion.md)：当时的讨论与决定，不替代现行规格。
- [设计生成记录与截图索引](docs/design/resources/README.md)：提示词、页面截图及检查证据。

## 实现进度与检查记录

当前仓库已实现任务 1–18 的功能，支持 Flutter Android/Web 构建（系统备份文件操作仅开放 Android）：

- 学习管理：离线学期、每日节次、校园时区、手动录课、今日／周课表、学习任务、倒计时事件、单次调停课、重复安排变更影响处理、课程删除后保留 DDL，以及学习任务／有效课程／倒计时事件本地提醒与真实通知状态反馈。
- 随机工具：六面骰／硬币（翻滚／翻面与落地回弹）、多列表自定义转盘（旋转与指针落位）、多名单随机点名（持久化轮次与姓名滚动）、多签池抽签（持久化轮次、摇袋、升签与长文滚动）、独立名单随机分组（按组数或人数上限均衡分配、洗牌与逐张发牌），以及统一搜索、收藏、最近使用和首页常用入口。
- 学校导入：河北科技师范学院真实 XLSX 文件选择与离线解析，目标学期、逐项纠错／跳过、精确重复标记、冲突确认与原子提交。
- 本地备份：全部领域数据、工具列表及轮次、收藏与最近使用完整导出，校验后确认覆盖，事务失败完整回滚，恢复后依据当前设备权限重建未来提醒。

任务 7–9 仍待实体 Android 真机验收；任务 19 整版发布验收及真实学校导入数据迁移联验尚未交付。任务 17 已按用户确认的实际格式与身份／去重规则完成；任务 18 已验证手动领域数据的 Android 文件操作、干净安装恢复和提醒重建。各次检查的证据与限制以对应记录为准，不把模拟器结果视为真机或整版验收。

| 任务 | 检查记录 |
| --- | --- |
| 01 · 应用工程与学期配置 | [任务 1 检查记录](.scratch/unipocket-v1/verification/01-bootstrap-semester.md) |
| 02 · 手动录课与课表 | [任务 2 检查记录](.scratch/unipocket-v1/verification/02-manual-timetable.md) |
| 03 · 学习任务 | [任务 3 检查记录](.scratch/unipocket-v1/verification/03-learning-tasks.md) |
| 04 · 倒计时事件 | [任务 4 检查记录](.scratch/unipocket-v1/verification/04-countdown-events.md) |
| 05 · 单次调课与停课 | [任务 5 检查记录](.scratch/unipocket-v1/verification/05-class-exceptions.md) |
| 06 · 重复安排变更与删除影响 | [任务 6 检查记录](.scratch/unipocket-v1/verification/06-schedule-impact.md) |
| 07 · DDL 提醒 | [任务 7 检查记录](.scratch/unipocket-v1/verification/07-ddl-notifications.md) |
| 08 · 有效课程提醒 | [任务 8 检查记录](.scratch/unipocket-v1/verification/08-class-notifications.md) |
| 09 · 倒计时事件提醒 | [任务 9 检查记录](.scratch/unipocket-v1/verification/09-event-notifications.md) |
| 10 · 掷骰子与抛硬币 | [任务 10 检查记录](.scratch/unipocket-v1/verification/10-dice-coin.md) |
| 11 · 自定义转盘 | [任务 11 检查记录](.scratch/unipocket-v1/verification/11-custom-wheel.md) |
| 12 · 随机点名 | [任务 12 检查记录](.scratch/unipocket-v1/verification/12-random-roll-call.md) |
| 13 · 抽签 | [任务 13 检查记录](.scratch/unipocket-v1/verification/13-lottery-pool.md) |
| 14 · 随机分组 | [任务 14 检查记录](.scratch/unipocket-v1/verification/14-random-groups.md) |
| 15 · 工具发现与首页常用入口 | [任务 15 检查记录](.scratch/unipocket-v1/verification/15-tool-discovery.md) |
| 16 · 导入预览、纠错与原子提交 | [任务 16 检查记录](.scratch/unipocket-v1/verification/16-import-preview.md) |
| 17 · 真实学校 XLSX 导入 | [任务 17 检查记录](.scratch/unipocket-v1/verification/17-school-xlsx.md) |
| 18 · 完整本地备份与覆盖恢复 | [任务 18 检查记录](.scratch/unipocket-v1/verification/18-backup-restore.md) |

设计手册、效果图、HTML 样板截图和六项随机工具的[独立动效演示](docs/design/motion.html)仍是设计参考。原完整应用样板源码未纳入仓库；独立演示源码维护在 `docs/design/motion-demo.js` 和 `motion-demo.css`。

## 开发与运行

工程直接位于仓库根目录，应用标识为 `com.hongbozcode.unipocket`。使用 Flutter 3.47.7 / Dart 3.13.5，依赖版本锁定在 `pubspec.lock`。Android SDK、JDK 和设备状态先通过 `flutter doctor -v` 检查。

```powershell
flutter pub get
dart run build_runner build
flutter run -d edge
# 连接 Android 设备或启动模拟器后：
flutter run -d <设备ID>
```

```powershell
flutter analyze
flutter test
flutter build apk --debug
flutter build web --no-web-resources-cdn
```

Drift 管理 SQLite；学期、课程、学习任务与倒计时事件业务操作集中在 `lib/semesters/planner.dart`，课次计算与录课／课表界面位于 `lib/timetable/`，任务模型、列表及表单位于 `lib/tasks/`，倒计时模型、列表及表单位于 `lib/events/`，数据库与事务封装在 `lib/storage/`。测试使用真实 SQLite，关键界面测试会关闭并重新打开文件数据库。Web 的 SQLite 文件随应用分发；网页数据属于当前浏览器站点，不能代替 Android 持久化验收。

Android 进程重启验收分为创建与恢复两个阶段，使用同一个专用测试数据库名（每轮验收更换名字）。必须使用 `--keep-app-running`：当前 Flutter 驱动默认在结束后卸载应用，不能用卸载重装代替进程恢复验证。两个阶段之间仅结束应用进程，保留应用数据。

```powershell
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/semester_flow_test.dart -d <设备ID> --dart-define=ACCEPTANCE_DATABASE=unipocket_acceptance_01
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/semester_flow_test.dart -d <设备ID> --dart-define=ACCEPTANCE_DATABASE=unipocket_acceptance_01 --dart-define=ACCEPTANCE_RESTORE=true
```

`flutter drive` 安装的是自动验收包。`--keep-app-running` 用于保留进程恢复验收的数据，不表示测试结束后可以正常手动操作；测试绑定可能拦截真实点击并保留最后的截图画面。人工体验前应重新运行正常入口 `lib/main.dart`。

需要手动查看任务 16 的冲突样例时，使用独立的[导入预览入口](tool/import_preview.dart)：

```powershell
flutter run --no-pub --no-resident -d <设备ID> --target=tool/import_preview.dart
```

该入口使用正常 Flutter binding 和专用演示数据库，不向正式应用数据库写入样例；首次创建两门时间重叠的测试课程，导入课程以淡紫色区分，展示时钟固定为校园时间 2026-08-31 08:15。详细说明见[任务 16 跟进记录](.scratch/unipocket-v1/verification/16-import-preview.md)。
