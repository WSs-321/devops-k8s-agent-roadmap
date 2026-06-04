# 75-Day Timetable

每天 3 小时。每一天都建议形成一个 commit，哪怕只是补充笔记、修复 workflow、整理错误记录。

## Week 1: GitHub Actions 基础

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 01 | 路线启动 | 阅读本仓库 README/ROADMAP，创建学习日志，确认 GitHub 账号、仓库命名、分支策略 | 第一篇 daily log |
| 02 | GitHub Actions 概念 | 学习 workflow、job、step、runner、event；手写第一个 hello workflow | `hello-actions.yml` |
| 03 | PR 触发 | 配置 `pull_request` 和 `push` 事件，理解默认分支保护思路 | PR CI demo |
| 04 | Checkout 与脚本 | 使用 `actions/checkout`，练习执行 shell 命令，记录 runner 环境信息 | runner notes |
| 05 | Node/Java/Python 任选栈 CI | 为你的示例技术栈添加 setup、install、test 步骤 | 可运行 CI |
| 06 | CI 失败调试 | 故意制造一次失败，阅读日志，修复失败 | failure note |
| 07 | 周复盘 | 整理 Week 1 学习内容，更新 README，列出卡点 | weekly review |

## Week 2: CI 工程化

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 08 | Lint 阶段 | 增加 lint 或格式检查，理解失败阻断机制 | lint job |
| 09 | Test 阶段 | 增加单元测试和测试报告输出 | test job |
| 10 | Build 阶段 | 增加构建步骤，区分测试构建和生产构建 | build job |
| 11 | Cache | 配置依赖缓存，加速 CI | cache config |
| 12 | Matrix | 使用 matrix 测试多个版本或环境 | matrix workflow |
| 13 | Artifacts | 上传构建产物、测试报告或日志 | artifact demo |
| 14 | 周复盘 | 完成 `project-01-ci-baseline` 验收 | project 01 done |

## Week 3: Docker 与容器基础

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 15 | Dockerfile 基础 | 为示例项目写 Dockerfile，本地构建镜像 | Dockerfile |
| 16 | 容器运行 | 使用 `docker run` 验证服务启动、端口、环境变量 | run note |
| 17 | 多阶段构建 | 优化镜像构建流程，减少镜像体积 | multi-stage Dockerfile |
| 18 | 健康检查 | 为应用设计 health endpoint 或容器健康检查 | health check |
| 19 | 配置外置 | 把环境配置从代码中移出，使用 env 注入 | config note |
| 20 | 镜像标签 | 设计 commit sha、semver、latest 的使用规则 | image tag policy |
| 21 | 周复盘 | 整理 Docker 错误与最佳实践 | weekly review |

## Week 4: GHCR 与镜像流水线

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 22 | GHCR 登录 | 学习 `GITHUB_TOKEN` 和 packages 权限 | ghcr notes |
| 23 | build-push-action | 添加自动构建和推送镜像 workflow | docker-ghcr workflow |
| 24 | 镜像元数据 | 使用 commit sha/tag 生成镜像 tag | metadata config |
| 25 | 镜像扫描 | 接入 Trivy 基础扫描 | scan job |
| 26 | 发布制品追踪 | 在 workflow summary 中输出镜像地址和版本 | summary output |
| 27 | 失败回放 | 故意制造 Docker build 失败并分析 | docker failure note |
| 28 | 周复盘 | 完成 `project-02-docker-ghcr` 验收 | project 02 done |

## Week 5: CD 与 GitHub Environments

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 29 | Environments | 创建 dev/staging/production 环境概念设计 | env design |
| 30 | Secrets | 学习 repo secrets 和 environment secrets 区别 | secrets policy |
| 31 | Dev 部署 | 写 dev deploy job，可先用 echo 或模拟脚本 | deploy-dev job |
| 32 | Production 审批 | 配置 production environment 人工审批 | approval flow |
| 33 | 部署脚本 | 设计 SSH/ECS/Docker Compose 部署脚本接口 | deploy script design |
| 34 | Release notes | 根据 commit 生成 release note 模板 | release note |
| 35 | 周复盘 | 完成 `project-03-cd-environments` 验收 | project 03 done |

## Week 6: 安全、质量、治理

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 36 | 权限最小化 | 为 workflow 增加 `permissions`，避免默认过大权限 | permissions update |
| 37 | Dependabot | 配置依赖更新策略 | dependabot config |
| 38 | CodeQL | 学习并接入 CodeQL 或记录适用条件 | code scanning note |
| 39 | Secret 安全 | 整理密钥使用规范，避免写入日志 | secret checklist |
| 40 | SBOM 入门 | 了解 SBOM，尝试 Trivy/Syft 生成清单 | sbom note |
| 41 | 分支保护 | 设计 main 分支保护规则和合并策略 | branch policy |
| 42 | 周复盘 | 输出 CI/CD 安全基线文档 | security baseline |

## Week 7: Kubernetes 基础

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 43 | K8s 概念 | 学习 Pod、Deployment、Service、Namespace | k8s concept note |
| 44 | Deployment | 为示例服务写 Deployment YAML | deployment.yaml |
| 45 | Service | 写 Service YAML，理解 ClusterIP/NodePort/LoadBalancer | service.yaml |
| 46 | Ingress | 写 Ingress 或 Gateway 初步设计 | ingress.yaml |
| 47 | Config/Secret | 写 ConfigMap/Secret 示例，区分敏感配置 | config note |
| 48 | Health Probe | 添加 readiness/liveness probe | probe config |
| 49 | 周复盘 | 形成 K8s 应用清单最小模板 | k8s template |

## Week 8: 阿里云 ACK 与 GitOps 预备

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 50 | ACK 架构 | 了解 ACK、ACR、SLB、日志服务、云监控关系 | ack architecture |
| 51 | ACR 迁移 | 设计从 GHCR 到阿里云 ACR 的镜像推送方案 | acr plan |
| 52 | Helm | 把 YAML 改造成 Helm chart 基础结构 | helm notes |
| 53 | Kustomize | 对比 Helm/Kustomize，设计环境覆盖方案 | kustomize notes |
| 54 | GitOps | 学习 Argo CD/Flux 的基本思想 | gitops note |
| 55 | GitOps Repo | 设计未来 GitOps 仓库目录结构 | gitops repo design |
| 56 | 周复盘 | 输出 ACK 迁移设计文档 | ack migration design |

## Week 9: Agent 基础与 CI 失败分析

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 57 | Agent 仓库规划 | 创建或设计 `agent-platform` 仓库结构 | agent repo design |
| 58 | 输入输出定义 | 定义 CI failure agent 的输入、输出、限制 | agent contract |
| 59 | 日志解析 | 写一个读取 Actions 日志文本并摘要失败原因的脚本 | log parser |
| 60 | GitHub API | 学习 workflow run、job、log 的 API 数据结构 | github api note |
| 61 | LLM 接入 | 设计模型调用、prompt、工具边界、错误处理 | llm design |
| 62 | 本地 MVP | 完成“输入日志 -> 输出分析”的本地 MVP | ci analyzer mvp |
| 63 | 周复盘 | 完成 `project-04-agent-ci-analyzer` 第一阶段 | project 04 part 1 |

## Week 10: Agent 与 GitHub 集成

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 64 | PR Summary | 设计 PR summary agent，输入 diff，输出摘要和风险点 | pr summary design |
| 65 | Release Agent | 设计 release note agent，输入 commits，输出变更说明 | release agent design |
| 66 | 权限设计 | 设计 Agent token 权限、只读/写评论边界 | agent permission policy |
| 67 | 评论 PR | 实现或伪实现向 PR 评论分析结果 | pr comment demo |
| 68 | Guardrails | 增加敏感信息脱敏、命令白名单、人工确认 | guardrails checklist |
| 69 | Actions 集成 | 用 workflow 调用 Agent 脚本或服务 | agent workflow |
| 70 | 周复盘 | 完成 Agent MVP 演示文档 | agent mvp doc |

## Week 11: 集成、展示与下一阶段

| Day | 主题 | 3 小时任务 | 产出 |
| --- | --- | --- | --- |
| 71 | 端到端梳理 | 串联 CI、镜像、CD、Agent 的完整链路 | e2e diagram |
| 72 | 文档补齐 | 补齐 README、项目说明、运行方式、截图 | final docs |
| 73 | 自测验收 | 按项目验收标准逐项检查 | checklist |
| 74 | 总复盘 | 总结 75 天学习收获、薄弱点和下一阶段 | final review |
| 75 | 下一阶段计划 | 规划 ACK 实战、GitOps、SRE、Agent 深化路线 | next roadmap |

