---
alwaysApply: true
scene: learning_flow
---

# 学习流程规则

凡涉及 `timetable/75-day-plan.md` 中的每日学习内容，AI 必须严格按"先学习 → 总结 → 落盘 → 提 PR"四步流程执行，缺一步都不得进入下一步。

## 第一步：学习

- 仅做讲解、贴示例、写代码片段，**不创建、不修改任何文件**。
- 内容以 Markdown 代码块、ASCII 图、表格呈现，便于直接在对话里消化。
- 不创建 feature 分支，不运行 `git add` / `git commit` / `git push`。
- 不写 `logs/week-*/day-*.md`，不写 `docs/*.md`，不动 `.github/workflows/*.yml`。

## 第二步：总结

- 学完一个主题后，把当天要落的文件清单、关键要点、YAML / Markdown 草稿以"总结"形式输出在对话里，**等你 review**。
- 总结里必须显式列出：① 文件路径 ② 变更目的 ③ 关键参数 / 字段说明 ④ 风险点。
- **未收到用户明确同意（点头 / "动手" / "落盘" / "提交"等）之前，不进入第三步**。

## 第三步：落盘

- 收到用户同意后，按总结里确认的文件路径创建或修改。
- 本地先 `git checkout main && git pull --ff-only` 拉齐。
- 从 `main` 新建 `feature_<变更摘要>` 分支（摘要小写英文、`-` 连接，参考 `git-commit-message.md`）。
- `git add -A` + `git commit -m "<message>"`，message 中文、≤10 字、含 day / 任务信息。
- 不在本步 push。

## 第四步：提 PR

- `git push -u origin <feature-branch>`。
- 若可用 GitHub CLI，调用 `gh pr create --base main --head <branch>` 创建 PR，并回显 PR URL。
- 若 `gh` 不可用，给出 GitHub Compare 链接让用户手动创建。
- 推完后向用户回报：commit hash、message、分支名、PR URL。
- 失败立即停止并报告原因，不重试破坏性操作。

## 每日日志模板（`logs/week-XX/day-NN.md`）

新建每日日志必须严格套用以下骨架，一级章节固定为七个，不得增删或调整顺序：

```markdown
# Daily Log

Date: YYYYMMDD
Day: <星期英文，如 Tuesday>

## 今日目标

- 当日要学习 / 产出的内容

## 实际完成

- 实际完成的内容；主题较多时用 ### 小节展开

## 遇到的问题

- 无

## 解决方式

- 无

## 明日计划

- 下一 Day 的学习主题（以 timetable/75-day-plan.md 为准）

## Commit

- `<type>: <中文摘要>`
```

- 第一行固定 `# Daily Log`，禁止写成 `# Day NN: 标题` 之类；日期与 Day 信息只放在 Date / Day 两行。
- `Date` 统一八位紧凑格式 `YYYYMMDD`（与 week-01~03 历史日志一致），`Day` 统一英文星期名（Monday…Sunday）。
- `实际完成` 下允许用 `###` 小节展开主题；`今日收获` 不单独设一级章节，并入 `实际完成` 或 `解决方式`。
- 周复盘日（Day 21 / 28 / 35 / 42 …）沿用同一骨架，`实际完成` 以索引式条目指向 `week-XX.md`，参考 week-03/day-21.md。
- 某节确实无内容时写 `- 无`，不得整节省略（day-46/47 缺"遇到的问题 / 解决方式"、day-48/49 缺 Date / Day 均属历史不一致，新日志不再沿用）。

## 强制约束

- 全程**禁止跳过"总结 review"**；用户没有点头就不准动文件、不准建分支。
- 全程**禁止直接 commit / push 到 `main`**（与 `git-commit-message.md` 一致）。
- 任何"先写出来给你看"的代码片段，**只在对话里贴**，不要顺手写到磁盘。
- 误判当日主题时（如把 Week 4 当成 K8s 而非 GHCR），必须以 `timetable/75-day-plan.md` 为准，不要凭直觉。
- 不在第一 / 第二步运行 `git checkout -b` 之类会改变仓库状态的高风险命令。

## 自测 checklist（每条 daily 提交前对照）

- [ ] 总结里列出的文件路径用户已确认
- [ ] 文件内容符合 [markdownlint 配置](file:///d:/project/devops-k8s-agent-roadmap/.markdownlint.json) 且与既有 `docs/docker-*.md` 风格一致
- [ ] 日志符合"每日日志模板"（H1、Date / Day、七节齐全且顺序正确）
- [ ] commit message ≤ 10 字、含 day 信息
- [ ] 分支名 `feature_<摘要>`，从最新 `main` 拉出
- [ ] `gh pr create` 已成功并拿到 PR URL 回显
