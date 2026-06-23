# Daily Log

Date: 20260616
Day: Tuesday

## 今日目标

- 启动 Week 3 学习：Docker 基础与镜像构建
- 完成 app/Dockerfile 编写
- 准备 .dockerignore

## 实际完成

- 创建分支 feature_docker-basics，开始 Docker 学习
- 写 [app/Dockerfile](file:///d:/Project/devops-k8s-agent-roadmap/app/Dockerfile)：
  - 基础镜像：node:22-alpine
  - 暴露端口：3000
  - 启动命令：node src/index.js
- 整理 .dockerignore 待写项：node_modules、dist、test、.github、.git、*.md

## 遇到的问题

- Dockerfile 应该放哪里：根目录 vs app/ 子目录
  - 答案：放在 app/ 下，配合 `context: ./app` 在 CI 中构建

## 解决方式

- AI 辅助学习
- 参考 [tracks/02-docker-and-registry.md](file:///d:/Project/devops-k8s-agent-roadmap/tracks/02-docker-and-registry.md) 镜像标签建议

## 明日计划

- 继续 Docker 基础：镜像、容器、容器生命周期
- 写 .dockerignore 排除无关文件

## Commit
