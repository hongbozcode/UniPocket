# 任务 1 检查记录

日期：2026-10-25。范围：[任务 1](../issues/01-bootstrap-semester.md)，不代表整版功能完成。

## 工程与环境

- 从零应用代码、零应用测试起步，在仓库根目录创建 Flutter Android/Web 工程。
- 初始化参数：`--platforms=android,web --project-name=unipocket --org=com.hongbozcode --empty --no-pub`。
- Flutter 3.47.7 / Dart 3.13.5；Material 3；Drift 2.35.3 / drift_flutter 0.3.1；timezone 0.11.2。
- Android SDK 位于 `D:\develop\Android\SDK`。NDK 28.2.13676358 已由 `sdkmanager` 安装到该 SDK 下；本机兼容入口使用 `ndk/28.2.13676358` 包路径。
- SDK Platform 35/36、Build Tools 36.0.0、CMake 3.22.1 均位于该 D 盘 SDK 下。CMake 经用户确认后通过 `sdkmanager --install cmake/3.22.1` 安装。
- Gradle 缓存使用现有 `C:\Users\ZHB\.gradle`；Android CLI 自解压运行时位于 `C:\Users\ZHB\.android\cli`。安装目录与工具缓存不是同一概念。

## 已运行的验证

| 检查 | 结果与边界 |
| --- | --- |
| `flutter analyze` | 通过，无静态分析问题。 |
| `flutter test` | 9 条通过：4 条应用行为测试、5 条界面测试；使用真实 SQLite。 |
| 文件持久化 | 创建学期、不同星期的节次与校园时区；关闭文件数据库后重新打开，完整读取。 |
| 多学期 | 新建保留历史、指定当前学期、编辑历史不影响其他学期；失败操作不改原数据。 |
| 校园时间 | 默认 Asia/Shanghai、可切换 IANA 时区；同一时刻按校园时区计算日期，非法时区不覆盖原设置。 |
| 界面 | 首次运行四入口；创建学期到真实 SQLite 再重开应用。320/393 宽度、双倍字号、长名称、安全区域、滚动保存、时区搜索与选择均通过。 |
| 输入错误回归 | 顶部表单项滚出屏幕并卸载后，非法日期或非整数周数仍有明确提示；没有 SQLite 写入，也不误报存储失败。 |
| `flutter build web --no-web-resources-cdn` | 通过；SQLite Web worker/wasm 与渲染资源随构建本地分发。 |
| 浏览器操作 | 实际创建并保存学期；刷新后保留名称、当前选择、教学周基准与周数。此项不能替代 Android 验收。 |
| Android 构建与进程恢复 | 调试构建通过；Android API 36 模拟器完成断网保存和新进程恢复两阶段验收，见下方证据。 |

## 两轴代码审查

用户确认以空仓库为基线。规范轴发现 2 项，规格轴发现 1 项（其中表单问题重合）。

### Standards

发现 2 项，均已修复并复核关闭：

- Android 自动备份与主动导出约束冲突：清单关闭备份与设备迁移，并配置全部数据域排除规则；Android 调试构建通过，合并清单中相关设置已核对。
- 滚出屏幕的基础字段未被 Form 校验：保存前独立解析全部控制器；两条回归测试先失败后通过，非法数据不写入。

### Spec

发现 1 项，与规范轴的表单问题重合，已修复并复核关闭。未发现其他任务越界实现。

最终未关闭发现：Standards 0 项，Spec 0 项。

## 明确边界

- 首页、课表、工具和设置入口已建立。课程、学习任务、倒计时、随机工具、提醒及备份恢复尚未交付，界面有明确说明。
- 复用既有蓝紫色变量与 SVG 素材。SVG 阴影滤镜在 Flutter 中简化；不以 HTML 或 Web 截图宣称 Android 已实现复杂动效。
- 学校 XLSX 样例仍未提供，本任务未实现导入适配。
- Web 数据属于当前浏览器站点；清除站点数据或隐私浏览会影响留存。Web 尚未作首次离线加载与发布验收。

## Android 最终结果

- 对象：Medium Phone API 36.0 模拟器，1080×2400、density 420；正式应用可见窗口已打开。
- `flutter build apk --debug` 通过，应用标识为 `com.hongbozcode.unipocket`。
- 模拟器 Wi‑Fi 和移动数据均关闭（两项设置均为 0），无需账号，通过真实表单创建学期和保存校园时区。
- 两阶段均使用 `flutter drive --keep-app-running` 和专用数据库 `unipocket_acceptance_20261025_c`。默认驱动会在结束时卸载应用，故不能省略此参数。
- 第一阶段通过，实际应用进程 4271。保留安装和数据后强制结束该进程，手机时区为 America/Los_Angeles，再启动第二阶段。
- 第二阶段通过，新进程 4462。从 SQLite 恢复学期“Android 验收秋季学期”、第 1 周周一 2026-08-31 和校园时区 Asia/Tokyo；不随手机时区改变。
- 原生键盘验证中补齐拖动表单收起键盘的行为；等待布局稳定后保存可达，完整界面回归仍通过。
- 验收数据使用独立数据库；正式入口不预置演示学期。
- 验收后已恢复模拟器原 GMT、自动时区、Wi‑Fi 和移动数据设置，重新构建并打开正式 `main.dart` 入口。
- Android APK 内容检查未包含 Web 专用 `drift_worker.js` 或 `sqlite3.wasm`；两平台独立构建。
- 尚未作 Android 真机验证、发布签名或整版功能验收。本任务不包含系统通知、真实 XLSX 导入等后续任务。

运行证据：

- [Android 断网保存后的设置](evidence/android-settings-saved.png)
- [Android 新进程恢复后的首页](evidence/android-process-restored.png)
- [正式应用可见窗口中的首页](evidence/android-main-visible.png)
- [Web 刷新恢复后的首页](evidence/web-home-restored.png)
