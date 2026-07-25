# Daily Log

Date: 20260712
Day: Saturday

## 今日目标

- 写 ConfigMap / Secret YAML
- 理解三种注入方式
- 区分 ConfigMap 和 Secret 用途

## 实际完成

### ConfigMap / Secret 解决什么问题

前六周用 `docker run -e NODE_ENV=prod` 传配置，K8s 里同样需要配置外置，但不能写死在 Deployment YAML 里。

| 方式 | 对应 Docker | 存放内容 | 示例 |
| --- | --- | --- | --- |
| ConfigMap | `-e` 环境变量 / 挂载文件 | 非敏感配置 | `NODE_ENV=prod`、`LOG_LEVEL=info` |
| Secret | `-e` 敏感变量 / 挂载文件 | 敏感配置 | `DB_PASSWORD=xxx`、`API_KEY=yyy` |

### ConfigMap 三种注入方式

#### envFrom（一次注入全部）

```yaml
envFrom:
  - configMapRef:
      name: app-config
```

#### 单个 env 变量

```yaml
env:
  - name: GREETING
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: GREETING
```

#### 挂载为文件

```yaml
volumeMounts:
  - name: config-volume
    mountPath: /etc/config
volumes:
  - name: config-volume
    configMap:
      name: app-config
```

### 三种方式对比

| 方式 | 优点 | 缺点 | 适用 |
| --- | --- | --- | --- |
| envFrom | 一次注入全部 | 变量多时难管理 | 配置项少 |
| env 单个 | 精确控制 | 写起来长 | 只需要部分变量 |
| 挂载文件 | 支持多行配置、热更新 | 需要应用读文件 | 配置文件（json/yaml） |

### ConfigMap vs Secret

| 维度 | ConfigMap | Secret |
| --- | --- | --- |
| 存储内容 | 明文 | base64 编码 |
| 使用方式 | env / volume | env / volume（完全一样） |
| 安全性 | 不安全 | 略好（base64 不是加密） |
| 适用 | 普通配置 | 密码、密钥、证书 |

注意：base64 不是加密，只是编码。`echo -n 'xxx' | base64` 就能解码。真正安全靠 RBAC 限制访问 + etcd encryption-at-rest。

### 关键理解

- ConfigMap 更新后，envFrom 注入的变量不会热更新（需要重启 Pod）
- 挂载文件方式才支持热更新（kubelet 定期同步）
- 对应前六周：ConfigMap = `docker run -e`，Secret = GitHub Actions secrets

### 为示例服务写 ConfigMap

产出 `k8s/configmap.yaml`：包含 GREETING、LOG_LEVEL、NODE_ENV 三个非敏感配置。

### killercoda 练习

```bash
# 创建 ConfigMap
kubectl create configmap app-config \
  --from-literal=GREETING="Hello,K8s!" \
  --from-literal=LOG_LEVEL=info

# 创建 Secret
kubectl create secret generic app-secret \
  --from-literal=DB_PASSWORD=mysecretpassword \
  --from-literal=API_KEY=abc123

# 看 ConfigMap
kubectl describe configmap app-config

# 看 Secret（显示 base64）
kubectl describe secret app-secret

# 部署引用 ConfigMap + Secret
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 1
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
          image: nginx
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: app-secret
EOF

kubectl apply -f deployment.yaml

# 进入 Pod 验证环境变量
POD=$(kubectl get pods -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- env | grep GREETING
kubectl exec -it $POD -- env | grep DB_PASSWORD

# 清理
kubectl delete deploy my-app
kubectl delete configmap app-config
kubectl delete secret app-secret
```

## 明日计划

- Day 48：Health Probe（liveness / readiness / startup）

## Commit

- add k8s/configmap.yaml and day-47 notes
