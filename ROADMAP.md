# Roadmap

## 总体路线

```text
Git/GitHub 基础
  -> GitHub Actions CI
  -> Docker 与镜像仓库
  -> GitHub Environments CD
  -> 安全扫描与质量门禁
  -> 可观测与发布治理
  -> Kubernetes/阿里云 ACK 预备
  -> Agent MVP
```

## 阶段划分

| 阶段 | 时间 | 主题 | 关键产出 |
| --- | --- | --- | --- |
| Phase 1 | 第 1-2 周 | GitHub Actions CI | PR 检查、测试、构建 workflow |
| Phase 2 | 第 3-4 周 | Docker + GHCR | Dockerfile、镜像构建、镜像推送 |
| Phase 3 | 第 5 周 | CD 与环境治理 | dev/staging/prod environments |
| Phase 4 | 第 6 周 | 安全与质量门禁 | CodeQL/Trivy/Dependabot 基础接入 |
| Phase 5 | 第 7-8 周 | K8s/ACK 预备 | Deployment、Service、Ingress、Helm 基础 |
| Phase 6 | 第 9-10 周 | Agent MVP | CI failure agent、PR summary agent |
| Phase 7 | 第 11 周前半 | 集成与复盘 | 端到端演示、最终文档、下一阶段计划 |

## 学习原则

- 先 GitHub Actions，后 Kubernetes。
- 先 GitHub-hosted runner，后自建 runner。
- 先 GHCR，后阿里云 ACR。
- 先普通部署，后 GitOps。
- 先只读 Agent，后半自动 Agent。
- 生产操作始终保留人工审批。

## 仓库策略

建议至少维护两个仓库：

| 仓库 | 作用 |
| --- | --- |
| `devops-k8s-agent-roadmap` | 学习计划、笔记、模板、复盘 |
| `cicd-demo-app` | 练习 GitHub Actions CI/CD 的示例业务项目 |
| `agent-platform` | 后续实现 CI 分析、PR 总结、发布评审 Agent |

第一个仓库就是当前学习路线仓库。后两个仓库可以在第 2 周和第 7 周分别创建。

