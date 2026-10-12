# Skill Matrix: 技术栈熟练度标准

本矩阵与 `timetable/75-day-plan.md`、`timetable/advanced-plan.md` 配套使用：计划决定"学什么"，本矩阵定义"学到什么程度算掌握"。

核心原则：等级必须由可拿出手的证据支撑，而不是自我感觉。求职时简历措辞与等级挂钩，防止面试翻车。

## 一、熟练度分级标准

| 等级 | 名称 | 能力定义 | 验收证据（缺一不可） |
| --- | --- | --- | --- |
| L1 | 了解 | 知道是什么、解决什么问题、适用场景；能读懂别人的配置 | 一篇说清概念的笔记；被问到能答上 |
| L2 | 会用 | 能照官方文档或模板独立跑通；知道关键参数含义 | 一次可运行实验 + commit；踩坑记录 |
| L3 | 熟练 | 脱稿写出正确配置；能独立排障（报错定位修复）；能讲清原理 | 一份从失败到修复的完整记录；不看文档复现实验 |
| L4 | 精通 | 能做方案设计与权衡；处理复杂或线上问题；能定规范、做 review | 一份被评审通过的设计文档；一次解决真实问题的记录 |

## 二、技术栈矩阵

当前等级基于已完成 Week 1-7 的实际产出预估，目标等级为 Day 100 收官时的合理预期。

| 技术栈 | 对应计划 | 当前 | 目标 | 达标证据 |
| --- | --- | --- | --- | --- |
| Git/GitHub 工作流 | Week 1 | L3 | L3 | 已达标：分支保护、PR 流程、commit 规范全走过 |
| GitHub Actions | Week 1-2 | L3 | L3 | 已达标：手写 matrix/cache/artifacts/outputs 并排障 |
| Docker/容器 | Week 3-4 | L3 | L3 | 已达标：多阶段构建、HEALTHCHECK、失败回放 |
| 镜像流水线（GHCR/Trivy/SBOM） | Week 4 | L3 | L3 | 已达标：build-push-action、metadata-action、扫描拦截 |
| CD 与 Environments | Week 5 | L2 | L2 | 模拟部署已跑通；L3 需真实服务器部署，下一阶段 |
| 安全治理（CodeQL/Dependabot/Secret） | Week 6 | L2 | L2 | 已达标：基线文档 + checklist |
| K8s 基础对象 | Week 7 | L2 | L3 | 差距：缺排障记录；Week 8 实操 ACK 时补齐 |
| Helm | Day 52 | - | L2 | 读懂 chart 结构并完成一次安装 |
| Kustomize | Day 53 | - | L2 | 写出 base + overlay 环境覆盖 |
| Argo CD | Day 54/91 | - | L2 | App 部署跑通 + 能解释 sync/self-heal/drift |
| Argo Rollouts | Day 92-93 | - | L2 | 金丝雀跑通一次 + 自动回滚实验记录 |
| Prometheus/Grafana | Day 83-89 | - | L2 | 应用指标接入 + 自定义面板 + 告警分级 |
| Loki/日志聚合 | Day 87 | - | L1 | 了解架构，LogQL 会基本查询 |
| Terraform | Day 76-82 | - | L2 | VPC/ACR/ACK 资源声明 + state 协作规范 |
| K8s 安全（RBAC/Kyverno/NetworkPolicy） | Day 97-98 | - | L1 | 知道体系与默认拒绝原则，能聊场景 |
| SRE 方法论（SLI/SLO） | Day 99 | - | L1 | 概念笔记 + 一份 SLO 设计草稿 |
| Linux/Shell | 全程穿插 | L2 | L3 | JD 硬要求；穿插补 systemd/journalctl/文本处理 |
| Python/Agent 开发 | Week 9-10 | - | L2 | MVP 跑通即 L2：日志输入、分析输出、评论 PR |
| 服务网格/混沌工程/FinOps | Day 100 之后 | - | 不设目标 | 明确不贪多，列入下一阶段 |

分配逻辑：核心 5 项到 L3（JD 硬性要求，面试主战场），监控/GitOps/IaC 到 L2（有实践经验就能讲），加分项 L1（能聊两句不露怯）。全部冲 L3 不合理：每天 3 小时撑不起每个 L3 的证据清单。

## 三、等级与简历表述映射

| 等级 | 简历用词 | 面试官预期 |
| --- | --- | --- |
| L3 | 熟练掌握 | 现场写配置、追问原理、问排障经历 |
| L2 | 熟悉，有实践经验 | 讲清使用场景、参数含义、踩过的坑 |
| L1 | 了解 | 说清概念和适用场景，不会被深挖 |

简历措辞必须与真实等级一致：写"精通"会被往深里问，写"熟悉"问到实验和踩坑为止，写"了解"只问概念。

## 四、自测机制

- 每周复盘使用 `templates/weekly-review.md` 的"技能等级打卡"一栏，对照本矩阵自查，只认有证据的等级。
- 每两周对照"当前"列更新一次预估，与目标有差距的项在"下周调整"里补学习任务。
- 求职前按矩阵逐项检查证据是否齐全，证据缺失的项降级表述。
