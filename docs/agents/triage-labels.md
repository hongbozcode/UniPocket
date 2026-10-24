# Triage Labels

本地任务通过文件顶部的 `Status:` 行记录 triage 状态。

| 规范角色 | 本地状态 | 含义 |
| --- | --- | --- |
| needs-triage | needs-triage | 等待维护者评估 |
| needs-info | needs-info | 等待补充信息 |
| ready-for-agent | ready-for-agent | 规格完整，可由代理执行 |
| ready-for-human | ready-for-human | 需要人工实现 |
| wontfix | wontfix | 不予处理 |

技能提及某个 triage 角色时，使用此表对应的本地状态。
Wayfinder 的执行状态遵循 `docs/agents/issue-tracker.md`。
