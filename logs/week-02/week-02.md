# Weekly Review

Week: 2
Date Range: 2026-06-10 ~ 2026-06-16

## 本周主题

GitHub Actions CI 工程化：规范提交、test 报告、缓存优化、matrix 多版本测试、PR 合并流程。

## 完成的内容

- Day08 完善 commit message 规则，统一分支命名前缀
- Day09 配置 test 报告输出目录，测试分支保护规则
- Day10 完善构建流程，配置 CI 缓存
- Day11 深入 npm 缓存配置，验证缓存效果
- Day12 配置 matrix 多版本测试（Node 18.x/20.x），理解 fail-fast
- Day13 规范 PR 合并流程，验证 CI 触发行为
- Day14 整理 Week2 学习日志，回顾 Phase 1 成果

## 最有价值的收获

- matrix 策略可以并行测试多个 Node 版本，保障兼容性
- fail-fast 控制某个版本失败时是否取消其他版本
- npm 缓存能显著减少 CI 执行时间
- commit message 规范化是后续 release note 自动化的基础
- protected branch 确保只有 CI 通过的 PR 才能合并

## 主要卡点

- protected branch 配置错误导致 PR 无法合并
- 缓存命中率不稳定，需要正确设计 cache key
- PR 触发与 push 触发的 CI 行为差异

## 下周调整

- 进入 Phase 2 Docker 与容器基础学习
- 学习 Dockerfile、docker image、docker container
- 为后续镜像构建和 GHCR 推送做准备

## 可展示产出

- `.github/workflows/ci-basic.yml`
- `.github/workflows/ci-node.yml`
- `app/` 示例应用
- project-01-ci-baseline 验收
