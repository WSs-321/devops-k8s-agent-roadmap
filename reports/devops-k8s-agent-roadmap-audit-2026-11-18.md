# DevOps + K8s + Agent Roadmap 学习审计与追赶计划

> 审计对象：`WSs-321/devops-k8s-agent-roadmap`
> 审计日期：2026-11-18
> 审计方式：读取当前主线、49 篇日日志、7 篇周复盘、6 条学习轨道、5 个项目说明、CI/CD workflow、K8s 清单和示例应用，并实际运行 Node 示例的 lint、test、build 与服务探针验证。

## 一、结论先行

这个仓库的基础并不差，甚至可以说前 49 天的沉淀明显高于普通“只看教程”的学习仓库：

- GitHub Actions、Docker、GHCR、Trivy、SBOM、Environments、部署脚本和 K8s 基础对象都有对应材料。
- 49 篇日日志按 Week 1-7 完整排列，说明有过稳定的执行节奏。
- 多篇 README、周复盘、技能矩阵、项目验收说明已经形成个人知识库骨架。
- 示例 Node 应用的 lint、3 个单元测试和 build 在今天可以正常运行。

当前真正的问题不是“基础没学”，而是三个断层：

1. **进度断层**：主线和日志停在 Day 49，Day 50-75 未开始；最后学习日志约在 2026-07-26，距今 115 天。
2. **反馈断层**：前 49 天有 PR、CI、Docker、K8s 实验提供即时反馈；Day 50 之后转向 ACK、GitOps 和 Agent，外部依赖变多，仓库没有及时补上本地可运行环境。
3. **AI 实践断层**：AI 相关文档约 170 KB，但仓库里没有 Python Agent 代码、依赖清单、测试、评测集或可运行服务。AI 学习目前主要是 L1-L2 的阅读与复述，尚未进入 L3。

因此，补齐进度的正确目标不是“把 Day 50-75 的文档再写一遍”，而是：

> 用 5-6 周补齐一组可运行、可测试、可演示的证据，把能力从“我知道”推进到“我能独立做出来并排障”。

## 二、仓库全貌与真实进度

### 2.1 体量结构

| 区域 | 规模 | 判断 |
| --- | ---: | --- |
| `docs/` | 23 篇，约 238 KB | 知识量很大，AI 文档占约 170 KB |
| `logs/` | 58 篇，约 158 KB | 49 篇日日志齐全，周复盘完整到 Week 7 |
| `.github/` | 12 个文件，约 17 KB | 有真实 CI/CD 资产，但存在几处关键链路问题 |
| `k8s/` | 9 个文件，约 10.5 KB | 概念清单较完整，主要是 killercoda/nginx 演练 |
| `app/` | 约 43 KB | 最小 Node 示例，可测试、可构建 |
| `projects/` | 5 个项目说明 | Project 04 未开始，Project 05 未完成 |

### 2.2 时间与完成率

- 学习起点：2026-06-04。
- 当前日志：Day 1-49，共 49 篇。
- 原 75 天计划按起点计算，理论结束日约为 2026-08-17。
- 截至 2026-11-18，已比原计划结束日超出约 93 天。
- 主路线进度：49 / 75，约 65.3%。
- 原计划剩余学习量：26 个计划日，按每天 3 小时约 78 小时。
- 最后提交：2026-10-22；最后一次明确学习日志：约 2026-07-26。

这说明问题不是“还差几天”，而是原有以日历驱动的计划已经失效。继续沿用“Day 50 在哪一天”会产生持续欠账感，应该改为里程碑驱动。

### 2.3 已完成度分层

| 领域 | 现有证据 | 更可信的判断 |
| --- | --- | --- |
| Git/GitHub PR 流程 | 大量提交、PR、分支、模板 | L2-L3，基础扎实 |
| GitHub Actions | lint/test/build、matrix、cache、artifact、Trivy | L2-L3，但当前 workflow 仍有关键链路错误 |
| Docker | Dockerfile、多阶段、Compose、运行实验 | L2-L3 |
| GHCR/镜像扫描 | build-push、metadata、Trivy、summary | L2，扫描与最终推送不是同一镜像，未到稳定 L3 |
| CD/Environments | 三环境设计、审批说明、`DRY_RUN` 脚本 | L2，尚未真实部署 |
| 安全治理 | permissions、Dependabot、CodeQL、SBOM、secret 清单 | L1-L2，文档多于强验证 |
| K8s 基础对象 | 8 个清单、killercoda 练习 | L2，尚未把自身应用端到端跑进集群 |
| ACK/Helm/Kustomize/GitOps | 仅有计划和设计任务 | 未开始 |
| Python/Agent 开发 | 只有文档中的代码片段 | L0-L1，无可运行证据 |
| Evals/Guardrails/可观测性 | AI 文档中有方法论 | 未落地 |

## 三、前 49 天最有价值的部分

这些优势应保留，不应推倒重来：

1. **真实 CI 经验**：cache、matrix、artifact、Trivy SARIF、workflow outputs 和失败修复都不是纯理论。
2. **从失败中学习的记录**：Trivy 字段、多行 outputs、`load: true` 与多平台构建互斥等问题有真实踩坑。
3. **容器与 K8s 的概念串联**：`HEALTHCHECK` 到 probe、`docker run -e` 到 ConfigMap、Docker 到 Pod 的映射写得清楚。
4. **学习资产意识**：模板、周复盘、技能矩阵、项目验收说明已经形成知识管理系统。
5. **DevOps 与 Agent 的结合方向正确**：用 CI 失败分析作为 Agent 首个场景，反馈客观，且能复用现有 CI/CD 能力。

## 四、当前卡点的根因

### 4.1 从“按步骤执行”切换到“开放式构建”

Week 1-7 大多有明确命令、明确 YAML 和即时结果。Day 50 之后的任务变成架构设计、云资源、GitOps、Agent 架构和评测，答案不再唯一，反馈也不再即时。没有拆成小步可验证任务时，很容易停在“继续看资料”。

### 4.2 云资源依赖把学习放到了不可控侧

ACK、ACR、SLB、Argo CD 等主题容易让人以为必须先拥有真实云环境。实际上当前最需要的是：

- 用 kind、minikube 或 Docker Desktop K8s 建立本地集群。
- 用 Helm/Kustomize 在本地完成一次安装和环境覆盖。
- 用 kind + Argo CD 或纯设计文档完成 GitOps 训练。
- ACK 先用 `plan`、架构图和成本预估完成，不急于创建收费资源。

先云后本地会增加阻塞；先本地后云才能保持反馈。

### 4.3 AI 部分“文档过载、代码为零”

AI 文档覆盖面很广，从机器学习史、Transformer、RAG、Agent、MCP、Harness，到 CUDA、PyTorch、模型训练和小程序。作为长期知识库有价值，但当前主攻 DevOps Agent 时，这些内容不能同等投入。

当前应明确：

- 主攻：Agent 应用层。
- 辅修：模型应用侧，例如 LoRA、RAG 调优的基本理解。
- 暂缓：CUDA、算子、框架内部、模型训练、小程序上线、复杂多 Agent。

否则学习面会持续扩张，但可演示产物不会增加。

### 4.4 Python 与 Agent 先修课没有补齐

进阶计划已经提醒过“Day 59 日志解析脚本可能卡在 Python 基础”，但没有把先修课变成验收门槛。Agent MVP 至少需要：

- Python 模块、类型、异常处理。
- HTTP/JSON、API 鉴权、超时和重试。
- `pytest`、fixture、mock。
- 结构化输出、JSON Schema、数据校验。
- 基础 `asyncio` 或至少理解异步调用边界。
- secret redaction 与日志脱敏。

没有这些基础，直接写 Agent loop 会把语言问题、API 问题、模型问题和业务问题混在一起。

### 4.5 当前“完成”标准偏向文档，不偏向证据

很多日日志能证明“读过并整理过”，但不能稳定证明以下能力：

- 关掉资料后复现配置。
- 故意引入故障并独立定位。
- 为新输入写测试。
- 解释一次设计取舍。
- 在 30 分钟内重新跑通。

后续必须将“当天产出一篇笔记”升级为“当天产出一个可验证工件”。

## 五、面向 AI 学习的路线重排

### 5.1 目标定位

建议把职业方向收敛为：

> 懂 CI/CD、K8s 和可观测性的 Agent 应用工程师。

这不是转纯算法，也不是立刻深入推理框架。你的稀缺性来自“既懂 Agent 工程，又能把它可靠部署和运维”。

### 5.2 当前应掌握的最小 AI 栈

| 层 | 当前重点 | 学到什么程度 |
| --- | --- | --- |
| Python 工程 | venv/pyproject、typing、pytest、ruff | 能独立写 CLI 与测试 |
| LLM API | messages、stream、tool calls、结构化输出 | 能完成稳定调用与错误处理 |
| Prompt/Context | prompt 版本、上下文预算、截断、引用 | 能解释并评测改动 |
| RAG | chunk、embedding、Top-K、引用 | 能改造一个小型知识库 demo |
| Agent Loop | 工具 schema、循环、步数上限、重试 | 能脱稿解释并实现 |
| MCP | 工具标准化接入 | 能写一个本地 MCP Server |
| Evals | golden set、自动打分、回归门禁 | 能给出改动前后数字 |
| 安全 | 脱敏、权限、命令白名单、人工确认 | 能证明不泄露 secret |
| 部署 | Docker、CI、K8s、日志、成本 | 能在本地集群端到端运行 |

暂不要求：训练模型、CUDA kernel、PyTorch 源码、分布式训练、多 Agent 全自动合并。

### 5.3 首个 AI 项目仍选 CI Failure Analyzer

理由：

- 输入输出明确。
- 失败日志容易构造 fixture。
- 评价标准客观。
- 可以直接复用已有 Actions、Docker、K8s 能力。
- 适合把“只读分析”与“危险写操作”严格分开。

第一版不要接真实模型。先写确定性解析器，再接 LLM：

```text
日志输入
  -> 脱敏
  -> 识别 workflow/job/step
  -> 规则提取失败行与上下文
  -> 结构化 JSON
  -> 可选 LLM 归因与修复建议
  -> Markdown 报告
```

这样即使没有 API Key，项目也能运行和测试。

## 六、仓库中需要先修的工程问题

这些问题会影响后续学习和作品可信度，建议在开始 Agent 前用 2-3 天修完。

### P0：必须优先

1. **探针健康语义不成立**
   - `app/src/index.js` 只定义了 `/health`。
   - `k8s/app-template.yaml` 与 `k8s/probe-demo.yaml` 使用 `/healthz` 和 `/readyz`。
   - 实际请求 `/healthz`、`/readyz` 会落到兜底欢迎路由并返回 200，所以 probe 会一直“通过”，但并没有检查真实健康状态。
   - 应新增独立 `/healthz` 和 `/readyz` 路由，并为状态码写测试。

2. **镜像工作流的触发范围不足**
   - `.github/workflows/ci-docker.yml` 只在 Dockerfile、`.dockerignore` 和 workflow 变化时触发。
   - 修改 `app/src/**` 或 `package*.json` 不会重建镜像，可能发布旧代码。
   - 应将触发路径覆盖 `app/**`，或至少覆盖源码、依赖、构建脚本和 Dockerfile。

3. **CD 没有明确保证 CI 成功后才部署**
   - `.github/workflows/cd-deploy.yml` 在 `pull_request` 和 `push` 上都执行，且是独立 workflow。
   - 当前看不到它等待构建、扫描、测试成功的强依赖。
   - PR 阶段的 DRY_RUN 虽然不会真实部署，但会污染 Environment 记录并掩盖流程问题。
   - 建议构建一个明确的主链路：`check -> test -> build -> scan -> push -> deploy`，至少让部署 job 使用 `needs` 或由成功的 `workflow_run` 触发。

4. **扫描镜像与推送镜像不是同一个不可变制品**
   - build job 构建并扫描一次，push job 再构建一次并推送。
   - cache 提高速度，但不能证明两次构建的镜像内容和 digest 完全相同。
   - 应构建一次后按 digest 扫描并推送，或执行明确的制品提升流程。

5. **Docker 部署端口不一致**
   - `scripts/deploy.sh` 的 `deploy_docker` 使用 `-p 80:80`。
   - 应用实际监听 3000，应改为 `-p 80:3000`。

### P1：进入 Agent 阶段前完成

1. `ci-basic.yml` 和 `ci-docs.yml` 当前没有显式 `permissions`，与 Day 36 的完成记录不一致。
2. `ci-basic.yml` 的 build 只是 echo，容易让人误以为存在有效质量门禁。
3. `ci-docs.yml` 没有覆盖 `timetable/`、`projects/`、`tracks/`、`templates/` 等 Markdown 目录。
4. `sbom.yml` 在 `workflow_run` 中扫描 `latest`，没有先判断上游 workflow 是否成功，也没有处理私有 GHCR 登录和固定 digest。
5. `k8s/deployment.yaml` 和 `k8s/service.yaml` 使用 nginx/80 端口，是教学替代品，不是自身应用的端到端部署。
6. Day 48、Day 49 日志缺少统一 `Date` 字段，日志模板执行不一致。
7. 开发依赖存在 npm audit high 告警；生产依赖当前无漏洞，但仍应升级工具链或锁定可接受版本。

### P2：作品化阶段完成

1. 统一所有 workflow 的 concurrency、timeout、权限与触发策略。
2. 增加本地 make 脚本或 PowerShell 脚本，一键完成 lint/test/build/容器/K8s 演练。
3. 增加 K8s 清单静态检查、YAML 解析和动作 lint。
4. 增加架构图、运行截图、演示脚本和故障注入记录。

## 七、6 周高强度追赶方案

### 7.1 强度设置

建议从原来的每天 3 小时，调整为每周约 24 小时：

| 时间 | 安排 |
| --- | --- |
| 周一至周五 | 每天 3.5 小时 |
| 周六 | 5 小时集成实验 |
| 周日 | 2 小时复盘、回测、下周计划 |

每日比例建议：

- 20% 阅读与概念校准。
- 60% 编码、实验、排障。
- 20% 测试、评测、写日志。

不要用“每天 6-8 小时”硬补。高强度应体现为稳定输出，而不是一次性透支。

### 7.2 六周目标

假设从 2026-11-19 开始：

| 周 | 时间 | 唯一主目标 | 必须交付 |
| --- | --- | --- | --- |
| W1 | 11/19-11/25 | 修复反馈系统，建立本地可运行基线 | 应用进 kind/minikube；P0 workflow 修复；4 类日志 fixture |
| W2 | 11/26-12/02 | 完成确定性 CI Failure Analyzer | CLI、JSON/Markdown 输出、3 类失败测试、脱敏测试 |
| W3 | 12/03-12/09 | 接入 LLM 与 Evals | provider adapter、prompt v1、20-30 条 golden set、前后对比指标 |
| W4 | 12/10-12/16 | 接入 GitHub Actions 与只读 API | workflow run/job/log 读取；报告 artifact；可选 PR 评论 |
| W5 | 12/17-12/23 | 容器化并部署到本地 K8s，补 Week 8 | 镜像、K8s 清单、探针、日志、资源限制；ACK/Helm/Kustomize 设计 |
| W6 | 12/24-12/30 | 集成、演示、复盘和缓冲 | 5 分钟演示、README、架构图、评测报告、Day 50-75 证据清单 |

### 7.3 W1：先让系统重新“给反馈”

每日任务：

1. 修 `/healthz`、`/readyz`，补测试。
2. 修 Docker workflow 触发路径。
3. 修 CD 的 CI 依赖和 PR 部署问题。
4. 修 Docker 部署端口与 workflow permissions。
5. 用 kind 或现有 Docker Desktop K8s 启动集群。
6. 构建本地镜像并 apply 自身应用，而不是 nginx。
7. 写恢复复盘，冻结所有新 AI 长文，直到 Agent 有测试。

W1 验收：

- `npm run lint && npm test && npm run build` 通过。
- `/healthz`、`/readyz` 有独立状态码测试。
- Pod 处于 Ready，Service 可访问，probe 失败时能触发预期行为。
- 修改 `app/src` 会触发镜像构建。
- PR 不会进入真实部署 Environment。

### 7.4 W2：先做“不用模型也能工作”的 Agent

建议先在当前仓库创建 `agent/`，不要一开始就拆三个仓库。跑通后再独立成 `agent-platform`。

建议结构：

```text
agent/
  pyproject.toml
  src/ci_agent/
    __init__.py
    cli.py
    models.py
    redaction.py
    parsers/actions_log.py
    analyzers/rules.py
    renderers/markdown.py
  tests/
    fixtures/logs/
    test_parser.py
    test_redaction.py
    test_schema.py
```

首个 CLI：

```text
python -m ci_agent analyze tests/fixtures/logs/failure-01.txt --format markdown
python -m ci_agent analyze tests/fixtures/logs/failure-01.txt --format json
```

W2 验收：

- 至少 3 类失败：依赖安装、测试失败、Docker build 失败。
- 输出包含失败 job、失败 step、关键错误、上下文和建议。
- JSON 输出通过 schema 校验。
- 敏感信息替换为 `[REDACTED]`。
- 不调用 LLM 也能完成全部测试。

### 7.5 W3：LLM 只作为可替换组件

关键设计：

```text
Analyzer Core -> Provider Adapter -> Model
                      |
                      +-> FakeProvider（测试用）
                      +-> OpenAI-compatible Provider（真实调用）
```

不要把模型 SDK 直接写进 parser。应保留：

- 超时、重试和最大步数。
- 结构化输出校验。
- 失败回退到确定性分析。
- token、延迟、成本记录。
- prompt 版本号。

W3 验收：

- 20-30 条 golden set。
- 同一输入在 FakeProvider 下测试稳定。
- 改 prompt 前后都有通过率记录。
- 100% 输出符合 schema。
- secret 泄露用例为 0。

### 7.6 W4：接 GitHub，但先只读

第一阶段只做：

- 读取 workflow run。
- 读取 jobs。
- 下载失败 job 日志。
- 输出分析报告为 artifact。

第二阶段再做 PR 评论。评论能力必须单独授权，不能与读取日志使用同一个宽权限 token。

W4 验收：

- 对一个失败 run 生成报告。
- API 分页、404、限流、超时有明确处理。
- workflow 使用最小权限。
- 默认不写 PR、不触发部署、不执行任意命令。

### 7.7 W5：补 Week 8，但先本地后云端

本地完成：

- Helm chart 基础结构。
- base + dev/prod overlay。
- kind + Argo CD 的 GitOps 演练，或至少完成完整仓库结构设计。
- 本地 registry 或 kind load 镜像。

云端只完成：

- ACK/ACR/SLB/日志/监控关系图。
- ACR 镜像命名与认证方案。
- ACK 部署清单和成本预估。
- 回滚流程和审批边界。

不必为了“打卡 Day 50”立刻购买 ACK。只有本地链路无法覆盖的差异，才值得使用云端资源。

### 7.8 W6：作品化和缓冲

必须形成：

- 5 分钟 demo：失败日志 -> 分析报告 -> GitHub artifact。
- README：安装、运行、测试、架构、限制。
- 一页评测报告：准确率、schema 合规、泄露、延迟、成本。
- 一张端到端链路图。
- 一篇复盘：哪些结论由实验证明，哪些仍是假设。

## 八、每日与每周执行模板

### 8.1 每日闭环

每天结束前必须回答四个问题：

1. 今天新增了哪个可运行文件或配置？
2. 用什么命令证明它工作？
3. 我今天遇到的最小真实错误是什么，如何定位？
4. 如果明天重做，我能在 30 分钟内复现吗？

每日日志建议固定为：

```text
目标
实际产出（文件路径）
运行命令与结果
最小故障与定位过程
今日自测（闭卷回答 3 问）
明日唯一优先项
```

### 8.2 每周验收

每周只允许用以下证据标记完成：

- 一个可运行命令。
- 一组通过的测试。
- 一个真实失败及修复记录。
- 一份复盘或 ADR。
- 一次不看资料的重建实验。

文档数量、阅读页数和收藏数不算完成指标。

### 8.3 卡住时的 30 分钟规则

连续卡住 30 分钟时，先写清四行：

```text
期望：
实际：
最小复现命令：
我已经排除：
```

然后只问一个具体问题。若无法写出最小复现，说明应先缩小问题，而不是继续让 AI 给完整答案。

### 8.4 使用 AI 学习的正确姿势

1. 先自己跑通最小实验。
2. 卡住后提供错误、命令、期望和已排除项。
3. 要求 AI 解释假设与验证步骤，而不是直接给最终代码。
4. 修好后关闭答案，从空白或最小骨架复现一次。
5. 让 AI 出 5 道排障题，答错项进入下周回归清单。

AI 应加速反馈，不应替代理解。

## 九、验收指标

### 9.1 工程指标

| 指标 | 目标 |
| --- | --- |
| lint/test/build | 每次提交通过 |
| Agent JSON schema | 100% 合法 |
| golden set | 至少 20 条，最终建议 50 条 |
| 失败步骤识别 | 在固定 fixture 上 >= 90% |
| secret 泄露 | 0 |
| API 超时/限流 | 有测试和可读错误 |
| 本地 K8s 部署 | Pod Ready，Service 可访问 |
| 端到端演示 | 5 分钟内可重复 |

### 9.2 学习指标

| 能力 | 通过标准 |
| --- | --- |
| 复述 | 合上资料讲清概念与边界 |
| 复现 | 30 分钟内重建实验 |
| 改造 | 添加一个工具、测试或新日志类型 |
| 排障 | 能定位一个人为注入的错误 |
| 迁移 | 能把同样方法用于 PR 总结或 release note |

### 9.3 每周进度看板

每周只维护四列：

```text
本周唯一目标
正在做
已通过验证
被阻塞
```

被阻塞项必须写“缺什么权限/缺什么环境/缺什么知识”，不能只写“不会”。

## 十、建议的仓库改造顺序

1. `fix: align health endpoints and probes`
2. `test: cover health and readiness responses`
3. `ci: rebuild image on application changes`
4. `ci: gate deployment on successful build and scan`
5. `fix: correct docker deployment port`
6. `ci: restore explicit least-privilege permissions`
7. `feat: add deterministic ci_agent parser`
8. `test: add failure log fixtures and redaction cases`
9. `feat: add optional llm provider adapter`
10. `test: add golden set evaluation runner`
11. `feat: read failed workflow logs through GitHub API`
12. `feat: publish analysis report as artifact`
13. `chore: add local kind deployment workflow`
14. `docs: add architecture, demo, limitations, evaluation`

不要把“补 26 天日志”当目标。更合理的收官标准是：

- 主线 Day 50-75 的关键主题都有证据。
- Agent MVP 可运行、可测试、可部署。
- Week 8 的 ACK/GitOps 至少完成本地等价实现与云端设计。
- 技能矩阵中每项 L2/L3 都能指向具体文件和命令。

## 十一、未来 7 天立即执行清单

- [ ] 修 `/healthz`、`/readyz` 并补测试。
- [ ] 让 Docker workflow 在 `app/**` 变化时触发。
- [ ] 禁止 PR 进入真实部署 Environment。
- [ ] 让部署依赖构建、测试、扫描成功。
- [ ] 修正 Docker 部署端口。
- [ ] 启动 kind/minikube，跑自身应用而不是 nginx。
- [ ] 创建 `agent/` Python 骨架并跑通一个 CLI。
- [ ] 收集 4 类真实 CI 失败日志作为 fixture。
- [ ] 写一个 secret redaction 测试。
- [ ] 冻结新增 AI 长文 2 周，把时间全部投入可运行实验。

## 十二、最终判断

这个仓库已经证明你具备持续学习和系统整理能力，前 49 天不是无效积累。真正需要改变的是学习方式：

- 从“继续扩展知识面”转为“围绕一个 Agent 产品补齐最小能力”。
- 从“日历进度”转为“可运行证据进度”。
- 从“写更多总结”转为“写更少但能跑、能测、能演示的系统”。
- 从“先云后本地”转为“先本地闭环，再云端设计”。

如果按 6 周计划执行，最重要的不是把 Day 75 的数字补上，而是拿到一个能放进简历和面试演示的 DevOps Agent：

> 输入一次真实 CI 失败，自动脱敏、定位失败步骤、生成结构化分析与修复建议，并通过测试、评测和本地 K8s 部署证明它可靠。

这比再增加十万字笔记更能证明你已经补齐了进度。
