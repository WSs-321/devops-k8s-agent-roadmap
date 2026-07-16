# Daily Log

Date: 20260709
Day: Wednesday

## 今日目标

- 为示例服务写 Deployment YAML
- 理解 Deployment YAML 各字段含义
- 理解 resources 调度与 QoS 机制

## 实际完成

### Deployment YAML 基本结构

四个必填顶层字段：`apiVersion` / `kind` / `metadata` / `spec`

- `apiVersion`：用哪个 API（"去哪个窗口办"）
- `kind`：资源类型（"办什么业务"）
- `metadata`：身份信息（"我是谁"）
- `spec`：期望状态（"我要什么"）= specification（规格说明）

K8s 的工作就是不断把实际状态调到 `spec` 描述的期望状态 -- 声明式核心。

### 关键字段

- `replicas`：期望副本数
- `selector.matchLabels`：管理哪些 Pod（必须和 template.labels 一致，否则 Deployment 找不到自己创建的 Pod）
- `strategy.rollingUpdate`：滚动更新策略
  - `maxSurge: 1`：更新时最多多出 1 个 Pod（先启新的）
  - `maxUnavailable: 0`：不允许减少（零停机）
- `resources`：资源限制
  - `requests`：最低保障（调度器根据这个决定 Pod 放到哪个节点）
  - `limits`：最高上限（运行时 cgroup 硬上限）
  - `100m` = 0.1 核，`128Mi` = 128 MB

### 为示例服务写的 Deployment

产出 `k8s/deployment.yaml`，基于项目的 Node.js 示例应用：

- 镜像：`ghcr.io/wss-321/devops-k8s-agent-roadmap:latest`
- 端口：3000
- 环境变量：GREETING
- 3 副本 + 滚动更新 + 资源限制

### CPU 限流 vs Memory OOM Kill

CPU 和 Memory 超限处理完全不同：

| 维度 | CPU limit 超限 | Memory limit 超限 |
| --- | --- | --- |
| 处理方式 | 限流（throttle） | 杀掉（OOM Kill） |
| 进程是否死 | 不死，只是变慢 | 直接死 |
| 表现 | 响应变慢、延迟升高 | Pod 重启（RESTARTS +1） |
| 原因 | CPU 是可压缩资源 | Memory 是不可压缩资源 |
| 排查 | `kubectl top pod` 看 THROTTLING | `kubectl describe pod` 看 OOMKilled / Exit Code 137 |

- 137 = 128（被信号杀）+ 9（SIGKILL）
- CPU 限流日志无错误，很难发现；OOM 有明确的退出码，容易发现

### Docker vs K8s 内存限制

底层都是同一个 Linux cgroup 机制，差异在于 **swap**：

| 环境 | 是否有 Swap | 行为 |
| --- | --- | --- |
| Docker 默认 | 宿主机有 swap 就能用 | 内存超限先写 swap，变慢但不死 |
| K8s 默认 | 禁用 swap（kubelet 拒绝启动） | 超限直接 OOM Kill |

K8s 禁用 swap 的原因：调度准确性、性能可预测、故障明确（OOM 快速失败比 swap 缓慢拖死更好）。

### 机器总内存与 Pod 内存分配

K8s 按 requests 调度，不按 limits：

```text
所有 Pod requests 之和  ≤  节点总内存   ✅ 能调度
所有 Pod limits 之和    >  节点总内存   ✅ 允许（超卖）
```

超卖风险：所有 Pod 同时用到 limits 上限 -> 节点内存耗尽 -> 系统触发 OOM Killer -> 按优先级杀 Pod。

### QoS 等级（谁先被杀）

| 等级 | 条件 | 被杀顺序 |
| --- | --- | --- |
| Guaranteed | requests == limits（CPU 和内存都设且相等） | 最后杀 |
| Burstable | 有 requests 但不等于 limits | 中间杀 |
| BestEffort | 不设 requests 和 limits | 最先杀 |

实际建议：

- 生产关键服务：Guaranteed（requests == limits）
- 普通服务：Burstable（requests 给保底，limits 给余量）
- limits 总和不超过节点内存 1.5 倍，降低 OOM 风险

### killercoda 练习 demo

在 killercoda.com 上用 nginx 镜像练习的完整操作记录：

```text
# 创建 deployment
kubectl create deployment my-app --image=nginx --replicas=3

# 查看 Pod（默认命名空间）
kubectl get pods -o wide

# 查看 Deployment
kubectl get deploy

# 扩容到 5 个副本
kubectl scale deploy my-app --replicas=5

# 查看扩容结果（3 个 4s 新建 + 2 个 4m58s 原有）
kubectl get pods -o wide

# 查看单个 Pod 日志
kubectl logs my-app-64b78bfff-fpbfw -f

# 查看 Deployment 下所有 Pod 日志
kubectl logs -f deploy/my-app

# 进入 Pod shell
kubectl exec -it my-app-64b78bfff-fpbfw -- sh

# 暴露 Service
kubectl expose deploy my-app --port=80 --target-port=80

# 查看 Service
kubectl get svc

# 更新镜像
kubectl set image deploy/my-app my-app=nginx:1.25

# 看滚动更新过程
kubectl rollout status deploy/my-app

# 回滚
kubectl rollout undo deploy/my-app

# 缩容
kubectl scale deploy my-app --replicas=2

# 清理
kubectl delete deploy my-app
```

关键验证点：

- 5 个副本都 Running，Deployment 5/5 就绪
- Pod 名格式：`<deployment>-<replicaset-hash>-<random>`，如 `my-app-64b78bfff-fpbfw`
- `kubectl logs` 用 Pod 全名，不能用 Deployment 名
- `kubectl logs -f deploy/my-app` 可以看所有 Pod 日志

## 遇到的问题

- killercoda 拉不了 GHCR 镜像，练习时用 nginx 代替
- `kubectl logs my-app` 报 NotFound，因为 my-app 是 Deployment 名不是 Pod 名

## 解决方式

- 学习阶段用公共镜像练习，正式部署再用 GHCR 镜像

## 明日计划

- Day 45：写 Service YAML，理解 ClusterIP / NodePort / LoadBalancer

## Commit

- add k8s/deployment.yaml and day-44 notes
