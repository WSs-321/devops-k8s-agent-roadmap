# Track 03: CD And Environments

## 目标

使用 GitHub Environments 管理 dev、staging、production 发布流程。

## 环境策略

| 环境 | 触发方式 | 审批 | Secrets |
| --- | --- | --- | --- |
| dev | main push 后自动 | 不需要 | dev secrets |
| staging | main push 或手动 | 可选 | staging secrets |
| production | tag 或手动 | 必须 | production secrets |

## 发布原则

- CI 成功后才允许 CD。
- dev 可以自动，production 必须审批。
- 每次发布必须记录 commit sha、镜像 tag、触发人、时间。
- 生产密钥只放在 production environment secrets。

## 验收标准

- workflow 中存在独立 deploy job。
- deploy job 绑定 GitHub environment。
- production environment 需要人工审批。
- 发布日志能看到版本信息。

