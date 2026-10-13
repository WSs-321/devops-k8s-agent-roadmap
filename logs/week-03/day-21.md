# Daily Log

Date: 20260622
Day: Monday

## 今日目标

- 完成 Week 3 周复盘，整理 Docker 错误与最佳实践

## 实际完成

- 编写 [week-03.md](week-03.md) 周复盘，梳理 Day 15-20 学习路径
- 沉淀本周踩坑与解法：
  - branch protection "Waiting for status to be reported" 误报（CI 实际 success）
  - workflow 文件名混乱 → 统一重命名为 `ci-<scope>.yml`
  - 一个 step 写了两个 uses → 一个 step 只能有一个 uses
  - `*.md` 与 `**/*.md` 跨目录匹配混淆 → 用 `**/*.md` 覆盖任意层级
  - PR 流程不规范 → 每个新功能单独建 feature 分支
- 梳理 Docker 最佳实践：多阶段构建、HEALTHCHECK、配置外置、镜像标签策略（latest 陷阱）
- 固化本周基建：CI 拆分（ci-node / ci-docs / ci-basic）、markdownlint 中文场景配置、IDE autofetch

## 遇到的问题

- 无（本周问题已在周复盘统一沉淀）

## 解决方式

- 以 [week-03.md](week-03.md) 作为 Week 3 踩坑与解法的主记录，后续每周沿用该复盘模式

## 明日计划

- 进入 Week 4：GHCR 与镜像流水线（Day 22 GHCR 登录）

## Commit

- `整理 Week 3 学习内容：Docker 4 个文档 + CI 拆分 + IDE 配置`
