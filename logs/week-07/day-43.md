# Daily Log

Date: 20260708
Day: Tuesday

## 今日目标

- 学习 K8s 核心概念：Pod、Deployment、Service、Namespace
- 理解 K8s 对象关系和与前六周知识的衔接

## 实际完成

### K8s 是什么

容器编排平台，解决"多个容器怎么协同运行"的问题。Docker 解决一个容器怎么跑，K8s 解决几百个容器怎么调度、扩缩容、自愈、发现彼此。

### 核心对象关系

```text
Namespace（逻辑隔离）
  └── Deployment（声明期望状态）
        └── ReplicaSet（维持副本数）
              └── Pod（最小调度单元）
                    └── Container（实际运行的容器）
Service（稳定访问入口）
  └── 指向 Pod（通过 label selector）
Ingress（外部流量入口）
  └── 指向 Service
ConfigMap / Secret（配置注入）
  └── 挂载到 Pod
```

### Pod - 最小调度单元

- K8s 调度的最小单位是 Pod，不是 Container
- 一个 Pod 可以含多个 Container（主容器 + sidecar），共享 localhost 和网络命名空间
- Pod IP 会变（挂了重建、滚动更新），所以不直接创建 Pod
- 生命周期：Pending -> Running -> Succeeded/Failed

### Deployment - 声明期望状态

- 你告诉 K8s "我要 3 个副本"，K8s 负责维持
- 核心能力：副本数维持、自愈、滚动更新、回滚
- Deployment -> ReplicaSet -> Pod 的层级关系
- 更新镜像时创建新 ReplicaSet，逐步替换旧 Pod
- 旧 ReplicaSet 保留（replicas=0），用于回滚

### Service - 稳定访问入口

- 解决 Pod IP 会变的问题
- 通过 label selector 关联一组 Pod
- 四种类型：ClusterIP（默认）/ NodePort / LoadBalancer / Headless
- DNS 解析：`my-app.namespace.svc.cluster.local`

### Namespace - 逻辑隔离

- 用途：环境隔离、资源限额、权限控制、DNS 前缀
- 内置：default / kube-system / kube-public / kube-node-lease

### 与前六周知识的衔接

| 前六周概念 | K8s 对应 |
| --- | --- |
| Docker 容器 | Pod 中的 Container |
| Dockerfile HEALTHCHECK | livenessProbe / readinessProbe |
| docker run -e ENV=xxx | ConfigMap / Secret + env |
| docker run -p 3000:3000 | Service port -> targetPort |
| docker-compose 多服务编排 | Deployment + Service + Ingress |
| `:latest` 陷阱 | K8s 默认 `imagePullPolicy: Always`（latest） |
| deploy.sh 部署 | kubectl apply / GitOps |
| GHCR 镜像 | K8s 从 registry pull 镜像 |

### 常用 kubectl 命令

```bash
kubectl get pods -o wide
kubectl get deploy
kubectl get svc
kubectl get ns
kubectl describe pod my-app
kubectl logs my-app -f
kubectl apply -f deploy.yaml
kubectl scale deploy my-app --replicas=5
kubectl rollout undo deploy my-app
kubectl exec -it my-app -- sh
```

## 遇到的问题

- 无

## 解决方式

- 无

## 明日计划

- Day 44：为示例服务写 Deployment YAML

## Commit

- study k8s core concepts: Pod / Deployment / Service / Namespace
