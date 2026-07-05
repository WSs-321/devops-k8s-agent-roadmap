# Daily Log

Date: 2026-06-28
Day: Sunday

## 今日目标

- 完成 Day33 部署脚本接口设计
- 设计 SSH / Docker / Docker Compose / ECS 四类部署方式的统一接口
- 让 GitHub Actions workflow 只负责传参，部署逻辑下沉到脚本

## 实际完成

- 新增 `scripts/deploy.sh` 部署脚本接口
  - 参数校验：`DEPLOY_ENV` / `DEPLOY_TARGET` / `APP_NAME` / `IMAGE` / `IMAGE_TAG` 必填
  - 退出码约定：0 成功、10 参数缺失、20 认证失败、30 拉取失败、40 启动失败、50 健康检查失败
  - 四种部署后端：`ssh` / `docker` / `compose` / `ecs`
  - `DRY_RUN=true` 时只打印命令不真正执行，便于无服务器时演练
  - `health_check` 支持 curl 重试 5 次，每次间隔 3 秒
- 新增 `.github/workflows/cd-deploy.yml` 三阶段部署 workflow
  - dev → staging → production 串行
  - 每个 job 调用 `./scripts/deploy.sh`，用 `env:` 注入参数
  - secret / vars 按环境隔离（DEV / STAGING / PROD 三组）
- 新增 `app/compose.yml` 占位，为后续 Docker Compose 部署做准备

## 关键概念

- 部署脚本接口 = 固定输入 + 固定输出 + 固定退出码 + 可替换部署后端
- workflow 不直接写复杂部署逻辑，只调用脚本，职责清晰
- `DEPLOY_TARGET` 决定走哪个部署函数，未来切换 ECS / K8s 只改参数不改 workflow
- secret 通过 GitHub environment 注入，脚本不打印敏感值
- 幂等性：`docker stop || true; docker rm || true` 避免容器名冲突

## 接口设计

### 输入参数（环境变量）

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `DEPLOY_ENV` | 是 | dev / staging / production |
| `DEPLOY_TARGET` | 是 | ssh / docker / compose / ecs |
| `APP_NAME` | 是 | 应用名 |
| `IMAGE` | 是 | 镜像地址 |
| `IMAGE_TAG` | 是 | 镜像 tag |
| `HEALTH_CHECK_URL` | 否 | 健康检查地址 |
| `DRY_RUN` | 否 | true 时只打印不执行 |
| `SSH_PRIVATE_KEY` | 否 | ssh 模式密钥 |
| `DEPLOY_HOST` | 否 | ssh 模式主机 |
| `DEPLOY_USER` | 否 | ssh 模式用户 |

### 退出码

| 码 | 含义 |
| --- | --- |
| 0 | 成功 |
| 10 | 参数缺失 |
| 20 | 认证失败 |
| 30 | 镜像拉取失败 |
| 40 | 启动失败 |
| 50 | 健康检查失败 |

## 遇到的问题

- bash `{ echo ...; }` 花括号前后必须有空格，否则报 `{echo: command not found`
- `ssh user@host cmd` 中变量未加引号会被本地 shell 拆词
- `docker run --name app` 重复执行会因容器名冲突失败，需要先 `stop/rm`
- workflow `paths` 写错文件名（`cd-env.yml` 而非 `cd-deploy.yml`），导致改 workflow 不触发 CI

## 解决方式

- 修正 `{ }` 语法，前后加空格
- ssh 命令字符串加双引号：`ssh "$DEPLOY_USER@$DEPLOY_HOST" "cmd"`
- 加 `docker stop || true; docker rm || true` 实现幂等
- 修正 `paths` 为 `cd-deploy.yml`，并追加 `scripts/deploy.sh`

## 今日收获

- 部署脚本接口的核心是"契约先行"：先定输入输出，再写实现
- `case "$DEPLOY_TARGET" in` 分发模式让脚本可扩展，未来加 K8s 只需新增一个函数
- `DRY_RUN` 机制让无服务器环境也能演练整条部署链路
- workflow 与脚本的职责分离：workflow 管流程编排，脚本管部署细节
- `set -euo pipefail` 让脚本在任意失败处立即退出，避免错误传播

## 明日计划

- Day34 Release notes 学习
- 根据 commit 生成 release note 模板
- 了解发布 workflow 与 deploy workflow 的职责边界

## Commit

- `feat: day33加部署脚本接口`
