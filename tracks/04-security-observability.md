# Track 04: Security And Observability

## 目标

为 CI/CD 建立最小安全基线和可观测意识。

## 安全基线

- workflow 显式声明 `permissions`。
- 使用 Dependabot 管理依赖更新。
- 使用 CodeQL 或其他工具做代码扫描。
- 使用 Trivy 做镜像扫描。
- secrets 不写入代码、不打印到日志。
- production secrets 只配置到 production environment。

## 可观测基线

即使还没有 K8s，也需要在学习项目中建立以下意识：

- 应用输出结构化日志。
- 服务提供健康检查接口。
- 发布记录包含版本和 commit sha。
- 失败时能够从日志定位问题。
- 每个重要故障都写复盘。

## 验收标准

- 至少有一个安全扫描 workflow。
- 至少有一份 secrets 管理规范。
- 至少有一份发布失败复盘记录。

