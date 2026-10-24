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

当前仓库提供任务 1 的 Flutter Android/Web 工程，支持离线学期、每日节次与校园时区配置；其他任务尚未交付，学校 XLSX 格式适配等待真实样例。实现验证记录见[任务 1 检查记录](.scratch/unipocket-v1/verification/01-bootstrap-semester.md)。

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

Drift 管理 SQLite；业务校验集中在 `lib/semesters/`，数据库与事务封装在 `lib/storage/`。测试使用真实 SQLite，关键界面测试会关闭并重新打开文件数据库。Web 的 SQLite 文件随应用分发；网页数据属于当前浏览器站点，不能代替 Android 持久化验收。

Android 进程重启验收分为创建与恢复两个阶段，使用同一个专用测试数据库名（每轮验收更换名字）。必须使用 `--keep-app-running`：当前 Flutter 驱动默认在结束后卸载应用，不能用卸载重装代替进程恢复验证。两个阶段之间仅结束应用进程，保留应用数据。

```powershell
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/semester_flow_test.dart -d <设备ID> --dart-define=ACCEPTANCE_DATABASE=unipocket_acceptance_01
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/semester_flow_test.dart -d <设备ID> --dart-define=ACCEPTANCE_DATABASE=unipocket_acceptance_01 --dart-define=ACCEPTANCE_RESTORE=true
```
