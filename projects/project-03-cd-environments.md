# Project 03: CD With GitHub Environments

## 目标

使用 GitHub Environments 实现 dev/prod 发布治理。

## 任务

- 创建 dev environment。
- 创建 production environment。
- 为 production 配置 required reviewers。
- 写 deploy workflow。
- dev 自动执行。
- production 需要审批。
- 发布日志输出版本信息。

## 验收标准

- dev job 可以自动执行。
- production job 会等待审批。
- environment secrets 不混用。
- 发布记录中包含 commit sha 和镜像 tag。

