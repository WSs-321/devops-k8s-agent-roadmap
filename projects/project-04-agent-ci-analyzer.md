# Project 04: Agent CI Analyzer

## 目标

实现一个最小可用的 CI 失败分析 Agent。

## 仓库建议

建议新建独立仓库：

```text
agent-platform
```

## MVP 范围

第一版只需要支持：

- 输入一份 GitHub Actions 日志文本。
- 识别失败 job 和失败 step。
- 提取关键错误片段。
- 输出 markdown 格式分析报告。

第二版再支持：

- 通过 GitHub API 读取 workflow run。
- 读取 PR 信息。
- 将报告评论到 PR。

## 验收标准

- 对至少 3 类失败日志输出分析。
- 不输出 secrets。
- 输出格式稳定，方便贴到 PR。
- 有最小测试用例。

