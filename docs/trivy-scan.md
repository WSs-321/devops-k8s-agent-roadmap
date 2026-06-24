# Trivy 镜像扫描（概念笔记）

> Day 25 概念总结。**本文件不含实例**，只列概念点。
> 实例（workflow 集成 / SARIF 上传 / 修复演练）由作者另行整理到对应 workflow 文件。

## 1. Trivy 是什么

- Aqua Security 开源的全能安全扫描器，Go 写，单文件零依赖。
- 扫容器镜像、应用依赖、IaC 配置、SBOM。
- 输出 table / json / sarif 多种格式。
- 首次拉漏洞库约 30s，之后秒级。

## 2. 扫描原理

- 第一轮：解压镜像层，识别已装组件（apk / dpkg / rpm + npm / pip / Java JAR / Go modules）。
- 第二轮：组件 + 版本号匹配漏洞库（NVD / Alpine SecDB / Debian OVAL / GitHub Advisory）。
- 结果按严重等级分类。

## 3. 漏洞分级

- CRITICAL：应立即修复，默认阻塞。
- HIGH：应尽快修复，默认阻塞。
- MEDIUM：评审后处理，通常不阻塞。
- LOW：低风险，通常不阻塞。
- UNKNOWN：无明确评级。

## 4. 关键参数

- `image-ref`：扫的镜像 tag。
- `format`：table / json / sarif。
- `exit-code: 1`：发现漏洞时让 job 失败。
- `ignore-unfixed: true`：忽略尚无补丁的漏洞。
- `vuln-type: os,library`：扫 OS 包和应用库。
- `severity: CRITICAL,HIGH`：哪些级别触发失败。
- `timeout: 10m`：扫描超时上限。
- `scanners: vuln,misconfig,secret`：分别对应漏洞 / 配置 / 密钥扫描。
- `output: trivy-results.sarif`：结果文件路径。
- `registry-username` / `registry-password`：扫私有 registry 时必填。

## 5. 扫描位置策略

- **本地镜像扫**：build-push-action 加 `load: true`，扫 runner daemon 里的本地镜像，不需要 registry 认证。
- **GHCR 远端扫**：build 推完后再 scan，必须配 registry 用户名密码。
- 推荐：build job `push: false` + `load: true` 扫本地，扫通过后由独立 push job 推到 GHCR。

## 6. SARIF 与 GitHub Security

- Trivy 用 `format: sarif` + `output:` 生成 SARIF 文件。
- 通过 `github/codeql-action/upload-sarif@v3` 上传到 GitHub Security UI。
- 需要 workflow 顶部声明 `permissions: security-events: write`。
- 上传 step 用 `if: always()`：扫描失败也上传结果，便于复盘。

## 7. Trivy 命令家族

- `trivy image`：扫镜像。
- `trivy fs`：扫文件系统（Dockerfile + 应用依赖）。
- `trivy config`：扫 IaC（K8s YAML / Terraform）。
- `trivy repo`：扫 Git 仓库。
- `trivy sbom`：生成 SBOM。

## 8. 漏洞修复路径

- 方法 A：升级基础镜像（最简单，覆盖面广）。
- 方法 B：构建期 `apk upgrade` / `apt-get upgrade` 给单包打补丁。
- 方法 C：删除不必要的工具（curl / wget / 编译器）减少攻击面。
- 方法 D：忽略短期无补丁的漏洞（用 `.trivyignore` 或 `ignore-unfixed`）。

## 9. 单平台扫 vs 多平台扫

- OS 漏洞 / 依赖漏洞跟 CPU 架构无关，**单平台扫覆盖所有架构**。
- 生产推荐：build job 单平台扫 + push job 多平台推。
- `load: true` 不支持多平台镜像，所以 build 阶段必须单平台。
- 替代方案：`outputs: type=docker,dest=tar` 导出 tar 让 Trivy 用 `input:` 参数扫。

## 10. workflow 整体编排（build + push 双 job）

- build job：`push: false` + `load: true` + Trivy 扫 + SARIF 上传。
- build job 顶部 `outputs:` 暴露 tags / labels / version。
- push job：`needs: build-docker-image` + `push: true` + 多平台。
- 失败传播：build job 失败（Trivy 阻断）→ push job skip → 不推有漏洞镜像。
- cache 两个 job 都加 `cache-from: type=gha` / `cache-to: type=gha,mode=max`。
- 两个 job 都建议 `setup-buildx-action` 显式声明，保持一致性。
