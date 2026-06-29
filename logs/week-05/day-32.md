# Daily Log

Date: 2026-06-27
Day: Saturday

## 今日目标

- 完成 Day32 Production 人工审批配置
- 理解审批规则配在平台、YAML 只声明环境名
- 对照 dev 与 prod 的差异

## 实际完成

- 明确审批配置位置：Settings → Environments → production
  - Required reviewers：指定审批人 / 团队
  - Wait timer：部署前等待
  - Deployment branches：限定只有 main 可部署
- YAML 侧只声明 `environment: production`，审批由环境配置触发
- 梳理审批执行流：分支检查 → wait timer → 进入 Waiting → 人工 Approve → 部署
- 对照 dev 与 production 的差异维度

## 关键概念

- 审批规则在平台侧，YAML 不写审批逻辑，只声明环境名
- 任意一名 required reviewer Approve 即放行（不是全员通过）
- 可勾选 Prevent self-review 禁止审批自己触发的部署
- 审批最长等待 30 天，超时 job 自动取消
- wait timer 与 reviewers 可叠加，先等计时器再等审批

## dev vs production 对照

| 维度 | dev | production |
| --- | --- | --- |
| 触发 | 自动 | dev 成功后 |
| 审批 | 无 | 必须人工 Approve |
| 分支限制 | 宽松 | 仅 main |
| secret | DEV 系列 | PROD 系列 |
| 出错影响 | 小 | 大 |

## 今日收获

- production 审批 = 环境配 Required reviewers + YAML 声明 environment
- 审批与代码分离，权限更安全、变更更灵活
- 代码仓库被攻破也改不了平台侧审批规则

## 明日计划

- Day33 部署脚本接口设计（SSH / ECS / Docker Compose）
