# Daily Log

Date: 2026-06-23
Day: Tuesday

## 今日目标

- 接入 Trivy 镜像扫描，让 PR / push 流水线具备漏洞门禁
- 串成 build + push 双 job 安全管线，扫描失败时阻断推送

## 实际完成

- 沉淀概念笔记 `docs/trivy-scan.md`，覆盖 10 个子主题：
  - Trivy 的能力范围与运行原理
  - 漏洞分级与默认阻塞策略
  - 关键参数（image-ref / format / exit-code / ignore-unfixed / scanners / severity / timeout / registry-* / output）
  - 本地扫 vs 远端扫的取舍
  - SARIF 与 GitHub Security 集成
  - Trivy 命令家族（image / fs / config / repo / sbom）
  - 漏洞修复路径
  - 单平台扫 vs 多平台扫
  - build + push 双 job 编排模型
- 改造 `.github/workflows/ci-docker.yml`：
  - build job 顶部声明 `outputs: tags / labels`
  - permissions 加 `security-events: write`
  - build-push-action 加 `load: true` 给 Trivy 扫本地
  - Trivy image-ref 改用 `outputs.version` 取单 tag
  - 新增 `upload-sarif` step，扫描结果上传 GitHub Security
  - 增加 `setup-buildx-action` 显式声明
  - 两个 job 都加 `cache-from: type=gha` / `cache-to: type=gha,mode=max`
  - push job 新增 `needs: build-docker-image`，build 失败时跳过推送
- 修正 `app/Dockerfile` 第一行 `From → FROM` 大小写

## 遇到的问题

- Trivy 默认扫远端 GHCR，但 build job 此时 `push: false`，远端没镜像 → 404 / 扫到旧版
- Trivy 用 `outputs.tags` 是多行字符串，拼出来的 image-ref 非法
- push job 没声明 `needs:`，直接用 `needs.X.outputs.Y` 表达式会失败
- multi-platform + `load: true` 互斥，buildx 不允许同时使用
- SARIF 上传需要额外权限，否则 step 失败

## 解决方式

- build job 改 `push: false` + `load: true`，Trivy 扫 runner daemon 里的本地镜像，不需要 registry 认证
- Trivy `image-ref` 改用 `steps.metadata.outputs.version`（单 tag），避免多行 tags 报错
- push job 顶部补 `needs: build-docker-image`，同时 build job 顶部加 `outputs:` 块
- 设计上 build job 固定单平台扫，多平台只在 push job 出现，绕过 `load: true` 限制
- workflow 顶部 `permissions` 加 `security-events: write`，并对 upload-sarif 加 `if: always()`

## 明日计划

- Day 26 制品追踪：在 workflow summary 输出镜像地址 / 版本 / SHA / 扫描状态

## Commit

- feature_day24-25-notes 分支
- 见 PR 描述
