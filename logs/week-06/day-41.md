# Daily Log

Date: 2026-07-07
Day: 41

## 今日目标

- 完成 Day 41 分支保护学习
- 设计 main 分支保护规则和合并策略
- 理解 status check 机制与常见坑

## 实际完成

- 学习 GitHub 分支保护规则的全部能力
- 明确项目适用的保护规则配置
- 理解合并策略（merge/squash/rebase）差异
- 梳理 status check 的 4 个常见坑
- 学习 signed commit 原理与适用场景

## 关键概念

### 分支保护规则六项能力

| 能力 | 说明 |
| --- | --- |
| 合并前要求 | PR 必须 ≥N 人 approve、通过 CI、解决 conversation |
| Status check | 指定 job 必须 green 才允许 merge |
| 推送限制 | 禁止 force push、禁止直接 push、禁止删除分支 |
| Signed commit | GPG/SSH 签名验证提交者身份 |
| 线性历史 | 禁止 merge commit，强制 rebase/squash |
| 锁定分支 | 只读，任何人都不能 push |

### 合并策略对比

| 策略 | 效果 | 适用 |
| --- | --- | --- |
| Merge commit | 保留完整分支历史 | 传统团队 |
| Squash merge | 整个 PR 压成 1 个 commit | 本项目（daily 笔记） |
| Rebase merge | 无 merge commit，线性历史 | 严格线性历史要求 |

### Status Check 命名规则

- 默认 status check 名 = job 的 `id`
- 显式 `name:` 会覆盖
- 矩阵 job 格式：`ci (18.x)`、`ci (20.x)`

### Signed Commit

- GPG/SSH 数字签名验证提交者身份，防伪造
- GitHub 标记：Verified（绿）/ Unverified（橙）/ 无标记
- 单人学习项目不推荐开启，增加复杂度且无实际收益

## "Require branches to be up to date" 深入分析

### 判断逻辑

- 检查 PR 分支 HEAD 是否包含 main 最新 commit
- 不包含 → 分支落后 → Merge 按钮灰掉，旧 CI 结果标记 stale

### PR 合入后其他 PR 的状态

```text
PR-a 合入 → main 前进 → PR-b 分支落后
→ PR-b 旧 CI 结果失效（stale），不会自动重跑
→ 需手动点击 "Update branch" 或 rebase → 才触发 CI 重跑
```

### 自动重跑场景

- 纯 GitHub + 保护规则：不会自动重跑
- 配 Mergify / Kodiak / bors / auto-merge 等 merge queue 工具：会自动 rebase → 触发 CI

### 本项目建议

不开 "Require branches to be up to date"，原因：

- 单人项目，一次一个 PR，无并发冲突
- 每天一个笔记文件，PR 间独立
- 开启只会徒增 rebase + CI 重跑开销

## 推荐配置

```text
Branch: main
✅ Require a pull request before merging
   ✅ Require approvals: 1
   ✅ Dismiss stale reviews when new commits are pushed
✅ Require status checks to pass before merging
   Status checks: ci, node-ci, docs-check
✅ Block force pushes
✅ Do not allow bypassing the above settings
```

不建议开启：

- Require branches to be up to date（单人项目无必要）
- Require signed commits（无实际安全收益）
- Require linear history（Squash merge 已覆盖）

## 今日收获

- 分支保护的核心是"PR + CI green + approve"三道防线
- Status check 名必须与 job 名完全一致，大小写敏感
- 新 workflow 首次 PR 不能作为 required check（必须先合入 main 一次）
- `workflow_run` 事件无法作为 required check（PR 阶段不触发）
- Squash merge 最适合单人学习项目，保持 main 干净
- "up to date" 规则有坑，无 merge queue 工具时是纯人工负担

## 明日计划

- Day 42 周复盘：输出 CI/CD 安全基线文档

## Commit

- `feat: Day41 分支保护规则笔记`
