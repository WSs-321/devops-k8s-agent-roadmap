# 岗位分析与能力差距报告

> 结论先行：本仓库当前是一套**质量不错的"学习路线 + 笔记 + 模板"仓库**，但还不是一份可以直接拿去面试的**生产级作品集**。最现实的求职入口是**云原生运维 / DevOps 工程师（初级-中级）**与**平台工程 / 研发效能**方向；**SRE** 和 **AIOps / DevOps Agent** 是高薪冲刺方向，但必须先补出可运行的作品集证据。

本文基于三类证据交叉验证：

1. 仓库本身的实际产出（workflow、YAML、文档、日志，截至 Day 49 / Week 7）。
2. 30+ 条互联网 / 云厂商 / AI 公司真实 JD 样本（招聘挂牌信息，随时可能下线）。
3. 公开市场数据（CNCF 年度报告、招聘平台薪资页、研究机构报告，口径见第 10 节）。

## 1. 结论摘要

| 求职方向 | 当前匹配度 | 定位 | 一句话判断 |
| --- | --- | --- | --- |
| 云原生运维 / DevOps 工程师 | ★★★★☆ | **主投** | CI/CD 与容器证据最扎实，缺真实部署闭环和排障记录 |
| 平台工程 / 研发效能 | ★★★★☆ | **主投** | Environments、门禁、模板化能力对口，缺多语言 CI 与真实用户 |
| SRE（稳定性 / 可观测性） | ★★☆☆☆ | **冲刺** | 缺可观测性全套、SLO/on-call/故障演练，硬门槛 3-5 年 |
| AIOps / DevOps Agent | ★★★☆☆ | **冲刺（潜力最大）** | 学习路线覆盖 LLM/Agent 全概念，但零代码落地，是当前最大机会缺口 |
| MLOps / AI 平台工程 | ★★☆☆☆ | 备选 | 需要 GPU/K8s 调度与训练管线经验 |
| 云原生平台研发（Go/K8s 二开） | ★☆☆☆☆ | 暂缓 | 要求生产级 Go 与 K8s 内部机制，短期补不齐 |
| 资深 SRE / 平台架构 | ★☆☆☆☆ | 暂缓 | 要求 5 年以上大规模生产经验，非学习能速成 |

核心差距只有一句话：**"从模拟到真实"**——所有部署都是 `DRY_RUN=true`，所有 Agent 都还停留在设计文档，所有运维经验都还没有一次真实的故障处置记录。

## 2. 仓库现状：已有证据与缺失项

### 2.1 已有能力（可直接写进简历的证据）

| 能力 | 证据位置 | 面试可讲什么 |
| --- | --- | --- |
| GitHub Actions CI | `ci-node.yml` / `ci-basic.yml` | matrix 三版本并行、npm cache、artifact 上传测试报告、`permissions` 最小化 |
| Docker 镜像工程 | `app/Dockerfile`、`docs/docker-multi-stage.md` | 多阶段构建、HEALTHCHECK、非 root、镜像标签策略 |
| 镜像流水线与 GHCR | `ci-docker.yml`、`build-push-action.md`、`metadata-action.md` | build-push-action + metadata-action 三层 outputs、tag 规则 |
| 供应链安全 | `codeql.yml`、`sbom.yml`、`trivy-scan.md`、`security-baseline.md` | CodeQL、Trivy、SBOM(SPDX)、Dependabot 分组、Secret 脱敏边界 |
| CD 与环境治理 | `cd-deploy.yml`、`cd-env.yml`、`deploy.sh` | Environments、三环境串行、审批门禁、DRY_RUN 模拟 |
| K8s 基础 | `k8s/` 七类清单、`killercoda-demo.sh` | Deployment/Service/Ingress/Probe/ConfigMap/PVC、QoS、流量链路 |
| 工程规范 | 分支保护、squash merge、Conventional Commits、49 篇 daily log | 工程习惯与文档化能力，学习执行力 |

这部分在初级 JD 对比中**不输甚至超出**多数 1-3 年候选人——多数候选人只会用 Jenkins 拖流水线，本仓库有完整的"权限-扫描-物料-门禁"安全叙事。

### 2.2 关键缺失（JD 对照后暴露的硬缺口）

| 缺口 | 影响 | 证据现状 |
| --- | --- | --- |
| 真实部署闭环 | 面试必被追问"你部署过什么" | `cd-deploy.yml` 三个环境全部 `DRY_RUN: "true"`，URL 是 `example.com` |
| K8s 生产运维深度 | 卡 SRE/中级运维岗 | 只有基础 YAML，无 Helm/Kustomize/Argo CD/HPA/PDB/RBAC/NetworkPolicy，无一次排障记录 |
| 可观测性全套 | 卡 SRE 与多数中高级 JD | Prometheus/Grafana/Loki/Alertmanager/OTel 均为 0，`skill-matrix` 全部"未开始" |
| IaC | 高级 JD 高频 | Terraform/Ansible/Pulumi 未开始（Week 12 计划） |
| Python/Go 服务开发 | 卡 AIOps/平台研发岗 | 业务项目仅 Node.js 单文件 HTTP server，无 Python/Go 工程 |
| Agent 可运行 MVP | 卡 AIOps/DevOps Agent 岗 | `project-04` 仅为设计文档，`tracks/06` 权限模型 L0-L5 无代码实现 |
| SRE 方法论 | 卡 SRE 岗 | 无 SLO/SLI 落地、无故障演练、无 postmortem、无容量规划 |
| 认证背书 | 筛简历环节 | 无 CKA/CKAD/CKS，JD 中多为"加分项"但已成筛选项 |
| 规模与协作证据 | 卡高级岗 | 单人项目、无真实用户、无 QPS/节点数等规模数据 |

结论：**Week 1-7 的 CI/CD + 容器 + 安全主线质量是达标的；Week 8-15（ACK/GitOps/可观测性/Agent）还停留在"计划文档"，而这恰恰是 JD 里区分初级与中级的分水岭。**

## 3. 互联网岗位地图

### 3.1 六类目标岗位与代表雇主

| 岗位类别 | 典型雇主（互联网为主） | 核心职责 | 与本仓库的关系 |
| --- | --- | --- | --- |
| DevOps / 云原生运维 | 电商、本地生活、出行（滴滴等）、SaaS 公司 | 流水线建设、K8s 运维、发布、成本 | Week 1-7 直接对口 |
| 平台工程 / 研发效能 | 大厂效能团队、字节火山引擎等 | 内部 CI/CD 平台、模板化、开发者体验 | Environments/门禁/模板思路对口 |
| SRE / 稳定性 | 字节、月之暗面、滴滴、智元机器人等 | SLO、可观测、on-call、容量、变更管控 | Week 13-15 计划，未落地 |
| AIOps / 智能运维 | 字节智能运维、阿里、腾讯、电信系 | 告警收敛、根因定位、异常检测 | 与 Agent MVP 计划强相关 |
| DevOps Agent / Agentic Ops | 字节火山引擎、BOSS 直聘、润建等 | LLM+运维工具链、MCP 编排、RCA | `tracks/06` + `project-04` 计划，未落地 |
| MLOps / AI 平台 | AI 独角兽、智元（GPU 集群） | 训推平台、GPU 调度、模型交付 | 部分重叠（K8s+CI/CD 底座） |

### 3.2 JD 高频硬要求归纳（30+ 条样本）

| 能力项 | 出现在 JD 中的频率 | 本仓库现状 |
| --- | --- | --- |
| Linux + Shell | 几乎 100% | 有使用但无专门训练（skill-matrix 标注 L2→L3 待补） |
| Python / Go | 约 80% | Python 计划中，Go 未开始 |
| Kubernetes（含排障） | 约 90% | 基础对象有，排障/调优无 |
| CI/CD（Actions/GitLab CI/Jenkins） | 约 90% | ✅ 最强项 |
| Docker / containerd | 约 85% | ✅ 达标 |
| Helm / Kustomize / Argo CD | 约 60%（中高级几乎必考） | ❌ Week 8 计划 |
| Prometheus / Grafana / Loki / OTel | 约 60% | ❌ Week 13 计划 |
| Terraform / Ansible | 约 50% | ❌ Week 12 计划 |
| SLI/SLO、on-call、postmortem | SRE 岗 100% | ❌ Week 15 计划 |
| 云平台（阿里云/腾讯云/AWS） | 约 70% | 仅设计文档（project-05） |
| 安全（RBAC/NetworkPolicy/DevSecOps/Vault） | 约 40% | CI 侧 ✅，运行时侧 ❌ |
| LLM / Agent / RAG / MCP / Function Calling | AIOps/Agent 岗 100% | 概念文档 ✅，代码 ❌ |
| CKA/CKAD/CKS 等认证 | 约 30%（"加分"） | ❌ |

### 3.3 真实 JD 样本摘录（脱敏，挂牌信息随时可能下线）

| 来源类型 | 岗位 | 挂牌薪资 | 年限 | 硬要求关键词 |
| --- | --- | --- | --- | --- |
| 互联网出行大厂 | 云原生平台研发 | 未标 | 3 年+ | Golang、K8s 二次开发、蓝绿/金丝雀、镜像管理 |
| 互联网出行大厂 | SRE | 未标 | 3 年+ | Go/Java/Python、可观测、容量、变更管控、AIOps 经验优先 |
| 大模型独角兽（北京） | 高级 SRE | 35-50K·16薪 | 5 年+ | SLO、ArgoCD、Prometheus 全家桶、OTel、on-call、postmortem |
| 大厂智能运维（杭州） | 大模型应用 | 未标 | 硕士起 | LLM/Agent、ReAct/RAG/MCP、根因定位、异常检测 |
| 大厂云部门（杭州） | DevOps Agent 研发 | 未标 | 2 年+后端 | 生产级 LLM/Agent、MCP、向量检索、human-in-the-loop、AIOps/RCA |
| 招聘平台公司（沪杭） | Agentic Ops | 未标 | - | 智能告警、根因定位、预案推荐、效果评估、人工确认、安全兜底 |
| 机器人独角兽（上海） | SRE 与可观测平台 | 25-50K·15薪 | 3 年+ | SLI/SLO、GitOps、GPU 集群加分、OTel |
| 传统 IT 转型（深圳） | IT AIOps | 1.5-3 万 | 2 年+ | Function Call/RAG、Prometheus/ELK/K8s、LLMOps、Dify/LangChain |
| 综合（猎聘样本） | 云平台运维（DevOps） | 15-25K·13薪 | 3 年+ | K8s/Helm/Operator、Terraform/Ansible、Prometheus/Loki、SRE 思维 |
| 综合（智联样本） | DevOps 工程师 | 1.8-2.8 万 | 3 年+ | Linux、K8s RBAC/Helm、微服务、Bash/Python/Go、IaC、ELK |

样本给出的两个关键信号：

1. **3 年是中级岗分水岭**，但"3 年经验"在互联网公司更接近"能力要求"而非硬性年限——有真实项目证据的 1-2 年候选人同样能过简历关。
2. **AIOps/Agent 岗的 JD 语言与本仓库 `tracks/06` + `project-04` 的设计语言几乎重合**（human-in-the-loop、guardrails、效果评估），说明路线设计是对的，只差"做出来"。

## 4. 能力差距矩阵

按目标岗位要求逐项对照（L=skill-matrix 等级）：

| 能力 | 当前 | 主投岗要求 | 冲刺岗（SRE/Agent）要求 | 差距 | 补齐途径（对应计划） |
| --- | --- | --- | --- | --- | --- |
| Git/GitHub | L3 | L3 | L3 | ✅ 无 | - |
| GitHub Actions | L3 | L3 | L3 | ✅ 无 | - |
| Docker/容器 | L3 | L3 | L3 | ✅ 无 | - |
| CD 与 Environments | L2 | L2 | L3 | ⚠️ 缺真实部署 | Week 8：把 DRY_RUN 换成真实目标 |
| K8s 基础对象 | L2 | L3 | L3+ | ⚠️ 缺排障记录 | Week 8：Helm/Kustomize + killercoda 排障实验 |
| K8s 生产运维 | - | L3 | L4 | ❌ 大 | Week 8/14：GitOps、Rollouts、RBAC/NetworkPolicy |
| Helm/Kustomize/ArgoCD | - | L2 | L3 | ❌ 大 | Week 8 主线 |
| 可观测性 | - | L2 | L3 | ❌ 大 | Week 13：kube-prometheus-stack + Loki + OTel |
| IaC（Terraform） | - | L2 | L3 | ❌ 大 | Week 12 主线 |
| SRE 方法论 | - | L1 | L2+ | ❌ 大 | Week 15：SLO、演练、postmortem |
| Linux/Shell | L2 | L3 | L3 | ⚠️ 中 | 每天 log 中固定排障练习 |
| Python | - | L2 | L3 | ❌ 大 | Week 9-10：Agent MVP 用 Python 实现 |
| LLM/Agent 工程 | 概念级 | - | L2（AIOps 岗） | ❌ 大但已规划 | Week 9-10：MVP 落代码 |
| K8s 安全 | - | L1 | L2 | ❌ 中 | Week 15 |
| Go | - | -（主投可选） | L2（平台研发） | ❌ 大，非必需 | 100 天后再评估 |

## 5. 岗位缺口与市场数据

数据口径：均为公开挂牌/报告样本，**不构成就业承诺**，仅用于方向判断。

| 数据点 | 数值 | 来源 | 对本仓库的含义 |
| --- | --- | --- | --- |
| 云原生采用率 | 89% 组织在使用 | CNCF《Cloud Native 2024》报告（2025 年发布） | 云原生技能是普适底座，不是加分项 |
| 生产环境容器使用 | 91% | 同上 | K8s 运维需求长期存在 |
| 生产 CI/CD 使用增长 | +31% | 同上 | CI/CD 是 JD 高频项的结构性原因 |
| 遵循 GitOps 原则的组织 | 77% | 同上 | Argo CD/Kustomize 是中高级 JD 必考的原因 |
| DevOps 全经验平均月薪 | 约 1.35 万；3-5 年约 1.76 万；北京 3-5 年约 3.16 万 | 猎聘 DevOps 薪资页（挂牌样本） | 3 年是薪资跳档点，与技能矩阵目标吻合 |
| SRE 招聘职位量 | 2026 年样本 1,501 个，68.3% 岗位 20-50K/月，36.7% 要求 5-10 年 | 职友集 SRE 职位页 | SRE 量少门槛高，印证"冲刺"定位 |
| 全球 AIOps 市场 | 2026 年约 189.5 亿美元 → 2031 年约 377.9 亿美元，CAGR 约 14.8%，亚太最快 | Mordor Intelligence | AIOps 是增速最快的方向，人才池尚未饱和 |
| 网络安全与 IT 运维人才缺口 | 全球约 350 万 | 同上引用行业口径 | "云原生+AI"复合人才稀缺是真实缺口 |

缺口判断（综合 JD 与市场数据）：

1. **存量最大**：初中级 DevOps/云原生运维——每个上规模的公司都在招，本仓库当前证据即可投。
2. **溢价最高**：SRE 与 AIOps——薪资带宽明显高于纯运维（对比上表 JD：传统 IT AIOps 1.5-3 万 vs 大模型公司 SRE 35-50K），但都要 3 年+ 证据。
3. **结构性缺口**：懂 DevOps 又懂 LLM/Agent 的复合人才——这正是 `tracks/06` 定位，目前市场上候选人极少，是本仓库最值得投入的差异化方向。

## 6. 匹配度分级与投递策略

### 6.1 主投（现在就投）

- **云原生运维 / DevOps 工程师（1-3 年档）**
- **平台工程 / 研发效能（初级）**

简历主线：GitHub Actions 全链路 + Docker/GHCR + 供应链安全 + Environments 三环境治理。

面试前必须补的三个点：

- [ ] 准备 3 个 CI 优化故事（cache 命中率、matrix 提效、artifact 报告消费）。
- [ ] 用 killercoda/本地 kind 至少完成一次 K8s 真实排障（CrashLoopBackOff、OOM、探针失败）并写成日志。
- [ ] 把 `cd-deploy.yml` 的 dev 环境接到一个真实目标（哪怕是一台 1 核 VPS 或本地 kind 集群），去掉 `DRY_RUN`。

### 6.2 冲刺（补 4-8 周作品集后投）

- **SRE / 稳定性**：需先完成 Week 13（可观测）+ Week 15（SLO/postmortem），至少一套自己的 Prometheus 告警规则 + 一次演练复盘。
- **AIOps / DevOps Agent**：需先完成 `project-04` MVP——本地 CLI 读 Actions 日志 → LLM 分析 → Markdown 报告，再进一步评论 PR。这是从"会背概念"到"能上生产"的关键一步，也是 JD 语言与本仓库设计重合度最高的赛道。

### 6.3 备选与暂缓

- **MLOps / AI 平台**：等 Agent MVP 做完后可平移（同样吃 K8s+CI/CD 底座），可关注 GPU 调度加分项。
- **云原生平台研发（Go 二开）/ 资深 SRE / 架构**：要求生产级 Go 与 5 年+ 大规模经验，非 100 天内可补，列入长期路线。

## 7. Day 50-100 补齐路线（与 timetable 对齐）

| 阶段 | 内容 | 产出的"简历证据" |
| --- | --- | --- |
| Week 8（Day 50-56） | ACK/ACR、Helm、Kustomize、Argo CD、GitOps 仓库 | 一个真实同步的 GitOps demo 仓库 + K8s 排障日志 |
| Week 9（Day 57-63） | Agent 仓库规划、GitHub API、LLM 接入、失败日志分析 MVP | **可运行的 ci-failure-analyzer CLI（Python）** |
| Week 10（Day 64-70） | PR Summary Agent、Release Agent、Guardrails、Actions 集成 | Agent 在真实 PR 上留下评论的截图/链接 |
| Week 11（Day 71-75） | 端到端梳理、总复盘 | 面试叙事："75 天从 CI 到 Agent 的完整工程闭环" |
| Week 12（Day 76-82） | Terraform、阿里云 Provider、state 管理 | VPC/ACR/ACK 的 IaC 代码库 |
| Week 13（Day 83-89） | kube-prometheus-stack、PromQL、Loki、Alertmanager、OTel | 自己的 Grafana 截图 + 告警规则库 |
| Week 14（Day 90-96） | Argo Rollouts、金丝雀、TLS、DORA | 一次真实的金丝雀发布记录 |
| Week 15（Day 97-100） | RBAC、NetworkPolicy、Kyverno、SLO、postmortem | 一份完整的 SLO 文档 + 故障复盘模板 |

优先级建议（如果时间不够，按此砍）：

1. Week 9-10 Agent MVP（差异化最大，别只留设计文档）。
2. Week 8 GitOps + 真实部署闭环（把 DRY_RUN 干掉）。
3. Week 13 可观测性（SRE 与 AIOps 岗的公共前置）。
4. Week 12/14/15 按目标岗位取舍。

## 8. 作品集与简历证据清单

| 证据 | 对应 JD 要求 | 当前状态 |
| --- | --- | --- |
| 本仓库（CI/CD + 安全 + K8s 清单） | CI/CD、Docker、供应链安全 | ✅ 已有，持续维护 |
| K8s 排障日志（≥3 类故障） | K8s 排障 | ⚠️ Week 8 补 |
| GitOps demo 仓库（Argo CD 同步） | Helm/Kustomize/Argo CD | ❌ Week 8 补 |
| Agent MVP 仓库（可运行） | LLM/Agent/Function Calling | ❌ Week 9-10 补 |
| 监控告警配置库 + Grafana 面板 | Prometheus/Grafana/Loki | ❌ Week 13 补 |
| Terraform IaC 仓库 | Terraform | ❌ Week 12 补 |
| SLO 文档 + postmortem 演练 | SLI/SLO、故障处理 | ❌ Week 15 补 |
| CKA（可选） | 认证加分 | 💡 若有余力，Week 8-13 内容与 CKA 大纲高度重合，可顺带考 |

## 9. 风险与口径说明

- 本文所有薪资均来自招聘平台**挂牌样本**（猎聘/智联/职友集/BOSS 直聘页面），实际 offer 受城市、公司、面试表现影响，不构成保证。
- JD 样本来自 2026 年公开挂牌，存在下线与时效性；归纳的是"要求模式"而非单家公司承诺。
- CNCF / Mordor Intelligence 数据为行业报告口径；国内部分 AIOps 市场规模数据来源可信度参差，本文未采用。
- 匹配度评分（★）为基于 JD 对照的定性判断，服务于学习决策，不是测评结论。

## 10. 参考来源

- CNCF - Cloud Native 2024 年度报告（2025 发布）：云原生采用率、GitOps、CI/CD 增长数据
- 猎聘 DevOps 薪资分布页：经验段与城市薪资样本
- 职友集 SRE 职位统计页：职位量、薪资带宽、年限分布
- Mordor Intelligence - AIOps Market：市场规模与 CAGR
- 招聘平台公开 JD 样本（字节/滴滴/月之暗面/智元机器人/BOSS 直聘等，2026 年挂牌）
- 本仓库：`README.md`、`ROADMAP.md`、`timetable/75-day-plan.md`、`timetable/advanced-plan.md`、`timetable/skill-matrix.md`、`tracks/05-k8s-ack-prep.md`、`tracks/06-agent-platform.md`、`projects/project-04-agent-ci-analyzer.md`、`projects/project-05-k8s-ack-design.md`
