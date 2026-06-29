# Daily Log

Date: 2026-06-27
Day: Saturday

## 今日目标

- 完成 Day29 GitHub Environments 环境概念设计
- 设计 dev / staging / production 三环境模型
- 理解 environment 与 protection rules 的关系

## 实际完成

- 理解 Environment 是仓库级"部署目标抽象"，不是服务器，而是带保护规则和专属配置的逻辑命名空间
- 设计三环境模型：
  - dev：push 到 main 自动部署，无审批，快速验证
  - staging：手动 / tag 触发，可选审批，贴近生产
  - production：tag / release 触发，必须人工审批，正式对外
- 梳理三类 protection rules：
  - Required reviewers：最多 6 人/团队，job 暂停等审批
  - Wait timer：部署前强制等待，最多 30 天
  - Deployment branches：限制可部署分支（all / protected / selected）
- 用 `environment:` + `needs:` 组合表达"分环境、有顺序、要审批"的 CD 骨架

## 关键概念

- `environment.name`：关联环境，决定读取哪个环境的 secret / variable
- `environment.url`：部署成功后 UI 显示的访问地址，仅展示用
- 部署执行流：分支白名单检查 → wait timer → required reviewers → 执行部署
- 核心价值：把"在哪部署、谁能部署、用什么密钥"从代码剥离，交给平台管控

## 今日收获

- Environment = 部署目标 + 保护规则 + 专属配置
- 三大保护规则是 CD 安全的核心机制
- needs 表达部署顺序，environment 叠加审批卡点

## 明日计划

- Day30 Secrets：repo secrets 与 environment secrets 的区别
