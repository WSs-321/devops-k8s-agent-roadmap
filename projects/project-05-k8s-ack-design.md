# Project 05: K8s ACK Design

## 目标

不急着上云，先完成从 GitHub Actions 到阿里云 ACK 的部署设计。

## 任务

- 画出 GitHub Actions -> ACR -> ACK 的链路。
- 设计 dev/staging/prod namespace。
- 设计 Deployment/Service/Ingress 模板。
- 设计 Helm 或 Kustomize 环境覆盖。
- 设计 Argo CD/Flux GitOps 仓库结构。
- 设计 secrets 管理方式。

## 验收标准

- 有完整架构图。
- 有 GitOps 仓库目录设计。
- 有 ACR 镜像命名规范。
- 有 production 发布审批说明。
- 有回滚流程说明。

