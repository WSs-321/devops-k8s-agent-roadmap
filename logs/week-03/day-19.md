# Daily Log

Date: 20260620
Day: Saturday

## 今日目标

- 学习 12-Factor App 配置外置
- 拆分 CI workflow

## 实际完成

- 输出 docs/docker-config.md（环境变量、配置文件挂载、密钥管理服务）
- 明确 kube_config.key 是数据，不是密钥管理服务
- 拆分 CI：ci-node.yml（app/） / ci-docs.yml（docs/） / ci-basic.yml（基础）
- 新增 .markdownlint.json 配置
- 文档命名规范统一为 docker-<主题>.md
- 新增 .vscode/settings.json 启用 autofetch

## 遇到的问题

- workflow 文件名混乱
- 一个 step 写了两个 uses（语法错误）
- `*.md` vs `**/*.md` 跨目录匹配混淆

## 解决方式

- 重命名为 ci-<scope>.yml
- 一个 step 一个 uses
- 用 `**/*.md` 覆盖任意层级

## 明日计划

- Day 20 学习镜像标签策略

## Commit
