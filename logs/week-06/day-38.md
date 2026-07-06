# Daily Log

Date: 2026-07-06
Day: Monday

## 今日目标

- 完成 Day38 CodeQL 代码扫描学习
- 配置 `.github/workflows/codeql.yml`，实现代码安全扫描

## 实际完成

- 学习 CodeQL 与 Dependabot/Trivy 的区别
  - Dependabot：检查依赖版本是否有已知漏洞
  - Trivy：扫描镜像里的系统包和依赖
  - CodeQL：分析自己写的源码逻辑是否有漏洞
- 理解 CodeQL 工作原理
  - 构建代码数据库 → 运行 QL 查询 → 生成 SARIF → 上传到 GitHub Security tab
- 新增 `.github/workflows/codeql.yml`
  - 扫描语言：javascript
  - 触发：push main + PR main + 每周一 cron
  - 权限：`contents: read` + `security-events: write`
  - 三个 step：checkout → init → analyze
- 理解 CodeQL 对 JS 不需要 `npm ci` 或 build 步骤
  - 编译型语言（C++/Java/Go）需要 build
  - JS/Python 直接解析源码，不需要安装依赖
- 理解 `analyze` step 自动上传 SARIF，不需要手动配 `upload-artifact`
- 理解 job ID 和 name 的区别
  - `codeql:` 是 job ID，给 workflow 内部引用用
  - `name: CodeQL` 是显示名，给 GitHub Actions UI 展示用
- 理解 CodeQL 没有 `directory` 配置，默认扫描整个 checkout 的仓库

## 遇到的问题

- 对 CodeQL 是否需要 `npm ci` 有疑问
  - JS 不需要，CodeQL 直接读源码
- 对 CodeQL 的产物和上传方式有疑问
  - `analyze` step 内置上传，不需要手动 `upload-sarif`
- 对 job ID 和 name 两个字段的关系有疑问
  - ID 是技术标识，name 是显示名

## 解决方式

- 查阅 CodeQL 官方文档确认 JS 不需要 build
- 确认 `analyze` = 扫描 + 上传，合二为一
- 对比 cd-deploy.yml 的 `deploy-dev` / `name: Deploy to Dev` 理解 ID vs name

## 今日收获

- CodeQL 是源码级静态分析，和依赖扫描/镜像扫描互补
- CodeQL workflow 的 `permissions` 必须有 `security-events: write`，否则无法上传结果
- JS 项目的 CodeQL workflow 最简三步：checkout → init → analyze
- 扫描结果在 仓库 Security → Code scanning alerts 查看
- `schedule` 定时扫描的意义：CodeQL 查询规则会更新，即使代码没变也能发现新漏洞

## 明日计划

- Day39 Secret 安全

## Commit

- `ci: day38配置codeql扫描`
