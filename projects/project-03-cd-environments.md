# Project 03: CD With GitHub Environments

## 目标

使用 GitHub Environments 实现 dev / staging / production 发布治理，形成环境隔离、密钥管理、部署脚本、人工审批与发布说明的基础 CD 链路。

## 任务

- 创建 dev environment。
- 创建 staging environment。
- 创建 production environment。
- 为 production 配置 required reviewers。
- 写 deploy workflow。
- dev 自动执行。
- staging 在 dev 成功后执行。
- production 需要审批。
- 发布日志输出版本信息。
- 使用部署脚本统一封装 SSH / Docker / Docker Compose / ECS 部署入口。
- 使用 release note 脚本根据 commit 生成发布说明。

## 已完成内容

- 设计 dev / staging / production 三套环境。
- 梳理 repository secrets 与 environment secrets 的职责边界。
- 新增 CD 环境示例 workflow，验证环境变量和环境声明方式。
- 新增 CD 部署 workflow：
  - dev 自动部署。
  - staging 依赖 dev。
  - production 依赖 staging，并通过 GitHub Environment 承载审批能力。
- 新增 `scripts/deploy.sh`：
  - 支持 `ssh` / `docker` / `compose` / `ecs` 部署目标。
  - 支持 `DRY_RUN=true`，在暂无服务器时演练部署流程。
  - 支持部署后 `HEALTH_CHECK_URL` 健康检查。
- 引入 Docker Compose 部署示例：
  - `app/compose.yml` 用于本地 build 验证。
  - `docker-compose.yml` 用于远程 image 拉取部署。
- 新增 release note 能力：
  - `scripts/gen-release-note.sh` 根据 commit 自动生成发布说明。
  - `.github/workflows/release.yml` 在 tag `v*` 推送时创建 GitHub Release。
- 更新 commit message 规范为 Conventional Commits 前缀，提升 release note 可读性。

## 验收标准

| 标准 | 状态 | 说明 |
| --- | --- | --- |
| dev job 可以自动执行 | 已完成 | `cd-deploy.yml` 中 dev 环境可自动运行 |
| production job 会等待审批 | 已设计 | YAML 声明 `environment: production`，审批规则在 GitHub Environment 平台侧配置 |
| environment secrets 不混用 | 已完成 | dev / staging / production 分别使用对应变量与 secret 命名 |
| 发布记录中包含 commit sha 和镜像 tag | 已完成 | workflow 使用 `github.sha` 作为 `IMAGE_TAG`，release note 支持记录镜像信息 |
| 部署脚本接口统一 | 已完成 | `deploy.sh` 通过 `DEPLOY_TARGET` 分发部署目标 |
| 暂无服务器时可验证流程 | 已完成 | `DRY_RUN=true` 保证部署与健康检查均走演练模式 |
| 发布说明可自动生成 | 已完成 | `gen-release-note.sh` 使用 git log 生成 Changes |

## 验收结论

Project 03 已达到基础验收标准。当前仓库已经具备从环境设计、密钥隔离、部署流程、生产审批、部署脚本封装到 release note 生成的基础 CD 能力。

当前仍属于学习 / 演练阶段，真实上线前还需要补齐以下内容：

- 在 GitHub Settings 中配置实际 dev / staging / production environments。
- 为 production 设置 required reviewers 和分支限制。
- 配置真实服务器的 `DEPLOY_HOST_*`、`DEPLOY_USER_*`、`SSH_PRIVATE_KEY_*`。
- 将 `DRY_RUN` 从 `true` 切换为 `false` 后进行真实部署验证。
- 根据实际发布策略创建 tag 并验证 release workflow。

## 后续改进

- 在 Week6 中审查所有 workflow 的最小权限配置。
- 配置 Dependabot 和 CodeQL，提升供应链与代码安全能力。
- 整理 Secret 安全规范，避免密钥误打印到日志。
- 引入 SBOM 与分支保护策略，形成 CI/CD 安全基线。
