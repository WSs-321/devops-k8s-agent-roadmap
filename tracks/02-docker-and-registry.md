# Track 02: Docker And Registry

## 目标

能把应用构建为容器镜像，并通过 GitHub Actions 推送到 GitHub Container Registry。

## 必学概念

- Dockerfile
- build context
- image layer
- multi-stage build
- container runtime
- image tag
- registry
- GHCR

## 镜像标签建议

```text
ghcr.io/<owner>/<repo>:<commit-sha>
ghcr.io/<owner>/<repo>:v1.0.0
ghcr.io/<owner>/<repo>:latest
```

生产环境优先使用 commit sha 或 release tag，不建议使用 `latest`。

## 验收标准

- 本地可以成功构建镜像。
- 本地可以成功运行容器。
- GitHub Actions 可以自动构建镜像。
- 镜像可以被推送到 GHCR。
- workflow summary 中能看到镜像版本。

