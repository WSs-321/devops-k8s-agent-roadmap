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

### 完整链路总结

```text
外部用户 -> Ingress（域名路由）-> Service（稳定IP+负载均衡）-> Pod x N（由 Deployment 维持）
                                                              ↑
                                              ConfigMap/Secret 注入配置
```

一句话：**Ingress 管入口，Service 管寻址，Deployment 管存活，ConfigMap/Secret 管配置**。

- Ingress 不直接连 Pod，因为 Pod IP 会变
- Ingress 指向 Service，Service 再负载均衡到 Pod
- Deployment 不是"持久化"，是"声明期望状态"（我要 N 个副本，挂了自动补）
- Pod 数量可随时 scale 调整，不是固定不变的

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

### K8s 学习环境方案

| 方案 | 成本 | 机器要求 | 适合阶段 | 推荐度 |
| --- | --- | --- | --- | --- |
| killercoda.com | 免费 | 无（浏览器） | 第一天体验 | ⭐⭐ |
| Minikube | 免费 | 本地 4GB+ | 学习阶段 | ⭐⭐⭐⭐⭐ |
| Kind | 免费 | 本地 4GB+ | CI/自动化测试 | ⭐⭐⭐⭐ |
| Docker Desktop | 免费 | 本地已装 | 已有 Docker 用户 | ⭐⭐⭐⭐ |
| 阿里云 ACK | 收费 | 云服务器 | Week 8 实战 | ⭐⭐⭐ |

**killercoda.com**：浏览器里直接给一个 K8s 集群 + 终端，免费账号每次 1 小时，零门槛体验 kubectl。

**Minikube**：本地单节点 K8s，Windows 支持，安装简单：

```powershell
winget install Kubernetes.minikube
minikube start
kubectl get nodes
```

**Docker Desktop 自带 K8s**：最省事，Settings -> Kubernetes -> Enable Kubernetes，一键开启。

**Kind（Kubernetes in Docker）**：用 Docker 容器模拟 K8s 节点，轻量，可跑多节点，GitHub Actions CI 测试常用。

**推荐路线**：

```text
第 1 步（今天）：killercoda.com 浏览器体验 kubectl
第 2 步（Day 44-48）：本地 Docker Desktop 开启 K8s 或 Minikube
第 3 步（Week 8）：阿里云 ACK 真实集群实战
```

## 遇到的问题

- 无

## 解决方式

- 无

## 明日计划

- Day 44：为示例服务写 Deployment YAML

## Commit

- study k8s core concepts: Pod / Deployment / Service / Namespace
