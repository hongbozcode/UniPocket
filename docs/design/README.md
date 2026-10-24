# 设计手册维护

入口：[AI 文档版](../product/design.md) · [HTML 可视化版](index.html)。本文件负责维护方式；页面设计要求见 AI 文档版。

## 维护来源

- `catalog.json`：更新日期、当前效果图、页面逻辑标识、截图、规则、流程、验收清单、HTML 动效参考与素材名称。基础页面的 `shot` 指向历史截图，随机工具的 `currentShot` 指向当前动效截图；逻辑标识用于清单关联，演示链接由 `motions` 的页面关联生成。
- [resources/](resources/README.md)：效果图、提示词、图标、插画、材质、视觉参数和页面截图，含历史资料的使用范围。
- `resources/tokens.css`：颜色、字体、间距、圆角及阴影的数值来源；手册的间距与圆角展示从中生成。
- `resources/materials.css`：独立通用材质样式，引用同级 `materials/`。
- `handbook.template.html`、`handbook.css`、`handbook.js`：人用设计手册的结构、样式和浏览交互。
- `build.py`：生成两版手册，并检查资源路径、标识唯一性及项目 Markdown 和生成 HTML 的本地文件链接。

采集状态见[截图索引](resources/screenshots/README.md)。

## 演示使用与动作参考

HTML 演示的通用播放规则维护在 `catalog.json` 的 `motionRules`，六项工具的触发条件、时长、动作与完成条件维护在 `motions`。应用通用的结果与轮次规则维护在 `rules` 的“状态反馈”；Android 首版采用简化反馈。

六项随机工具的动效源码为 [motion-demo.js](motion-demo.js)（动画时序、结果呈现与交互逻辑）和 [motion-demo.css](motion-demo.css)（场景布局、样式与三维表现），复用 resources 素材。[motion.html](motion.html) 是加载这两个文件的独立演示入口；页面卡片和 HTML 动效参考的“播放动效”复用同一套源码。默认示例选项、名单与签池可编辑，重复模式、分组方式和数量可调整；保存编辑会重置该工具的结果与轮次。

正常／慢速播放用于观察动作；“减少动效”便于直接查看结果，仅为演示观看控制，不构成应用功能或系统设置适配要求。

手册关闭预览时按视觉规范的“状态反馈”取消未完成动作。弹窗之间切换保留当前会话的编辑内容与已完成状态，刷新重置；独立样板切换工具会重新载入页面并重置演示状态。完整应用的持久化与编辑流程按首版规格实施。

## 更新

先按视觉规范的使用流程与验收清单判断变更影响。修改 catalog.json 中的页面关联或规则、资源库中的素材或变量；通用生成文案在 build.py，可视化结构在 handbook.template.html。仅文案或链接变化无需重采应用页面截图；布局、视觉或交互变化则更新受影响对象的证据。

在仓库根目录运行：

```powershell
python docs/design/build.py
python docs/design/build.py --check
```

docs/product/design.md 和 docs/design/index.html 是生成文件，直接编辑会被覆盖。数量从清单与资源目录计算，更新日期在 catalog.json 维护。

`--check` 不写文件：检查生成内容同步、资源存在、页面与参考稿标识唯一、页面关联有效；扫描根目录、docs/、.scratch/ 下的项目 Markdown 本地文件链接（排除代码示例），以及生成 HTML 的文件链接和页内锚点。它不验证外部网址、Markdown 标题锚点、技能包内部文档或截图内容，也不运行样板交互。

## 查看与验证

手册内嵌页面数据，可直接打开 index.html 浏览；直接文件模式的实际验证状态见检查记录。使用本地 HTTP 服务时，在仓库根目录运行：

```powershell
python -m http.server 4173 --bind 127.0.0.1
```

访问 `http://127.0.0.1:4173/docs/design/`，按 Ctrl+C 停止。手册支持效果图与样板截图对照、动效播放、素材筛选下载和色值复制。

检查结论见 [verification.md](verification.md)。业务范围仍以[首版规格](../../.scratch/unipocket-v1/spec.md)为准。
