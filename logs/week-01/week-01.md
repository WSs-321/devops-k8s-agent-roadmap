# Weekly Review

Week: 1
Date Range: 2026-06-04 ~ 2026-06-09

## 本周主题

GitHub Actions CI 基础：从零搭建 Node.js 项目的 CI workflow。

## 完成的内容

- Day01 创建学习日志，确认 GitHub 账号、仓库、分支策略
- Day02 学习 GitHub Actions 概念：workflow、job、step、runner、event、action、composite
- Day03 为示例应用添加 setup、install、test 步骤
- Day04 实现 node 打包构建流程，配置 PR 合并策略
- Day05 搭建最小 Node.js 示例应用作为 CI 基线
- Day06 初始化项目配置，配置 npm 缓存
- Day07 添加 ESLint 代码检查，集成到 CI

## 最有价值的收获

- GitHub Actions 的核心概念：workflow 由 job 组成，job 由 step 组成
- `npm ci` 需要 package-lock.json，比 `npm install` 更适合 CI
- ESLint 放在 devDependencies，CI 中 lint 失败可阻断流程
- protected branch + required status checks 保障代码质量

## 主要卡点

- `npm ci` 需要 package-lock.json 才能执行
- eslint 依赖位置（dependencies vs devDependencies）
- CI 缓存配置方式选择

## 下周调整

- 继续完善 CI：test 报告、缓存、matrix 多版本测试
- 规范 commit message 和分支命名
- 进入 project-01-ci-baseline 验收
