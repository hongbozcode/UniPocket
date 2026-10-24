<!-- context7 -->
库/框架/SDK/API/CLI/云服务文档问题（语法、配置、迁移、库相关调试、安装、用法）优先用 Context7 MCP 查最新文档，已知/知名项目也适用；优先于网页搜索。Context7 不可用或无结果时再用网页搜索。不用于：重构、从零写脚本、业务逻辑调试、代码审查、通用编程概念。

## Product context

实施首版功能前，读取 `.scratch/unipocket-v1/spec.md`；它是范围、行为与验收的权威依据。查找视觉规范、技术候选或后续规划时，使用 `README.md` 的文档入口。讨论记录仅作历史参考。

## 页面设计与视觉实现

设计或修改页面、组件、图标、材质或动效前，必须读取[视觉设计规范](docs/product/design.md)，按其中的使用流程复用资源，并按变更影响完成验收。[HTML 设计手册](docs/design/index.html)提供可视化对照；业务范围与行为仍以首版规格为准。

## 代理说明维护

代理说明统一维护在本文件，`CLAUDE.md` 仅保留指向本文件的入口。运行技能初始化或更新流程时，沿用此约定及 `docs/agents/` 的项目配置；技能内的通用模板不替代项目约定。

## Agent skills

### Issue tracker

任务和规格存放在 `.scratch/<feature>/`。创建、读取或更新任务前，阅读 `docs/agents/issue-tracker.md`。

### Triage labels

使用五个默认 triage 状态。分类任务或更新分类状态前，阅读 `docs/agents/triage-labels.md`。

### Domain docs

采用 single-context 布局：根目录 `GLOSSARY.md` 和 `docs/adr/`。探索领域或提出设计变更前，阅读 `docs/agents/domain.md`。
