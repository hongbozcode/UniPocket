# 设计截图索引

页面规则见[视觉规范](../../../product/design.md)，各页采用关系见[catalog.json](../../catalog.json)，检查结论与证据限制见[验证记录](../../verification.md)。文件名中的版本号是采集标签，不代表可追溯的源码版本；以下既有浏览器证据的采集日期与源码版本未完整记录。

## 当前独立动效样板截图

当前演示位于 [motion.html](../../motion.html)。以下为清单目前采用的截图；结果截图用于页面卡片与图稿对照，完整采集图保留浏览器上下文。采用关系不表示已针对当前源码重新采集或复测。

| 页面／状态 | 页面截图 | 完整采集图 |
| --- | --- | --- |
| 转盘 | [结果](../../qa/live-v2-wheel.png) | [完整采集](../../qa/live-v2-wheel-full.png) |
| 随机点名 | [结果](../../qa/live-v2-draw.png) | [完整采集](../../qa/live-v2-draw-full.png) |
| 随机分组 | [结果](../../qa/live-v2-groups.png) | [完整采集](../../qa/live-v2-groups-full.png) |
| 抽签 · 初始 | [页面](../../qa/lottery-v3-idle.png) | [完整采集](../../qa/lottery-v3-idle-full.png) |
| 抽签 · 完成 | [页面](../../qa/lottery-v3-result.png) | [完整采集](../../qa/lottery-v3-result-full.png) |
| 抽签 320px · 最长默认签文 | [页面](../../qa/lottery-v3-320-longest.png) | [完整采集](../../qa/lottery-v3-320-longest-full.png) |
| 抽签 320px · 新一轮复位 | [页面](../../qa/lottery-v3-320-reset.png) | [完整采集](../../qa/lottery-v3-320-reset-full.png) |
| 掷骰子 | [结果](../../qa/live-v2-die.png) | [完整采集](../../qa/live-v2-die-full.png) |
| 抛硬币 | [结果](../../qa/live-v2-coin.png) | [完整采集](../../qa/live-v2-coin-full.png) |

## 补充采集资料

| 资料 | 用途与限制 |
| --- | --- |
| [抽签两态对照](../../qa/lottery-v3-review.png) | 初始与完成状态的组合图。 |
| [抽签局部对照](../../qa/lottery-v3-details.png) | 签袋及纸签的前后局部画面；保留为采集资料，不单独证明当前实现符合规范。 |
| [live-v2 边界数据](../../qa/live-v2-bounds.json) | 六项工具采集区域的位置与宽高；抽签包含较早的 live-v2 记录。 |
| [lottery-v3 边界数据](../../qa/lottery-v3-bounds.json) | 抽签初始、完成及 320px 状态的采集区域；不包含动画时序或交互检查结果。 |

## 手册浏览界面

[桌面图稿对照](../../qa/handbook-reference-desktop.png) · [320px 底部入口与说明](../../qa/handbook-reference-320.png)。

## 原应用样板截图

以下六个页面尚无新版截图，保留原应用样板画面作为参考，并在手册中标注历史来源。

| 页面 | 截图 |
| --- | --- |
| 首页 | [home.png](home.png) |
| 周课表 | [timetable.png](timetable.png) |
| 学习任务 | [tasks.png](tasks.png) |
| 倒计时 | [events.png](events.png) |
| 工具箱 | [tools.png](tools.png) |
| 设置 | [settings.png](settings.png) |
