# Track 01: GitHub Actions CI

## 目标

掌握 GitHub Actions 的核心概念，并能为一个真实项目建立可靠的 CI 流水线。

## 必学概念

- workflow
- event
- job
- step
- runner
- action
- context
- secrets
- permissions
- artifacts
- cache
- matrix

## 最小 CI 流水线

```text
checkout
  -> setup runtime
  -> install dependencies
  -> lint
  -> test
  -> build
  -> upload artifact
```

## 验收标准

- PR 会自动触发 CI。
- main 分支 push 会自动触发 CI。
- lint/test/build 任一步失败都会让 workflow 失败。
- workflow 日志可以帮助你定位失败原因。
- 至少使用一次 cache 和 artifact。

