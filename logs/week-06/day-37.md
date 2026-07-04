# Daily Log

Date: 2026-07-04
Day: Saturday

## 今日目标

- 完成 Day37 Dependabot 学习
- 配置 `.github/dependabot.yml`，实现依赖自动更新

## 实际完成

- 学习 Dependabot 两种更新模式
  - version updates：定期检查依赖新版本
  - security updates：发现已知漏洞自动开 PR
- 新增 `.github/dependabot.yml`，配置 3 个 ecosystem：
  - npm：扫描 `/app/package.json`，weekly 检查，groups 合并 minor/patch
  - github-actions：扫描 workflow 里的 `uses:`，weekly 检查
  - docker：扫描 `app/Dockerfile` 里的 `FROM`，weekly 检查
- 理解 `package-ecosystem` + `directory` 的组合决定扫描什么文件
- 理解 `groups` 分组更新：minor/patch 合并一个 PR，major 单独 PR
- 理解 YAML 锚点的适用场景和局限：labels 是列表会被覆盖，不适合放锚点

## 遇到的问题

- 最初以为 package.json 里有 express 和 jest，实际只有 eslint 和 @eslint/js
- 对 `github-actions` 的 directory 写法有疑问：`/.github` 和 `/` 的区别
  - 官方推荐 `/`，因为 github-actions 只扫描 `.github/workflows/`
- 对 YAML 锚点合并 labels 的行为有疑问
  - `<<` 合并只对 map 有效，list 会被整体覆盖

## 解决方式

- 读 package.json 确认实际依赖
- `github-actions` 的 directory 改为 `/`
- 锚点只放 schedule 和 open-pull-requests-limit，labels 和 groups 各自写

## 今日收获

- Dependabot 通过 `package-ecosystem` + `directory` 精确定位依赖文件
- npm 查 npm registry、github-actions 查 GitHub releases、docker 查 Docker Hub
- `groups` 能把多个 minor/patch 更新合并成一个 PR，减少 PR 噪音
- major 版本不放进分组，单独 PR 审查，避免 breaking change 混入
- YAML 锚点对列表是覆盖不是追加，不能用来复用 labels

## 明日计划

- Day38 CodeQL 代码扫描

## Commit

- `ci: day37配置dependabot`
