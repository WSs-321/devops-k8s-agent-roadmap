# Daily Log

Date: 20260710
Day: Thursday

## 今日目标

- 写 Service YAML
- 理解 ClusterIP / NodePort / LoadBalancer / Headless
- 理解三种端口（nodePort / port / targetPort）

## 实际完成

### Service 解决什么问题

Pod 每次重建 IP 都变，Service 提供固定 IP + 负载均衡，通过 label selector 关联一组 Pod。

### 四种 Service 类型

| 类型 | 访问范围 | 场景 |
| --- | --- | --- |
| ClusterIP（默认） | 集群内部 | 内部服务互调 |
| NodePort | 集群 + 节点 IP:端口 | 临时测试 |
| LoadBalancer | 公网 | 云上生产 |
| Headless（clusterIP: None） | DNS 直连 Pod | StatefulSet |

### 三种端口的区别

```text
外部用户
   │
   │ nodePort: 30080    ← 节点上暴露的端口（NodePort 类型才有）
   ▼
Service (ClusterIP: 10.96.0.10)
   │
   │ port: 80           ← Service 自己的端口
   ▼
Pod (Pod IP: 192.168.0.147)
   │
   │ targetPort: 80     ← Pod 容器的端口（对应 containerPort）
   ▼
Container
```

| 端口 | 谁的端口 | 什么时候写 |
| --- | --- | --- |
| nodePort | 节点的端口 | NodePort / LoadBalancer |
| port | Service 的端口 | 必写 |
| targetPort | Pod 容器的端口 | 必写（对应 Dockerfile 的端口） |

### 为示例服务写 Service

产出 `k8s/service.yaml`：ClusterIP 类型，port 80 -> targetPort 80

### Service YAML 关键字段

- `selector`：必须和 Deployment 的 template.labels 匹配
- `port`：Service 暴露的端口
- `targetPort`：转发到 Pod 的端口（对应 containerPort）
- `nodePort`：仅 NodePort/LoadBalancer 用，范围 30000-32767

### killercoda 练习

- `kubectl expose deploy devops-roadmap --port=80 --target-port=80` 创建 ClusterIP Service
- `kubectl get svc` 查看 CLUSTER-IP
- `kubectl run curl-test --image=curlimages/curl -it --rm -- curl http://devops-roadmap` 集群内部测试
- `kubectl delete svc` + `kubectl expose --type=NodePort` 切换为 NodePort
- `curl http://localhost:<nodePort>` 外部访问测试

### 关键理解

- 同 namespace 内，Service 名就是域名（K8s 内置 DNS 自动解析）
- `kubectl expose` 不支持直接改类型，删了重建
- `kubectl run --rm` 正常退出才自动删 Pod，异常退出可能残留
- Service 默认用 iptables/IPVS 轮询负载均衡，不需要 nginx

## 遇到的问题

- `kubectl run curl-test` 报 AlreadyExists，上次异常退出 Pod 未清理

## 解决方式

- `kubectl delete pod curl-test` 清理残留 Pod

## 明日计划

- Day 46：写 ConfigMap / Secret，理解配置注入

## Commit

- add k8s/service.yaml and day-45 notes
