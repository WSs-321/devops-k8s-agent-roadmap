# Daily Log

Date: 2026-07-07
Day: 42

## 今日目标

- 完成 Day 42 Week 6 周复盘
- 输出 CI/CD 安全基线文档

## 实际完成

- 整理 Week 6 全部六天（Day 36-41）学习成果
- 新增 `docs/security-baseline.md` CI/CD 安全基线文档
  - 安全全景图（从权限最小化到分支保护的六层防护）
  - 六个主题各自的原则、配置、检查清单
  - 安全防护矩阵（防线 x 覆盖范围）

## Week 6 回顾

### 学到什么

| Day | 主题 | 一句话 |
| --- | --- | --- |
| 36 | 权限最小化 | 每个 workflow 显式声明 permissions，不给默认写权限 |
| 37 | Dependabot | npm + actions + docker 三 ecosystem 自动更新，major 单独审查 |
| 38 | CodeQL | JS 源码静态分析，checkout → init → analyze 三步搞定 |
| 39 | Secret 安全 | 创建最小权限、使用不打印、派生值不脱敏、pull_request_target 是深坑 |
| 40 | SBOM | 扫镜像不扫源码，SPDX 格式，独立 workflow 解耦 |
| 41 | 分支保护 | PR + CI green + approve 三道防线，squash merge 保持 main 干净 |

### 产出清单

- `docs/secret-checklist.md`：Secret 安全规范（Day 39）
- `docs/security-baseline.md`：CI/CD 安全基线（Day 42，本周汇总）
- `ci: day36权限最小化`：补齐 ci-basic、ci-docs 的 permissions
- `ci: day37配置dependabot`：新增 .github/dependabot.yml
- `ci: day38配置codeql扫描`：新增 .github/workflows/codeql.yml
- `docs: day39密钥安全规范`：上述 Secret 文档
- `ci: day40添加sbom生成workflow`：新增 .github/workflows/sbom.yml
- `feat: Day41 分支保护规则笔记`：分支保护笔记

### 收获最大的三个点

1. **权限最小化**：以前没注意过 permissions 字段，现在知道不写是"继承默认"，写了才是"最小"
2. **Secret 脱敏边界**：派生值不脱敏这个认知很重要，base64/截取/写文件都不能用
3. **workflow_run 不能做 required check**：这个结论影响架构决策，之前没意识到

### 仍薄弱的地方

- Dependabot 的 auto-merge 自动化（目前手动审查，可以加条件自动合并 minor/patch）
- CodeQL 的 QL 查询语言（只会用默认规则，不会自定义查询）
- SBOM 的消费侧（生成后如何做持续审计和漏洞关联）

## 明日计划

- 进入 Week 7：Kubernetes 基础
- Day 43：学习 Pod、Deployment、Service、Namespace 概念

## Commit

- `docs: day42周复盘输出CI/CD安全基线`
