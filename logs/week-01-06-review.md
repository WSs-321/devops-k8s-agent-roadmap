# 前六周回顾：GitHub Actions -> Docker -> GHCR -> CD -> 安全治理

> Day 01-42 完整知识点回顾，覆盖 6 周 4 个 Project 里程碑。

---

## 总览

```text
Week 1 ──── Week 2 ──── Week 3 ──── Week 4 ──── Week 5 ──── Week 6
  CI 基础 ->  CI 工程化 -> Docker 容器 -> GHCR 流水线 -> CD 与环境 -> 安全治理
```

---

## Week 1：GitHub Actions CI 基础（Day 01-07）

### Day 01 - 仓库初始化

- 创建私有仓库 `devops-k8s-agent-roadmap`
- 确认分支策略：main + feature 分支 + PR 合并

### Day 02 - GitHub Actions 核心概念

- **六个核心概念**：workflow / job / step / runner / event / action
  - `workflow` = `.github/workflows/*.yml`，由事件触发
  - `job` = 一组 step 组成的执行单元，默认并行
  - `step` = job 内最小的执行块，可以是 shell 命令或 action
  - `runner` = 执行 workflow 的虚拟机（ubuntu-latest / windows-latest 等）
  - `event` = 触发 workflow 的动作（push / pull_request / schedule / workflow_dispatch 等）
  - `action` = 可复用的 workflow 片段（`uses: actions/checkout@v4`）
- 手写第一个 `hello-actions.yml` 验证概念

### Day 03 - Node.js CI 搭骨架

- 配置 setup -> install -> test 三步 CI
- 学习 `actions/setup-node@v4` 的使用
- 理解 `runs-on` 指定 runner 类型

### Day 04 - `npm ci` vs `npm install`

- **`npm ci`**：严格按 `package-lock.json` 安装，依赖版本锁定，适合 CI
- **`npm install`**：可能更新 `package-lock.json`，版本不确定，适合本地开发
- `npm ci` 必须存在 `package-lock.json`，否则报错
- 配置 PR 合并策略：`pull_request` 触发 CI

### Day 05 - 最小 Node.js 示例应用

- 创建 `app/` 目录结构：`package.json` / `src/index.js` / `test/index.test.js`
- 为 CI 提供可测试的代码基线

### Day 06 - npm 缓存配置

- 配置 `actions/setup-node` 内置缓存 `cache: 'npm'`
- `package-lock.json` 作为缓存 key，依赖不变可直接命中
- 缓存命中后依赖安装从 ~30s 降到 ~3s

### Day 07 - ESLint 代码检查

- **dependencies vs devDependencies**：
  - `dependencies`：运行时需要（express、lodash）
  - `devDependencies`：开发时用（eslint、jest），放 docker 生产镜像时不装
- ESLint 放在 `devDependencies`，CI 中 lint 失败阻断后续 step
- 理解失败阻断机制：job 中 step 按顺序执行，前一步失败后后续不执行

### Week 1 知识点清单

- workflow / job / step / runner / event / action
- `on: push / pull_request / workflow_dispatch`
- `actions/checkout@v4`、`actions/setup-node@v4`
- `npm ci` vs `npm install`
- dependencies vs devDependencies
- `actions/setup-node` 内置缓存
- protected branch + required status checks 基础

---

## Week 2：CI 工程化（Day 08-14）

### Day 08 - Commit Message 规范

- 统一格式：`<type>: <中文描述>`
- 分支命名：`feature_<描述>_<日期>`
- 规范化是后续 release note 自动生成的前置条件

### Day 09 - Test 报告与分支保护

- 配置 test 报告输出目录
- **分支保护规则基础**：
  - `Require a pull request before merging`
  - `Require status checks to pass before merging`
  - PR 必须通过 CI 才能合并

### Day 10 - 构建流程完善

- 优化 CI workflow 的构建步骤
- 区分测试构建和生产构建

### Day 11 - 深入缓存配置

- **`actions/cache` vs `setup-node` 内置缓存**：
  - `actions/cache`：通用，需要手动指定 path + key
  - `setup-node` 内置：只需 `cache: 'npm'`，自动推断路径和 key
- cache key 设计原则：用依赖文件的 hash（如 `package-lock.json`），变更时才重新缓存
- 缓存命中率影响 CI 速度的核心

### Day 12 - Matrix 多版本测试

- **Matrix 策略**：

  ```yaml
  strategy:
    matrix:
      node-version: [18.x, 20.x]
  ```

- 每个版本并行创建一个 job
- **`fail-fast`**：默认 `true`，某个版本失败会取消其他版本
  - 设为 `false`：让所有版本都跑完，全面了解兼容性
- 适用场景：测试多版本依赖兼容性、多 OS 兼容性

### Day 13 - PR 触发 vs Push 触发

- **`on: pull_request`**：PR 的每个新 commit 触发
- **`on: push`**：推送到分支触发（含 merge 到 main 后）
- 同一 workflow 可同时配置两种事件
- PR 合入后 push 触发和 PR 触发略有不同（分支上下文不同）

### Day 14 - Week 2 复盘

- 验收 project-01-ci-baseline

### Week 2 知识点清单

- commit message 规范（Conventional Commits 基础）
- 分支命名规范
- test 报告输出
- `actions/cache` vs `setup-node` 内置缓存
- cache key 设计原则
- matrix 策略 + `fail-fast`
- `on: push` vs `on: pull_request` 行为差异
- protected branch 规则实践

---

## Week 3：Docker 容器基础（Day 15-20）

### Day 15 - Dockerfile 编写

- 基础镜像：`node:22-alpine`
- Dockerfile 位置选择：放在 `app/` 子目录，CI 使用 `context: ./app`
- 写 `.dockerignore` 排除 `node_modules` / `dist` / `.git` / `test` / `*.md`

### Day 16 - Docker 基础概念

- **镜像、Dockerfile、容器三者关系**：
  - Dockerfile -> `docker build` -> Image -> `docker run` -> Container
- **`docker run` 常用参数**：
  - `-p 3000:3000`：主机:容器端口映射
  - `-P`：随机端口映射
  - 不写端口映射：容器内可访问，同网络容器可访问，外部不可
- **`EXPOSE`**：文档声明，不映射端口，仅描述容器预期监听端口
- **`--entrypoint`**：覆盖 Dockerfile 的 ENTRYPOINT
- **`--restart unless-stopped`**：容器退出后自动重启
- **`--memory` vs `--shm-size`**：
  - `--memory`：容器总内存限制
  - `--shm-size`：`/dev/shm` 共享内存大小，默认 64MB

### Day 17 - 多阶段构建

- **语法**：`FROM base AS builder` -> `FROM base AS runner` -> `COPY --from=builder`
- **优点**：镜像小（生产阶段不包含编译工具）、缓存好、安全
- **缺点**：复杂度增加、调试困难
- Node.js 多阶段模式：

  ```dockerfile
  FROM node:22-alpine AS builder
  WORKDIR /app
  COPY package*.json ./
  RUN npm ci --omit=dev     # 仅生产依赖

  FROM node:22-alpine AS runner
  COPY --from=builder /app/node_modules ./node_modules
  COPY src ./src
  CMD ["node", "src/index.js"]
  ```

- 关键理解：`--from=builder` 是从 builder 阶段产物中取，不是从构建上下文中取

### Day 18 - Docker HEALTHCHECK

- **容器三状态**：`starting` -> `healthy` / `unhealthy`
- **HEALTHCHECK 参数**：
  - `--interval=30s`：检查间隔
  - `--timeout=3s`：单次检查超时
  - `--start-period=5s`：启动缓冲期
  - `--retries=3`：失败重试次数
- 没有 HEALTHCHECK 指令时，容器永远显示 running，不知道是否真正健康
- **与 K8s 探针对应**：
  - `livenessProbe`：容器是否活着（对应 unhealthy）
  - `readinessProbe`：容器是否准备好接收流量
  - `startupProbe`：启动期间不检查 liveness

### Day 19 - 配置外置 + CI 拆分

- **12-Factor App 配置原则**：
  - 环境变量（推荐）：`process.env.NODE_ENV`
  - 配置文件挂载：`docker run -v config.json:/app/config.json`
  - 密钥管理服务：HashiCorp Vault / AWS Secrets Manager
- **CI 拆分**：
  - `ci-node.yml`：app/ 目录变更才触发
  - `ci-docs.yml`：docs/ / logs/ 等 md 文件变更触发
  - `ci-basic.yml`：基础检查
- **markdownlint 配置**：
  - 中文场景关闭 MD013（行长度）、MD033（禁止 HTML）、MD041（首行 heading）
  - `**/*.md` 覆盖任意层级，`*.md` 只匹配根目录
- **文档命名规范**：统一 `docker-<主题>.md` kebab-case
- **重要坑**：一个 step 只能有一个 `uses`，不能 `uses` + `run` 共存

### Day 20 - 镜像标签策略

- **三种标签类型**：
  - **commit SHA**（推荐）：`ghcr.io/user/app:abc123f`，不可变，精确追溯
  - **semver**：`v1.2.3` / `v1.2` / `v1`，语义化
  - **环境标签**：`dev` / `staging` / `prod`，可移动
- **`:latest` 陷阱**：不可回溯、不知道跑的是哪个版本、出问题时无法回滚
- **`docker/metadata-action`**：
  - 自动生成 tags：sha、latest（main 分支）、semver（tag 推送）
  - 自动生成 OCI labels

### Week 3 知识点清单

- Dockerfile / Image / Container 三者关系
- `.dockerignore` 编写
- `docker run` 核心参数（`-p` / `--entrypoint` / `--restart` / `--memory` / `--shm-size`）
- 多阶段构建（`AS` / `COPY --from`）
- HEALTHCHECK 与 K8s 探针对应
- 12-Factor App 配置外置
- CI workflow 拆分策略
- markdownlint 配置（MD013 / MD033 / MD041）
- `**/*.md` vs `*.md` 区别
- 一个 step 一个 `uses` 规则
- `:latest` 陷阱与 SHA/semver 策略
- `docker/metadata-action` DSL `{{ }}` 表达式

---

## Week 4：GHCR 镜像流水线（Day 22-28）

### Day 22 - GHCR 登录

- **GHCR 包归属**：包属于 user/org，不在仓库下面；仓库和包是软关联
- **`GITHUB_TOKEN` 权限**：
  - PR 来自 fork 时只读，不可写 packages
  - push / workflow_dispatch 时可写 packages
- `docker/login-action` 登录：

  ```yaml
  - uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
  ```

- PR 时 `if: github.event_name != 'pull_request'` 跳过登录

### Day 23 - build-push-action

- 完整 docker workflow 链路：

  ```text
  checkout -> setup-node -> npm ci -> lint -> test -> login -> metadata -> build-push
  ```

- PR 时不推镜像：`push: ${{ github.event_name != 'pull_request' }}`
- **metadata-action DSL vs GitHub 表达式**：
  - DSL `{{ }}`：metadata-action 内部 tag/label 模板
  - GitHub `${{ }}`：读上下文 / secrets / steps outputs
  - `type=sha256` 不存在，正确为 `type=sha`

### Day 24 - metadata-action 深入

- **tag 类型**：type=sha / ref / raw / semver / edge / schedule
- **enable 条件**：`is_default_branch` / `is_push` / `is_pr` / GitHub 表达式
- **flavor**：控制前缀后缀（如 `latest=false` 关闭 latest tag）
- **labels DSL**：`{{date}}` / `{{sha}}` / `{{branch}}` / `{{version}}` / `{{repository}}`
- **Dockerfile LABEL 覆盖规则**：
  - 标准 OCI key 交给 metadata-action 接管，不在 Dockerfile 写
  - 自定义 key 用 `custom.*` 前缀避免冲突
  - VERSION 默认 `dev`，CI 通过 `build-args` 注入真实值

### Day 25 - Trivy 镜像扫描

- **Trivy 能力范围**：image / fs / config / repo / sbom
- **漏洞分级**：CRITICAL / HIGH / MEDIUM / LOW
- **关键参数**：
  - `image-ref`：扫描目标镜像
  - `format: sarif`：输出 GitHub Security 兼容格式
  - `exit-code: 1`：有漏洞时让 step 失败
  - `severity: CRITICAL,HIGH`：只关注高危
- **本地扫 vs 远端扫**：
  - build job 中 `push: false` + `load: true` -> 扫 runner 本地 daemon 中的镜像
  - 不需要 registry 认证
- **multi-platform + `load: true` 互斥**：buildx 不允许同时使用
- **build + push 双 job 安全管线**：

  ```yaml
  jobs:
    build-docker-image:
      outputs: { tags, labels }    # 顶部声明输出
      steps: [..., build-push]      # push: false, load: true
    push:
      needs: build-docker-image     # 等待 build 完成
      if: github.event_name != 'pull_request'
      steps: [..., build-push]      # push: true，推多平台
  ```

- `setup-buildx-action` 显式声明 buildx
- `cache-from: type=gha` / `cache-to: type=gha,mode=max` 跨 job 缓存

### Day 26 - workflow summary 制品追踪

- 使用 `$GITHUB_STEP_SUMMARY` 输出镜像信息
- 追踪三核心字段：**tags / labels / digest**
- **digest > tag**：digest 是内容寻址的不可变标识，tag 可移动
- **多行字符串写 Markdown 表格**：先替换换行为 `<br>`，否则断表
- **三层 outputs 数据流**：

  ```text
  step outputs  ->  job outputs  ->  needs.X.outputs
  (step 自动产出)  (job 顶部映射)  (下游 job 读取)
  ```

- digest 从 `steps.push.outputs.digest` 读取（不是 build job 推断）

### Day 27 - CI 失败复盘

- 不再故意制造失败，基于真实失败分析
- workflow 调试要点：
  - 确认字段来源（哪个 step 产出）
  - 确认执行时机（PR vs push 不同阶段）
  - 确认输出格式（单行 vs 多行）
- 小步提交、小步验证，每次只修一个明确问题

### Day 28 - Week 4 复盘

- 验收 project-02-docker-ghcr

### Week 4 知识点清单

- GHCR 登录与 `GITHUB_TOKEN` permissions
- `packages: write` 权限
- `docker/login-action` / `docker/build-push-action` / `docker/metadata-action`
- `docker/setup-buildx-action`
- metadata-action DSL `{{ }}` vs GitHub Actions `${{ }}`
- tag 类型（sha / ref / semver / raw）
- flavor 前后缀控制
- Dockerfile LABEL 与 metadata-action 覆盖规则
- `build-args` + `ARG` 注入自定义变量
- Trivy image 扫描（本地 vs 远端、severity、exit-code）
- `load: true` + `push: false` 扫本地镜像
- multi-platform + `load: true` 互斥
- build + push 双 job 安全管线
- step outputs / job outputs / needs.X.outputs 三层传递
- `$GITHUB_STEP_SUMMARY` 制品追踪
- tags / labels / digest 三核心字段
- 多行字符串处理（换行 -> `<br>`）

---

## Week 5：CD 与 GitHub Environments（Day 29-35）

### Day 29 - GitHub Environments 设计

- **Environment = 部署目标抽象**，不是服务器，是带保护规则和专属配置的逻辑命名空间
- **三环境模型**：
  - **dev**：push main 自动部署，无审批，快速反馈
  - **staging**：手动 / tag 触发，可选审批
  - **production**：tag / release 触发，必须人工审批
- **三类 protection rules**：
  - Required reviewers（最多 6 人）：job 暂停等审批
  - Wait timer（最多 30 天）：部署前强制等待
  - Deployment branches：限制可部署分支
- **执行流**：分支白名单检查 -> wait timer -> required reviewers -> 执行部署
- **核心价值**：把"在哪部署、谁能部署、用什么密钥"从代码剥离到平台管控

### Day 30 - Secrets 三层级

- **三层级**：organization > repository > environment（作用域递减，优先级递增）
- **同名优先级**：environment > repository > organization
- **注入方式**：
  - 推荐：`env: { TOKEN: ${{ secrets.XXX }} }` 注入到环境变量
  - 不推荐：直接在 `run:` 里用 expression 插值
- **安全红线**：
  - 不 echo / 不 print / 不 base64 / 不截断 / 不写文件
  - 自动脱敏只对完整匹配生效，派生值不脱敏
  - fork 发起的 `pull_request` 默认无法访问 secrets
  - secret 不能跨 job 通过 outputs 传递
- **CD 场景规划**：
  - Repository：`GHCR_TOKEN`（共用）
  - Environment dev：`DEPLOY_HOST_DEV` / `DEPLOY_KEY_DEV`
  - Environment production：`DEPLOY_HOST_PROD` / `DEPLOY_KEY_PROD`（受审批保护）

### Day 31 - Dev 部署 Job

- **最小 dev deploy job 骨架**：

  ```yaml
  deploy-dev:
    environment:
      name: dev
      url: http://dev.example.com
    steps:
      - run: echo "deploying to dev..."
  ```

- **`vars.X` vs `secrets.X`**：
  - `vars.X`：非敏感配置（主机名、区域）
  - `secrets.X`：敏感凭证（密钥、密码）
- **CI 与 CD 衔接**：
  - 方式 A：同一 workflow，needs 串联 build -> deploy
  - 方式 B：独立 workflow，`workflow_run` / `repository_dispatch` 触发
- dev 定位：自动触发、无审批、快速反馈

### Day 32 - Production 审批

- **审批配置在平台侧**：Settings -> Environments -> production
- YAML 只声明 `environment: production`，审批由环境配置触发
- **审批规则**：
  - 任意一名 required reviewer Approve 即放行
  - 可勾选 Prevent self-review 禁止自审
  - 审批最长 30 天超时，超时 job 取消
  - wait timer + reviewers 可叠加
- **dev vs production 对照**：

  | 维度 | dev | production |
  | --- | --- | --- |
  | 触发 | 自动 | 手动/审批后 |
  | 审批 | 无 | 必须人工 |
  | 分支 | 宽松 | 仅 main |
  | secret | DEV 系列 | PROD 系列 |

### Day 33 - 部署脚本接口

- **契约先行**：先定输入输出 + 退出码，再写实现
- **输入参数**（环境变量）：
  - 必填：`DEPLOY_ENV` / `DEPLOY_TARGET` / `APP_NAME` / `IMAGE` / `IMAGE_TAG`
  - 可选：`HEALTH_CHECK_URL` / `DRY_RUN` / `SSH_PRIVATE_KEY` / `DEPLOY_HOST` / `DEPLOY_USER`
- **退出码约定**：
  - 0 成功、10 参数缺失、20 认证失败、30 拉取失败、40 启动失败、50 健康检查失败
- **四种部署后端**：`ssh` / `docker` / `compose` / `ecs`
- **`case "$DEPLOY_TARGET" in` 分发模式**：未来加 K8s 只需新增一个函数
- **`DRY_RUN=true`**：只打印不执行，无服务器时演练完整链路
- **幂等性**：`docker stop || true; docker rm || true` 避免容器名冲突
- **`set -euo pipefail`**：任意失败立即退出，避免错误传播
- **workflow 与脚本职责分离**：workflow 管流程编排 + 参数注入，脚本管部署细节
- **坑**：
  - bash `{ echo ...; }` 花括号前后必须有空格
  - `ssh user@host cmd` 变量需引号
  - workflow `paths` 写错文件名不触发 CI

### Day 34 - Release Notes

- **Conventional Commits 规范**：`<type>: <中文摘要>`
- **`gen-release-note.sh` 脚本**：
  - `git describe --tags --abbrev=0`：找最近 tag
  - `git log v1.0.0..HEAD --pretty=format:"- %s (%h)"`：生成变更列表
  - `v1.0.0..HEAD` 是合法 revision range
- **Release workflow**：

  ```yaml
  on:
    push:
      tags: ['v*']
  permissions:
    contents: write
  ```

- **`gh release create`**：使用 `${{ github.token }}` 自动认证，无需手动配置
- **`fetch-depth: 0`**：release workflow 需要完整 tag 历史
- **release vs deploy 职责边界**：
  - release：声明一个版本 + 变更内容
  - deploy：部署某个版本到环境

### Day 35 - Week 5 复盘

- Project-03-cd-environments 验收

### Week 5 知识点清单

- GitHub Environments 概念与 design
- dev / staging / production 三环境模型
- protection rules（reviewers / wait timer / branches）
- secrets 三层级（org / repo / environment）
- `vars` vs `secrets` 区别
- 环境变量注入（`env:`）vs expression 插值
- environment secret 的审批保护
- deploy job 最小骨架
- production 审批配置（平台侧 vs YAML 侧）
- 部署脚本接口设计（契约先行、退出码、DRY_RUN）
- 四种部署后端（ssh / docker / compose / ecs）
- `case ... in` 分发模式
- docker 部署幂等性
- `set -euo pipefail` 严格模式
- workflow 与脚本职责分离
- Conventional Commits 规范
- `git describe --tags` / `git log range`
- `gh release create`
- `${{ github.token }}` vs secrets
- release vs deploy 职责边界

---

## Week 6：安全、质量、治理（Day 36-42）

### Day 36 - 权限最小化

- **`permissions` 核心原则**：
  - 不写 `permissions` = 使用仓库/组织默认权限（可能过大）
  - 写了 `permissions` = 未声明权限默认 `none`（符合最小权限原则）
  - 唯一例外：`metadata: read` 始终保留
- **各场景权限需求**：

  | 场景 | 权限 |
  | --- | --- |
  | 普通 CI | `contents: read` |
  | 推送 GHCR | `contents: read` + `packages: write` |
  | 上传 SARIF | `security-events: write` |
  | 创建 Release | `contents: write` |

- 补齐 `ci-basic.yml`、`ci-docs.yml` 的 permissions

### Day 37 - Dependabot

- **两种更新模式**：
  - **version updates**：定期检查依赖新版本
  - **security updates**：发现已知漏洞自动开 PR
- **配置 3 个 ecosystem**：

  | Ecosystem | 扫描路径 | 频率 |
  | --- | --- | --- |
  | npm | `/app/` | weekly |
  | github-actions | `/` | weekly |
  | docker | `/app/` | weekly |

- **`groups` 分组更新**：minor/patch 合并一个 PR，major 单独 PR
  - 目的：减少 PR 噪音，major 需要人工审查
- **YAML 锚点局限**：`<<` 合并只对 map 有效，list 会被整体覆盖
- **`github-actions` ecosystem**：官方推荐 directory 为 `/`，只扫描 `.github/workflows/`

### Day 38 - CodeQL

- **CodeQL 定位**：源码级静态分析（SAST），检查自己代码的逻辑漏洞
- **与 Dependabot / Trivy 的区别**：
  - Dependabot：依赖版本已知漏洞
  - Trivy：镜像系统包和依赖漏洞
  - CodeQL：源码逻辑漏洞（SQL 注入、XSS 等）
- **工作原理**：

  ```text
  checkout -> init（构建代码数据库）-> analyze（QL 查询 + 上传 SARIF）-> Security tab
  ```

- **JS/Python vs 编译型语言**：
  - JS/Python：不需要 build 步骤，直接解析源码
  - C++/Java/Go：需要 build 步骤生成编译数据库
- **`analyze` step 内置上传**：不需要手动 `upload-sarif`
- **定时扫描的意义**：CodeQL 查询规则持续更新，旧代码也能发现新漏洞
- **permissions**：`contents: read` + `security-events: write`

### Day 39 - Secret 安全

- **核心原则**：创建用最小权限、使用不打印、日志查脱敏、泄露先 revoke
- **自动脱敏边界**：

  | 场景 | 脱敏 |
  | --- | --- |
  | 原始值直接打印 | 自动脱敏 |
  | 截取子串 | 派生值不脱敏 |
  | base64 编码 | 派生值不脱敏 |
  | 写入文件 | 不在 stdout，无法脱敏 |

- **手动脱敏**：`echo "::add-mask::$VALUE"` 处理派生值
- **`pull_request_target` 陷阱**：
  - 能访问 secrets（CVE 高危事件）
  - checkout PR 代码 -> 攻击者注入的代码能读到 secrets
  - 永远不要 checkout PR 代码并执行
- **`GITHUB_TOKEN` vs `github.token`**：同一个 token 的三种写法（`secrets.GITHUB_TOKEN` / `github.token` / `$GITHUB_TOKEN`）
- **安全写法 vs 禁止写法**：

  ```yaml
  # 正确
  env: { TOKEN: ${{ secrets.TOKEN }} }
  run: echo "deploying..."

  # 错误
  run: echo ${{ secrets.TOKEN }}   # 直接打印
  run: echo "${{ secrets.TOKEN }}" | base64  # 派生值
  ```

- **`set -x` + secret = 泄露**：deploy.sh 用 `set -euo pipefail`（无 `-x`）
- **`curl -v` 会打印 header**：带 token 用 `gh api` 或 `-s`
- **Token 泄露应急**：revoke -> rotate -> audit -> notify

### Day 40 - SBOM

- **SBOM 三大标准**：

  | 标准 | 主导方 | 方向 | 格式 |
  | --- | --- | --- | --- |
  | SPDX | Linux Foundation | 许可证合规 | JSON / YAML / tag:value |
  | CycloneDX | OWASP | 安全扫描 | JSON / XML |
  | SWID | NIST | 政府采购 | XML |

- **SBOM ≠ 漏洞扫描**：SBOM 是"清单"，漏洞扫描是"核对清单找问题"
- **三个方案对比**：

  | 决策点 | 选择 | 原因 |
  | --- | --- | --- |
  | 源码 vs 镜像 | 镜像 | 含 OS 层、运行时依赖 |
  | 独立 vs 合并 | 独立 workflow | 关注点分离 |
  | Registry Pull vs 本地 tar | Registry Pull | 构建后镜像已在 registry |

- **`anchore/sbom-action@v0`**：内置 Syft，支持 image / path 两种模式
- **`workflow_run` 事件**：

  ```yaml
  on:
    workflow_run:
      workflows: ["docker CI"]
      types: [completed]
  ```

  - 仅在默认分支（main）生效
  - **不能作为 required status check**（PR 阶段不触发）
- **GitHub Actions 语法坑**：
  - `run:` 和 `uses:` 不能共存于同一 step
  - `upload-artifact@v3` 已废弃，须用 v4
  - `$GITHUB_OUTPUT` 用于 step 间传值
  - 镜像名双冒号是语法错误

### Day 41 - 分支保护

- **分支保护六项能力**：

  | 能力 | 说明 |
  | --- | --- |
  | 合并前要求 | PR 必须 >=N 人 approve + CI green + conversation resolved |
  | Status check | 指定 job 必须 green 才允许 merge |
  | 推送限制 | 禁止 force push / 直接 push / 删除分支 |
  | Signed commit | GPG/SSH 验证提交者身份 |
  | 线性历史 | 禁止 merge commit，强制 rebase/squash |
  | 锁定分支 | 只读 |

- **三种合并策略**：

  | 策略 | 效果 | 适用 |
  | --- | --- | --- |
  | Merge commit | 保留完整分支历史 | 传统团队 |
  | Squash merge | 整个 PR 压成 1 个 commit | 本项目 |
  | Rebase merge | 无 merge commit，线性历史 | 严格线性 |

- **Status Check 4 个坑**：

  | 坑 | 说明 |
  | --- | --- |
  | 大小写 | `ci` != `CI` |
  | 新 workflow | 必须先合入 main 一次才能选为 required |
  | workflow_run | PR 阶段不触发，不能做 required |
  | 矩阵 job | 格式 `name (version)`，如 `ci (18.x)` |

- **Signed commit**：用 GPG/SSH 签名防伪造，单人项目不推荐
- **"Require branches to be up to date"**：
  - 判断逻辑：PR 分支 HEAD 是否包含 main 最新 commit
  - PR 合入后其他 PR 不会自动重跑 CI
  - 只有手动 "Update branch" 或 Mergify/Kodiak 类工具才触发
  - 单人项目不建议开启
- **推荐配置**：

  ```text
  Require PR before merging (1 approval, dismiss stale)
  Status checks: ci, node-ci, docs-check
  Block force pushes
  No bypassing
  ```

### Day 42 - 周复盘

- 输出 `docs/security-baseline.md` CI/CD 安全基线
- 整合六项安全实践：权限最小化 -> Dependabot -> CodeQL -> Secret -> SBOM -> 分支保护
- 每个主题包含：原则 + 配置 + 检查清单

### Week 6 知识点清单

- `permissions` 显式声明 vs 默认继承
- CI / Docker / Release / CodeQL 各自的最小权限
- Dependabot version updates vs security updates
- 3 个 ecosystem 配置（npm / github-actions / docker）
- groups 分组更新（minor/patch 合并，major 单独）
- CodeQL SAST 原理（build -> query -> SARIF -> Security tab）
- JS vs 编译型语言的 build 需求
- CodeQL 定时扫描的价值
- Secret 自动脱敏边界（原始值 vs 派生值）
- `pull_request_target` 高危陷阱
- `::add-masker::` 手动脱敏
- Secret 泄露应急四步
- SBOM 三大标准（SPDX / CycloneDX / SWID）
- `anchore/sbom-action@v0` 集成
- `workflow_run` 事件特性（仅默认分支、不做 required check）
- GitHub Actions 语法常见坑
- `upload-artifact@v3 -> v4` 升级
- `$GITHUB_OUTPUT` 传值
- 分支保护六项能力
- 三种合并策略（merge / squash / rebase）
- Status Check 4 个坑
- signed commit 原理
- "Require branches to be up to date" 判断逻辑
- merge queue 工具（Mergify / Kodiak / bors）

---

## 六周全局技能树

```text
                     ┌──────────────────────────┐
                     │     Git / GitHub 基础      │
                     │  PR / branch / commit 规范  │
                     └────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
  ┌───────▼───────┐     ┌────────▼────────┐     ┌────────▼────────┐
  │  GitHub Actions │     │    Docker       │     │   安全治理       │
  │                │     │                │     │                │
  │ workflow/job   │     │ Dockerfile     │     │ permissions    │
  │ step/runner    │     │ multi-stage    │     │ Dependabot     │
  │ event/action   │     │ HEALTHCHECK    │     │ CodeQL         │
  │ matrix/cache   │     │ image tag      │     │ Secret 安全     │
  │ environments   │     │ .dockerignore  │     │ SBOM           │
  │ secrets/vars   │     │ docker run     │     │ 分支保护        │
  │ release        │     │ docker compose │     │                │
  └───────┬───────┘     └────────┬────────┘     └────────┬────────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                     ┌────────────▼─────────────┐
                     │       GHCR 镜像流水线      │
                     │                          │
                     │ login -> metadata -> build  │
                     │ -> Trivy scan -> push       │
                     │ -> summary 制品追踪        │
                     └────────────┬─────────────┘
                                  │
                     ┌────────────▼─────────────┐
                     │           CD 链路          │
                     │                          │
                     │ dev(自动) -> staging(可选)   │
                     │ -> production(审批)         │
                     │ deploy.sh -> release note   │
                     └──────────────────────────┘
```

---

## 仓库产出总览

| 类别 | 数量 | 说明 |
| --- | --- | --- |
| workflow | 9 | ci-basic / ci-node / ci-docs / ci-docker / cd-env / cd-deploy / release / codeql / sbom |
| 技术文档 | 12 | docker 系列 5 篇 + ghcr 系列 4 篇 + secret-checklist + security-baseline + compose |
| 日志 | 42 篇 | day-01 ~ day-42 |
| 周复盘 | 6 篇 | week-01 ~ week-06 |
| 脚本 | 2 | deploy.sh / gen-release-note.sh |
| 模板 | 1 | release-note.md |
| 安全基线 | 1 | security-baseline.md |

**核心能力链路**：提交代码 -> CI 检查（lint/test/build）-> 构建镜像 + 安全扫描（Trivy + CodeQL + SBOM）-> 推送 GHCR -> CD 部署（dev 自动 / prod 审批）-> Release Note。

**技能栈覆盖**：GitHub Actions、Docker、GHCR、Trivy、CodeQL、Dependabot、Syft/SBOM、Docker Compose、分支保护、密钥安全。

**进度**：42 / 75 天（56%），已完成 4 个 Project 里程碑，下一站 Week 7 Kubernetes 基础。
