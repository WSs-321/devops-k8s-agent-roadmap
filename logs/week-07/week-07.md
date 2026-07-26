# Week 7 周复盘：Kubernetes 基础

## 复盘范围

Day 43-49，主题是 K8s 基础。

## 实际完成

| Day | 主题 | 产出 |
| --- | --- | --- |
| 43 | K8s 概念（Pod/Deployment/Service/Namespace） | k8s 概念笔记 |
| 44 | Deployment | k8s/deployment.yaml |
| 45 | Service | k8s/service.yaml |
| 46 | Ingress | k8s/ingress.yaml |
| 47 | ConfigMap / Secret | k8s/configmap.yaml + k8s/secret.yaml |
| 48 | Health Probe | k8s/probe-demo.yaml |
| 49 自定义 | PV/PVC 简化版 | k8s/pv-pvc-demo.yaml |
| 49 计划 | 周复盘 | k8s/app-template.yaml + 本文档 |

## K8s 核心概念（已掌握）

| 概念 | 一句话 |
| --- | --- |
| Pod | K8s 最小调度单位（容器组） |
| Deployment | 管理 Pod 副本 + 滚动更新 |
| Service | Pod 固定入口 + 负载均衡 |
| Ingress | 外部 HTTP/HTTPS 入口 |
| ConfigMap | 非敏感配置 |
| Secret | 敏感配置（base64，不是加密） |
| Probe | 容器健康检查（startup/liveness/readiness） |
| PV/PVC | 持久化存储（数据库场景） |

## 关键依赖关系

```text
Pod.status.Ready
   ↓
Endpoints Controller 监听
   ↓
自动更新 Service.Endpoints
   ↓
Service 路由流量只到 ready 的 Pod
```

## K8s 应用清单最小模板

一个应用 = 6 资源合一：

- Deployment
- Service
- Ingress
- ConfigMap
- Secret
- Probe（写在 Deployment 里）

详见 [k8s/app-template.yaml](file:///d:/Project/devops-k8s-agent-roadmap/k8s/app-template.yaml)。

### 关键决策点

| 决策点 | 选择 | 理由 |
| --- | --- | --- |
| 副本数 | 2 | 至少 2 个避免单点故障 |
| 镜像 tag | dev 用 latest，prod 用 commit sha | 可追溯 |
| 更新策略 | RollingUpdate | 零宕机 |
| maxUnavailable | 0 | 不允许有宕机 |
| maxSurge | 1 | 滚动更新时多 1 个 |
| 健康检查 | 三种 probe 都要 | startup 解决慢启动、liveness 解决死锁、readiness 解决流量路由 |
| 资源限制 | requests/limits | 防止资源抢占 |
| 命名 | my-app-* | 资源名前缀统一 |

## 踩过的坑

| 坑 | 解决 |
| --- | --- |
| github.repository 大小写 | 强制小写（GHCR 规范） |
| image: busybox 镜像拉取 | K8s 节点自动拉取 |
| Trivy summary 字段空 | 解析 sarif 用 message.text 字符串匹配 |
| markdownlint MD032 失败 | 列表前后加空行 |
| SSH key 误以为加密 | 实际只 base64 编码 |
| pull_request_target 危险 | 永远用 pull_request |
| fork PR 不在原仓库分支 | 通过 fork 避免分支泛滥 |
| probe 公式计算错误 | failureThreshold - 1，不是 failureThreshold |

## 重要概念再澄清

### readinessProbe 不在 Service 里

- readinessProbe 写在 Pod spec
- K8s 内部通过 Endpoints Controller 自动同步
- Service 只查 Endpoints 列表

### hostPath 的问题

- 节点宕机数据丢失
- Pod 跨节点调度数据找不到
- 生产环境禁用
- PV/PVC 的价值是抽象层，让 Pod 不直接绑定后端

### pull_request vs pull_request_target

- pull_request：fork PR 时 secrets 自动隔离
- pull_request_target：fork PR 时 secrets 可用，但**永远不要 checkout PR 代码并执行**
- 99% 场景用 pull_request

## 与前 6 周的联系

```text
Week 1-2  CI（GitHub Actions）
Week 3    Docker
Week 4    GHCR + Trivy
Week 5    CD + 部署
Week 6    安全（CodeQL/SBOM/Secret）
Week 7    K8s 基础 ← 你在这里
Week 8    ACK + GitOps
Week 9    Agent 基础
Week 10   Agent 集成
Week 11   总结
```

## 三个关键问题回答

### 1. K8s 配置外置怎么实现

ConfigMap（非敏感） + Secret（敏感）。Pod 用 env/envFrom/volumeMount 三种方式注入。

### 2. 容器怎么知道自己是健康的

K8s 用三种 probe 检测：

- startupProbe：启动慢的应用
- livenessProbe：进程是否活着
- readinessProbe：能否接流量

失败后果不同：liveness 失败重启，readiness 失败摘流量。

### 3. 容器数据怎么持久化

Volume（临时）→ PV/PVC（持久）→ StatefulSet（数据库场景）。

生产用云盘或分布式存储，不用 hostPath。

## 跳过的内容（按需后续学）

| 主题 | 何时学 |
| --- | --- |
| StorageClass 动态供给 | 跨云迁移时 |
| StatefulSet | 加 MySQL/Redis 时 |
| CSI driver 高级 | 备份/快照需求时 |
| NetworkPolicy | 多租户隔离时 |
| RBAC 细粒度 | 多团队权限管理时 |

## 关键产出物清单

| 文件 | 内容 |
| --- | --- |
| k8s/deployment.yaml | Deployment 完整示例 |
| k8s/service.yaml | Service ClusterIP |
| k8s/ingress.yaml | Ingress 路由 |
| k8s/configmap.yaml | ConfigMap 三种注入方式 |
| k8s/secret.yaml | 三种 Secret 类型 |
| k8s/probe-demo.yaml | 三种 Probe 完整配置 |
| k8s/pv-pvc-demo.yaml | PV/PVC 简化版 |
| k8s/app-template.yaml | K8s 应用最小模板（6 资源合一） |

## 自测 checklist

- [ ] 能在 5 分钟内写出最小应用清单
- [ ] 理解 readinessProbe 与 Service 的联动
- [ ] 知道 PV/PVC 的价值是抽象层
- [ ] 知道 liveness 不查外部依赖
- [ ] 知道 failureThreshold 的真实计算公式
- [ ] 知道 hostPath 仅演示用

## 下一步

按 75-day-plan.md：

- Day 50：ACK 架构（阿里云）
- Day 51：ACR 迁移
- Day 52：Helm
- Day 53：Kustomize
- Day 54-55：GitOps
- Day 56：周复盘

## Commit

- add k8s/app-template.yaml and week-07 review
