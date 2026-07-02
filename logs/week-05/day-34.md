# Daily Log

Date: 2026-07-02
Day: Thursday

## 今日目标

- 完成 Day34 Release notes 学习
- 根据 commit 生成 release note 模板
- 了解发布 workflow 与 deploy workflow 的职责边界

## 实际完成

- 更新提交规范，要求使用 Conventional Commits 前缀
  - 格式：`<type>: <中文摘要>`
  - 便于后续 release note 自动归类和阅读
- 新增 release note 生成脚本
  - `scripts/gen-release-note.sh`
  - 支持 `VERSION`、`IMAGE`、`DATE` 环境变量
  - 使用 `git describe --tags --abbrev=0` 自动识别最近 tag
  - 使用 `git log <range> --pretty=format:"- %s (%h)"` 生成变更列表
- 完善 release note 模板
  - 增加 `Commit Range`
  - 增加 `AUTO_CHANGES_START/END` 自动变更区
- 新增 release workflow
  - `.github/workflows/release.yml`
  - tag `v*` 推送时生成 release note
  - 使用 `gh release create` 创建 GitHub Release
  - 使用 `${{ github.token }}`，无需手动配置 `GH_TOKEN`
- 理解 release 与 deploy 的职责区别
  - deploy：部署某个版本到环境
  - release：声明一个版本及变更内容

## 遇到的问题

- 起初脚本文件只生成了片段，没有完整落盘
- `git update-index --chmod=+x` 对未跟踪文件失败，需要改用 `git add --chmod=+x`
- `release.yml` 初稿中存在 YAML 细节问题：
  - `Name` 应为 `name`
  - `run:` 多行命令需要 `|`
  - `gh` 更适合使用 `GH_TOKEN`
- 对 `${{ github.token }}` 与 `${{ secrets.GITHUB_TOKEN }}` 的关系需要澄清

## 解决方式

- 补全 `scripts/gen-release-note.sh`
- 使用 `git add --chmod=+x scripts/gen-release-note.sh` 提交脚本执行权限
- 修正 release workflow：
  - `name: Release`
  - `run: |`
  - `GH_TOKEN: ${{ github.token }}`
  - `permissions: contents: write`
- 明确 `${{ github.token }}` 是 GitHub Actions 自动生成的临时 token，无需手动配置

## 今日收获

- `v1.0.0..HEAD` 是 Git 合法的 revision range，表示 tag 之后到当前 HEAD 的提交
- Release Note 可以从 commit message 自动生成，但 commit message 规范直接决定生成质量
- `fetch-depth: 0` 对 release workflow 很重要，否则可能拿不到完整 tag 历史
- Release workflow 应独立于 CI/CD 部署 workflow，职责更清晰

## 明日计划

- Day35 周复盘
- 完成 `project-03-cd-environments` 验收
- 梳理 Week5 的环境、密钥、部署、审批、发布能力闭环

## Commit

- `chore: day34提交前缀规则`
- `feat: day34发布说明脚本`
- `feat: day34发布工作流`
