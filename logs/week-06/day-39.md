# Daily Log

Date: 2026-07-05
Day: Saturday

## 今日目标

- 完成 Day39 Secret 安全学习
- 整理密钥使用规范，避免写入日志
- 输出 secret checklist 文档

## 实际完成

- 新增 `docs/secret-checklist.md` Secret 安全规范文档
  - 创建规范：最小权限、environment vs repository、命名规范
  - 使用规范：正确写法与禁止写法
  - 日志规范：自动脱敏边界、`::add-masker::` 手动脱敏派生值
  - 检查清单：创建前 / 使用中 / 定期
  - 应急流程：revoke → rotate → 排查 → 通知
  - `pull_request_target` 陷阱
  - Secret 扫描工具对比
  - `GITHUB_TOKEN` vs `github.token` 说明
  - 项目隐患排查

## 关键概念

- GitHub 自动脱敏只对**原始值**生效，**派生值不脱敏**（截取、base64、写文件）
- `secrets.GITHUB_TOKEN` 和 `github.token` 是同一个 token 的两种写法
- `GITHUB_TOKEN` 仅限当前仓库，PAT 跨仓库
- `pull_request` 事件（fork）自动拒绝访问 secrets
- `pull_request_target` 能访问 secrets，但 checkout PR 代码会泄露
- environment secret 优先级高于 repository secret
- 生产密钥必须用 environment secret + 审批

## 遇到的问题

- 起初不清楚 `GITHUB_TOKEN` 和 `github.token` 是否相同
- 不清楚自动脱敏的边界（派生值是否脱敏）

## 解决方式

- 确认 `secrets.GITHUB_TOKEN` / `github.token` / `$GITHUB_TOKEN` 三者等价
- 整理自动脱敏边界表：原始值脱敏、派生值不脱敏
- 记录 `::add-masker::` 手动脱敏派生值的方法

## 今日收获

- Secret 安全的核心是"创建用最小权限、使用不打印、日志查脱敏、泄露先 revoke"
- `pull_request_target` 是最危险的 trap，永远不要 checkout PR 代码并执行
- `set -x` + secret = 泄露，deploy.sh 用 `set -euo pipefail`（无 `-x`）是安全的
- `curl -v` 会打印 header，带 token 时用 `gh api` 或 `-s` 静默
- GitHub Secret Scanning 公开仓库自动开启，是第一道防线

## 明日计划

- Day40 SBOM 入门
- 了解 SBOM，尝试 Trivy/Syft 生成清单

## Commit

- `docs: day39密钥安全规范`
