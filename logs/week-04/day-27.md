# Daily Log

Date: 2026-06-27
Day: Saturday

## 今日目标

- 复盘 Week 4 中真实出现的 Docker / GHCR / Trivy workflow 失败
- 不再额外制造 Docker build 失败
- 总结 CI 失败定位和修复方法

## 实际完成

- 复盘 Trivy SARIF 解析相关问题
- 复盘 severity 字段解析不稳定问题
- 复盘最终改用 `msg.text` 提取漏洞等级的处理方式
- 复盘 workflow summary 中 tags / labels 多行输出导致 Markdown 表格断裂的问题
- 复盘 digest、heredoc、job outputs 等多次 workflow 修复
- 将 Day27 从“故意制造失败”调整为“真实失败处理复盘”

## 遇到的问题

- SARIF JSON 结构不适合直接按简单字段读取
- 不同 Trivy 输出字段之间存在差异，导致解析逻辑多次调整
- 多行 outputs 在 GitHub Actions 中跨 job、跨 step 传递时容易造成格式问题
- workflow 修改需要通过 PR 和 Actions 运行结果反复验证

## 解决方式

- 优先基于真实 Actions 日志定位问题
- 小步提交、小步验证，每次只修一个明确问题
- 对多行输出先格式化，再写入 summary
- 对扫描结果解析逻辑增加更贴近实际输出结构的字段读取方式
- 不额外制造失败，避免引入无意义的噪音变更

## 今日收获

- 真实 CI 失败比人为制造失败更有复盘价值
- workflow 调试重点是确认字段来源、执行时机和输出格式
- GitHub Actions 的 step outputs、job outputs、needs outputs 必须逐层确认
- CI 修复适合用短分支、短 PR、短反馈闭环

## 明日计划

- Day28 Week 4 周复盘
- 验收 `project-02-docker-ghcr`
