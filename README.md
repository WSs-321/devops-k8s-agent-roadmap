# DevOps + GitHub Actions + K8s + Agent Learning Roadmap

这是一个 2.5 个月、每天 3 小时的学习路线仓库。目标是从 GitHub Actions CI/CD 入手，逐步掌握 Docker、制品管理、部署治理、Kubernetes/阿里云 ACK 预备知识，并最终实现一个可落地的 DevOps Agent MVP。

## 学习目标

完成本路线后，你应该具备以下能力：

- 使用 GitHub Actions 为项目建立 CI 流水线。
- 使用 GitHub-hosted runner 完成测试、构建、扫描和制品发布。
- 使用 Docker 和 GHCR 管理镜像制品。
- 使用 GitHub Environments 管理 dev、staging、production 发布流程。
- 理解后续迁移到阿里云 ACK/Kubernetes 的架构路径。
- 设计并实现一个基础 Agent，用于分析 CI 失败、总结 PR、生成发布说明。
- 形成可复用的学习笔记、模板、项目文档和复盘记录。

## 每日节奏

每天 3 小时，建议按下面节奏执行：

| 时间 | 内容 |
| --- | --- |
| 30 分钟 | 阅读文档、课程或源码 |
| 90 分钟 | 动手实验、写 workflow、写代码 |
| 40 分钟 | 调试、记录问题、修正方案 |
| 20 分钟 | 更新学习日志、提交 commit |

## 仓库目录

```text
.
|-- README.md
|-- ROADMAP.md
|-- timetable/
|   |-- 75-day-plan.md
|   `-- weekly-milestones.md
|-- tracks/
|   |-- 01-github-actions-ci.md
|   |-- 02-docker-and-registry.md
|   |-- 03-cd-and-environments.md
|   |-- 04-security-observability.md
|   |-- 05-k8s-ack-prep.md
|   `-- 06-agent-platform.md
|-- projects/
|   |-- project-01-ci-baseline.md
|   |-- project-02-docker-ghcr.md
|   |-- project-03-cd-environments.md
|   |-- project-04-agent-ci-analyzer.md
|   `-- project-05-k8s-ack-design.md
|-- examples/
|   `-- github-actions/
|       |-- node-ci.yml
|       |-- docker-ghcr.yml
|       `-- deploy-with-environments.yml
`-- templates/
    |-- daily-log.md
    |-- weekly-review.md
    |-- release-note.md
    `-- agent-design.md
```

## 推荐学习方式

1. 每天根据 `timetable/75-day-plan.md` 执行任务。
2. 每周结束时填写 `templates/weekly-review.md`。
3. 每完成一个项目，按 `projects/` 中的验收标准自测。
4. 每天至少提交一次 commit，保留学习过程。
5. 第 6 周后开始建立单独的 `agent-platform` 仓库，逐步实现 Agent MVP。

## 最终产出

- 一个 CI/CD 示例业务项目仓库。
- 一个 Agent 平台原型仓库。
- 一套 GitHub Actions workflow 模板。
- 一份从 GitHub Actions 到阿里云 ACK 的迁移设计。
- 一套个人 DevOps 学习笔记和复盘材料。
