# docker/metadata-action（概念笔记）

> Day 24 概念总结。**本文件不含实例**，只列概念点。
> 实例（tag 策略 / job outputs / Dockerfile 与 buildx 覆盖）由作者另行整理到 workflow 文件。

## 1. 解决的问题

- `build-push-action` 不知道镜像该打哪些 tag。
- 裸写 `tags: user/app:latest` 只能打一个 tag。
- 手动拼 SHA / branch / semver 容易出错。
- `docker/metadata-action` 是"标签策略引擎"，一次构建打多个 tag。

## 2. 标签类型（type）

- `type=sha`：commit SHA（默认 7 位短 SHA）。
- `type=ref,event=branch`：分支名。
- `type=ref,event=tag`：Git tag。
- `type=raw,value=latest`：滚动标签。
- `type=semver,pattern={{version}}`：从 `v1.0.0` 提取 `1.0.0`。
- `type=semver,pattern={{major}}.{{minor}}`：浮动大版本 `1.0`。
- `type=edge,branch=main`：开发滚动 tag。
- `type=schedule,pattern=nightly`：定时构建专用。
- `type=pep440,pattern={{version}}`：Python PEP 440 版本。

## 3. enable 条件

- `enable={{is_default_branch}}`：仅默认分支打。
- `enable={{is_push}}`：push 事件才打。
- `enable={{is_pr}}`：PR 事件才打。
- `enable=${{ github.event_name != 'pull_request' }}`：用 GitHub 表达式过滤。
- 不满足条件时该 tag 不输出，**不会报错**。

## 4. flavor（前后缀）

- `latest=true / false`：自动打 latest。
- `prefix=dev-`：所有 tag 加前缀。
- `suffix=-alpine`：所有 tag 加后缀。
- `onlatest=true`：latest 也跟 flavor 走。

## 5. labels DSL

- `{{date}}`：构建时间（ISO-8601）。
- `{{sha}}`：commit SHA。
- `{{branch}}`：分支名。
- `{{tag}}`：tag 名。
- `{{version}}`：解析后版本号。
- `{{repository}}`：仓库名。
- 注意：`{{ }}` 是 metadata-action 自带 DSL，`${{ }}` 是 GitHub Actions 表达式，**两套语法不要混**。

## 6. 默认自动输出的 OCI 标签

- `org.opencontainers.image.title`（从 repo 名解析）。
- `org.opencontainers.image.revision`（github.sha）。
- `org.opencontainers.image.created`（构建时间）。
- `org.opencontainers.image.source`（仓库 URL）。
- `org.opencontainers.image.version`（tag 解析）。
- `org.opencontainers.image.description`（仓库描述）。
- Dockerfile 一般不再写这些标准 OCI key，由 metadata-action 接管。

## 7. 与 build-push-action 的关系

- metadata-action 输出 `steps.metadata.outputs.tags / labels / version / json`。
- build-push-action 的 `tags:` / `labels:` 字段消费这些 outputs。
- **顺序**：metadata-action 必须在 build-push-action **之前**（前置 step 才能被读到）。
- 数据流方向单向：metadata → build-push，不能反过来。

## 8. job outputs（跨 job 复用）

- step outputs（`steps.x.outputs.y`）只在同一 job 内可见。
- 跨 job 必须在 job 顶部声明 `outputs:` 块映射到 job outputs。
- 下游 job 用 `needs.X.outputs.Y` 消费。
- job outputs 键名可自定义，是"对外接口"。
- 不在 job 顶部写 `needs:` 就直接用 `needs.X.outputs.Y`，workflow 校验会失败。

## 9. Dockerfile LABEL 与 buildx labels 的覆盖关系

- buildx labels 字段（来自 metadata-action）**后写**，覆盖 Dockerfile 同名 LABEL。
- 自定义 key 用 `custom.*` 前缀避免与 OCI 标准 key 冲突。
- ARG + build-args 是 Dockerfile 接收外部参数的标准方式。
- VERSION 等可变值默认 `dev`，CI 传 `github.ref_name`，tag 触发自动变为版本号。
- 标准 OCI key 交给 metadata-action 写，Dockerfile 仅写自定义业务 key。
