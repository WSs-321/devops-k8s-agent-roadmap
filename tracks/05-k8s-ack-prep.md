# Track 05: K8s And ACK Prep

## 目标

为后续迁移到阿里云 ACK 做技术准备。当前阶段只要求理解和设计，不要求立即购买云资源。

## K8s 最小对象

- Namespace
- Deployment
- Service
- Ingress 或 Gateway
- ConfigMap
- Secret
- HorizontalPodAutoscaler
- PodDisruptionBudget

## ACK 迁移思路

```text
GitHub Actions
  -> build image
  -> push GHCR or ACR
  -> update GitOps repo
  -> Argo CD sync
  -> ACK cluster
```

早期可以由 GitHub Actions 直接部署到 ECS 或测试服务器。服务数量变多后，再迁移到 ACK + GitOps。

## 验收标准

- 能为示例服务写出 K8s YAML。
- 能说明 GHCR 和 ACR 的取舍。
- 能画出 GitHub Actions 到 ACK 的部署链路。
- 能解释为什么生产环境推荐 GitOps。

