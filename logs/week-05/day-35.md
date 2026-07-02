# Daily Log

Date: 2026-07-02
Day: Thursday

## 今日目标

- 完成 Day35 Week5 周复盘与 Project-03 验收
- 检查 CD 与 GitHub Environments 学习成果是否闭环
- 为 Week6 安全、质量、治理主题做准备

## 实际完成

- 更新 `projects/project-03-cd-environments.md` 验收结果
- 对 Week5 的关键产出做归档：
  - dev / staging / production 环境设计
  - repository secrets 与 environment secrets 区分
  - dev / staging / production 部署链路
  - production environment 审批设计
  - `scripts/deploy.sh` 部署入口封装
  - Docker Compose 本地与远程部署示例
  - release note 生成脚本和 release workflow
- 明确 Project-03 当前状态：
  - 已达到基础验收标准
  - 真实上线前仍需配置实际环境、服务器、审批人和 tag 发布策略
- 安排 Week6 学习计划：
  - workflow permissions 最小化
  - Dependabot
  - CodeQL
  - Secret 安全
  - SBOM
  - 分支保护

## 遇到的问题

- 当前项目仍处于学习演练阶段，没有真实服务器，部署链路需要依赖 `DRY_RUN` 模式验证
- production 审批规则无法完全由 YAML 表达，需要在 GitHub Settings 的 Environments 页面配置
- release workflow 已具备结构，但还需要实际 tag 触发验证

## 解决方式

- 在项目验收文件中区分“已完成基础能力”和“真实上线前待补齐内容”
- 明确 GitHub Environment 平台侧配置项：
  - required reviewers
  - deployment branches
  - environment secrets
- 将 Week6 的安全治理任务列为后续改进方向

## 今日收获

- Project-03 的核心不是单个部署 job，而是环境、密钥、审批、部署和发布说明组成的治理闭环
- `DRY_RUN` 对学习阶段很关键，可以在没有真实服务器时保持部署流程可演练
- CD 能力需要和发布说明、commit message 规范联动，才能形成可追踪的发布链路
- 下阶段安全治理需要围绕权限最小化、依赖更新、代码扫描、密钥安全展开

## 明日计划

- 进入 Day36 权限最小化
- 审查 `.github/workflows/*.yml` 的 `permissions` 配置
- 区分 CI、CD、Release workflow 的最小权限需求

## Commit

- `docs: day35项目验收`
