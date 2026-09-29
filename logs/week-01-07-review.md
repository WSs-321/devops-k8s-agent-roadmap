# 前七周知识详细复习（Day 01-49）

> 覆盖 Week 1-7：GitHub Actions CI → Docker → GHCR → CD/Environments → 安全治理 → Kubernetes 基础。
> 用途：全面复习 + 面试自测，每个部分的"重点"均为高频考点。

---

# 第一部分：GitHub Actions CI（Week 1-2）

## 1.1 六大核心概念

| 概念 | 定义 | 要点 |
| --- | --- | --- |
| workflow | `.github/workflows/*.yml` 一个自动化流程文件 | 由事件触发，可包含多个 job |
| job | 一组 step 的执行单元 | 多个 job 默认并行执行，`needs` 可串行 |
| step | job 内最小执行块 | `run:`（shell 命令）或 `uses:`（action）不能共存 |
| runner | 执行 job 的虚拟机 | `ubuntu-latest` / `windows-latest` / `macos-latest` |
| event | 触发 workflow 的动作 | push / pull_request / workflow_dispatch / schedule / workflow_run |
| action | 可复用的流程片段 | `actions/checkout@v4`、`actions/setup-node@v4`，@ 后跟版本 |

## 1.2 触发事件

```yaml
on:
  push:
    branches: [main]           # 推送到 main 才触发
    paths: ['app/**']          # 只有 app 目录变更才触发
  pull_request:                # PR 的每个新 commit 都触发
  workflow_dispatch:           # 手动触发按钮
```

- push vs pull_request 差异：PR 触发时 checkout 的是 PR 合并预览（merge result），push 触发 checkout 的是分支本身
- paths 过滤：ci-node.yml 只在 `app/**` 变更时跑，ci-docs.yml 只在 `**/*.md` 变更时跑，节省 CI 资源

## 1.3 依赖安装

| 命令 | 特点 | 适用 |
| --- | --- | --- |
| `npm ci` | 严格按 `package-lock.json` 安装，快、确定性强 | CI 必用；无 lockfile 报错 |
| `npm install` | 可能解析并更新 lockfile | 本地开发 |

dependencies vs devDependencies：

- dependencies：运行时必需（express）
- devDependencies：开发期工具（eslint、jest）
- 生产镜像里 `npm ci --omit=dev` 不装 dev，镜像更小更安全

## 1.4 缓存

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: 'npm'          # 自动缓存 ~/.npm，key 基于 package-lock.json hash
```

- 缓存 key 基于依赖文件 hash：依赖不变则命中缓存，安装从 30s 降到 3s
- 通用场景用 `actions/cache` 手动指定 path + key
- key 设计原则：粒度对准"什么变了缓存才失效"

## 1.5 Matrix 多版本

```yaml
strategy:
  matrix:
    node-version: [18.x, 20.x]
  fail-fast: false           # 一个失败不取消其他，看全部兼容性
```

- 每个版本生成一个独立 job 并行跑
- `fail-fast` 默认 true（快速失败省资源）；要全面看兼容性时设 false
- 矩阵 job 的 status check 名带版本：`ci (18.x)`、`ci (20.x)`

## 1.6 失败阻断与门禁

- job 内 step 顺序执行，前一步失败后面不跑（除非 `if: always()`）
- 这是"门禁"的基础：lint 失败 → 不 build → 不 test → 不合并
- 配合分支保护的 required status check，保证 main 上代码永远通过 CI

---

# 第二部分：Docker 容器（Week 3）

## 2.1 三者关系

```text
Dockerfile --docker build--> Image --docker run--> Container
   (配方)                      (模板)                 (运行实例)
```

## 2.2 多阶段构建

```dockerfile
# 阶段 1：构建
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev          # 只装生产依赖

# 阶段 2：运行
FROM node:22-alpine AS runner
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
CMD ["node", "src/index.js"]
```

- 最终镜像不含 npm 缓存、构建工具、dev 依赖，镜像更小（几百 MB → 几十 MB）、攻击面更小
- 关键：`COPY --from=builder` 从上一阶段产物取文件，不是从构建上下文取

## 2.3 容器运行参数

| 参数 | 作用 |
| --- | --- |
| `-p 3000:3000` | 主机端口:容器端口映射；不映射则外部不可达 |
| `-e KEY=value` | 环境变量注入（配置外置） |
| `--entrypoint` | 覆盖镜像默认入口命令 |
| `--restart unless-stopped` | 退出自动重启（手动 stop 的不重启） |
| `--memory 256m` | 内存硬限制，超限 OOM Kill（与 K8s limits 同源 cgroup） |
| `--shm-size` | /dev/shm 共享内存大小，仅特定程序用，不是普通内存 |

EXPOSE 是纯文档声明，不做任何端口映射。

## 2.4 HEALTHCHECK

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

- 容器状态：`starting` → `healthy` / `unhealthy`
- `--start-period`：启动缓冲期，失败不计入 retries（应用启动慢的场景）
- 没有 HEALTHCHECK 时容器永远显示 running，崩了也不知道，这就是为什么 K8s 探针重要

## 2.5 配置外置（12-Factor）

```text
代码和配置分离：同一镜像跑 dev/staging/prod，只改环境变量
优先级：环境变量（推荐）> 配置文件挂载 > 密钥管理服务
```

对应关系：`docker run -e NODE_ENV=prod` 对应 K8s ConfigMap

## 2.6 镜像标签策略

| 标签 | 优点 | 缺点 |
| --- | --- | --- |
| commit SHA（`app:abc123f`） | 不可变、精确追溯 | 可读性差 |
| semver（`v1.2.3`） | 语义清晰 | 需要发版流程 |
| `latest` | 看着方便 | 可移动、不可回溯、无法审计回滚 |

结论：生产部署用 SHA 或 semver，`latest` 只用于本地开发。回滚以 digest（内容寻址，不可变）为准。

## 2.7 Docker Compose

- 一个 YAML 声明多容器（app + db），`docker compose up` 一键起
- 同 compose 内容器通过服务名互访（内置 DNS）

---

# 第三部分：GHCR 与镜像流水线（Week 4）

## 3.1 GHCR 要点

- 包归属：镜像属于 user/org，不在仓库下；仓库和包是软关联
- 权限：`GITHUB_TOKEN` 需要 `packages: write`；fork PR 来的 token 只读
- 登录三要素：

```yaml
- uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

## 3.2 完整流水线链路

```text
checkout → setup-node → npm ci → lint → test
  → login → metadata → build-push(push:false, load:true)
  → Trivy 扫描本地镜像
  → [main 分支] push job: build-push(push:true) 推多平台
  → summary 输出 tags/labels/digest
```

build 与 push 拆成两个 job 的原因：PR 时只构建+扫描不推送；只有 main 合入后才推 GHCR，形成安全管线。

## 3.3 metadata-action 两套语法

| 语法 | 归属 | 示例 |
| --- | --- | --- |
| `{{ }}` | metadata-action DSL（模板） | `type=sha`、`{{date}}`、`{{version}}` |
| `${{ }}` | GitHub Actions 表达式 | `${{ secrets.X }}`、`${{ steps.image.outputs.name }}` |

- tag 类型：`type=sha`（commit 短 sha）/ `type=semver` / `type=raw` / `type=ref`
- 注意：`type=sha256` 不存在，正确写法是 `type=sha`

## 3.4 Trivy 镜像扫描

```yaml
- uses: aquasecurity/trivy-action@master
  with:
    image-ref: ghcr.io/owner/app:sha-abc123f
    format: sarif
    severity: CRITICAL,HIGH
    exit-code: '1'          # 有高危漏洞让 step 失败，阻断流水线
```

- 扫本地镜像（build job 里 `load: true` + `push: false`）不需要 registry 认证
- 漏洞分级：CRITICAL / HIGH / MEDIUM / LOW
- 互斥：multi-platform 构建 + `load: true` 不能同时用（buildx 限制）
- SARIF 上传到 Security tab 需要 `security-events: write` 权限

## 3.5 三层 outputs 数据流

```yaml
jobs:
  build:
    outputs:
      digest: ${{ steps.push.outputs.digest }}   # 2. job 顶部映射
    steps:
      - id: push
        run: echo "digest=xxx" >> $GITHUB_OUTPUT  # 1. step 产出
  track:
    needs: build
    - run: echo ${{ needs.build.outputs.digest }} # 3. 下游读取
```

- `$GITHUB_OUTPUT` 是 step 间传值的标准方式
- 多行输出先替换换行为 `<br>` 再写入，否则会破坏格式

---

# 第四部分：CD 与 Environments（Week 5）

## 4.1 Environment 概念

Environment = 部署目标的逻辑抽象（不是服务器），捆绑：

1. 专属 secrets/vars
2. 保护规则（审批、等待、分支白名单）
3. 部署历史与 URL

```yaml
deploy-prod:
  environment:
    name: production        # 触发该环境的保护规则
    url: https://prod.example.com
```

## 4.2 三环境模型

| 环境 | 触发 | 审批 | 密钥 |
| --- | --- | --- | --- |
| dev | push main 自动 | 无 | DEV 系列 |
| staging | 手动/tag | 可选 | STAGING 系列 |
| production | tag/release | 必须人工审批 | PROD 系列（受保护） |

执行顺序：分支白名单检查 → wait timer（最长 30 天）→ required reviewers 审批 → 执行 job

## 4.3 Secrets 三层级

```text
Organization < Repository < Environment
（作用域递减，同名优先级递增：environment 最高）
```

为什么生产密钥放 environment secret：即使 workflow YAML 被改，没有该 environment 的部署权限 + 审批，也拿不到密钥，权限与审批双重保护。

```yaml
# 正确：环境变量注入
env:
  TOKEN: ${{ secrets.DEPLOY_KEY }}
run: ./deploy.sh

# 错误：直接插值打印
run: echo ${{ secrets.DEPLOY_KEY }}
```

## 4.4 部署脚本设计（deploy.sh）

- 契约先行：先定输入（环境变量）+ 输出 + 退出码，再写实现
- 退出码约定：0 成功 / 10 参数缺失 / 20 认证失败 / 30 拉取失败 / 40 启动失败 / 50 健康检查失败
- `set -euo pipefail`：未定义变量报错、命令失败即退出、管道任一环失败整体失败（不要加 `-x`，会打印 secret）
- 幂等性：`docker stop app || true; docker rm app || true`，重复执行结果一致
- `DRY_RUN=true`：只打印不执行，无真实服务器也能验证完整链路
- `case "$DEPLOY_TARGET" in` 分发：ssh / docker / compose / ecs，未来加 K8s 只加一个函数
- workflow 与脚本职责分离：workflow 管编排和参数注入，脚本管部署细节

## 4.5 Release

```yaml
on:
  push:
    tags: ['v*']
permissions:
  contents: write        # 创建 release 需要
```

- `git describe --tags --abbrev=0` 取最近 tag
- `git log v1.0.0..HEAD --pretty=format:"- %s (%h)"` 生成变更列表
- `fetch-depth: 0` 拉完整历史（否则拿不到 tag）
- release 管声明版本，deploy 管部署版本，职责分离

---

# 第五部分：安全治理（Week 6）

## 5.1 权限最小化

```yaml
permissions:              # 写了这行，未声明的权限全部变 none（除 metadata: read）
  contents: read
```

| 场景 | 最小权限 |
| --- | --- |
| 普通 CI | `contents: read` |
| 推 GHCR | `contents: read` + `packages: write` |
| Trivy SARIF 上传 | + `security-events: write` |
| 创建 Release | `contents: write` |
| CodeQL | `contents: read` + `security-events: write` |

核心：不写 permissions = 继承仓库/组织默认（可能读写全开）；写了 = 默认全关，显式开需要的。

## 5.2 Dependabot

```yaml
version: 2
updates:
  - package-ecosystem: npm
    directory: /app
    schedule: { interval: weekly }
    groups:
      minor-and-patch:
        update-types: [minor, patch]   # 合并一个 PR；major 单独 PR 人工审查
  - package-ecosystem: github-actions
    directory: /
  - package-ecosystem: docker
    directory: /app
```

- version updates（定期升级）vs security updates（漏洞自动 PR）
- groups 减少噪音：minor/patch 打包，major 隔离
- YAML 锚点 `<<` 合并只对 map 有效，list 会被整体覆盖

## 5.3 CodeQL

- SAST 静态分析：查自己代码的逻辑漏洞（SQL 注入、XSS、路径穿越）
- 三者分工：Dependabot 查依赖版本漏洞、Trivy 查镜像漏洞、CodeQL 查代码逻辑漏洞
- 流程：checkout → init（建代码数据库）→ analyze（QL 查询 + 自动上传 SARIF）→ Security tab
- JS/Python 直接解析源码不需 build；C++/Java/Go 需要 build 步骤
- 定时扫描的意义：查询规则持续更新，老代码也能发现新漏洞

## 5.4 Secret 安全

自动脱敏边界：

| 操作 | 脱敏 |
| --- | --- |
| 直接 echo 原始值 | 是 |
| base64 编码后输出 | 否（派生值） |
| 截取子串 | 否（派生值） |
| 写入文件再 cat | 否（文件内容不扫） |
| `set -x` 调试模式 | 否（会打印每条命令含 secret） |
| `curl -v` | 否（header 里的 token 会打印） |

派生值手动脱敏：`echo "::add-mask::$VALUE"`

最高危事件 `pull_request_target`：以 base 分支上下文运行 → 有 secrets 权限，若 checkout 并执行 PR 代码，攻击者可直接窃取密钥。永远不要 checkout 不可信 PR 代码后在其上下文执行。

泄露应急四步：revoke（立即吊销）→ rotate（换新）→ audit（查滥用记录）→ notify

## 5.5 SBOM

- SBOM 是物料清单（有什么），漏洞扫描是核对清单找问题（有没有毛病），互补不替代
- 三大标准：SPDX（Linux 基金会，合规）/ CycloneDX（OWASP，安全）/ SWID（政府采购）
- 扫镜像 > 扫源码：镜像含 OS 层 + 运行时依赖 + 二进制，源码只有语言依赖
- Syft 直接 `syft image:tag -o spdx-json` 就能出清单；`anchore/sbom-action@v0` 只是封装（自动安装 Syft）
- `workflow_run` 两个特性：仅默认分支生效、不能做 required status check（PR 阶段不触发）

## 5.6 分支保护

| 能力 | 说明 |
| --- | --- |
| Require PR | 必须 PR + N 人 approve |
| Status checks | 指定 job 必须 green |
| 推送限制 | 禁 force push / 禁直接 push / 禁删除 |
| Signed commit | GPG/SSH 验证提交者身份 |
| 线性历史 | 禁 merge commit |
| 锁定分支 | 只读 |

三种合并策略：merge commit（保留完整历史）/ squash（整个 PR 压 1 个 commit，单人项目推荐）/ rebase（线性无 merge commit）

Status Check 四个坑：

1. 大小写敏感（`ci` 不等于 `CI`）
2. 新 workflow 必须先在 main 跑过一次才能被选为 required
3. `workflow_run` 触发的不能做 required
4. 矩阵 job 名是 `name (version)` 格式

"Require branches up to date"：判断 PR 分支 HEAD 是否包含 main 最新 commit。一个 PR 合入后，其他 PR 的 CI 不会自动重跑，需手动 Update branch（rebase 触发新 CI）或用 Mergify/Kodiak/bors 类 merge queue 自动处理。

---

# 第六部分：Kubernetes 基础（Week 7）

## 6.1 核心对象层级

```text
Namespace（逻辑隔离：环境/团队/资源配额）
   └── Deployment（声明期望状态：副本数、镜像、滚动策略）
         └── ReplicaSet（维持副本数：挂了补、多了删）
               └── Pod（最小调度单元：可含多容器共享 localhost/IP）
                     └── Container（实际运行容器）
```

- `spec` = 期望状态：K8s 控制循环持续把实际状态调到期望状态（声明式核心）
- Pod 名结构：`deploy名-RShash-随机后缀`（如 `my-app-64b78bfff-fpbfw`），logs/exec/describe 必须用完整 Pod 名

## 6.2 常用 kubectl 命令

```bash
kubectl get pods -o wide          # 加 IP、NODE 列
kubectl describe pod <name>       # 排查首选：事件、调度、失败原因
kubectl logs <name> -f            # 单 Pod 日志
kubectl logs -f deploy/my-app     # 整个 Deployment 所有 Pod
kubectl exec -it <name> -- sh     # 进容器
kubectl apply -f x.yaml           # 声明式创建/更新
kubectl scale deploy my-app --replicas=5
kubectl rollout status/undo deploy my-app   # 滚动状态/回滚
```

## 6.3 流量链路

```text
外部用户
   │
Ingress（域名 + 路径路由，七层）     ← Ingress 只是规则，需要 Ingress Controller 执行
   │
Service（稳定 ClusterIP + 负载均衡） ← Pod IP 会变，Service IP 稳定，label selector 关联
   │
Pod x N
```

- Ingress 不能直接指向 Pod（Pod IP 不稳定），必须经 Service
- Service 三端口：`nodePort`（节点暴露，30000-32767）/ `port`（Service 自身）/ `targetPort`（容器端口）
- 四类型：ClusterIP（内部）/ NodePort（测试）/ LoadBalancer（云上每 Service 一个公网 IP，贵）/ Headless（clusterIP: None，DNS 直连 Pod，用于 StatefulSet）
- pathType：Prefix（前缀匹配，最常用）/ Exact（精确）
- annotations 给 Controller 读（如 `rewrite-target`、CORS、超时），labels 才用于 selector
- 负载均衡是 K8s 内置的（iptables/IPVS 轮询），不需要 nginx

## 6.4 资源与调度

```yaml
resources:
  requests: { cpu: 100m, memory: 128Mi }   # 调度器看：保证值
  limits:   { cpu: 250m, memory: 256Mi }   # cgroup 看：硬上限
```

- requests 给调度器：Pod 所有容器 requests 之和 ≤ 节点可分配量才能调度上去
- limits 给运行时：允许超卖（limits 总和可超节点容量）
- `100m` = 0.1 核（millicores）

超限行为差异：

| 资源 | 属性 | 超限行为 | 表现 | 排查 |
| --- | --- | --- | --- | --- |
| CPU | 可压缩 | 限流 throttle | 变慢、延迟升高，进程不死 | `kubectl top pod`，日志无错误难发现 |
| Memory | 不可压缩 | OOM Kill | 进程死、重启，Exit Code 137（128+9） | `describe pod` 看 Last State |

- Docker `--memory` 和 K8s limits 底层同为 cgroup，超限都是 OOM Kill
- 差异在 K8s 禁用 swap（调度准确性 + 性能可预测），Docker 有 swap 会先变慢

QoS 三等级（节点资源紧张时的被杀顺序）：

| 等级 | 条件 | 被杀顺序 |
| --- | --- | --- |
| Guaranteed | requests == limits（CPU 和内存都相等） | 最后 |
| Burstable | requests < limits | 中间 |
| BestEffort | 全不设 | 最先 |

## 6.5 Health Probe

| 探针 | 判断 | 失败后果 |
| --- | --- | --- |
| livenessProbe | 还活着吗 | 重启容器 |
| readinessProbe | 能接流量吗 | 从 Service endpoints 摘除，不重启 |
| startupProbe | 启动完成没 | 完成前不跑 liveness（保护慢启动应用） |

对应 Docker HEALTHCHECK；readiness 是流量门禁，liveness 是自愈机制，两者不能混用（readiness 失败就重启会把正常但繁忙的服务打死）。

## 6.6 ConfigMap / Secret

```text
ConfigMap（明文非敏感配置）──┐
                            ├──> envFrom / env / volume 挂载 ──> 容器
Secret（base64 编码敏感配置）──┘
```

- 三种注入：`envFrom`（全量）/ 单个 `env.valueFrom`（精确）/ volume 挂载文件
- base64 不是加密（一条命令就能解码），真正安全靠 RBAC + etcd 加密
- envFrom 不热更新（改了要重启 Pod），volume 挂载热更新（kubelet 定期同步）
- 对应关系：ConfigMap = `docker run -e` / GitHub `vars`；Secret = GitHub `secrets`

## 6.7 Ingress Controller

- Ingress YAML 只是路由规则，没有 Controller 就不生效
- 常见：nginx-ingress、traefik、云厂商 ALB
- killercoda 自带 nginx ingress controller，可直接练习

---

# 七周能力主线

```text
写代码 → push → CI（lint/test/matrix/cache）
     → 构建镜像（多阶段）→ Trivy 扫描 → CodeQL 查代码 → SBOM 清单
     → 推 GHCR（SHA 标签 + metadata-action）→ summary 记录 digest
     → CD：dev 自动（Environment 隔离密钥）→ prod 人工审批
     → deploy.sh（幂等 + 退出码 + DRY_RUN）
     → K8s：Deployment 声明副本 → Probe 保活 → Service 稳定访问 → Ingress 外部入口
     → ConfigMap/Secret 配置注入
     → 全程被保护：permissions 最小化 + Dependabot + 分支保护 + squash merge
```

---

# 自测重点清单

- [ ] 为什么 CI 里用 `npm ci` 而不是 `npm install`
- [ ] `load: true` 为什么和 multi-platform 互斥
- [ ] 镜像回滚应该用 tag 还是 digest，为什么
- [ ] 为什么生产密钥必须放 environment secret 而不是 repo secret
- [ ] `workflow_run` 触发的 job 为什么不能当 required status check
- [ ] Secret 的哪几种操作会导致自动脱敏失效
- [ ] requests 和 limits 分别谁在用，是否允许超卖
- [ ] CPU 超限和内存超限的表现差异与排查方法
- [ ] Ingress 为什么不能直接指向 Pod
- [ ] liveness 和 readiness 探针的区别与混用风险

---

# 相关文件索引

| 模块 | 笔记位置 |
| --- | --- |
| CI 基础 | `logs/week-01/`、`logs/week-02/` |
| Docker | `docs/docker-*.md`、`logs/week-03/` |
| 镜像/GHCR | `docs/ghcr-login.md`、`docs/metadata-action.md`、`docs/trivy-scan.md`、`logs/week-04/` |
| CD/环境 | `logs/week-05/`、`scripts/deploy.sh` |
| 安全 | `docs/security-baseline.md`、`docs/secret-checklist.md`、`logs/week-06/` |
| K8s | `logs/week-07/`、`k8s/*.yaml`、`k8s/killercoda-demo.sh` |
| 前六周总览 | `logs/week-01-06-review.md` |
