# week 04 Log

Date: 20260627
Day: Saturday

## 本周目标

- 打通从代码提交到镜像发布的 GHCR 流水线
- 学习 build-push-action、metadata-action、Trivy 的协作方式
- 在 workflow summary 中实现镜像制品追踪
- 完成 project-02-docker-ghcr 验收

## 实际完成

- Day 22：GHCR 登录（GITHUB_TOKEN、packages 权限、docker/login-action）
- Day 23：build-push-action 自动构建并推送镜像，PR 触发时不推送
- Day 24：metadata-action tag/label 策略，区分 DSL 与 GitHub 表达式
- Day 25：Trivy 镜像扫描，build/push 双 job 安全管线，扫描失败阻断推送
- Day 26：workflow summary 输出镜像名称、tags、labels、digest 和 Trivy 状态
- Day 27：基于真实 workflow 失败做复盘，不再额外制造 Docker build 失败
- ci-docker.yml 拆分 build-docker-image / push 两个 job，用 job outputs 传递元数据

## 遇到的问题

- metadata-action DSL `{{ }}` 与 GitHub 表达式 `${{ }}` 混用
- Trivy 默认扫远端 GHCR，build 阶段 push: false 时远端无镜像
- 多行 tags / labels 写入 Markdown 表格导致断表
- digest 需从 push step 输出读取，不能从 build job 推断
- SARIF / severity 字段解析不稳定，多次调整

## 解决方式

- 明确两套表达式边界：DSL 管 tag/label 模板，GitHub 表达式读上下文/secrets/outputs
- build job 改 push: false + load: true，Trivy 扫本地镜像，无需 registry 认证
- 多行 tags / labels 转 `<br>` 后再写入 summary 表格
- 用 needs.X.outputs 与 steps.push.outputs.digest 分层读取
- 最终改用 msg.text 提取漏洞等级，小步 PR 逐个修复

## 本周收获

- 理解了 GHCR 镜像发布完整链路
- 掌握了 tags / labels / digest 三个制品追踪核心字段
- 掌握了 Trivy 在 CI 中的基础漏洞门禁用法
- 理解了 step outputs / job outputs / needs outputs 三层数据流
- 建立了 CI 失败定位、小步修复、验证的闭环

## 下周计划

- Week 5：CD 与 GitHub Environments（Day 29-35）
- dev/staging/production 环境设计、secrets 隔离、人工审批、部署脚本、release notes

## Commit

- 整理 Week 4 学习内容：GHCR 登录 + 镜像流水线 + Trivy 扫描 + 制品追踪
