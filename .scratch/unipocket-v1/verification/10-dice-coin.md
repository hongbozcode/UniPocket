# 任务 10 检查记录

日期：2026-10-25。范围：[掷骰子与抛硬币](../issues/10-dice-coin.md)。审查基线：开始实现前 HEAD `1e432b9ec56861dd5388d4a927f360498a0e7c79`。

## 实现与边界

- 工具箱提供掷骰子、抛硬币两个真实入口，沿用两列薄荷／浅粉工具卡及现有贴纸。无需学期、账号或网络。搜索、收藏、最近使用和首页常用入口属于任务 15，本轮没有提前开放。
- 使用 Dart `Random.nextInt(6)`／`nextInt(2)`选择整个候选范围，每次操作只取一次结果，没有权重、取模、重抽或覆盖结果。默认应用使用实际随机源，固定候选只用于测试入口。Context7 未返回相关 API 文档后核对了 [Dart 官方 nextInt 文档](https://api.dart.dev/dart-math/Random/nextInt.html)。
- 结果属于当前页面的临时状态；触发后确定候选，运动结束才显示最终文字，进行中按钮禁用。返回销毁动画控制器，重新进入恢复等待状态。没有添加随机结果数据库表或持久化历史。
- 本轮用户明确要求参照 HTML 源动效，并提供[更圆润的骰子棱边参考](evidence/10-edge-reference.png)。这覆盖任务默认的简化反馈范围；业务规格和其他工具范围不变。没有修改 HTML 手册、生成源或其他工具。
- 未安装环境、未新增依赖，`pubspec.lock` 不变。新增资源声明均为已有项目素材。现有 Flutter 3.47.7／Dart 3.13.5、Android SDK 36、JDK 与许可证可用；机器缺少 Chrome 不影响 Android 和本轮 Web 构建。

## 视觉与动作

依据：[骰子源效果图](../../../docs/design/resources/random-tools/04-掷骰子.png)、[硬币源效果图](../../../docs/design/resources/random-tools/05-抛硬币.png)、[工具箱源效果图](../../../docs/design/resources/core-pages/03-随机工具箱与点名.png)，以及 `motion-demo.js`／`motion-demo.css` 的骰子和硬币场景。

- 页面采用 HTML 参考的浅蓝白底、圆角投掷台、淡紫／奶黄结果便笺和蓝色主按钮；币面图例复用星星正面、月牙反面 SVG。文字为实际 Flutter 文本，结果可由无障碍语义读取。
- 骰子为六个正交面构成的立方体，六面点阵与参考一致，透视投影、背面剔除及可见面绘制保证完整结构。连续曲面的倒角网格填平棱边和角落，柔和蓝色光照与面内高光对应用户追加参考；没有使用固定点数贴图冒充投掷结果。
- 骰子约 1.9 秒，绕 X／Y 轴分别翻滚 720°／1080°后落在选中面；硬币约 1.8 秒，Y 轴连续翻转 1800°，反面增加半圈。硬币有真实侧边厚度，任何时刻只绘制朝向用户的一个币面，反面不会镜像透出。
- 运动沿 HTML 的 40% 腾空、76% 落地压缩、87% 回弹、100% 停稳时序，阴影同步缩小变淡和落地加深。旋转采用源曲线，飞行／阴影按关键帧线性变化。旋转后的顶点按投掷台与说明区域限制高度，防止最高点裁切或挡住文字。

## 已运行检查

| 检查 | 结果与范围 |
| --- | --- |
| TDD | 工具入口及随机源注入缺失的失败用例先运行，再实现页面。边界沿用规格已确认的应用操作／真实 SQLite，仅控制随机源与测试时钟。 |
| 行为测试 | 六个骰子候选、硬币两面、图像语义与最终文字、进行中重复点击、取消后重进、文件 SQLite 关闭重开后无结果历史均通过。 |
| 界面适配 | 320／393 逻辑宽、1／2 倍文字、安全区、长说明换行和滚动到主操作／底部提示通过。修复了 320 宽双倍文字时工具箱品牌行溢出。 |
| 运动逐帧 | 两项工具各采集 20 个运动阶段及初始画面，对实际绘制像素检查腾空位移、落地回弹、旋转轮廓变化、边界和停稳落位。帧图在 `build/toss-preview/`，属于宿主 Flutter 绘制证据；不将其作为 Android 截图。 |
| 全量回归 | 最终圆角网格代码的 `flutter test --no-pub --reporter expanded` 共 100 项通过，包含既有 92 项与新增 8 项。 |
| 静态检查 | `flutter analyze --no-pub` 无问题。 |
| 构建 | Android debug APK 与 Web 正式入口均构建通过；Web 使用 `--no-web-resources-cdn`。本轮未做浏览器交互验收。 |
| Android 集成 | 现有 Android 16／API 36 模拟器完成真实入口、全部骰面、硬币两面、再次投掷和返回取消流程。专用 SQLite 名称 `unipocket_dice_coin_20261025_c`，没有写入骰子或硬币历史。 |

Android 命令：

```powershell
flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/dice_coin_flow_test.dart -d emulator-5554 --dart-define=ACCEPTANCE_DATABASE=unipocket_dice_coin_20261025_c
```

验收截图为 1179×2556／density 480，即 393 逻辑宽。采集后恢复设备原 1080×2400／density 420。早期两次模拟器进程退出导致的中断不计为通过；改用持续模拟器会话后完整流程通过。没有清除原应用数据或卸载应用。

## Android 截图

- [工具箱](evidence/10-android-tools.png)。
- [骰子等待](evidence/10-android-die-ready.png)，[1 点](evidence/10-android-die-1.png)、[2 点](evidence/10-android-die-2.png)、[3 点](evidence/10-android-die-3.png)、[4 点](evidence/10-android-die-4.png)、[5 点](evidence/10-android-die-5.png)、[6 点](evidence/10-android-die-6.png)。
- [硬币等待](evidence/10-android-coin-ready.png)、[星星正面](evidence/10-android-coin-heads.png)、[月牙反面](evidence/10-android-coin-tails.png)、[取消后重新进入](evidence/10-android-coin-cancelled.png)。

截图来自实际 Flutter Android 运行；源效果图及 HTML 仅为视觉与动作参考。本轮没有宣称实体设备性能或固定帧率已经验收。

## 审查

实现提交：`810df74`。按 `code-review` 技能以开始实现前 HEAD 为固定基线，由两个独立子代理分别完成两轴审查；审查结束后仅补充本记录。42 个本地文档链接检查通过。模拟器已覆盖部署正常随机的正式入口 debug APK，替换固定候选的测试构建，保留原应用数据。

## Standards

硬性标准违规：0 项。未发现违反 AGENTS.md、架构约束、视觉资源与状态反馈规则、任务跟踪约定或领域术语要求的可确认问题。随机结果仅保存在页面状态中，随机源注入位于允许控制的外部边界；页面复用现有素材，验收记录区分 Flutter 绘制、Android 模拟器和未验证范围。

判断性 smell：0 项。已检查全部 baseline；两种工具共享页面与飞行时序，各自封装绘制逻辑，未发现值得要求修改的重复代码、无用抽象或职责分散。数学投影中的短变量有明确局部含义，不作为命名问题。

完整三维动效及圆润骰边来自用户明确追加要求，不能按原默认简化反馈约束认定违规。

## Spec

0 项明确问题。随机选择覆盖 6／2 个候选，每次只抽取一次；结果、骰面及币面使用同一候选值。返回销毁动画与页面临时状态，无历史持久化。

六面结构、圆角网格、硬币正反面剔除及上抛／回弹时序符合追加要求；已查看 Android 骰子 6 点、硬币反面与圆润棱边参考截图。页面可滚动，现有测试覆盖 320／393 宽、双倍文字及安全区。完整动画已获用户追加授权，搜索等功能明确由任务 15 承接，没有据此误报越界。

审查为静态检查与截图检查，子代理未重跑构建或测试。Standards 0 项／Spec 0 项，两轴均无阻断项。
