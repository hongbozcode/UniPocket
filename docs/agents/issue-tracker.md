# Issue tracker: Local Markdown

任务和规格以 Markdown 文件保存在本仓库的 `.scratch/` 中。

## 文件约定

- 每个功能使用一个目录：`.scratch/<feature-slug>/`。
- 规格：`.scratch/<feature-slug>/spec.md`。
- 实现任务：`.scratch/<feature-slug>/issues/<NN>-<slug>.md`，
  从 `01` 开始编号，每个任务独立成文件。
- 任务顶部使用 `Status:` 记录 triage 状态；
  状态取值见 `docs/agents/triage-labels.md`。
- 评论和讨论追加到文件末尾的 `## Comments` 下。

## 发布与读取

技能要求“发布到 issue tracker”时，按上述约定创建文件及所需目录。

技能要求“获取相关 ticket”时，读取给定路径。
只提供编号时，在对应功能目录中查找；无法唯一定位时询问用户。

## Wayfinding

供 `/wayfinder` 使用：

- 地图：`.scratch/<effort>/map.md`，
  包含 Notes、Decisions-so-far、Fog。
- 子任务：`.scratch/<effort>/issues/<NN>-<slug>.md`，
  从 `01` 开始编号，正文记录待解问题。
- `Type:` 为 research、prototype、grilling 或 task。
- Wayfinder 子任务的 `Status:` 使用执行状态：
  open、claimed、resolved；与 triage 分类状态分开使用。
- 依赖：文件顶部用 `Blocked by: NN, NN` 列出前置任务；
  所有前置任务均为 resolved 时解除阻塞。
- 选择任务：按编号选择第一个 open 且无阻塞的任务。
- 认领：开始工作前写入 `Status: claimed` 并保存。
- 完成：在 `## Answer` 下追加结果，设置 `Status: resolved`，
  并向地图的 Decisions-so-far 追加摘要及相对文件链接。
