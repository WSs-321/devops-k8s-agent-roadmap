# Advanced Plan: 76-100 天进阶路线

本路线衔接 `timetable/75-day-plan.md`，补齐 75 天计划中未展开的生产化技术栈：Terraform IaC、可观测性、发布策略、K8s 安全与 SRE 基础。

前置条件：完成 75 天计划，或至少完成 Week 8 的 ACK 架构与 ACR 迁移方案设计。

## 与 75 天计划的衔接

| 进阶主题 | 呼应的 75 天内容 |
| --- | --- |
| Terraform IaC | Day 50-51 ACK 架构与 ACR 迁移方案，从控制台手工操作升级为代码化管理 |
| 可观测性 | Day 48 探针、Day 52 Helm，用 Helm 安装 kube-prometheus-stack |
| 发布策略 | Day 54 Argo CD、Week 5 CD 审批流程，从单环境替换升级为金丝雀发布 |
| K8s 安全 | Week 6 安全基线，从 CI/CD 层延伸到集群层 |
| SRE 基础 | Day 75 下一阶段规划中提到的 SRE 方向 |

## 先修提示

- Week 9 开始写 Agent（Python）前，建议在 Day 56 周复盘时插入 2 小时 Python 速通：venv、requests、pytest。否则 Day 59 日志解析脚本会卡在语言基础。
- 本路线假设 Week 8 已产出 ACK 架构笔记与 ACR 迁移方案，可反复对照。
- Week 12-14 涉及阿里云真实资源时，先用 `terraform plan` 确认 diff 再决定是否 apply；ACK 集群创建有费用，仅做 plan review 也可完成学习目标。

## Week 12: Terraform IaC

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 76 | IaC 概念与 Terraform 安装 | 理解 IaC 与命令式脚本的差异；安装 Terraform；跑通 hello world，掌握 provider/block/state/plan/apply 生命周期 | terraform notes |
| 77 | 阿里云 Provider 与凭证 | 创建 RAM 用户，AK 走环境变量注入；理解 state 文件含敏感信息、禁止提交入库 | provider notes |
| 78 | 核心网络资源 | 用 HCL 声明 VPC、交换机、安全组，与 Day 50 ACK 架构笔记逐项对照 | vpc terraform |
| 79 | ACR IaC 化 | 声明容器镜像仓库与企业版实例，替代 Day 51 方案中的手工创建步骤 | acr terraform |
| 80 | ACK 集群 IaC 化 | 声明 ACK 托管集群，理解节点池、运行时、网络插件参数；只做 plan 不 apply | ack terraform |
| 81 | state 管理与模块化 | state 放 OSS 远程 backend；理解 state 锁与团队协作；把重复资源抽成 module | state policy |
| 82 | 周复盘 | 输出 IaC 仓库目录结构与命名规范；演练一次 plan diff review 流程 | weekly review |

## Week 13: 可观测性

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 83 | 三支柱与 Prometheus | 理解 metrics/logs/traces 三支柱；Prometheus Pull 模型、Exporter 机制、PromQL 入门 | prometheus notes |
| 84 | kube-prometheus-stack | 用 Helm 安装 kube-prometheus-stack；理解 ServiceMonitor 如何发现抓取目标 | stack install notes |
| 85 | 应用指标接入 | 为 app 示例增加 /metrics 端点（prom-client）；在 Grafana 做第一个自定义面板 | metrics endpoint |
| 86 | PromQL 实战 | CPU、内存常用查询与 rate 函数；关联 Day 48 的 requests/limits 与 QoS 分级 | promql notes |
| 87 | Loki 日志聚合 | 理解 Promtail 采集与 LogQL 查询；为应用定义结构化日志规范 | loki notes |
| 88 | Alertmanager 告警 | 告警路由、P0-P2 分级、静默规则；接入 webhook 模拟值班通知 | alert rules |
| 89 | 周复盘 | 输出可观测性基线：指标清单、日志规范、告警分级表 | observability baseline |

## Week 14: 发布策略与 GitOps 进阶

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 90 | 发布策略全景 | 对比滚动、蓝绿、金丝雀的原理、适用场景与回滚成本 | release strategy note |
| 91 | Argo CD 深入 | App 级 sync 策略、self-heal、drift 检测；把 Day 55 设计的 GitOps 仓库跑通 | argocd practice |
| 92 | Argo Rollouts 金丝雀 | 安装 Rollouts controller；把 Deployment 改造成 Rollout；理解 steps 权重切流 | rollout yaml |
| 93 | 金丝雀分析与回滚 | 配置 Analysis 基于 Prometheus 指标自动判定；制造失败指标触发自动回滚 | analysis yaml |
| 94 | TLS 与流量入口 | cert-manager 签发证书；Ingress 配 TLS；回顾 Day 46 的 Ingress 到 Pod 流量链路 | tls notes |
| 95 | DORA 指标 | 理解部署频率、变更前置时间、MTTR、变更失败率；从本仓库流水线提炼真实数据 | dora notes |
| 96 | 周复盘 | 输出发布策略与 GitOps 生产化设计文档 | gitops design |

## Week 15: K8s 安全与 SRE 基础

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 97 | RBAC 最小权限 | Role、ClusterRole、Binding、ServiceAccount；为应用和未来 Agent 设计只读角色 | rbac yaml |
| 98 | 网络与准入安全 | NetworkPolicy 默认拒绝；Pod Security Standards；Kyverno 拒绝 latest 镜像、强制 resource limits | policy notes |
| 99 | SRE 基础 | SLI/SLO 与错误预算；告警分级原则；设计 postmortem 模板 | sre notes |
| 100 | 总收官 | 76-100 复盘；规划下一阶段：Istio、Chaos Mesh、FinOps、Agent 深化 | final roadmap |

## 每周验收方式

沿用 `timetable/weekly-milestones.md` 标准：每周 1 篇学习笔记、1 次可运行实验、1 个 commit、1 份周复盘。
