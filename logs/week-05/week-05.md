# Weekly Review

Week: 5
Date Range: 2026-06-24 ~ 2026-07-02

## 本周主题

CD 与 GitHub Environments：从环境设计、密钥管理、部署 job、生产审批，到部署脚本和 release note 生成，形成一条基础发布链路。

## 完成的内容

- Day29 Environments
  - 设计 dev / staging / production 三套环境
  - 理解 GitHub Environments 的环境隔离作用
- Day30 Secrets
  - 区分 repository secrets 与 environment secrets
  - 梳理不同环境的变量与密钥命名方式
- Day31 Dev 部署
  - 编写 dev deploy job
  - 用 echo / 模拟脚本验证部署链路
- Day32 Production 审批
  - 理解 production environment 的人工审批规则
  - 明确审批在平台侧配置，YAML 只声明环境名
- Day33 部署脚本
  - 设计 `scripts/deploy.sh`
  - 支持 ssh / docker / compose / ecs 部署目标
  - 引入 `DRY_RUN` 演练模式
  - 学习 Docker Compose 并补充本地和远程 compose 示例
- Day34 Release notes
  - 更新提交规范为 Conventional Commits 前缀
  - 新增 `scripts/gen-release-note.sh`
  - 新增 `.github/workflows/release.yml`
  - 支持 tag 触发生成 GitHub Release

## 最有价值的收获

- CD 不是单个 workflow，而是一套环境、权限、密钥、审批、部署、发布说明组成的链路
- GitHub Environments 适合承载环境级变量、密钥和审批规则
- `DRY_RUN` 是没有真实服务器时保持部署流程可验证的关键手段
- Docker Compose 适合把部署命令从手写 `docker run` 升级为声明式编排
- Release Note 的质量依赖 commit message 规范，因此引入前缀规范是必要前置工作

## 主要卡点

- 没有真实服务器时，SSH 部署和健康检查需要模拟模式协调
- `deploy.sh` 中 `set -u` 会让未设置变量提前失败，需要使用 `${VAR-}` 兜底
- `health_check` 不能在模拟部署时真实 curl，否则部署与检查逻辑不一致
- release workflow 需要正确配置 `permissions: contents: write` 与 `GH_TOKEN`
- Windows / PowerShell 环境下部分 shell 命令细节需要注意

## 下周调整

- 进入 Week6 安全、质量、治理主题
- 重点关注 workflow permissions 最小化、Dependabot、CodeQL、Secrets 安全
- 延续前缀化 commit message，为后续 release note 自动生成打基础
- 对已有 workflow 做权限收敛和安全审查

## 可展示产出

- `.github/workflows/cd-env.yml`
- `.github/workflows/cd-deploy.yml`
- `.github/workflows/release.yml`
- `scripts/deploy.sh`
- `scripts/gen-release-note.sh`
- `app/compose.yml`
- `docker-compose.yml`
- `docs/docker-compose.md`
- `templates/release-note.md`
