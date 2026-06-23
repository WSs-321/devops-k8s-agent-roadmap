# GHCR 登录（概念笔记）

> Day 22 概念总结。**本文件不含实例**，只列概念点。
> 实例（workflow / 命令 / 报错截图）由作者另行整理到 `examples/` 或对应工作流文件。

## 1. 基础概念

- GHCR 是什么：GitHub 官方容器仓库。
- 地址：`ghcr.io`。
- 与 GitHub Packages 同源，只存 OCI 镜像。
- 镜像地址格式：`ghcr.io/<owner>/<repo>:<tag>`。
- Public 仓库免费无限。
- Private 仓库按存储 + 带宽计费。
- 跟 Docker Hub 的差别：复用 GitHub 身份（同一 PAT 或 GITHUB_TOKEN 即可 push）。

## 2. 登录身份

- GITHUB_TOKEN：
  - 临时、自动注入、job 结束立即失效。
  - 走 `secrets.GITHUB_TOKEN` 引用。
  - 受 workflow 顶部 `permissions` 字段控制。
  - 日志自动 mask，不易泄露。
- PAT：
  - 本地 / 跨平台 CI 使用。
  - 两种类型：fine-grained（推荐，scope 显式）、classic（兼容老仓库）。
  - 必须保密，建议走 stdin / keyring。

## 3. permissions 字段

- 写在 workflow 顶部，控制 GITHUB_TOKEN 的权限范围。
- 推 GHCR 至少需要 `packages: write`。
- 默认给最小权限，不要一次开全。

## 4. 登录方式

- Actions 内：使用 `docker/login-action`，username 用 `github.actor`，password 用 `secrets.GITHUB_TOKEN`。
- 本地：使用 `gh auth login` + `docker login` 配合，密码走 stdin。
- 跨平台 CI：仍用 PAT，username/password 来自各自 secret。

## 5. github.actor 语义

- 触发本次 workflow 的账户 login。
- 不一定是仓库 owner，也不一定是 commit 作者。
- 拼镜像地址时用 `github.repository_owner`，不用 `github.actor`。
- 触发方式与 actor 取值关系：
  - 用户直接 push：actor = 用户。
  - PR 触发：actor = PR 作者。
  - schedule 定时：actor = `github-actions[bot]`。
  - Dependabot：actor = `dependabot[bot]`。
  - GitHub App：actor = App slug（如 `my-app[bot]`）。

## 6. 评论触发相关事件

- `issue_comment`：在 Issue 或 PR 会话区发评论（含 `/命令`），actor = 评论者。
- `pull_request_review_comment`：reviewer 在 diff 行内评论，actor = 评论者。
- `pull_request_review`：提交整体 review（approve / request changes），actor = reviewer。
- 评论者通常不是 PR 作者，身份跟推包权限不挂钩，评论触发的 workflow 一般不直接推 GHCR。

## 7. 镜像可见性

- push 完默认 private。
- 改 public：UI（Packages → Change visibility）或 API。
- 生产仓库建议保持 private，靠 team / 角色控访问。

## 8. 典型报错 → 原因 → 解决

- `unauthorized: authentication required`：没登录 / token 失效。
- `denied: requested access to the resource is denied`：token 没写权限（缺 `packages: write` / `write:packages`）。
- `denied: ... not found`：镜像路径 owner 拼错。
- `Name unknown to registry`：仓库名含大写。
- `toomanyrequests`：GitHub 限流。
- `not visible to your account`：私有包未授权给你。

## 9. 安全 checklist

- `permissions` 最小化，不全开。
- 不在日志 echo token / PAT。
- 本地 PAT 走 keyring / stdin，不写 `.env` 提交。
- 私有包用 team 分配权限。
- 定期清理不再用的 PAT。
