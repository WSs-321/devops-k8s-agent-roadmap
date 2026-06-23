# week 03 Log

Date: 20260622
Day: Monday

## 本周目标

- 学习 Docker 多阶段构建、健康检查、配置外置、镜像标签
- 拆分 CI workflow，让 Node/docs/基础检查各司其职
- 引入 markdownlint 做文档规范检查
- IDE 工作区配置（autofetch）

## 实际完成

- Day 17：Docker 多阶段构建（AS / COPY --from、优缺点、典型示例）
- Day 18：Docker 健康检查（HEALTHCHECK 参数、容器三状态、K8s 探针对应）
- Day 19：配置外置（环境变量、配置文件挂载、密钥管理服务、kube_config 性质）
- Day 20：镜像标签（latest 陷阱、SHA/semver/环境标签策略、metadata-action）
- CI 拆分：ci-node.yml（app/） / ci-docs.yml（docs/） / ci-basic.yml（基础）
- .markdownlint.json 中文场景配置（关 MD013/MD033/MD041）
- .vscode/settings.json 启用 autofetch + pruneOnFetch
- 文档命名规范：统一 `docker-<主题>.md` kebab-case

## 遇到的问题

- branch protection "Waiting for status to be reported" 误报（CI 实际 success）
- workflow 文件名混乱：hello-actions.yml / node-ci.yml / blank.yml
- 一次 step 里写了两个 uses（语法错误）
- `*.md` vs `**/*.md` 跨目录匹配混淆
- pr 流程不规范，分支直接在旧 feature 分支上提交

## 解决方式

- 关闭 branch protection 确认逻辑，后续再正确配置
- 重命名 workflow 为 ci-<scope>.yml 规范
- 一个 step 只能有一个 uses，分开写
- 用 `**/*.md` 覆盖任意层级
- 每次新功能建新分支 feature_<描述>_<日期>

## 下周计划

- K8s 基础（Day 22-28）：kubectl、Pod/Deployment、Service/Ingress、ConfigMap/Secret、Volume/PV/PVC

## Commit

- 整理 Week 3 学习内容：Docker 4 个文档 + CI 拆分 + IDE 配置
