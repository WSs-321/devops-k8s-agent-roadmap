# Daily Log

Date: 2026-06-23
Day: Tuesday

## 今日目标

- 配置 build-push-action 自动化构建和推送
- 完成 docker-ghcr workflow

## 实际完成

- 新增 `app/Dockerfile` 多阶段构建（builder + runner）
- 新增 `app/.dockerignore` 排除无关文件
- 新增 `.github/workflows/ci-docker.yml`：
  - checkout → setup-node → npm ci → lint → test → login → metadata → build-push
  - PR 触发时不推镜像
  - 自动生成 sha、latest、semver tag
- 完成 PR #22 并合入 main
- 验证 GHCR 镜像：
  - 包名：devops-k8s-agent-roadmap
  - 可见性：public
  - tags：`7cf66f1c` + `latest`
  - digest：sha256:549207130208c76b2b945f680d11e3bbd049c923bd1814d1bd6ac5bc6584bdd9
  - URL：<https://github.com/WSs-321?tab=packages>

## 遇到的问题

- metadata-action DSL 语法与 GitHub Actions 表达式混淆：
  - `type=sha256` 不存在，应该是 `type=sha`
  - `enabled=` 拼写错，应为 `enable=`
  - `pattern=${{ version }}` 是 GitHub 表达式，DSL 用 `{{version}}`
- `secrets.GIT_TOKEN` 不存在，应为 `GITHUB_TOKEN`
- PR 触发时 push 失败
- metadata-action step 必须有 `id`，后面才能 `steps.xxx.outputs.yyy`
- gh CLI 之前因 sandbox 限制无法使用，修改 sandbox.json 后正常

## 解决方式

- 区分两种表达式系统：
  - `${{ }}` = GitHub Actions 表达式（读上下文、secrets、steps 输出）
  - `{{ }}` = metadata-action DSL（格式化 tag/label）
- 用 `if: github.event_name != 'pull_request'` 跳过 Login
- 用 `push: ${{ github.event_name != 'pull_request' }}` 跳过 Push
- metadata-action step 加 `id: metadata`，build-push 引用 `steps.metadata.outputs.tags`

## 明日计划

- Day 24 镜像元数据与 tag 策略细化
- Day 25 接入 Trivy 镜像扫描

## Commit

- feature_ci-docker 分支
- c1344ef docker CI 门禁
- PR #22 <https://github.com/WSs-321/devops-k8s-agent-roadmap/pull/22>
