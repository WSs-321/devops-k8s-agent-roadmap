# Daily Log

Date: 20260618
Day: Thursday

## 今日目标

- 学习 Docker 多阶段构建（multi-stage build）
- 改造 app/Dockerfile 为多阶段版本

## 实际完成

- 整理多阶段构建优点（镜像小、缓存好、安全）
- 整理多阶段构建缺点（复杂度高、调试难）
- 典型示例：Node.js、Python、Java/Maven、Go
- 输出 [docs/docker-multi-stage.md](file:///d:/Project/devops-k8s-agent-roadmap/docs/docker-multi-stage.md)
- 改造 [app/Dockerfile](file:///d:/Project/devops-k8s-agent-roadmap/app/Dockerfile) 为多阶段：

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
EXPOSE 3000
CMD ["node", "src/index.js"]
```

## 遇到的问题

- 多阶段对纯解释型语言收益不大
- node_modules 为什么要单独 copy，不能 COPY . . 吗
- src 为什么不需要 --from=builder

## 解决方式

- AI 辅助讲解 + 文档整理
- 理解：deps 阶段产出 node_modules（不在源码里），src 是本地源码（从构建上下文 COPY）
- 多阶段按需 copy 避免 .git、test、.env 误进镜像

## 明日计划

- Day 18 学习 Docker 健康检查 HEALTHCHECK

## Commit
