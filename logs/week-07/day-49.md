# Day 49: PV / PVC 学习日志（简化版）

## 今日目标

- 理解 Volume / PV / PVC 概念
- 掌握 emptyDir 和静态 PV 的差异
- 跳过：StorageClass 动态供给、StatefulSet

## 实际完成

### 为什么需要持久化

Pod 里的数据默认是临时的：

- Pod 重建 → 数据丢失
- Pod 跨节点调度 → 数据找不到
- 多 Pod 共享数据 → 没有机制

**Volume / PV / PVC 解决这些。**

### 三个核心概念

| 概念 | 作用 | 类比 |
| --- | --- | --- |
| Volume | Pod 里的目录 | U 盘 |
| PV (PersistentVolume) | 集群级存储资源（管理员创建） | 物理硬盘 |
| PVC (PersistentVolumeClaim) | Pod 申请存储的请求 | "我要 10G 硬盘" |

### 与前几天的联系

| Day | 学的内容 | 存什么 |
| --- | --- | --- |
| Day 47 | ConfigMap / Secret | 存配置 |
| Day 48 | Probe | 进程健康 |
| Day 49 | PV / PVC | 存数据 |

三个一起 = Pod 完整生命周期管理。

### emptyDir 临时存储

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  containers:
  - name: app
    image: busybox
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: cache
    emptyDir: {}
```

特点：

- Pod 启动时创建空目录
- Pod 删除时数据清空
- 同一 Pod 多容器可共享
- 适用：缓存、临时文件

### 静态 PV + PVC（演示）

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

完整调用链：

```text
管理员：写 PV（10Gi, hostPath）
   ↓
用户：写 PVC（10Gi, ReadWriteOnce）
   ↓
K8s：自动匹配 PV → 绑定 PVC
   ↓
Pod 引用 PVC → 挂载到容器路径
   ↓
容器读写 /data
```

### hostPath 演示 vs 生产

**演示场景**（killercoda / 单节点）：

```yaml
hostPath:
  path: /mnt/data
```

**生产环境**（云厂商 / 分布式）：

```yaml
# AWS EBS
awsElasticBlockStore:
  volumeID: vol-1234567890
  fsType: ext4

# 或 NFS
nfs:
  server: nfs.example.com
  path: /exports
```

**hostPath 的问题**：

- 节点宕机 → 数据丢失
- Pod 跨节点调度 → 数据找不到
- **生产环境禁用**

### PV/PVC 真正的价值是抽象层

```text
不用 PV/PVC：
  Pod → hostPath → 节点路径
  （直接耦合节点）

用 PV/PVC：
  Pod → PVC → PV → 后端（hostPath/EBS/NFS/...）
  （解耦后端）
```

**生产正确做法**：

```yaml
# StorageClass + 动态供给
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
```

```yaml
# 用户只写 PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  storageClassName: gp3-ssd
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
```

### 跳过的内容（按需后续学）

- **StorageClass 动态供给**：更现代的方式
- **StatefulSet**：数据库场景，Pod 需要固定存储
- **CSI driver 高级配置**：快照、克隆、扩容
- **PV 回收策略**：Retain / Recycle / Delete

### 跳过的原因

当前 [app/src/index.js](file:///d:/Project/devops-k8s-agent-roadmap/app/src/index.js) 是无状态 HTTP 服务，不需要持久化。

**触发条件**：

- 加 MySQL / Redis → 必须学 StatefulSet
- 加文件上传功能 → 必须学 RWX PVC
- 跨云迁移 → 必须学 StorageClass 动态供给

## killercoda 练习

### 练习 1：emptyDir

```bash
# 创建 Pod
cat > emptydir-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh", "-c", "echo hello > /cache/data.txt; sleep 3600"]
    volumeMounts:
    - name: cache
      mountPath: /cache
  - name: reader
    image: busybox
    command: ["sh", "-c", "cat /cache/data.txt; sleep 3600"]
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: cache
    emptyDir: {}
EOF
kubectl apply -f emptydir-pod.yaml

# 验证：reader 容器能读到 writer 写的内容
kubectl exec emptydir-pod -c reader -- cat /cache/data.txt
# 输出: hello

# 清理
kubectl delete pod emptydir-pod
```

### 练习 2：PV + PVC

```bash
# 创建 PV 和 PVC
cat > pv-pvc.yaml << 'EOF'
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF
kubectl apply -f pv-pvc.yaml

# 查看 PV 状态
kubectl get pv my-pv
# STATUS: Bound  ← 已绑定

# 查看 PVC 状态
kubectl get pvc my-pvc
# STATUS: Bound  ← 已绑定
```

### 练习 3：Pod 挂载 PVC

```bash
cat > pvc-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'persistent data' > /data/test.txt; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
EOF
kubectl apply -f pvc-pod.yaml

# 验证文件写入
kubectl exec pvc-pod -- cat /data/test.txt
# 输出: persistent data

# 验证 Pod 重建后数据保留
kubectl delete pod pvc-pod
kubectl apply -f pvc-pod.yaml
kubectl exec pvc-pod -- cat /data/test.txt
# 输出: persistent data  ← 数据还在
```

### 练习 4：清理

```bash
kubectl delete pod pvc-pod
kubectl delete pvc my-pvc
kubectl delete pv my-pv
```

## 关键理解

- PV/PVC 是抽象层，让 Pod 不直接绑定后端存储
- emptyDir 临时（Pod 生命周期）
- hostPath 仅演示（生产禁用）
- 生产用云盘（EBS / PD / Disk）或分布式存储（Ceph / NFS）
- 当前项目无状态，不需要 PV/PVC，加 DB 时再学

## 产出

- `k8s/pv-pvc-demo.yaml`：emptyDir + 静态 PV + PVC + Pod 完整示例
- 本文档：学习日志

## 明日计划

- Day 50：ServiceAccount / RBAC（认证授权）

## Commit

- add k8s/pv-pvc-demo.yaml and day-49 notes
