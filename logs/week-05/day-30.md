# Daily Log

Date: 2026-06-27
Day: Saturday

## 今日目标

- 完成 Day30 Secrets 学习
- 区分 repository secrets 与 environment secrets
- 建立 secret 安全使用意识

## 实际完成

- 梳理 secret 三层级：organization / repository / environment，作用域递减
- 对比 repo secret 与 environment secret：
  - repo secret：整个仓库所有 job 可读
  - environment secret：仅声明对应 environment 的 job 可读，借用环境保护规则
- 明确同名优先级：environment > repository > organization
- 梳理两种注入方式，推荐用 `env:` 注入而非直接在表达式里使用
- 建立安全红线意识

## 关键概念

- 读取语法统一 `${{ secrets.NAME }}`，区别只在作用域
- environment secret 受环境审批 / 分支限制保护，比 repo secret 更安全
- secret 自动脱敏只对完整匹配生效，base64 / 拼接 / 截断后不保证脱敏
- fork 发起的 pull_request 默认无法访问 secret（防止恶意 PR 窃取）
- secret 不能跨 job 通过 outputs 传递，需要时用 environment 或重新读取

## CD 场景 secret 规划

- Repository secrets：GHCR_TOKEN 等所有环境共用的通用凭证
- Environment dev：DEPLOY_HOST_DEV / DEPLOY_KEY_DEV
- Environment production：DEPLOY_HOST_PROD / DEPLOY_KEY_PROD（受审批保护）

## 今日收获

- secret 分层隔离是 CD 安全的基础
- environment secret 借助环境保护规则实现二次防护
- 注入优先用 env，不要 echo、不进 artifact / 缓存 / PR 评论

## 明日计划

- Day31 Dev 部署 job：用 echo 模拟跑通 CD 骨架
