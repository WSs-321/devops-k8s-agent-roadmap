# Project 02: Docker And GHCR

## 目标

把示例项目容器化，并通过 GitHub Actions 推送镜像到 GHCR。

## 任务

- 编写 Dockerfile。
- 本地构建镜像。
- 本地运行容器。
- 编写 docker build workflow。
- 登录 GHCR。
- 推送 commit sha tag。
- 输出镜像地址。

## 验收标准

- GHCR 中能看到镜像。
- 镜像 tag 包含 commit sha。
- workflow 权限显式包含 `packages: write`。
- 失败日志可定位 Dockerfile 问题。

