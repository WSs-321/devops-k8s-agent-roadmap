# Daily Log

Date: 2026-07-02
Day: Thursday

## 今日目标

- 开始 Week6 安全、质量、治理主题
- 学习 GitHub Actions `permissions` 权限最小化
- 为现有 workflow 补齐显式最小权限声明

## 学习内容

- `permissions` 控制的是 GitHub Actions 自动生成的 `GITHUB_TOKEN` / `${{ github.token }}` 权限范围。
- 如果 workflow 完全不写 `permissions`，会使用仓库或组织的默认 workflow token 权限。
- 如果 workflow 显式写了部分 `permissions`，未声明的权限默认是 `none`，只有 `metadata: read` 会保留。
- 最小权限原则：
  - 普通 CI 只需要 `contents: read`。
  - 推送 GHCR 镜像需要 `contents: read` 和 `packages: write`。
  - 上传 SARIF 扫描结果需要 `security-events: write`。
  - 创建 GitHub Release 需要 `contents: write`。

## 实际完成

- 审查现有 `.github/workflows/*.yml`。
- 确认以下 workflow 已具备合适权限：
  - `ci-node.yml`：`contents: read`
  - `ci-docker.yml`：`contents: read`、`packages: write`、`security-events: write`
  - `cd-env.yml`：`contents: read`
  - `cd-deploy.yml`：`contents: read`
  - `release.yml`：`contents: write`
- 为缺失权限声明的 workflow 补齐最小权限：
  - `ci-basic.yml`：新增 `contents: read`
  - `ci-docs.yml`：新增 `contents: read`

## 关键结论

- 不写 `permissions` 不代表没有权限，而是使用仓库默认权限，可能过大。
- 显式声明 `permissions` 后，未声明权限默认关闭，更符合最小权限原则。
- CI、CD、Release workflow 的权限需求不同，不应统一给写权限。
- Release workflow 使用 `${{ github.token }}` 时无需手动配置 secret，但必须有 `contents: write`。

## 风险与注意事项

- `contents: read` 足够支持 `actions/checkout`。
- 如果后续 workflow 需要写 PR 评论、创建 issue、推送 package，需要单独补充对应权限。
- 不熟悉时应避免使用 `pull_request_target`，防止在高权限上下文中执行不可信代码。

## 明日计划

- Day37 学习 Dependabot
- 配置依赖与 GitHub Actions 自动更新策略
- 梳理自动依赖 PR 的审查风险

## Commit

- `ci: day36权限最小化`
