---
alwaysApply: true
scene: git_message
---

# Git Commit Message 规则

## 内容格式
- 使用 Conventional Commits 前缀，格式为 `<type>: <中文摘要>`
- `type` 必须使用：`feat`、`fix`、`docs`、`style`、`refactor`、`test`、`chore`、`ci` 之一
- 摘要使用中文，简短概括本次变更内容，尽量不超过 15 字
- 若一次涉及多处相似改动，合并为一条 message，需覆盖所有改动要点

## 自动提交行为
- 完成任意代码/文档/配置变更后，AI 必须自动按本规则生成 commit message
- 禁止直接向 `main` 分支提交或推送变更
- 若当前在 `main` 分支，先创建功能分支，分支名统一使用 `feature_<变更摘要>`，摘要使用小写英文短词并用 `-` 连接
- message 尽可能包含 timetable 中的 day 和任务信息，格式仍需符合 `<type>: <中文摘要>`
- 生成 message 后无需向用户确认，直接执行：`git add -A`、`git commit -m "<message>"`、`git push -u origin <branch>`
- 推送完成后，向用户回报：commit hash、message、分支名、PR 创建入口
- 若可用 GitHub CLI，则优先创建 PR；否则提供 GitHub Compare 链接让用户创建 PR
- 如执行失败（冲突、网络等），停止并向用户报告原因，不要重试破坏性操作

## 合并提交
- 若上一次 push 之后产生了多次本地 commit 且内容相似，应通过 `git reset --soft` 或 `git commit --amend` 合并为一条
- 合并后的 message 必须覆盖被合并 commit 的全部要点，并符合 `<type>: <中文摘要>` 格式
- 不修改已经推送到远端的历史 commit

