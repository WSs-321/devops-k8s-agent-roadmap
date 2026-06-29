# Daily Log

Date: 2026-06-27
Day: Saturday

## 今日目标

- 完成 Day26 发布制品追踪
- 在 GitHub Actions workflow summary 中输出镜像地址、版本、digest 和 Trivy 扫描状态
- 让 Docker 镜像发布结果具备可追溯性

## 实际完成

- 改造 `.github/workflows/ci-docker.yml` 的 summary 输出
- 在 push job 中输出 Docker Image Summary：
  - Image Name
  - Tags
  - Labels
  - Digest
- 在 summary 中补充 Trivy Scan Results：
  - Total vulnerabilities
  - Critical vulnerabilities
  - High vulnerabilities
  - Status
- 修复多行 tags / labels 写入 Markdown 表格导致断表的问题
- 修复 digest 输出来源和 heredoc 写法问题
- 通过多次 PR 小步修正 workflow summary 展示效果

## 遇到的问题

- `metadata-action` 输出的 tags / labels 是多行字符串，直接放入 Markdown 表格会破坏表格结构
- digest 需要从 push step 输出读取，不能从 build job 推断
- workflow summary 同时包含镜像信息和扫描信息时，字段来源容易混淆
- 多 job 之间传递 outputs 时，需要明确区分 step outputs、job outputs 和 needs outputs

## 解决方式

- 将多行 tags / labels 转换为 `<br>` 后再写入 summary 表格
- 使用 `needs.build-docker-image.outputs.*` 读取上游 job 输出
- 使用 `steps.push.outputs.digest` 读取实际推送后的镜像 digest
- 将镜像追踪信息和 Trivy 扫描结果统一展示在 `$GITHUB_STEP_SUMMARY`

## 今日收获

- workflow summary 适合作为 CI/CD 制品追踪入口
- 多行字符串写入 Markdown 表格前需要格式化
- 镜像 tag、label、digest 是发布追踪的三个核心字段
- digest 比 tag 更适合作为不可变制品标识

## 明日计划

- Day27 不再额外制造 Docker build 失败
- 基于真实 workflow 失败案例做复盘
