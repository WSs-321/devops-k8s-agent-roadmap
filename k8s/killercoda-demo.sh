#!/bin/bash
# killercoda.com Deployment 练习 demo
# 使用 nginx 镜像，在 killercoda 终端中直接执行

# === 创建 ===
kubectl create deployment my-app --image=nginx --replicas=3

# 查看 Pod（默认命名空间）
kubectl get pods -o wide

# 查看 Deployment
kubectl get deploy

# === 扩缩容 ===
kubectl scale deploy my-app --replicas=5

# 查看扩容结果
kubectl get pods -o wide

# 缩容
kubectl scale deploy my-app --replicas=2

# === 日志与调试 ===
# 查看单个 Pod 日志（替换为实际 Pod 名）
kubectl logs my-app-64b78bfff-fpbfw -f

# 查看 Deployment 下所有 Pod 日志
kubectl logs -f deploy/my-app

# 进入 Pod shell（替换为实际 Pod 名）
kubectl exec -it my-app-64b78bfff-fpbfw -- sh

# === Service ===
kubectl expose deploy my-app --port=80 --target-port=80
kubectl get svc

# === 滚动更新与回滚 ===
kubectl set image deploy/my-app my-app=nginx:1.25
kubectl rollout status deploy/my-app
kubectl rollout undo deploy/my-app

# === 清理 ===
kubectl delete deploy my-app
