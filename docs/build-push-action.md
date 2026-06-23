# docker/build-push-action（概念笔记）

> Day 23 概念总结。**本文件不含实例**，只列概念点。
> 实例（workflow / 参数示例 / cache 调试）由作者另行整理到 `examples/` 或对应工作流文件。

## 1. 解决的问题

- 不支持 buildx 多平台 → 出不了 arm64 镜像。
- 不支持 layer 缓存 → 每次重头构建。
- 不支持 metadata 多 tag → 一次只能推一个 tag。
- 不支持 provenance / SBOM → 合规接不进。
- `docker/build-push-action` 把以上能力封装成一个 step。

## 2. buildx 与 BuildKit 的关系

- `buildx`：Docker 的 CLI 前端。
- BuildKit：真正干活的构建引擎。
- Docker 默认构建方式演进：
  - 19.03：`buildx` 是实验插件，需单独装。
  - 20.10：内置 buildx，但仍不是默认，要 `DOCKER_BUILDKIT=1` 才用。
  - 23.0：BuildKit 取代 classic builder 成为默认。
  - 25.0：classic builder 完全移除。
- `build-push-action` 内部隐式调用 buildx / setup-buildx / setup-qemu。
- 23.0 起 `docker build` 底层就是 buildx。

## 3. action 关键参数（概念层）

- `context`：构建根目录，不是 Dockerfile 所在目录。
- `file`：Dockerfile 路径，相对 `context`。
- `push`：是否推到 registry。
- `tags`：镜像 tag，支持多值。
- `platforms`：多平台目标。
- `cache-from` / `cache-to`：缓存来源 / 写入。
- `provenance`：SLSA provenance 开关。
- `sbom`：生成 SBOM 开关。
- `labels`：OCI 标签。
- `build-args` / `secrets`：传给 Dockerfile 的构建参数 / 密钥。
- `outputs`：额外输出（如 tar 包）。
- `no-cache`：调试用，跳过缓存。

## 4. 缓存策略

- GHA 内置缓存：`type=gha`。
- 第一次跑：`cache-from` 找不到，`cache-to` 写入。
- 第二次跑同分支：命中缓存，秒级完成。
- `mode=max` 缓存中间层（最快）、`mode=min` 只缓存最终层（省空间）。
- `cache-from` 和 `push` 是独立参数：PR 阶段不推包但仍能命中缓存。
- 缓存按 `context` + `Dockerfile` 内容计算 key，不冲突就能复用。

## 5. PR 防推送的安全模式

- 表达式：`push: ${{ github.event_name != 'pull_request' }}`。
- 含义：只有非 PR 触发才推，PR 阶段只构建不推。
- 目的：
  - 避免把未合并代码推到 GHCR。
  - 防御外部 fork PR 的恶意代码注入。
- 配套：`on:` 里要列 `pull_request`。
- 行为差异：PR 阶段 `push: false` 会把镜像 load 到本地（可继续 smoke test），不会上传。

## 6. 与 metadata-action 的关系

- `metadata-action` 算 tag 列表，输出在 `steps.meta.outputs.tags` / `labels`。
- `build-push-action` 读这些输出作为自己的 `tags` / `labels` 入参。
- 数据流方向决定 step 顺序：metadata 必须在 build-push 之前。
- ${{ }} 表达式是字符串替换 + DAG 消费：前置 step 的 outputs 才能被后置 step 读到。

## 7. 多平台构建（buildx + QEMU）

- `platforms: linux/amd64,linux/arm64` 一行开启。
- QEMU：CPU 模拟器，让 amd64 runner "假装"成 arm64。
- 第一次慢的原因：
  - 拉 BuildKit 镜像。
  - QEMU 翻译指令。
  - 拉多份基础镜像。
  - 无缓存。
- 第二次命中缓存会快很多。
- 多平台产物是 1 个 manifest list 指向 N 个架构镜像，tag 本身不变。

## 8. 架构取舍

- ACK / 阿里云 ECS：多 amd64。
- 边缘网关 / Graviton / Apple Silicon：需要 arm64。
- 单平台 `linux/amd64` → CI 更快。
- 多平台 `linux/amd64,linux/arm64` → CI 时间翻倍，但覆盖更广。

## 9. provenance vs SBOM（埋点，Day 25 细讲）

- `provenance`：记录"这个镜像是怎么构建出来的"（SLSA 标准）。
- `sbom`：镜像里装了什么软件、什么版本。
- 都需要 `attestations: write` 权限。

## 10. 与 Day 22 的衔接

- Day 22 学"身份 + 登录"：怎么拿到推包权限。
- Day 23 学"用权限推包"：怎么构建、缓存、推多 tag。
- Day 24 学"打什么 tag"：metadata-action 的 tag 策略学。
- Day 25 学"安全扫描"：provenance / SBOM / Trivy 扫描。
