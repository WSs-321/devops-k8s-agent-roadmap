# Day 48: Health Probe 学习日志

## 今日目标

- 理解 startup/liveness/readiness 三种 probe 的区别
- 掌握 probe 三种探测方式（httpGet/tcpSocket/exec）
- 学会关键参数（initialDelaySeconds、periodSeconds、failureThreshold）
- 通过 killercoda 练习

## 实际完成

### 为什么需要健康检查

Pod 启动 ≠ 服务可用。可能的问题：

- 进程在跑但 DB 连接还没建立
- 端口在 listen 但应用初始化报错
- 死锁中（进程在但 100% CPU）

Health Probe 让 K8s 自动检测容器是否"真的健康"。

### 三种 Probe 类型

| 类型 | 作用 | 失败后果 |
| --- | --- | --- |
| startupProbe | 容器是否"启动完成" | 阻止 liveness/readiness 跑 |
| livenessProbe | 容器是否"还活着" | 重启容器 |
| readinessProbe | 容器是否"准备好接流量" | 从 Service endpoint 摘除 |

关键区别：

- liveness 失败 → kubelet 杀容器 → 重启
- readiness 失败 → Service 不再路由流量 → 但不重启

### 三种探测方式

| 方式 | 速度 | 灵活度 | 适用 |
| --- | --- | --- | --- |
| httpGet | 快 | 高 | Web 服务（推荐） |
| tcpSocket | 快 | 低 | DB / Redis |
| exec | 慢 | 最高 | 自定义检查 |

### 关键参数

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 3000
  initialDelaySeconds: 10    # 启动后等多久开始探测
  periodSeconds: 5          # 探测间隔
  timeoutSeconds: 1         # 单次探测超时
  successThreshold: 1       # 几次成功算健康（liveness 必须是 1）
  failureThreshold: 3       # 几次失败算不健康
```

### 时间线计算（修正版）

最长存活时间 = `initialDelaySeconds + (failureThreshold - 1) × periodSeconds`

举例（initialDelaySeconds=10, periodSeconds=5, failureThreshold=3）：

```text
T=0s:    容器启动
T=10s:   第一次探测（失败）→ count=1
T=15s:   第二次探测（失败）→ count=2
T=20s:   第三次探测（失败）→ count=3 → 达到 failureThreshold=3 → 判定不健康
```

最长存活 = 10 + (3-1) × 5 = 10 + 10 = 20s

注意：failureThreshold 是"达到这个次数才算失败"，不是"到第几次失败时启动失败判定"。

### Probe 协同工作

```text
T=0s:    容器启动
T=5s:    startupProbe 开始
T=20s:   startup 成功 → 标记"已启动"
T=20s:   livenessProbe 和 readinessProbe 才开始跑
T=25s:   readiness 第一次成功 → 加入 Service endpoint
T=25s:   流量开始打进来
```

### 常见陷阱

#### 陷阱 1：readiness 查 DB 导致雪崩

liveness 不要查外部依赖（DB 抖动 → 全部 Pod 被重启 → 雪崩）

```yaml
# 正确做法
livenessProbe:
  httpGet:
    path: /healthz    # 只看进程活着
readinessProbe:
  httpGet:
    path: /readyz     # 可以查 DB
```

#### 陷阱 2：periodSeconds 太短导致误杀

```yaml
# 错误
periodSeconds: 1
failureThreshold: 1    # 任何 1 秒抖动 → 杀容器
# 推荐
periodSeconds: 10
failureThreshold: 3    # 容忍 30s 抖动
```

#### 陷阱 3：startupProbe 缺失导致慢启动应用被杀

```yaml
# 正确：用 startupProbe 替代 initialDelaySeconds
startupProbe:
  failureThreshold: 30    # 允许启动 150s
livenessProbe:
  # 不需要 initialDelaySeconds
```

#### 陷阱 4：probe 路径在主路由

应使用独立端点（/healthz），不与业务路由混。

## killercoda 练习

### 练习 1：HTTP GET probe

```bash
# 创建带 probe 的 pod
cat > probe-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: probe-pod
spec:
  containers:
  - name: app
    image: ghcr.io/wss-321/devops-k8s-agent-roadmap:latest
    ports:
    - containerPort: 3000
    livenessProbe:
      httpGet:
        path: /healthz
        port: 3000
      initialDelaySeconds: 5
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /readyz
        port: 3000
      periodSeconds: 3
EOF
kubectl apply -f probe-pod.yaml

# 看 probe 状态
kubectl describe pod probe-pod | grep -A 10 "Liveness\|Readiness"

# 看 pod 状态变化
kubectl get pod probe-pod -w
```

### 练习 2：TCP Socket probe（DB/Redis）

```bash
cat > tcp-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: tcp-pod
spec:
  containers:
  - name: redis
    image: redis:alpine
    livenessProbe:
      tcpSocket:
        port: 6379
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
kubectl apply -f tcp-pod.yaml
kubectl describe pod tcp-pod | grep -A 5 Liveness
```

### 练习 3：exec probe

```bash
cat > exec-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: exec-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "touch /tmp/healthy; sleep 3600"]
    livenessProbe:
      exec:
        command: ["sh", "-c", "test -f /tmp/healthy"]
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
kubectl apply -f exec-pod.yaml

# 触发失败：进入容器删除 /tmp/healthy → 5 秒后 liveness 失败 → 重启
kubectl exec -it exec-pod -- rm /tmp/healthy
kubectl get pod exec-pod -w    # 看重启次数 RESTARTS 增加
```

### 练习 4：readiness + Service 联动

```bash
# 创建 deployment（3 副本）
cat > app-deploy.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: ghcr.io/wss-321/devops-k8s-agent-roadmap:latest
        ports:
        - containerPort: 3000
        readinessProbe:
          httpGet:
            path: /readyz
            port: 3000
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000
EOF
kubectl apply -f app-deploy.yaml

# 等待所有 pod ready
kubectl wait --for=condition=Ready pod -l app=my-app --timeout=60s

# 查看 service endpoints（应该有 3 个）
kubectl get endpoints my-app
# ENDPOINTS
# 10.244.1.5:3000,10.244.1.6:3000,10.244.1.7:3000

# 测试 service 负载均衡
for i in 1 2 3 4 5; do
  kubectl run -it --rm curl --image=alpine --restart=Never -- \
    sh -c "wget -qO- http://my-app/ | head -1"
done

# 模拟某个 pod readiness 失败（需要进入 pod 改 /readyz 端点或 kill 进程）
POD=$(kubectl get pod -l app=my-app -o jsonpath='{.items[0].metadata.name}')
echo "killing app in $POD"
kubectl exec $POD -- kill 1

# 再看 endpoints（少了一个）
kubectl get endpoints my-app
# ENDPOINTS
# 10.244.1.6:3000,10.244.1.7:3000  ← 少了一个

# 清理
kubectl delete deploy my-app
kubectl delete svc my-app
```

### 练习 5：清理

```bash
kubectl delete pod probe-pod tcp-pod exec-pod
```

## 关键理解

- Service 不写 readinessProbe，只通过 selector 选 Pod
- readinessProbe 写在 Pod spec 里
- K8s 内部通过 Endpoints Controller 自动同步：Pod readiness → Endpoints → Service 路由
- liveness 不要查外部依赖，避免雪崩
- startupProbe 是慢启动应用的关键，避免被 liveness 误杀

## 与 Day 46 联动

Day 46 学的 Service 通过 selector 选 Pod：

- Service 不直接看 Pod 的 readinessProbe
- Service 看 Endpoints 列表
- Endpoints Controller 监听 Pod 状态变化，自动从列表里摘除不健康的 Pod

## 产出

- `k8s/probe-demo.yaml`：完整 probe 演示（startup + liveness + readiness）
- 本文档：学习日志

## 明日计划

- Day 49：Volumes / PV / PVC（持久化存储）

## Commit

- add k8s/probe-demo.yaml and day-48 notes
