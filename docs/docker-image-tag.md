# Docker 镜像标签

## 什么是镜像标签

镜像标签是给 Docker 镜像打的"版本号"，跟在镜像名后面用 `:` 分隔。

```text
ghcr.io/user/app:latest
                ^^^^^^ ← 标签（tag）
```

## 常见标签类型

| 标签 | 示例 | 用途 |
|---|---|---|
| `latest` | `myapp:latest` | 最新版本，官方默认 |
| Git commit SHA | `myapp:a1b2c3d` | 精确追溯到某次提交 |
| 短 SHA | `myapp:a1b2c3` | SHA 的前 7 位 |
| 分支名 | `myapp:main` | 跟随分支 |
| SemVer | `myapp:1.2.3` | 语义化版本 |
| 预发布 | `myapp:1.2.3-rc.1` | 测试版本 |
| 时间戳 | `myapp:20260611` | 按时间 |
| 内部构建号 | `myapp:build-456` | CI 编号 |

## `:latest` 的陷阱

### `latest` 到底是什么

```text
:latest = "本地缓存里名字为 latest 的镜像"
```

它不是"最新的镜像"，只是标签叫 latest。

### 常见坑

CI/CD 里用 latest 部署会导致：

```text
- 不知道现在跑的是哪个版本
- 回滚困难（latest 已经指向新版本）
- 不同的环境可能拉取到不同版本
```

## 推荐的标签策略

### 策略 1：commit SHA（最推荐）

```yaml
- uses: docker/build-push-action@v5
  with:
    tags: |
      ghcr.io/${{ github.repository }}/app:${{ github.sha }}
      ghcr.io/${{ github.repository }}/app:latest
```

推送后生成：

```text
ghcr.io/user/app:a1b2c3d4e5f6...   ← 精确到 commit
ghcr.io/user/app:latest            ← 兼容老用法
```

优点：

- 100% 可追溯
- 回滚方便（部署 a1b2c3 而不是 latest）
- 同一个 SHA 在所有环境跑的是同一个镜像

### 策略 2：semver（生产发布）

```yaml
tags: |
  ghcr.io/${{ github.repository }}/app:1.2.3
  ghcr.io/${{ github.repository }}/app:1.2
  ghcr.io/${{ github.repository }}/app:1
  ghcr.io/${{ github.repository }}/app:latest
```

推送 1.2.3 后，多个标签都指向这个镜像：

```text
1.2.3  → 精确版本
1.2    → 最新的 1.2.x
1      → 最新的 1.x
latest → 兜底标签
```

### 策略 3：环境标签

```yaml
tags: |
  ghcr.io/${{ github.repository }}/app:dev-${{ github.sha }}
  ghcr.io/${{ github.repository }}/app:staging-${{ github.sha }}
  ghcr.io/${{ github.repository }}/app:prod-${{ github.sha }}
```

按环境区分。

## 完整示例：用 docker/metadata-action 自动生成标签

```yaml
- uses: docker/metadata-action@v5
  id: meta
  with:
    images: ghcr.io/${{ github.repository }}/app
    tags: |
      # 默认 latest
      type=raw,value=latest,enable={{is_default_branch}}

      # 分支名
      type=ref,event=branch

      # PR
      type=ref,event=pr

      # 完整 commit SHA
      type=sha

      # SemVer（从 git tag 推断）
      type=semver,pattern={{version}}
      type=semver,pattern={{major}}.{{minor}}
      type=semver,pattern={{major}}
```

### 生成的标签

| 触发事件 | 生成的标签 |
|---|---|
| push 到 main | `latest`, `main` |
| push 到 develop | `develop` |
| PR #5 | `pr-5` |
| push commit `a1b2c3` | `a1b2c3` |
| push tag `v1.2.3` | `1.2.3`, `1.2`, `1`, `latest` |

## 设计原则

### 原则 1：可追溯

```text
✅ 任何线上镜像，都能追溯到 commit
❌ 只用 latest、env、dev 看不出对应哪个代码
```

### 原则 2：不可变

```text
✅ 同一 SHA 标签永远指向同一个镜像内容
❌ 同一标签不同时刻指向不同内容
```

GitHub Container Registry 默认就不可变：同一个 tag 重新推送会创建新版本，老的仍然存在。

### 原则 3：环境隔离

```text
✅ dev / staging / prod 用不同标签
❌ 三套环境共用 latest
```

### 原则 4：覆盖范围合理

```text
✅ 一个 commit 一个标签，便于追踪
❌ 一个分支一个 latest，难以回滚
```

## 实战工作流

### 开发阶段

```text
git push origin feature-xxx
  ↓
CI 构建镜像
  ↓
标签：pr-123, a1b2c3d
  ↓
部署到 dev 环境
```

### 测试阶段

```text
PR 合并到 main
  ↓
CI 构建
  ↓
标签：main, a1b2c3d, latest
  ↓
部署到 staging
```

### 发布阶段

```text
git tag v1.2.3
git push origin v1.2.3
  ↓
CI 构建
  ↓
标签：1.2.3, 1.2, 1, latest, a1b2c3d
  ↓
部署到 prod
```

## 标签命名规范

### 合法字符

```text
✅ a-z, 0-9, _, ., -
❌ 大写字母、空格、其他符号
```

### 长度限制

```text
总长度 ≤ 128 字符（OCI 标准）
建议 < 64 字符
```

### 避免的标签

| 不推荐 | 原因 |
|---|---|
| `latest`（生产部署） | 不可追溯 |
| `v1.2.3`（前缀 v） | SemVer 推荐不带 v |
| 时间戳 `2026-06-11` | 看起来精确但易混 |
| 环境名 `prod` | 多次部署会变，难回滚 |

### 推荐组合

```text
生产：1.2.3（semver） + a1b2c3d（sha）
预发：staging-a1b2c3d
开发：dev-a1b2c3d 或 pr-123-a1b2c3d
兜底：latest（仅用于本地快速测试）
```

## 一句话总结

```text
镜像标签 = 镜像的版本号
核心原则：可追溯 + 不可变 + 环境隔离
推荐组合：semver（人看）+ commit SHA（机器追溯）+ latest（兜底）
生产部署不要用 latest，必须能用 SHA 精确指定
```
