# Daily Log

Date: 2026-06-23
Day: Tuesday

## 今日目标

- 学习 docker/metadata-action 标签策略与 OCI 标签策略
- 整理与 build-push-action / Dockerfile 之间的协作关系

## 实际完成

- 沉淀概念笔记 `docs/metadata-action.md`，覆盖 9 个子主题：
  - 解决的问题
  - 标签类型（type=sha / ref / raw / semver / edge / schedule / pep440）
  - enable 条件（is_default_branch / is_push / is_pr / GitHub 表达式）
  - flavor 前后缀
  - labels DSL（{{date}} / {{sha}} / {{branch}} / {{version}} / {{repository}}）
  - 默认输出的 OCI 标签
  - 与 build-push-action 的数据流方向
  - job outputs 跨 job 复用
  - Dockerfile LABEL 与 buildx labels 的覆盖规则
- 校准 Dockerfile 的 ARG / build-args / LABEL 协作模式
  - 标准 OCI key 让 metadata-action 接管
  - 自定义 key 用 `custom.*` 前缀避免冲突
  - VERSION 默认 `dev`，CI 用 `github.ref_name` 覆盖

## 遇到的问题

- `{{ }}` 与 `${{ }}` 两套表达式系统混用：metadata-action DSL vs GitHub Actions 表达式
- Dockerfile 里写 `LABEL org.opencontainers.image.revision=$GITHUB_SHA` 取不到值
- Dockerfile LABEL 与 metadata-action 同名 key 之间的覆盖顺序困惑
- step outputs / job outputs / needs.X.outputs 三层概念区分不清

## 解决方式

- 明确两套表达式的边界：DSL 用于 metadata-action 内部 tag/label 模板，GitHub 表达式用于读上下文 / secrets / steps 输出
- Dockerfile 不再写标准 OCI key，全部交给 metadata-action 自动注入
- 自定义 key 写在 Dockerfile 时用 `ARG XXX=default` + `LABEL custom.xxx="${XXX}"`，CI 通过 `build-args` 注入真实值
- 建立"step → job outputs → needs"三层数据流模型：step 自动产出，job 顶部声明映射，下游 job 用 needs 消费

## 明日计划

- 接入 Trivy 镜像扫描，串成 build + push 双 job 安全管线

## Commit

- feature_day24-25-notes 分支
- 见 PR 描述
