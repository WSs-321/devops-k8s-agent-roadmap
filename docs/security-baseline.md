# CI/CD 安全基线

本文档汇总了 Week 6 安全治理主题的全部成果，形成此项目的 CI/CD 安全基线，供后续项目参考复用。

## 安全全景

```text
                ┌──────────────┐
                │  分支保护     │ ← 入库最后一道防线
                │  Day 41      │
                └──────┬───────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
  ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
  │  CodeQL   │ │   SBOM    │ │ Secret    │
  │  源码扫描  │ │  物料清单  │ │  密钥安全  │
  │  Day 38   │ │  Day 40   │ │  Day 39   │
  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
                ┌──────▼───────┐
                │  Dependabot  │ ← 依赖自动更新
                │  Day 37      │
                └──────┬───────┘
                       │
                ┌──────▼───────┐
                │ 权限最小化    │ ← 最底层基础
                │  Day 36      │
                └──────────────┘
```

## 1. 权限最小化（Day 36）

### 原则

每个 workflow 显式声明 `permissions`，只给必要权限，未声明项默认 `none`。

### 权限配置总览

| Workflow | `contents` | `packages` | `security-events` | 说明 |
| --- | --- | --- | --- | --- |
| `ci-basic.yml` | read | - | - | 基础 CI |
| `ci-node.yml` | read | - | - | Node.js CI |
| `ci-docs.yml` | read | - | - | 文档检查 |
| `ci-docker.yml` | read | write | write | 构建镜像 + Trivy 扫描 |
| `codeql.yml` | read | - | write | 上传 SARIF |
| `sbom.yml` | read | - | - | 生成 SBOM |
| `cd-env.yml` | read | - | - | 环境检查 |
| `cd-deploy.yml` | read | - | - | 部署 |
| `release.yml` | write | - | - | 创建 Release |

### 权限最小化检查清单

- [ ] 每个 workflow 都显式声明 `permissions`
- [ ] 没有 workflow 用 `write-all`
- [ ] CI workflow 只用 `contents: read`
- [ ] 需要推送镜像的才有 `packages: write`
- [ ] 需要上传扫描结果的才有 `security-events: write`

## 2. Dependabot（Day 37）

### Dependabot 配置

`.github/dependabot.yml` 配置 3 个 ecosystem：

| Ecosystem | 扫描路径 | 频率 | 分组 |
| --- | --- | --- | --- |
| npm | `/app/` | weekly | minor/patch 合并，major 单独 |
| github-actions | `/` | weekly | minor/patch 合并 |
| docker | `/app/` | weekly | - |

### 策略

- **minor/patch 合并**：减少 PR 噪音，自动合并
- **major 单独**：需人工审查，防止 breaking change
- **security updates**：GitHub 自动开启，发现已知漏洞立即开 PR

### Dependabot 检查清单

- [ ] 已配置所有包管理器对应的 ecosystem
- [ ] open-pull-requests-limit 合理（建议 ≤10）
- [ ] labels 区分依赖类型
- [ ] 有 groups 分组策略

## 3. CodeQL（Day 38）

### CodeQL 配置

`.github/workflows/codeql.yml`：

- **语言**：javascript
- **触发**：push main + PR main + 每周一 cron
- **权限**：`contents: read` + `security-events: write`

### 工作原理

```text
源码 → init（构建数据库）→ analyze（QL 查询 + 上传 SARIF）→ Security tab
```

### 注意事项

- JS/Python 不需要 build 步骤，直接解析源码
- 编译型语言（C++/Java/Go）需加 build 步骤
- `analyze` step 内置上传，不需要手动 `upload-sarif`
- 定时扫描的意义：CodeQL 规则持续更新，旧代码也能发现新漏洞

### CodeQL 检查清单

- [ ] CodeQL workflow 存在且能正常运行
- [ ] `security-events: write` 权限已配置
- [ ] 定时扫描已配置（建议 weekly）
- [ ] Security tab 中无未处理的 critical/high alert

## 4. Secret 安全（Day 39）

### 核心原则

> **创建用最小权限、使用不打印、日志查脱敏、泄露先 revoke**

### 使用规范

```yaml
# ✅ 正确：只读引用
env:
  TOKEN: ${{ secrets.GITHUB_TOKEN }}

# ❌ 错误：打印到日志
- run: echo ${{ secrets.TOKEN }} | base64

# ❌ 错误：写入文件
- run: echo "${{ secrets.KUBECONFIG }}" > kubeconfig
```

### 自动脱敏边界

| 场景 | 脱敏 | 说明 |
| --- | --- | --- |
| 原始值直接打印 | ✅ | GitHub 自动脱敏 |
| 截取子串 | ❌ | 派生值不脱敏 |
| base64 编码 | ❌ | 派生值不脱敏 |
| 写入文件 | ❌ | 不在 stdout，无法脱敏 |

### 关键陷阱

- **`pull_request_target`**：能访问 secrets，但 checkout PR 代码会泄露，是最高危事件
- **`set -x`**：开启后所有命令回显到日志，secret 值会暴露
- **`curl -v`**：verbose 模式打印 header，含 token

### Token 泄露应急

```text
revoke（立即撤销 token）
  → rotate（生成新 token）
  → audit（排查日志，确认是否被利用）
  → notify（通知安全团队/相关方）
```

### Secret 安全检查清单

- [ ] 每个 custom token 都有明确用途和最小 scope
- [ ] 生产密钥使用 environment secret + 审批
- [ ] 所有 workflow 用 permissions 限制 GITHUB_TOKEN
- [ ] 没有 workflow 对 secret 做编码/截取/写文件
- [ ] GitHub Secret Scanning 已启用（公开仓库默认）
- [ ] 没有使用 `pull_request_target`（除非绝对必要且经安全审查）

## 5. SBOM（Day 40）

### 标准选择

| 标准 | 主导方 | 方向 | 本项目选择 |
| --- | --- | --- | --- |
| SPDX | Linux Foundation | 许可证合规 | ✅ 使用 |
| CycloneDX | OWASP | 安全扫描 | - |
| SWID | NIST | 政府采购 | - |

### 工作流

`.github/workflows/sbom.yml`：

- **触发**：`workflow_run` 监听 `docker CI` 完成
- **工具**：`anchore/sbom-action@v0`（内置 Syft）
- **扫描对象**：GHCR 镜像（`image:` 模式）
- **输出**：`sbom.spdx.json`，上传为 artifact

### 方案决策

| 决策点 | 选择 | 原因 |
| --- | --- | --- |
| 源码 vs 镜像 | **镜像** | 包含 OS 层、运行时依赖等源码看不到的组件 |
| 独立 vs 合并 | **独立 workflow** | 关注点分离，不污染 docker workflow 拓扑 |
| Registry Pull vs 本地 tar | **Registry Pull** | 每次构建后镜像已在 registry，直接拉取即可 |

### SBOM 检查清单

- [ ] 每次构建镜像后自动生成 SBOM
- [ ] SBOM 作为 release artifact 发布
- [ ] SBOM 格式为 SPDX 或 CycloneDX（标准格式）
- [ ] 扫描对象是最终镜像而非源码

## 6. 分支保护（Day 41）

### 推荐配置

```text
Branch: main
✅ Require a pull request before merging
   ✅ Require approvals: 1
   ✅ Dismiss stale reviews when new commits are pushed
✅ Require status checks to pass before merging
   Status checks: ci, node-ci, docs-check
✅ Block force pushes
✅ Do not allow bypassing the above settings
```

### 不建议开启

| 选项 | 原因 |
| --- | --- |
| Require signed commits | 单人学习项目，无实际安全收益，徒增复杂度 |
| Require branches to be up to date | 单人项目无并发冲突，无 merge queue 时是纯负担 |
| Require linear history | Squash merge 已覆盖，main 天然线性 |

### 合并策略

**Squash merge**：整个 PR 压成 1 个 commit，main 历史干净，适合 daily 笔记。

### Status Check 避坑

| 坑 | 说明 |
| --- | --- |
| 大小写 | `ci` ≠ `CI`，和 workflow 中 job name/id 严格一致 |
| 新 workflow | 必须先合入 main 一次，才能选为 required check |
| workflow_run | PR 阶段不触发，不能作为 required check |
| 矩阵 job | 格式 `name (version)`，如 `ci (18.x)` |

### 分支保护检查清单

- [ ] main 分支已配置上述保护规则
- [ ] 所有 required status checks 都能正常通过
- [ ] 没有管理员绕过保护设置
- [ ] Squash merge 已启用

## 汇总

### 安全防护矩阵

| 层级 | 防线 | 覆盖范围 |
| --- | --- | --- |
| 代码入库前 | 分支保护 + Status Check | 阻止未审查/未测试代码进入 main |
| CI 阶段 | 权限最小化 | 限制每个 workflow 的能力边界 |
| CI 阶段 | CodeQL | 源码级安全漏洞（SAST） |
| CI 阶段 | Dependabot | 依赖版本漏洞 + 过期检测 |
| CI 阶段 | SBOM | 最终镜像的完整物料清单 |
| 运行时 | Secret 安全 | 密钥全生命周期管理 |
| 持续 | Dependabot Security | 已知漏洞自动 PR |
| 持续 | CodeQL 定时扫描 | 新规则发现旧代码漏洞 |

### 后续改进方向

- 接入 Trivy 镜像扫描（已在 `ci-docker.yml` 中有基础配置）
- Dependabot auto-merge minor/patch（当前为手动审查）
- 接入 GitHub Secret Scanning push protection（私有仓库需 Advanced Security）
- 制定 SBOM 消费策略（定期审计 + 漏洞关联）
- 为组织级项目增加 signed commit + merge queue
