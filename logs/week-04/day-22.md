# Daily Log

Date: 2026-06-23
Day: Tuesday

## 今日目标

- 理解 GHCR 登录机制与 GITHUB_TOKEN 权限
- 学习 packages 写入权限

## 实际完成

- 理解 GITHUB_TOKEN 默认权限
  - PR 来自 fork 时是只读
  - push / workflow_dispatch 时可写 packages
- workflow 加 `permissions: contents: read, packages: write`
- 验证 GHCR 镜像包归属：
  - 包名 = owner 下的命名空间
  - 仓库和包是软关联

## 遇到的问题

- GHCR 包属于 owner，不在仓库下面
- PR 时 secrets 拿不到 packages: write 权限

## 解决方式

- Login step 加 `if: github.event_name != 'pull_request'`
- PR 时跳过登录，只在 push / dispatch 时推镜像
- 在 github.com/WSs-321?tab=packages 查看镜像

## 明日计划

- Day 23 配置 build-push-action 自动化构建和推送

## Commit
