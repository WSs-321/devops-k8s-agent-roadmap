# SBOM 入门笔记

## 1. SBOM 是什么

**SBOM（Software Bill of Materials）**：软件物料清单，一份"这个软件里包含什么"的完整清单。

### 类比

就像食品包装上的配料表：

```text
食品包装：
  配料：小麦粉、水、盐、酵母、防腐剂(E282)
  过敏原：含麸质

SBOM：
  组件：express@4.18.0、body-parser@1.20.0
  漏洞：body-parser@1.20.0 有 CVE-2024-xxxx
  许可证：MIT、Apache-2.0
```

## 2. SBOM vs SWBOM

**SWBOM 不是标准术语**，可能就是 SBOM 的另一种写法：

```text
SBOM  = S(oftware) + BOM
SWBOM = SW(software) + BOM
```

两者指同一个东西，SBOM 是官方标准写法。

### 其他 BOM 类型

| 术语 | 全称 | 说明 |
| --- | --- | --- |
| SBOM | Software Bill of Materials | 软件物料清单（标准） |
| HBOM | Hardware Bill of Materials | 硬件物料清单（制造业） |
| CBOM | Cryptographic Bill of Materials | 加密算法清单 |
| SaaSBOM | SaaS Bill of Materials | 云服务依赖清单 |
| ML-BOM | ML Bill of Materials | 机器学习模型清单 |

## 3. SBOM 包含什么

| 字段 | 示例 |
| --- | --- |
| 组件名 | `express` |
| 版本 | `4.18.0` |
| 许可证 | `MIT` |
| 下载地址 | `https://npmjs.com/package/express` |
| 哈希值 | `sha256:abc123...` |
| 依赖关系 | express 依赖 body-parser |
| 供应商 | `npm` |

## 4. 两大标准格式

### SPDX（Software Package Data Exchange）

- **来源**：Linux 基金会
- **侧重**：法律合规，许可证追踪
- **格式**：JSON / RDF / TAGS

```json
{
  "SPDXID": "SPDXRef-Package-express",
  "name": "express",
  "versionInfo": "4.18.0",
  "licenseConcluded": "MIT",
  "downloadLocation": "https://npmjs.com/package/express"
}
```

### CycloneDX

- **来源**：OWASP
- **侧重**：安全，漏洞关联
- **格式**：JSON / XML

```json
{
  "bomFormat": "CycloneDX",
  "components": [
    {
      "type": "library",
      "name": "express",
      "version": "4.18.0",
      "licenses": [{"license": {"id": "MIT"}}],
      "purl": "pkg:npm/express@4.18.0"
    }
  ]
}
```

### 对比

| 维度 | SPDX | CycloneDX |
| --- | --- | --- |
| 来源 | Linux 基金会 | OWASP |
| 侧重 | 法律合规 | 安全 |
| 格式 | JSON/RDF/TAGS | JSON/XML |
| 漏洞关联 | 弱 | 强（有 VEX） |
| 工具支持 | 广 | Trivy/Syft 默认 |

## 5. VEX（Vulnerability Exploitability eXchange）

**漏洞可利用性声明**：告诉你"虽然有 CVE，但你的场景不受影响"。

```text
SBOM 说：你用了 log4j@2.14.0
CVE 库说：log4j@2.14.0 有 CVE-2021-44228（Log4Shell）
VEX 说：你的应用不用 JNDI，不受影响 ✅
```

### SBOM + VEX = 完整安全画像

```text
SBOM  → 我用了什么
CVE   → 这些东西有什么漏洞
VEX   → 这些漏洞对我有没有影响
```

## 6. 生成 SBOM 的工具

| 工具 | 来源 | 格式 | 特点 |
| --- | --- | --- | --- |
| Syft | Anchore | SPDX / CycloneDX | 专做 SBOM，速度快 |
| Trivy | Aqua | SPDX / CycloneDX | 已有，`--format cyclonedx` |
| cyclonedx-cli | OWASP | CycloneDX | 官方工具 |
| spdx-tools | Linux 基金会 | SPDX | 官方工具 |

### 用 Trivy 生成 SBOM

```bash
# 生成 CycloneDX 格式
trivy fs --format cyclonedx -o sbom.json .

# 生成 SPDX 格式
trivy fs --format spdx-json -o sbom.spdx.json .
```

## 7. SBOM 在 CI/CD 中的位置

```text
┌────────────────────────────────────────┐
│  CI 阶段                                │
│  ├─ lint / test                         │
│  ├─ build image                         │
│  ├─ Trivy 扫镜像 CVE     ← 已有         │
│  └─ Trivy 生成 SBOM      ← 待加         │
├────────────────────────────────────────┤
│  CD 阶段                                │
│  └─ 部署时附带 SBOM（合规要求）          │
├────────────────────────────────────────┤
│  运维阶段                                │
│  └─ 新 CVE 爆出时，查 SBOM 看是否受影响  │
└────────────────────────────────────────┘
```

## 8. SBOM vs Trivy 漏洞扫描

| 维度 | SBOM | Trivy 漏洞扫描 |
| --- | --- | --- |
| 回答什么 | 我用了什么 | 我用的东西有没有漏洞 |
| 输出 | 依赖清单 | 漏洞列表 |
| 时间点 | 构建时 | 构建时 + 定期 |
| 关系 | SBOM 是基础 | 扫描基于 SBOM |

**Trivy 内部就生成了 SBOM**，默认只输出漏洞结果。加 `--format cyclonedx` 就能看到完整的 SBOM。

## 9. 为什么需要 SBOM

| 场景 | 没 SBOM | 有 SBOM |
| --- | --- | --- |
| Log4Shell 爆发 | 翻所有项目查 log4j | 搜 SBOM，秒查 |
| 合规审计 | 手动整理依赖 | 直接交 SBOM |
| 许可证检查 | 手动看 package.json | SBOM 自动报 |

## 10. 后续实操计划

- 在 `ci-docker.yml` 中新增 SBOM 生成步骤
- 生成 CycloneDX 格式 SBOM 并上传为 artifact
- 可选：上传到 GitHub Dependency Graph
