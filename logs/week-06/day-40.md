# Daily Log

Date: 2026-07-07
Day: 40

## 今日目标

- 完成 Day 40 SBOM 入门学习
- 了解 SBOM 概念与三大标准
- 掌握 Syft/Trivy 生成 SBOM 的方法
- 在 GitHub Actions 中集成 SBOM 生成

## 实际完成

- 新增 `.github/workflows/sbom.yml` SBOM 生成 workflow
  - 触发：`workflow_run` 监听 `docker CI` 完成事件
  - 使用 `anchore/sbom-action@v0` 扫描 GHCR 镜像
  - 输出 SPDX JSON 格式 SBOM
  - 上传为 workflow artifact

## 关键概念

- **SBOM**（Software Bill of Materials）：软件物料清单，精确列出所有组件、依赖、版本和许可证
- **SPDX**：Linux Foundation 主导，ISO/IEC 5962 标准，许可证合规场景首选
- **CycloneDX**：OWASP 主导，安全导向，Web 工具生态好
- **SWID**：NIST 标签标准，政府采购用，CI/CD 中较少直接使用
- SBOM ≠ 漏洞扫描，SBOM 是"清单"，漏洞扫描是"核对清单找问题"
- 每次构建都应生成 SBOM，作为 artifact 附在 release 上

## Syft 常用命令

```bash
# 扫描本地目录
syft .

# 扫描 Docker 镜像
syft node:18-alpine

# 输出 SPDX JSON
syft node:18-alpine -o spdx-json > sbom.spdx.json

# 输出 CycloneDX
syft node:18-alpine -o cyclonedx-json > sbom.cdx.json
```

## SBOM 三种使用场景

| 场景 | 说明 |
| --- | --- |
| 合规审计 | CI 生成 spdx.json → 归档 → 客户/监管审查时直接交付 |
| 漏洞响应 | Trivy DB 更新 → 交叉比对 SBOM → 自动告警受影响组件 |
| 准入控制 | K8s admission webhook → 检查镜像 SBOM → 禁止含风险许可证的镜像进入生产 |

## 方案对比

### 扫描对象：源码 vs 镜像

| 维度 | `path: ./`（源码） | `image: <镜像名>`（镜像） |
| --- | --- | --- |
| 覆盖范围 | 仅声明依赖（package.json 等） | 完整镜像层，含基础镜像系统包 |
| 是否需要 build | 否 | 是（需先构建并推送镜像） |
| 准确性 | 可能漏报基础镜像自带组件 | 反映最终运行时真实组成 |
| 适用场景 | 快速依赖审计 | 合规审计 / 漏洞响应 |

结论：**选镜像扫描**，覆盖范围更全。

### 工作流架构：独立 workflow vs 合并到 docker workflow

| 维度 | `workflow_run` 串联 | 合并到 `ci-docker.yml` |
| --- | --- | --- |
| 触发条件 | 仅默认分支生效 | 所有分支均可触发 |
| 调试难度 | 高（看不到联动日志） | 低（同 workflow 内可见） |
| 维护性 | 解耦，各自独立 | 单文件，逻辑集中 |
| 镜像来源 | 从 GHCR pull | 直接用本地 docker cache |
| 执行时间 | 多一次 pull 开销 | 无额外网络开销 |

结论：**选独立 workflow**（本次选择），关注点分离。

### 镜像获取方式：registry pull vs 本地 tar

| 维度 | `image:` 从 Registry 拉 | `path:` 指向 docker save tar |
| --- | --- | --- |
| 实现方式 | `image: ghcr.io/xx/app:latest` | `docker save -o image.tar` + `path: image.tar` |
| 存储开销 | 无本地文件 | tar 文件占用 runner 磁盘 |
| 前置依赖 | 镜像必须已 push | 镜像在本地 docker daemon |
| 适用场景 | `workflow_run` 解耦架构 | 同 workflow 内 build 完即扫 |

结论：**选 registry pull**，配合 `workflow_run` 架构自然契合。

## 遇到的问题

- `workflow_run` 引用的 workflow 名必须与目标 workflow 的 `name:` 字段完全一致
- `uses:` 和 `run:` 不能同时存在于同一个 step
- Docker 镜像引用中不能出现两个冒号（如 `repo:app:latest` 非法）
- `$GITHUB_OUTPUT` 是 step 间传值的标准方式，不能随意改成其他变量名
- `upload-artifact@v3` 已废弃，必须升级到 v4

## 解决方式

- 修正 `workflows: ["docker CI"]` 匹配 `ci-docker.yml` 的实际 name
- 将镜像名计算拆为独立 `run` step，使用 `$GITHUB_OUTPUT` 输出
- 镜像名使用 `steps.image.outputs.name:latest` 单冒号格式
- 修复 `use:` → `uses:` 拼写错误
- 升级 `upload-artifact@v3` → `v4`

## 今日收获

- SBOM 的核心价值是"5 分钟内回答用了什么组件"，应对 Log4Shell 级漏洞时至关重要
- 扫描镜像比扫描源码目录更完整，能覆盖基础镜像的系统包
- `anchore/sbom-action@v0` 是最便捷的 GHCR 镜像 SBOM 生成方案
- SBOM 文件本身是 JSON，可以挂 artifact 也可以进 Git 归档
- SPDX JSON 是合规首选格式，CycloneDX JSON 是安全平台对接首选

## 明日计划

- Day 41 分支保护：设计 main 分支保护规则和合并策略

## Commit

- `feat: Day40 SBOM 入门笔记与workflow`
