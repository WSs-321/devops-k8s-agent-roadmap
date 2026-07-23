# Daily Log

Date: 20260711
Day: Friday

## 今日目标

- 写 Ingress YAML
- 理解 Ingress / Ingress Controller 的两层概念
- 对比 NodePort / LoadBalancer / Ingress

## 实际完成

### Ingress 解决什么问题

NodePort 端口范围受限（30000-32767），不支持域名路由和 HTTPS。Ingress 是 K8s 的七层反向代理 + 路由规则。

### Ingress 两层概念

```text
Ingress（路由规则）    ← YAML 声明域名/路径 -> Service
   │
Ingress Controller（执行者） ← 真正跑的 Pod，读规则并转发流量
   │
   ├── nginx-ingress
   ├── traefik
   └── ALB / CLB（云厂商）
```

Ingress 只是指令，Ingress Controller 才是干活的。没装 Controller，Ingress 规则不生效。

### Ingress YAML 关键字段

- `ingressClassName`：指定用哪个 Ingress Controller
- `rules[].host`：域名
- `rules[].http.paths[].path`：路径
- `rules[].http.paths[].pathType`：匹配方式
- `backend.service`：转发到哪个 Service

### pathType 三种匹配方式

| pathType | 匹配规则 | 示例 |
| --- | --- | --- |
| Prefix | 前缀匹配（最常用） | `/api` 匹配 `/api`、`/api/v1`、`/api/users` |
| Exact | 精确匹配 | `/health` 只匹配 `/health` |
| ImplementationSpecific | 由 Controller 决定 | 不推荐 |

### annotations 的作用

给资源附加额外配置信息，给工具/Controller 读取，不用于 K8s 内部匹配。

| 维度 | labels | annotations |
| --- | --- | --- |
| 用途 | 标识、筛选（selector） | 附加配置信息 |
| K8s 用 | 用来关联资源 | K8s 不关心，给 Controller 读 |
| 例子 | `app: my-app` | `nginx.ingress.kubernetes.io/rewrite-target: /` |
| 比喻 | 身份证标签 | 说明书 |

常见 Ingress annotations：

- `nginx.ingress.kubernetes.io/rewrite-target: /`：路径重写
- `nginx.ingress.kubernetes.io/proxy-body-size: "10m"`：限制上传文件大小
- `nginx.ingress.kubernetes.io/proxy-read-timeout: "60"`：超时设置
- `nginx.ingress.kubernetes.io/enable-cors: "true"`：跨域配置
- `nginx.ingress.kubernetes.io/ssl-redirect: "true"`：强制 HTTPS 跳转

### Ingress vs NodePort vs LoadBalancer

| 维度 | NodePort | LoadBalancer | Ingress |
| --- | --- | --- | --- |
| 端口 | 30000-32767 | 80/443 | 80/443 |
| 公网 IP | 节点 IP | 每个 Service 一个 | 一个 IP 路由多个 |
| 域名路由 | 不支持 | 不支持 | 支持 |
| HTTPS | 不支持 | 支持 | 支持 |
| 费用 | 免费 | 贵（云厂商 LB） | 一个 LB + 多个 Service |
| 适用 | 临时测试 | 单 Service 公网暴露 | 多 Service 生产环境 |

### 多 Service 路由

一个 Ingress 可以路由多个 Service：

```yaml
rules:
  - host: myapp.com
    http:
      paths:
        - path: /api
          backend: api-service
        - path: /web
          backend: web-service
        - path: /
          backend: web-service  # 默认路由
```

### 为示例服务写 Ingress

产出 `k8s/ingress.yaml`：host `devops-roadmap.local`，路径 `/`，转发到 `devops-roadmap` Service。

### killercoda 练习

```bash
# 检查 ingress controller 是否已装
kubectl get pods -n ingress-nginx

# 创建 deployment + service
kubectl create deployment my-app --image=nginx --replicas=2
kubectl expose deploy my-app --port=80 --target-port=80

# 创建 ingress
cat > ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: my-app.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
EOF

kubectl apply -f ingress.yaml

# 查看 ingress
kubectl get ingress

# 测试（用 --resolve 模拟域名解析）
curl --resolve my-app.local:80:<node-ip> http://my-app.local

# 清理
kubectl delete ingress my-app-ingress
kubectl delete svc my-app
kubectl delete deploy my-app
```

### 与前六周的对应

| K8s | 前六周 |
| --- | --- |
| Ingress | nginx 反向代理 |
| Ingress 规则 | nginx.conf 的 `location` 块 |
| Ingress Controller | nginx 进程本身 |
| TLS Secret | SSL 证书 |
| `nginx.ingress.kubernetes.io/*` 注解 | nginx.conf 指令 |

## 明日计划

- Day 47：ConfigMap / Secret 配置注入

## Commit

- add k8s/ingress.yaml and day-46 notes
