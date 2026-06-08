---
alwaysApply: true
scene: git_message
---

# Git Commit Message 规则

## 内容格式
- 使用中文，简短概括本次变更内容，总字数不超过 10 字
- 不需要 type 前缀（如 feat/fix），直接描述变更
- 若一次涉及多处相似改动，合并为一条 message，需覆盖所有改动要点

## 自动提交行为
- 完成任意代码/文档/配置变更后，AI 必须自动按本规则生成 commit message
- 生成 message 后无需向用户确认，直接执行：`git add -A`、`git commit -m "<message>"`、`git push`
- 推送完成后，向用户回报：commit hash、message、推送结果
- 如执行失败（冲突、网络等），停止并向用户报告原因，不要重试破坏性操作

## 合并提交
- 若上一次 push 之后产生了多次本地 commit 且内容相似，应通过 `git reset --soft` 或 `git commit --amend` 合并为一条
- 合并后的 message 必须覆盖被合并 commit 的全部要点，仍保持 10 字以内
- 不修改已经推送到远端的历史 commit

