# 任务 15：工具发现与首页常用入口

日期：2026-10-26。实施分支：`codex/dev15`。实施前基线：`7182795811e19e142a74d400a268c31ecc148d36`；实现提交：`394fff2`。

## 范围与行为

- 工具箱只展示转盘、随机点名、随机分组、抽签、掷骰子和抛硬币。统一目录及路由复用既有工具实现。
- 搜索会去除两端空白，匹配名称和简介，可与全部／收藏／最近使用筛选交叉使用。搜索无结果、无收藏和无最近使用均提供原因与返回全部入口。
- 收藏独立保存。打开工具即记录使用；重复进入将该工具移到最近列表首位，不生成重复项。最近顺序使用持久化递增序号，避免同一时间或系统时钟调整影响排序；不记录骰子／硬币的随机结果。
- 首页保留今日课程、未完成学习任务、近期倒计时顺序，在末尾增加常用工具卡片。两项入口按收藏、最近使用、默认目录顺序去重补齐，提供全部工具入口。收藏本身不计入最近使用。
- 读取或收藏保存失败有重试反馈。最近记录保存失败会说明原因，仍可进入工具。

## 持久化与迁移

Drift schema 13→14 新增工具收藏和最近使用记录，重新生成存储类型代码。通过真实 SQLite 文件重开验证收藏与最近顺序保留；版本 13 夹具升级验证学期、校园时区、课程、任务、事件、调停课、转盘列表、点名／抽签轮次及分组名单保留。无新增依赖或 Android 原生通知改动。

## 视觉依据与检查

依据[工具箱源图](../../../docs/design/resources/core-pages/03-随机工具箱与点名.png)、[工具箱样板截图](../../../docs/design/resources/screenshots/tools.png)、[首页源图](../../../docs/design/resources/core-pages/01-首页与周课表.png)及[首页样板截图](../../../docs/design/resources/screenshots/home.png)，复用现有 SVG／PNG 贴纸与统一主题。

工具箱为浅蓝白底、浅色两列圆角卡片、右上星形收藏、搜索和淡紫筛选胶囊；卡片顺序为转盘／随机点名、随机分组／抽签、掷骰子／抛硬币。最终 Android 默认字号截图中六项工具及说明完整可见。首页常用工具使用白底卡片和两列贴纸入口。

界面测试验证 320／393 逻辑宽、双倍文字和上下安全区，六项工具均能进入并返回；末项与首页工具可滚动触达，无布局溢出。首页测试还验证四个模块的顺序。未把 HTML 截图作为 Android 运行证据。

## 实际验证

| 检查 | 结果与证据 |
| --- | --- |
| 定向业务与界面测试 | `build/task15-focused-final.log`：6 项通过，覆盖迁移、文件数据库重开、搜索与筛选交叉、收藏／最近空状态、首页顺序及窄屏入口。 |
| 完整回归 | `build/task15-full-tests-final.log`：145 项通过，末行为 `All tests passed!`。 |
| 静态分析 | `build/task15-analyze.log`：`No issues found!`。 |
| Android 创建验收 | `build/task15-android-create-final.log`：通过，覆盖空状态、搜索、三项收藏、全部六个正确路由、最近排序和首页进入。 |
| Android 新进程恢复 | `build/task15-android-restore-final.log`：通过，同一文件数据库中的收藏、最近排序和首页入口恢复；创建与恢复应用进程分别为 PID 3470、3811。 |
| Android 调试构建 | `flutter build apk --debug --no-pub --target=lib/main.dart` 通过，日志 `build/task15-android-build.log`。 |
| Web 构建 | `flutter build web --no-pub --no-web-resources-cdn --target=lib/main.dart` 通过，日志 `build/task15-web-build-final.log`。 |
| 差异检查 | 实现提交相对基线及最终任务文件均执行 `git diff --check`。 |

Android 验收设备为现有 Android 16 / API 36 x86_64 模拟器。最终两阶段使用数据库 `unipocket_task15_20261026_04`，均带 `--keep-app-running`；测试未清除其他应用数据库。中间一次模拟器进程退出导致 VM Service 断连，重启已有 AVD 后重新完成最终两阶段；未安装或升级环境。

全量回归发现既有抽签测试模拟了 paused→resumed 的非法生命周期跳转。已改为 inactive→hidden→paused→hidden→inactive→resumed，保留后台取消且不消耗签项的原断言。首次 Android 检查发现搜索图标未打包，已在资源清单补齐搜索及清除图标并复验。

现有 SVG 资源仍输出 `unhandled element <filter/>` 日志；Android 构建有 JDK native-access 提示，Web 构建有既有 CupertinoIcons 字体提示。上述日志未阻止最终检查通过，未将其描述为无警告构建。

## Standards

0 项发现。未发现需要修改的规范违规或有实际维护影响的代码异味。本次改动沿用现有业务入口与存储封装，包含 schema 13→14 迁移、对应生成代码和真实 SQLite 保留测试；新增图标已声明打包。界面提供读取／保存失败反馈，并覆盖窄屏、双倍文字、安全区域及末项可达性。

## Spec

0 项代码发现。六项工具目录、搜索与筛选交叉、收藏及最近顺序持久化、统一路由、首页顺序、常用入口、迁移和窄屏滚动均符合任务 15；未增加骰币结果历史或未上线工具。审查时待补的最终 Android 证据现已通过创建及新进程恢复流程补齐。

审查范围：`git diff 7182795811e19e142a74d400a268c31ecc148d36...394fff2`。Standards 0 项，Spec 0 项；两轴均无最高严重问题。

## Android 最终截图

- [全部工具及收藏状态](evidence/15-android-tools-favorites.png)、[首次工具箱](evidence/15-android-tools.png)。
- [搜索结果](evidence/15-android-search.png)、[搜索无结果](evidence/15-android-search-empty.png)。
- [无收藏](evidence/15-android-favorites-empty.png)、[收藏列表](evidence/15-android-favorites.png)、[新进程收藏恢复](evidence/15-android-favorites-restored.png)。
- [无最近记录](evidence/15-android-recent-empty.png)、[最近列表](evidence/15-android-recent.png)、[新进程最近恢复](evidence/15-android-recent-restored.png)。
- [首页](evidence/15-android-home.png)、[常用工具](evidence/15-android-home-tools.png)、[新进程首页](evidence/15-android-home-restored.png)、[新进程常用工具](evidence/15-android-home-tools-restored.png)。

## 交付边界

任务 15 的 5 项验收已完成并同步任务文件。仅提交本任务代码、测试、任务文件及对应证据；工作开始前已有的任务 12–14、README 修改及任务 14 检查记录保留在原工作区。本任务证据来自真实 SQLite、Flutter 测试和 Android 模拟器；未进行实体手机或整版发布验收。浏览器交互未另行验收，Web 结论限于构建。`build/` 日志为本地忽略文件，最终截图随任务记录入库。
