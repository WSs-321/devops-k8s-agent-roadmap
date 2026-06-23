# Daily Log

Date: 20260617
Day: Wednesday

## 今日目标

- 整理 Docker 基础文档（基础概念、镜像与容器、镜像层缓存）
- 写 .dockerignore

## 实际完成

- 输出 [docs/docker.md](file:///d:/Project/devops-k8s-agent-roadmap/docs/docker.md)：
  - Dockerfile 位置选择
  - 镜像、Dockerfile、容器关系
  - docker run 常用参数
  - -p / -P / 不映射端口区别
  - EXPOSE 声明
  - --entrypoint 覆盖入口
  - --restart unless-stopped 策略
  - --memory 与 --shm-size 区别
  - OOM 与 Docker/K8s 调度
- 写 [app/.dockerignore](file:///d:/Project/devops-k8s-agent-roadmap/app/.dockerignore)：

```text
node_modules
dist
test
.github
.git
*.md
.trae
.vscode
.idea
.eslintrc*
eslint.config.js
```

## 遇到的问题

- .dockerignore 写多了会不会影响构建
- -p / -P / 不写端口映射区别
- 为什么要写 EXPOSE 3000

## 解决方式

- AI 辅助整理
- 对照 Dockerfile 的 COPY 列表确认 .dockerignore 没误伤必须文件
- 实际验证：不写端口也能跑（容器内能访问，同网络容器能访问）

## 明日计划

- Day 17 学习 Docker 多阶段构建

## Commit
