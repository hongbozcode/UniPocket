# Domain Docs

本仓库采用 single-context 领域文档布局。

## 探索前读取

- 根目录 `GLOSSARY.md`：领域术语。
- `docs/adr/`：与当前工作相关的架构决策。

文件缺失时直接继续。领域术语或决策明确后，由
`/domain-modeling` 按需创建相应文档。

## 布局

- `GLOSSARY.md`
- `docs/adr/<NNNN>-<decision-slug>.md`

## 术语一致性

任务标题、设计提案、假设和测试名称使用词汇表定义的术语。
遇到未收录的概念时，先判断能否使用已有术语；
确有缺口则记录给 `/domain-modeling`。

## 决策冲突

提案与现有 ADR 冲突时，明确指出对应 ADR 和重新讨论的理由。
