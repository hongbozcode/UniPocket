# UniPocket 视觉设计规范与资源索引

> 后续页面设计与资源使用的现行规范。更新日期：2026-10-27。本文件自动生成，维护源见文末说明。

阅读顺序：**效果图 → HTML 样板运行截图与交互说明 → 设计资源 → 设计规范**。可视化对照：[HTML 设计手册](../design/index.html)。

业务依据：[首版规格](../../.scratch/unipocket-v1/spec.md)；术语：[词汇表](../../GLOSSARY.md)。

## 依据与使用流程

- 用户最新明确要求优先；业务范围、行为与发布验收以首版规格为准，视觉表现与资源使用以本规范为准。
- 效果图提供视觉方向，运行截图记录采集时布局；提示词、示例文案和展示外壳不覆盖现行规范。
- Flutter 应用已进入实现阶段，应用交付与验收以仓库 README 的任务检查记录为准；本手册的 HTML 演示和截图仅提供设计参考，其验证范围见设计检查记录。

1. 按效果图、HTML 样板截图与交互说明、设计资源、设计规范的顺序查看所改页面；缺少的状态明确标为待设计或待采集。
2. 复用现有变量与素材，按首版规格核对业务行为；页面规则描述采用目标，实际达成情况查看检查记录。
3. 完成与变更相关的验收项，在维护源更新说明与资源关联，再生成两版手册。

## 01 / 效果图

当前 9 张效果图覆盖 12 个页面，组合图可对应多个页面。效果图与提示词见[资源目录](../design/resources/README.md)。

| 当前稿 | 用途与约束 | 来源 |
| --- | --- | --- |
| [首页与周课表](../design/resources/core-pages/01-首页与周课表.png) | 浅蓝白底、课程层级、淡紫导航与贴纸。组合图覆盖两个页面。 | [提示词](../design/resources/core-pages/生成提示词.md) |
| [学习任务与倒计时](../design/resources/core-pages/02-学习任务与倒计时.png) | 任务强调截止状态，倒计时用大数字和彩纸便笺。 | [提示词](../design/resources/core-pages/生成提示词.md) |
| [工具箱与随机点名](../design/resources/core-pages/03-随机工具箱与点名.png) | 两列工具色块、统一白边贴纸、名单和抽取轮次。 | [提示词](../design/resources/core-pages/生成提示词.md) |
| [设置](../design/resources/core-pages/04-设置.png) | 学习安排、提醒、本地备份与关于；功能分组清楚。 | [提示词](../design/resources/core-pages/设置页提示词.md) |
| [转盘](../design/resources/random-tools/01-转盘.png) | 大尺寸纯文字转盘，文字沿各扇区半径排布；固定指针和明确结果，自定义项不匹配图标。 | [提示词](../design/resources/random-tools/01-转盘-提示词.md) |
| [随机分组 · 水平标签](../design/resources/random-tools/02-随机分组-v2-水平标签.png) | 分组纸卡与水平姓名标签。 | [提示词](../design/resources/random-tools/02-随机分组-v2-提示词.md) |
| [抽签](../design/resources/random-tools/03-抽签.png) | 桃色签袋、独立纸签、完整签文与本轮进度。 | [提示词](../design/resources/random-tools/03-抽签-提示词.md) |
| [掷骰子](../design/resources/random-tools/04-掷骰子.png) | 单颗蓝色六面骰、薄荷色投掷台、大号结果数字。 | [提示词](../design/resources/random-tools/04-掷骰子-提示词.md) |
| [抛硬币](../design/resources/random-tools/05-抛硬币.png) | 单枚金色硬币，星星正面、月牙反面，浅粉投掷台。 | [提示词](../design/resources/random-tools/05-抛硬币-提示词.md) |

## 02 / HTML 样板运行截图与交互说明

六项随机工具提供当前独立演示；其余页面仅保留历史截图，原完整应用样板源码未纳入仓库。逻辑标识用于清单关联，不是页面锚点或应用路由。补充状态见[截图索引](../design/resources/screenshots/README.md)。

| 页面 | 当前效果图 | 逻辑标识 | 运行截图 | 可运行入口 | 页面约束 |
| --- | --- | --- | --- | --- | --- |
| 首页 | [效果图](../design/resources/core-pages/01-首页与周课表.png) | `home` | [历史应用样板](../design/resources/screenshots/home.png) | 仅历史截图 | 课程时间与地点优先；逾期任务保留，状态同时使用文字。 |
| 周课表 | [效果图](../design/resources/core-pages/01-首页与周课表.png) | `timetable` | [历史应用样板](../design/resources/screenshots/timetable.png) | 仅历史截图 | 课程色用于识别课程；今天高亮，横纵网格保持清晰。 |
| 学习任务 | [效果图](../design/resources/core-pages/02-学习任务与倒计时.png) | `tasks` | [历史应用样板](../design/resources/screenshots/tasks.png) | 仅历史截图 | 学习任务具有明确截止时间和完成状态，与倒计时事件分开。 |
| 倒计时 | [效果图](../design/resources/core-pages/02-学习任务与倒计时.png) | `events` | [历史应用样板](../design/resources/screenshots/events.png) | 仅历史截图 | 使用日历日期计算剩余天数，当天显示“就是今天”；使用彩纸和大数字。 |
| 随机工具箱 | [效果图](../design/resources/core-pages/03-随机工具箱与点名.png) | `tools` | [历史应用样板](../design/resources/screenshots/tools.png) | 仅历史截图 | 两列圆角色块、统一贴纸插画；只展示首版六项工具。 |
| 随机点名 | [效果图](../design/resources/core-pages/03-随机工具箱与点名.png) | `draw` | [当前动效样板](../design/qa/live-v2-draw.png) | [打开演示](../design/motion.html?tool=draw) | 同名成员分别保留；离开页面保留轮次，修改名单前说明重置影响。 |
| 设置 | [效果图](../design/resources/core-pages/04-设置.png) | `settings` | [历史应用样板](../design/resources/screenshots/settings.png) | 仅历史截图 | 普通设置行按分组组织；通知展示真实状态，正式应用适配设备安全区域。 |
| 转盘 | [效果图](../design/resources/random-tools/01-转盘.png) | `tool-wheel` | [当前动效样板](../design/qa/live-v2-wheel.png) | [打开演示](../design/motion.html?tool=wheel) | 转盘随可用宽度适配，393px 视口下约 353px 作为参考；选项仅显示用户文字，沿扇区半径排布并处理朝向；固定指针与结果一致。 |
| 随机分组 | [效果图](../design/resources/random-tools/02-随机分组-v2-水平标签.png) | `tool-groups` | [当前动效样板](../design/qa/live-v2-groups.png) | [打开演示](../design/motion.html?tool=groups) | 完成后所有姓名标签水平排列；洗牌与逐张发牌表现见 HTML 动效参考，分组人数规则见首版规格。 |
| 抽签 | [效果图](../design/resources/random-tools/03-抽签.png) | `tool-lottery` | [当前动效样板](../design/qa/lottery-v3-result.png) | [打开演示](../design/motion.html?tool=lottery) | 桃色签袋配 spark-yellow.svg、spark-lavender.svg 的实心浅色白边星星，签文完整可读；纸签姿态与落位见 HTML 动效参考，轮次规则见状态反馈与首版规格。 |
| 掷骰子 | [效果图](../design/resources/random-tools/04-掷骰子.png) | `tool-die` | [当前动效样板](../design/qa/live-v2-die.png) | [打开演示](../design/motion.html?tool=die) | 单颗六面骰，展示点数与文字结果一致；六面结构、翻滚与落地回弹见 HTML 动效参考。 |
| 抛硬币 | [效果图](../design/resources/random-tools/05-抛硬币.png) | `tool-coin` | [当前动效样板](../design/qa/live-v2-coin.png) | [打开演示](../design/motion.html?tool=coin) | 单枚硬币，星星正面、月牙反面，展示币面与文字结果一致；上抛与翻转见 HTML 动效参考。 |

### 页面内容与待补状态

| 页面 | 内容顺序 | 样板操作及来源 | 应用待补设计 |
| --- | --- | --- | --- |
| 首页 | 今日课程 → 未完成学习任务 → 近期倒计时事件 → 常用工具 | 历史样板曾演示的操作：快捷添加、课程详情、任务完成与撤销、进入二级页 | 无数据、无课日、任务较多时的完整状态。 |
| 周课表 | 当前学期与校园时区 → 周切换 → 七天课表网格 | 历史样板曾演示的操作：切周、回本周、今日列表、课程详情 | 课程新增、编辑和删除影响确认；导入预览与纠错、重复及冲突提示；单次调停课与失去关联的例外处理。 |
| 学习任务 | 逾期 → 今天 → 接下来；课程与状态筛选 | 历史样板曾演示的操作：新增、完成、撤销、筛选 | 完整编辑、删除与单项提醒配置。 |
| 倒计时 | 置顶事件 → 按临近日期排序 → 历史入口 | 历史样板曾演示的操作：新增、编辑、置顶、删除 | 单项提醒配置及更多日期边界状态。 |
| 随机工具箱 | 搜索 → 全部／收藏／最近 → 六项随机工具 | 历史样板曾演示的操作：搜索、收藏、进入工具 | 最近使用展示及搜索、收藏的空状态。 |
| 随机点名 | 名单 → 重复模式 → 抽取结果 → 本轮进度 | 当前演示操作：抽取、修改名单、主动开始新一轮 | 多名单命名保存、重名成员区分及修改名单的重置确认。 |
| 设置 | 学习安排 → 提醒 → 本地备份 → 关于 | 历史样板曾演示的操作：查看设置、演示导出和恢复 | 多学期管理、完整节次配置、校园时区设置；权限关闭反馈及备份校验、覆盖确认和失败状态。 |
| 转盘 | 选项列表 → 大转盘 → 结果便笺 → 主操作 | 当前演示操作：编辑选项、转动、再次转动 | 选项列表命名保存、重复选项提示及长文本、文本放大状态。 |
| 随机分组 | 名单 → 分组方式 → 数量设置 → 分组纸卡 | 当前演示操作：按组数或人数上限分组、重新分组 | 名单命名保存、同名成员区分及更大名单的展示。 |
| 抽签 | 签池 → 重复模式 → 签袋和纸签 → 进度与主操作 | 当前演示操作：编辑签池、抽签、新一轮 | 多签池命名保存、重复签文提示及修改签池的重置确认。 |
| 掷骰子 | 单颗立体骰子 → 大号点数 → 主操作 | 当前演示操作：投掷、再次投掷 | Android 首版的简化投掷反馈，包含投掷前、进行中与结果状态。 |
| 抛硬币 | 单枚硬币 → 正反面结果 → 主操作 → 币面图例 | 当前演示操作：抛掷、再次抛掷 | Android 首版的简化抛掷反馈，包含抛掷前、进行中与结果状态。 |

历史样板操作仅作记录，当前仓库无法运行复核；应用待补设计列定位尚需展开的界面与状态，完整开发范围以首版规格为准。

### 样板资料

- 原应用样板截图的示例日期固定为 2026-10-23、学期第 8 周；课程、任务和名单均为演示数据。
- 六项随机工具的**动效源码**：[motion-demo.js](../design/motion-demo.js) 实现动画时序、结果呈现与交互逻辑；[motion-demo.css](../design/motion-demo.css) 定义场景布局、样式与三维表现。
- [motion.html](../design/motion.html) 是加载上述 JS／CSS 的独立演示入口，HTML 手册的“播放动效”也复用同一套源码。理解具体实现时读取动效源码，确认实际效果时用浏览器打开演示；编辑与状态保留方式见[演示使用说明](../design/README.md)。

## 03 / 设计资源

共 59 个独立素材：37 个界面图标、18 个插画、4 个材质文件。按以下索引引用；效果图和截图另列。

### 界面图标

独立 SVG：[图标目录](../design/resources/icons/)。默认主蓝，使用时可按平台设置颜色；尺寸和描边要求见“图标与插画”。

| 名称 | 文件 |
| --- | --- |
| 箭头 | [arrow.svg](../design/resources/icons/arrow.svg) |
| 返回 | [back.svg](../design/resources/icons/back.svg) |
| 口袋标识 | [badge.svg](../design/resources/icons/badge.svg) |
| 提醒 | [bell.svg](../design/resources/icons/bell.svg) |
| 书本 | [book.svg](../design/resources/icons/book.svg) |
| 日历 | [calendar.svg](../design/resources/icons/calendar.svg) |
| 完成 | [check.svg](../design/resources/icons/check.svg) |
| 时间 | [clock.svg](../design/resources/icons/clock.svg) |
| 关闭 | [close.svg](../design/resources/icons/close.svg) |
| 硬币 | [coin.svg](../design/resources/icons/coin.svg) |
| 骰子 | [die.svg](../design/resources/icons/die.svg) |
| 展开 | [down.svg](../design/resources/icons/down.svg) |
| 下载 | [download.svg](../design/resources/icons/download.svg) |
| 导出 | [export.svg](../design/resources/icons/export.svg) |
| 文件夹 | [folder.svg](../design/resources/icons/folder.svg) |
| 时区 | [globe.svg](../design/resources/icons/globe.svg) |
| 工具箱 | [grid.svg](../design/resources/icons/grid.svg) |
| 收藏 | [heart.svg](../design/resources/icons/heart.svg) |
| 首页 | [home.svg](../design/resources/icons/home.svg) |
| 说明 | [info.svg](../design/resources/icons/info.svg) |
| 素材 | [layers.svg](../design/resources/icons/layers.svg) |
| 上一项 | [left.svg](../design/resources/icons/left.svg) |
| 地点 | [location.svg](../design/resources/icons/location.svg) |
| 更多 | [more.svg](../design/resources/icons/more.svg) |
| 置顶 | [pin.svg](../design/resources/icons/pin.svg) |
| 添加 | [plus.svg](../design/resources/icons/plus.svg) |
| 恢复 | [restore.svg](../design/resources/icons/restore.svg) |
| 下一项 | [right.svg](../design/resources/icons/right.svg) |
| 搜索 | [search.svg](../design/resources/icons/search.svg) |
| 设置 | [settings.svg](../design/resources/icons/settings.svg) |
| 随机 | [shuffle.svg](../design/resources/icons/shuffle.svg) |
| 星星 | [star.svg](../design/resources/icons/star.svg) |
| 任务 | [task.svg](../design/resources/icons/task.svg) |
| 抽签 | [ticket.svg](../design/resources/icons/ticket.svg) |
| 成员 | [users.svg](../design/resources/icons/users.svg) |
| 警告 | [warning.svg](../design/resources/icons/warning.svg) |
| 转盘 | [wheel.svg](../design/resources/icons/wheel.svg) |

### 贴纸与场景插画

| 名称 | 文件 | 来源 |
| --- | --- | --- |
| 口袋标识 | [badge.svg](../design/resources/illustrations/badge.svg) | 项目内 SVG |
| 书本 | [book.svg](../design/resources/illustrations/book.svg) | 项目内 SVG |
| 日历 | [calendar.svg](../design/resources/illustrations/calendar.svg) | 项目内 SVG |
| 星星正面 | [coin-head.svg](../design/resources/illustrations/coin-head.svg) | 项目内 SVG |
| 月牙反面 | [coin-tail.svg](../design/resources/illustrations/coin-tail.svg) | 项目内 SVG |
| 硬币 | [coin.svg](../design/resources/illustrations/coin.svg) | 项目内 SVG |
| 骰子 | [die.svg](../design/resources/illustrations/die.svg) | 项目内 SVG |
| 纸签 | [draw.svg](../design/resources/illustrations/draw.svg) | 项目内 SVG |
| 旗帜 | [flag.svg](../design/resources/illustrations/flag.svg) | 项目内 SVG |
| 文件夹 | [folder.svg](../design/resources/illustrations/folder.svg) | 项目内 SVG |
| 分组 | [groups.svg](../design/resources/illustrations/groups.svg) | 项目内 SVG |
| 签袋 | [lottery-bag.png](../design/resources/illustrations/lottery-bag.png) | 内置生图 |
| 铅笔 | [pencil.svg](../design/resources/illustrations/pencil.svg) | 项目内 SVG |
| 口袋吉祥物 | [pocket.png](../design/resources/illustrations/pocket.png) | 内置生图 |
| 淡紫白边星星 | [spark-lavender.svg](../design/resources/illustrations/spark-lavender.svg) | 项目内 SVG |
| 浅黄白边星星 | [spark-yellow.svg](../design/resources/illustrations/spark-yellow.svg) | 项目内 SVG |
| 太阳 | [sun.svg](../design/resources/illustrations/sun.svg) | 项目内 SVG |
| 转盘 | [wheel.svg](../design/resources/illustrations/wheel.svg) | 项目内 SVG |

口袋、签袋为透明 PNG，纸纹为可平铺 PNG，其余为项目内 SVG。die.svg 用于入口贴纸；六面结构见 HTML 动效参考。

素材生成记录：[抽签袋素材生成记录](../design/resources/random-tools/素材-签袋-提示词.md)。

### 通用材质

| 素材 | 文件 | 样式 | 用途 |
| --- | --- | --- | --- |
| 细纸纹 | [paper-grain.png](../design/resources/materials/paper-grain.png) | `.paper-surface` | 低强度平铺，给便笺增加触感。 |
| 微纤维 | [paper-fibers.svg](../design/resources/materials/paper-fibers.svg) | `.paper-surface` | 与细纸纹叠加，保持正文对比度。 |
| 撕纸边 | [torn-edge.svg](../design/resources/materials/torn-edge.svg) | `.paper-torn` | 底边 SVG 蒙版，随卡片底色变化。 |
| 和纸胶带 | [washi-tape.svg](../design/resources/materials/washi-tape.svg) | `.with-tape` | 局部半透明装饰，避开交互控件。 |

### HTML 资源复用

- 先引入 tokens.css，再引入 materials.css，并保留 materials 目录与样式文件的相对位置。CSS px 和 CSS 类名是 HTML 复用方式；正式应用按平台逻辑尺寸、安全区域和文本缩放适配。
- 纸纹使用 .paper-surface，默认 --paper-grain-opacity 为 .18；撕纸使用 .paper-torn，底色来自 --paper-color，底边预留 12px。
- 胶带使用 .with-tape，默认宽 76px；横线、网格和贴纸分别使用 .paper-ruled、.paper-grid、.sticker。
- .paper-torn 与 .with-tape 都使用 ::after；组合时以外层 .with-tape 包裹内层 .paper-surface.paper-torn。

### 视觉参数与通用样式

| 入口 | 职责 |
| --- | --- |
| [tokens.css](../design/resources/tokens.css) | 颜色、字体、间距、圆角与阴影 |
| [materials.css](../design/resources/materials.css) | 通用纸纹、撕边、胶带、横线与网格 |

## 04 / 设计规范

### 视觉方向

- 浅蓝白为底，主蓝承担主要操作，淡紫用于选中态；奶黄、浅桃、薄荷、柔粉分配给课程与工具场景。
- 采用圆润卡片、白边贴纸和局部纸感；所有页面可以适当活泼，保持文字和操作优先。
- 每个区域只设一个视觉重点。插画与装饰避让文字和点击区域，普通设置行按组组织。

### 排版与布局

- HTML 页面参考视口为 393 × 852 CSS px，并检查 320px 窄屏；正式应用按平台逻辑尺寸、设备安全区域和文本缩放适配。
- 间距基准 4px，页面常规左右留白 20px；圆角采用 12／18／24／30px 和胶囊。卡片轻阴影，靠留白与浅色表面区分层次。
- 中文无衬线字体回退使用 --font-ui；首页标题参考 26px、模块标题 15px、正文基础 14px，按页面层级与文本放大需求调整。
- 四个主导航固定为：首页、课表、工具、设置。二级页保留返回与必要操作；滚动末项可触达，长标题允许换行。

### 图标与插画

- 界面图标使用 24 × 24 viewBox、1.9px 圆头圆角描边，常规显示为 22px；导航图标按页面截图的层级适配。优先使用 resources/icons 中的现有 SVG。
- 插画使用独立 SVG 或透明 PNG，统一白边与轻阴影；界面图标和装饰插画分别使用，不把整张效果图作为交互界面。
- 可生图、画 SVG 或采用合适的现成素材；新增第三方资源时记录来源、许可和使用范围。界面文字使用真实文本，不嵌入整页位图；按内容需要支持选择或复制。

### 纸张与材质

- 纸纹低对比、局部使用，保持正文清晰；装饰层避开文字并不拦截操作。
- 撕纸边随卡片底色变化，底边留出空间；胶带用于局部装饰，横线与网格保持克制，网格纸不叠加在周课表网格上。
- 贴纸使用统一轻阴影。倾斜用于装饰、纸签规定的静态姿态或动作过程；随机分组完成后的姓名标签必须水平。

### 状态反馈

- 逾期、完成、选中和禁用有文字或图标反馈，状态不能只靠颜色区分；保留键盘焦点和可理解的操作名称。
- 随机结果清晰可读，指针、骰面或币面与文字结果一致；骰子与硬币只展示本次结果，点名与抽签按抽取轮次管理。可重复抽签显示完整签池，不显示耗尽进度。
- 触发操作时确定本次结果，反馈完成后提交结果并更新轮次；一次操作只提交一次，取消未完成操作不消耗点名或抽签轮次。

### 视觉变量（从 tokens.css 自动提取）

颜色、字体与尺寸参数读取独立资源库；HTML 单位的跨平台使用见“HTML 资源复用”。

| 变量 | 当前值 |
| --- | --- |
| `--color-primary` | `#3867e8` |
| `--color-primary-strong` | `#2854d9` |
| `--color-primary-soft` | `#eaf2ff` |
| `--color-lavender` | `#bba3f4` |
| `--color-lavender-soft` | `#f0eaff` |
| `--color-butter` | `#fff4d2` |
| `--color-peach` | `#ffecdf` |
| `--color-mint` | `#e6f5ed` |
| `--color-pink` | `#fcecf3` |
| `--color-ink` | `#202b40` |
| `--color-muted` | `#73819a` |
| `--color-faint` | `#93a0b5` |
| `--color-line` | `#e9edf5` |
| `--color-surface` | `#fff` |
| `--color-canvas` | `#f5f8fd` |
| `--color-danger` | `#d94c62` |
| `--color-danger-soft` | `#ffedf0` |
| `--color-success` | `#198568` |
| `--radius-sm` | `12px` |
| `--radius-md` | `18px` |
| `--radius-lg` | `24px` |
| `--radius-xl` | `30px` |
| `--radius-pill` | `999px` |
| `--space-1` | `4px` |
| `--space-2` | `8px` |
| `--space-3` | `12px` |
| `--space-4` | `16px` |
| `--space-5` | `20px` |
| `--space-6` | `24px` |
| `--shadow-card` | `0 3px 16px #506b9b05, inset 0 1px 0 #ffffffd9` |
| `--shadow-sticker` | `0 5px 3px #6d7ba817` |
| `--shadow-float` | `0 8px 24px #3260c329` |
| `--font-ui` | `"MiSans", "HarmonyOS Sans SC", "PingFang SC", "Microsoft YaHei", system-ui, sans-serif` |
| `--ease-out` | `cubic-bezier(.2,.7,.2,1)` |
| `--duration-fast` | `160ms` |

### 随机工具 HTML 动效参考

以下为六项随机工具的 HTML 动效表现参考，时长、圈数及三维翻转用于展示动作。正式应用的结果与轮次要求见“状态反馈”和首版规格；Android 首版采用简化反馈，复杂动画后置。

- 结果确定、提交与取消遵循“状态反馈”；动画期间不得重新抽取。
- 播放期间锁定编辑、模式切换与重复触发，保留返回以取消动作。演示状态的保留范围见维护说明。
- 运动范围随容器尺寸适配，不遮挡主操作或裁切主体；动作完成或取消时清除临时图层、飞行副本和进行中状态，撤销动作带来的额外倾斜，恢复各场景规定的静态姿态。

#### 转盘

- **触发与时长：**点击“转动”，选项列表非空。参考时长：约 3.1s。
- **动作：**转盘绕中心连续转动至少 5 圈，逐渐减速至停止；指针固定在顶部，仅在转动期间小幅摆动，文字随扇区旋转。
- **完成条件：**指针对准获选扇区中心，停稳后显示对应文字；单选项也应正确落位。

#### 随机点名

- **触发与时长：**点击“开始点名”或“再抽一位”，存在可抽成员。参考时长：约 1.4s。
- **动作：**姓名在固定高度的结果窗口内纵向滚动，逐渐减速并定格；容器与周围进度区保持稳定，不随姓名长度跳动。
- **完成条件：**姓名及可选学号或备注对应同一成员，完整可读；不重复模式完成后更新本轮已抽与剩余人数。

#### 随机分组

- **触发与时长：**点击“开始分组”或“重新分组”，名单与分组参数有效。参考时长：洗牌约 0.8s；发牌 480ms／张，间隔 65ms。
- **动作：**名签先在牌堆两侧交错展开、收拢，再从牌堆逐张飞向目标组；飞行中可轻微倾斜，落位时归正。飞行名签位于分组纸卡上层，目标位置在落位前隐藏，避免重影。
- **完成条件：**每位成员恰好出现一次，同名成员按独立名签保留；标签落位后归正，分组人数符合首版规格。

#### 抽签

- **触发与时长：**点击“抽一签”或“再抽一签”，签池中存在可抽签项。参考时长：摇袋 850ms + 抽签 750ms。
- **动作：**初始长纸签隐藏，袋内短签仅露出签头。签袋与袋内短签整体左右摇动，摆幅逐次收敛；袋身停稳后，长纸签从袋口向上抽出，略微越过终点再回落。抽出区域限制在袋口上方，纸签不得从袋底穿出；袋身遮住纸签下部。
- **完成条件：**停稳后的纸签保留约 −4° 的轻微倾斜，短签文全部露在袋口上方；较长的自定义签文可在纸签内滚动，并在下方提供完整文字，不以默认示例长度限制输入。新一轮恢复初始姿态。

#### 掷骰子

- **触发与时长：**点击“掷一下”或“再掷一次”。参考时长：约 1.9s。
- **动作：**单颗六面骰同时绕两个轴翻滚并向上抛起，下落触地时短暂压缩，随后小幅回弹、停稳；阴影在腾空时缩小变淡，落地时扩大加深，最终恢复。各面随空间朝向显隐，不以切换点数图片代替翻滚。
- **完成条件：**停稳后主可见面点数与大号结果一致；投掷过程中不提前显示本次点数。

#### 抛硬币

- **触发与时长：**点击“抛一下”或“再抛一次”。参考时长：约 1.8s。
- **动作：**单枚硬币上抛并连续翻转，正反面交替显露，侧转时可见厚度；下落后轻弹一次再停稳。阴影随腾空缩小变淡、落地扩大加深，保持与投掷台的位置关系。
- **完成条件：**最终展示星星正面或月牙反面，与文字结果一致；翻转期间不同时透出两面。

演示使用方式见[维护说明](../design/README.md)；运行证据与限制见[检查记录](../design/verification.md)。

### 更新与验收清单

- [ ] 页面标识与当前采用的参考稿明确；已实现状态关联运行截图，尚未设计或实现的状态明确标注缺项。
- [ ] 复用现行变量、图标与材质；新增资源记录来源、用途及替代关系，历史证据与当前稿分开索引。
- [ ] 视觉、布局或交互变更后更新对应运行截图，检查受影响的 393px、320px 布局、长文本、空状态、焦点、滚动与交互。纯说明或链接修改只检查相关文档和入口。
- [ ] 涉及随机工具时核对结果、轮次和反馈；修改 HTML 动效时按动作参考检查取消、落位与临时图层清理。
- [ ] 两版手册同步，本地引用有效；检查记录注明对象、方式、证据与未验证项，只将实际检查的内容记为通过。

资源清单、生成源与更新命令见[手册维护说明](../design/README.md)。
