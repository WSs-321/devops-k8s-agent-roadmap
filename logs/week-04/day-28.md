# Daily Log

Date: 2026-06-27
Day: Saturday

## 今日目标

- 完成 Week 4 周复盘
- 验收 `project-02-docker-ghcr`
- 总结 GHCR 镜像流水线的完整链路

## 实际完成

- 完成 GHCR 登录学习
- 完成 build-push-action 自动构建与推送
- 完成 metadata-action tag / label 生成
- 完成 Trivy 镜像扫描接入
- 完成 workflow summary 制品追踪
- 基于真实失败完成 CI / Docker workflow 复盘
- 形成从代码提交到镜像发布、扫描、追踪的完整流水线

## Week 4 验收项

- [x] 使用 `GITHUB_TOKEN` 登录 GHCR
- [x] 使用 build-push-action 构建并推送镜像
- [x] 使用 metadata-action 生成镜像 tags 和 labels
- [x] 使用 Trivy 扫描镜像漏洞
- [x] 在 workflow summary 中输出镜像名称、tags、labels、digest 和扫描结果
- [x] 处理真实 workflow 失败并完成复盘
- [x] 完成 `project-02-docker-ghcr` 基础验收

## 遇到的问题

- GHCR 登录、metadata-action、build-push-action、Trivy 之间的数据流较复杂
- 多行 tags / labels 输出容易影响 Markdown summary 展示
- Trivy 扫描结果解析需要结合实际 SARIF 输出结构
- workflow 的错误往往发生在运行时，不能只靠静态检查发现

## 解决方式

- 将 workflow 拆分为 build 和 push 两个 job
- 使用 job outputs 在不同 job 之间传递镜像元数据
- 使用 Trivy 做基础漏洞门禁
- 使用 `$GITHUB_STEP_SUMMARY` 汇总发布制品信息
- 对真实失败采用小步 PR 修复方式逐个解决

## 本周收获

- 理解了 GHCR 镜像发布链路
- 掌握了 Docker 镜像 tags、labels、digest 的追踪方式
- 掌握了 Trivy 在 CI 中的基础用法
- 理解了 GitHub Actions 多 job 数据传递方式
- 建立了 CI 失败定位、修复、验证的基本闭环

## 下周计划

- 进入 Week 5：CD 与 GitHub Environments
- 学习 dev / staging / production 环境设计
- 学习 repo secrets 与 environment secrets 的区别
- 开始设计部署 job 和审批流程
