# 岗位分析与能力差距报告

> 结论先行：本仓库当前是一套**质量不错的"学习路线 + 笔记 + 模板"仓库**，但还不是一份可以直接拿去面试的**生产级作品集**。最现实的求职入口是**云原生运维 / DevOps 工程师（初级-中级）**与**平台工程 / 研发效能**方向；**SRE** 和 **AIOps / DevOps Agent** 是高薪冲刺方向，但必须先补出可运行的作品集证据。

本文基于三类证据交叉验证：

1. 仓库本身的实际产出（workflow、YAML、文档、日志，截至 Day 49 / Week 7）。
2. 10 条可在线验证的真实 JD 直链（字节跳动、美团、阿里云、上海人工智能实验室等招聘官网及挂牌平台，2026-11 检索，见第 3.3 节）。
3. 公开市场数据（CNCF 2024/2026 年度报告、Mordor Intelligence、挂牌薪资页，口径与链接见第 9-10 节）。

## 1. 结论摘要

| 求职方向 | 当前匹配度 | 定位 | 一句话判断 |
| --- | --- | --- | --- |
| 云原生运维 / DevOps 工程师 | ★★★★☆ | **主投** | CI/CD 与容器证据最扎实，缺真实部署闭环和排障记录 |
| 平台工程 / 研发效能 | ★★★★☆ | **主投** | Environments、门禁、模板化能力对口，缺多语言 CI 与真实用户 |
| SRE（稳定性 / 可观测性） | ★★☆☆☆ | **冲刺** | 缺可观测性全套、SLO/on-call/故障演练；门槛多为 3-5 年（上海 AI Lab 有 1-3 年窗口） |
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
| DevOps / 云原生运维 | 美团（本地生活）、华泰保险（传统行业转型）、SaaS 公司 | 流水线建设、K8s 运维、发布、成本 | Week 1-7 直接对口 |
| 平台工程 / 研发效能 | 大厂效能团队、字节火山引擎等 | 内部 CI/CD 平台、模板化、开发者体验 | Environments/门禁/模板思路对口 |
| SRE / 稳定性 | 上海人工智能实验室（含 1-3 年窗口岗）、GoDaddy（海外对照） | SLO、可观测、on-call、容量、变更管控 | Week 13-15 计划，未落地 |
| AIOps / 智能运维 | 华泰保险（JD 明确要求 LLM 日志排障） | 告警收敛、根因定位、异常检测 | 与 Agent MVP 计划强相关 |
| DevOps Agent / Agentic Ops | 字节火山引擎、美团、阿里云（Qoder） | LLM+运维工具链、MCP 编排、RCA | `tracks/06` + `project-04` 计划，未落地 |
| MLOps / AI 平台 | AI 独角兽、上海人工智能实验室（GPU 算力集群） | 训推平台、GPU 调度、模型交付 | 部分重叠（K8s+CI/CD 底座） |

### 3.2 JD 高频硬要求归纳（基于第 3.3 节 10 条可验证 JD）

> 频率为 10 条样本中的出现占比，样本量小，**仅作趋势参考，不代表全市场统计**；每条样本的原文链接见第 3.3 节。

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

### 3.3 可验证的真实 JD 样本（实名 + 直链）

> 以下 10 条均为 2026-11-19 检索可访问的招聘官网 / 挂牌平台直链，**挂牌信息随时可能下线，以链接当时内容为准**；薪资为挂牌值，非承诺。

| 岗位（公司） | 地点 / 薪资 / 年限 | 核心要求 | 来源 |
| --- | --- | --- | --- |
| DevOps Agent 研发工程师 - 火山引擎（字节跳动） | 杭州 / 2 年+ 后端 | Go/Python/Java、生产级 LLM/Agent、Prompt/Function Calling/MCP/多轮推理、RAG/向量检索/知识图谱/Memory（ES/Milvus/Neo4j）；JD 原文"分级自治（human-in-the-loop→半自动→全自动）"与本仓库 `tracks/06` L0-L5 模型一致 | [字节招聘官网](https://jobs.bytedance.com/experienced/position/detail/7616589439938562357) |
| AI Agent 开发工程师（美团） | 北京 / 成都 / 5 年+ | 大模型推理、Prompt Engineering、Agent Loop、Tool Use、MCP、RAG、上下文工程、模型评估、Neo4j/Milvus、AIOps 实践加分 | [美团招聘](https://zhaopin.meituan.com/web/position/detail?highlightType=social&jobUnionId=4119654480) |
| AI Agent 研发工程师（harness 方向）- Qoder（阿里云） | 杭州 / 2 年+ | TS/Python/Go、Agent Loop/工具调用/推理规划/记忆/多智能体、Prompt/Context Engineering、评测与失败归因 | [阿里云招聘](https://careers.aliyun.com/off-campus/position-detail?positionId=100004083014) |
| Agent 开发工程师（上海人工智能实验室） | 上海 / 社招 | Python、Linux、Docker、RAG/Tool Use/ReAct/CoT/工作流编排/记忆/状态管理、Agent 评测体系 | [上海 AI Lab](https://www.shlab.org.cn/joinus/detail/7686149294239467814) |
| 智能体开发工程师（上海人工智能实验室） | 上海 / 5 年+ 架构 | 模型网关/多模型路由、Function Calling、RAG、多智能体编排/沙箱/插件/OTel、SRE 思维、LLMOps | [上海 AI Lab](https://www.shlab.org.cn/joinus/detail/7699017036320950537) |
| 云原生 & 算力集群 SRE（上海人工智能实验室） | 上海 / **1-3 年**（入门窗口证据） | K8s 核心组件原理、容器/镜像/PV/PVC/污点容忍、Docker/containerd、独立搭建 Prometheus/Grafana/ELK/Jaeger、Go/Python、GPU 集群/CKA/CKS 加分 | [上海 AI Lab](https://www.shlab.org.cn/joinus/detail/7678621698992949514) |
| SRE 运维开发工程师（猎聘挂牌） | 北京 / 30-40K / 5-10 年 | K8s(HPA/RBAC/NetworkPolicy)+Helm/Kustomize+ACK、Nacos/RocketMQ/Redis/ES、Prometheus 全家桶+OTel、SLO/SLI、Jenkins/GitLab CI/ArgoCD、arthas/tcpdump/kubectl debug、CKA/CKAD/ACP | [猎聘](https://www.liepin.com/a/80927155.shtml) |
| SRE 工程师（华泰保险，智联挂牌） | 广州 / 1.5-2 万 / 3-5 年 | K8s/Docker/Helm、GitOps(ArgoCD/Tekton)、Python、Terraform/Ansible、**用 LLM/Copilot 做日志分析与故障排查**（传统行业也要 LLM 运维的证据） | [智联招聘](https://m.zhaopin.com/jobs/CC000594630J40910498702.htm) |
| SRE 岗位职责聚合（职友集，3 份样本） | 全国 / 30-50K | 阿里云 ECS/ACK/SLB/OSS/RDS/VPC/云监控、Jenkins、GitOps、Terraform/Ansible、SLI/SLO/SLA | [职友集](https://www.jobui.com/gangwei/sre+engineer/) |
| Senior SRE（GoDaddy，海外对照） | Remote India / 7 年+ | Ansible、Linux、K8s、Terraform、Python、GitHub Actions、on-call、SLI/SLO、Loki/Mimir/Grafana、Vault | [Built In](https://builtin.com/job/senior-site-reliability-engineer/12097768) |

样本给出的三个关键信号：

1. **入门窗口真实存在**：上海人工智能实验室"云原生 & 算力集群 SRE"明确招 **1-3 年**，且硬要求（K8s 核心组件 + 自建 Prometheus/Grafana/ELK/Jaeger）与本仓库 Week 8/13 计划完全对齐——这是当前最值得冲刺的真实入口。
2. **学习路线被业界 JD 验证**：字节"DevOps Agent 研发"JD 原文"分级自治（human-in-the-loop→半自动→全自动）"与本仓库 `tracks/06` 的 L0-L5 权限模型几乎一致；美团 / 阿里云 / 上海 AI Lab 的 Agent 岗要求（MCP、RAG、Tool Use、评测归因）与 `project-04` 设计语言重合，路线是对的，只差"做出来"。
3. **LLM + 运维已下沉为通用要求**：连华泰保险（传统行业）的 SRE JD 都明确要求"探索 LLM 在日志分析、故障排查的应用"，说明 AIOps 不是互联网专属，而是全行业基线。

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

| 数据点 | 数值 | 来源（可点击验证） | 对本仓库的含义 |
| --- | --- | --- | --- |
| 云原生采用率（2024） | 89% 组织在使用 | [CNCF《Cloud Native 2024》PDF](https://www.cncf.io/wp-content/uploads/2025/04/cncf_annual_survey24_031225a.pdf) | 云原生技能是普适底座，不是加分项 |
| 生产环境容器 / K8s（2024） | 容器 91%、K8s 93% | 同上 | K8s 运维需求长期存在 |
| 生产 CI/CD 使用增长（2024） | +31%；29% 每天多次发布 | 同上 | CI/CD 是 JD 高频项的结构性原因 |
| 遵循 GitOps 原则的组织（2024） | 77% | 同上 | Argo CD/Kustomize 是中高级 JD 必考的原因 |
| 云原生采用率（2026 最新） | 98% 组织采用云原生；82% 容器用户在生产部署 K8s | [CNCF 2026.1 年度报告 PDF](https://www.cncf.io/wp-content/uploads/2026/01/CNCF_Annual_Survey_Report_final.pdf) | 最新口径确认云原生已近全面普及 |
| K8s 托管生成式 AI 工作负载（2026） | 66% 组织已用 K8s 托管 GenAI；成熟组织 CI/CD 达 91% | 同上 | 直接支撑 AIOps / MLOps 方向判断，"云原生 + AI"是真实交汇点 |
| 全球 AIOps 市场 | 2026 约 189.5 亿美元 → 2031 约 377.9 亿美元，CAGR 约 14.8%，亚太最快 | [Mordor Intelligence AIOps](https://www.mordorintelligence.com/industry-reports/artificial-intelligence-for-it-operations-aiops-market) | AIOps 增速最快，人才池尚未饱和 |
| 挂牌薪资对比（同 SRE 方向） | 北京互联网 30-40K（5-10 年）vs 广州传统行业 1.5-2 万（3-5 年） | [猎聘挂牌](https://www.liepin.com/a/80927155.shtml) / [智联挂牌](https://m.zhaopin.com/jobs/CC000594630J40910498702.htm) | 互联网溢价显著，但传统行业门槛更低，是可进的入口 |

缺口判断（综合 JD 与市场数据）：

1. **存量最大**：初中级 DevOps/云原生运维——每个上规模的公司都在招，本仓库当前证据即可投。
2. **溢价最高**：SRE 与 AIOps——互联网公司薪资带宽明显高于传统行业（上表挂牌对比：北京互联网 SRE 30-40K vs 广州传统行业 SRE 1.5-2 万）；多数要求 3 年+，但存在 1-3 年入门窗口（上海 AI Lab SRE 岗，见第 3.3 节）。
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

- 本文所有薪资均来自招聘平台**挂牌样本**（猎聘 / 智联 / 职友集页面，链接见第 3.3 节与第 5 节），实际 offer 受城市、公司、面试表现影响，不构成保证。
- 第 3.3 节 10 条 JD 直链均于 **2026-11-19 检索可访问**，挂牌信息随时可能下线，失效后以招聘官网当时内容为准；归纳的是"要求模式"而非单家公司承诺。
- 职友集"SRE 岗位职责聚合"仅 3 份样本，样本量极小，只作职责关键词参考，不作薪资 / 职位量统计依据（故第 5 节未采用其职位量数字）。
- CNCF / Mordor Intelligence 数据为行业报告口径，链接见第 5 节与第 10 节；国内部分 AIOps 市场规模数据来源可信度参差，本文未采用。
- 匹配度评分（★）为基于 10 条 JD 对照的定性判断，样本量小，服务于学习决策，不是测评结论。

## 10. 参考来源

### JD 样本（实名直链，2026-11-19 检索可访问，挂牌可能下线）

- 字节跳动火山引擎 - DevOps Agent 研发工程师：<https://jobs.bytedance.com/experienced/position/detail/7616589439938562357>
- 美团 - AI Agent 开发工程师：<https://zhaopin.meituan.com/web/position/detail?highlightType=social&jobUnionId=4119654480>
- 阿里云 Qoder - AI Agent 研发工程师：<https://careers.aliyun.com/off-campus/position-detail?positionId=100004083014>
- 上海人工智能实验室 - Agent 开发工程师：<https://www.shlab.org.cn/joinus/detail/7686149294239467814>
- 上海人工智能实验室 - 智能体开发工程师：<https://www.shlab.org.cn/joinus/detail/7699017036320950537>
- 上海人工智能实验室 - 云原生 & 算力集群 SRE：<https://www.shlab.org.cn/joinus/detail/7678621698992949514>
- 猎聘 - SRE 运维开发工程师：<https://www.liepin.com/a/80927155.shtml>
- 智联招聘 - SRE 工程师（华泰保险）：<https://m.zhaopin.com/jobs/CC000594630J40910498702.htm>
- 职友集 - SRE 岗位职责聚合（仅 3 份样本）：<https://www.jobui.com/gangwei/sre+engineer/>
- Built In - Senior SRE（GoDaddy，海外对照）：<https://builtin.com/job/senior-site-reliability-engineer/12097768>

### 市场数据报告

- CNCF《Cloud Native 2024》年度报告 PDF（2025 发布）：<https://www.cncf.io/wp-content/uploads/2025/04/cncf_annual_survey24_031225a.pdf>（89% 采用、91% 容器、+31% CI/CD、77% GitOps）
- CNCF 2026.1 年度报告《The infrastructure of AI's future》PDF：<https://www.cncf.io/wp-content/uploads/2026/01/CNCF_Annual_Survey_Report_final.pdf>（98% 采用、82% 生产 K8s、66% K8s 托管 GenAI）
- Mordor Intelligence - AIOps Market：<https://www.mordorintelligence.com/industry-reports/artificial-intelligence-for-it-operations-aiops-market>（市场规模与 CAGR）

### 仓库内部证据

- 本仓库：`README.md`、`ROADMAP.md`、`timetable/75-day-plan.md`、`timetable/advanced-plan.md`、`timetable/skill-matrix.md`、`tracks/05-k8s-ack-prep.md`、`tracks/06-agent-platform.md`、`projects/project-04-agent-ci-analyzer.md`、`projects/project-05-k8s-ack-design.md`
