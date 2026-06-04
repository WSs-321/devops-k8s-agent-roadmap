# Track 06: Agent Platform

## 目标

实现一个面向 DevOps 场景的 Agent MVP，优先支持 CI 失败分析和 PR 总结。

## 推荐独立仓库

Agent 建议使用单独仓库，例如：

```text
agent-platform/
  src/
    agents/
      ci_failure_agent.py
      pr_summary_agent.py
      release_note_agent.py
    tools/
      github_client.py
      actions_logs.py
    prompts/
    tests/
  .github/
    workflows/
      agent-ci.yml
  README.md
```

## Agent 权限阶段

| 阶段 | 权限 |
| --- | --- |
| L0 | 只读本地日志和输入文件 |
| L1 | 只读 GitHub PR、commit、workflow log |
| L2 | 可以生成 markdown 报告 |
| L3 | 可以评论 PR 或创建 issue |
| L4 | 可以触发 dev/staging workflow |
| L5 | 生产操作，暂不建议早期做 |

## MVP 1: CI Failure Agent

输入：

- workflow run id 或日志文件
- commit sha
- PR 信息，可选

输出：

- 失败步骤
- 可能原因
- 修复建议
- 是否需要人工介入
- 相关日志摘要

## MVP 2: PR Summary Agent

输入：

- PR diff
- commit messages
- changed files

输出：

- 变更摘要
- 风险点
- 测试建议
- 发布注意事项

## 验收标准

- 可以对一段 CI 日志生成结构化分析。
- 可以对一个 PR diff 生成摘要。
- Agent 不泄露 secrets。
- Agent 的每次执行都有日志记录。

