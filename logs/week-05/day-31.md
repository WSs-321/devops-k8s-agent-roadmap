# Daily Log

Date: 2026-06-27
Day: Saturday

## 今日目标

- 完成 Day31 Dev 部署 job
- 用 echo / 模拟脚本跑通 dev 部署链路
- 理解 CI 与 CD 的衔接方式

## 实际完成

- 写出最小 dev deploy job 骨架：
  - `environment.name: dev` 关联 dev 环境
  - `environment.url` 显示访问地址
  - 用 `env:` 注入 `vars.DEPLOY_HOST_DEV` 与 `secrets.DEPLOY_KEY_DEV`
  - steps 用 echo 模拟真实部署命令
- 梳理 CI 与 CD 两种衔接方式：
  - 方式 A：同一 workflow 用 needs 串联 build → push → deploy-dev
  - 方式 B：CD 独立 workflow，由镜像推送事件触发（workflow_run / repository_dispatch）
- 明确 dev 环境定位：自动触发、无审批、快速反馈

## 关键概念

- `vars.X` 存非敏感配置（主机名、区域），`secrets.X` 存敏感配置（密钥、密码）
- 先用 echo 占位跑通触发 / 环境 / 权限链路，真实命令最后接入
- dev 环境通常不设 reviewers，允许 main 分支自动部署
- 真实部署命令未来会替换为 ssh / kubectl / docker compose

## 今日收获

- dev deploy job = environment: dev + 模拟部署 steps
- 先打通骨架再接真实命令，降低调试成本
- dev 追求快速反馈，不加审批

## 明日计划

- Day32 Production 人工审批配置
