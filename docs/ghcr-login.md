# GHCR 登录

本文整理 Day 22 主题：GitHub Container Registry（GHCR）登录机制、`GITHUB_TOKEN` 权限边界、以及常见登录失败排查。

## 1. 什么是 GHCR

GHCR = **GitHub Container Registry**，地址是 `ghcr.io`，是 GitHub 官方提供的容器镜像仓库。

- 跟 GitHub Packages 同源，但**只存 OCI/Docker 镜像**。
- 镜像仓库路径：`<package-type>/<owner>/<repo>:<tag>`，其中 `package-type` 通常是容器本身，但默认路径在 push 时会自动判断；显式写法常用 `ghcr.io/<owner>/<repo>`。
- 跟 Docker Hub 比，最大差别：
  - 复用 GitHub 身份（同一个 PAT/GITHUB_TOKEN 就能 push）。
  - 免费层配额按 GitHub 计划走（Public 仓库免费无限，Private 按存储+带宽计费）。
  - 与 repo 直接绑定，权限沿用 repo collaborator / org member 体系。

## 2. 登录身份：GITHUB_TOKEN vs PAT

### 2.1 GITHUB_TOKEN（推荐用于 CI）

`GITHUB_TOKEN` 是 GitHub Actions 在每次 workflow 运行时**自动注入**的临时 token，存在环境变量 `secrets.GITHUB_TOKEN`（也可在 `with.token` 显式传入，默认值就是它）。

特点：

- **临时**：当前 job 结束后立即失效。
- **免配置**：不需要手动建 secret。
- **权限最小化**：默认权限受 `permissions:` 控制（Day 36 会专门讲）。
- **自动写日志时会被 mask**：`***` 形式显示，不会泄露。

最小权限声明（写在 workflow 顶部）：

```yaml
permissions:
  contents: read
  packages: write   # push GHCR 必须
```

只给 `packages: write`，不要放开 `id-token` / `attestations` 等其他权限。

### 2.2 PAT（个人访问令牌）

当不是从 Actions 触发（比如本地 docker login），或者要跨仓库跨组织操作时，用 **Personal Access Token (PAT)**。

| 类型 | 场景 | 注意事项 |
| --- | --- | --- |
| Fine-grained PAT（推荐） | 本地 / 跨仓 | 只能勾选指定 repo + 指定权限；scope 显式 |
| Classic PAT | 老仓库兼容性 | `read:packages` / `write:packages` / `delete:packages` 三个独立勾选 |

PAT 必须保密，本地推荐用 `gh auth login` / `docker login` 走 keyring 而不是写 `.env`。

## 3. 登录方式

### 3.1 在 GitHub Actions 里登录（最常见）

```yaml
- name: 登录 GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

要点：

- `username` 用 `github.actor`（触发工作流的人/应用），不是随便写一个字符串。
- `password` 用 `secrets.GITHUB_TOKEN`，**不要再用 `secrets.PAT`**（除非 push 到别人或外部 registry）。
- 不需要 `docker login ghcr.io` 命令式调用，`docker/login-action` 内部就是封装它。

### 3.2 本地登录

```bash
# 方式 A：gh CLI（推荐，会存到系统 keyring）
gh auth login --scopes write:packages
gh auth token | docker login ghcr.io -u USERNAME --password-stdin

# 方式 B：直接 docker login
echo "$GHCR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
# USERNAME 是 GitHub 用户名（小写），PAT 通过 stdin 注入，避免落到 history
```

注意：

- 密码必须通过 **stdin** 传，不要 `-p PAT` 写在命令行，会进 shell history。
- 本地 `~/.docker/config.json` 里会有 `auths.ghcr.io` 条目，**这台机器要保护好**。
- `docker logout ghcr.io` 可以清掉本地凭据。

### 3.3 在其他 CI（自建 runner / GitLab CI / Jenkins）里登录

仍然用 PAT，登录命令一样，只是 `username/password` 来自各自平台的 secret。

## 4. 镜像仓库可见性：public vs private

push 完之后，镜像默认是 **private**。要让别人能拉，需要改成 **public**：

1. 打开 GitHub → 个人头像 → **Packages**。
2. 选中刚 push 的 package。
3. **Package settings** → **Danger Zone** → **Change package visibility** → Public。

或用 API：

```bash
gh api -X PATCH /user/packages/container/<repo> \
  -f visibility=public
```

生产仓库建议保持 private，并通过 GitHub 团队 / 角色控制访问。

## 5. 权限与典型报错

| 报错 | 真正原因 | 解决 |
| --- | --- | --- |
| `unauthorized: authentication required` | 没登录 / token 失效 | 重新 login 或检查 `permissions: packages: write` |
| `denied: requested access to the resource is denied` | token 没有写权限 | ① Actions：加 `packages: write` ② PAT：勾 `write:packages` |
| `denied: install_slashr not found` | repo 路径写错 | 路径必须是 `ghcr.io/<owner>/<repo>`，owner 拼写一致 |
| `Name unknown to registry` | 仓库名含大写 / 路径前缀错 | 镜像名统一小写 |
| `toomanyrequests: retry-after` | GitHub 限流 | 降低并发，加退避 |
| `denied: ghcr.io/... not visible to your account` | 私有包，你不在协作者列表 | 找 owner 加权限或换成 public |

特别注意：

- **写入需要 `write:packages`**，**拉取私有包需要 `read:packages`**。
- 经典 PAT 必须同时勾 `repo`（涉及私有 repo 镜像时）。
- org 场景下，PAT 要先被 org 接受（Settings → Personal access tokens → Approve）。

## 6. 一个最小推送 workflow（GHCR 登录 + 推送）

```yaml
name: docker-ghcr

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  packages: write

jobs:
  build-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 登录 GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: 拉取并构建
        run: docker build -t ghcr.io/${{ github.repository_owner }}/ci-baseline-demo:${{ github.sha }} ./app

      - name: 推送
        run: docker push ghcr.io/${{ github.repository_owner }}/ci-baseline-demo:${{ github.sha }}
```

镜像地址规则：

```text
ghcr.io/<owner>/<repo>:<tag>
           ^^^^^  仓库名（不含 .git 后缀）
```

`${{ github.repository_owner }}` = 仓库所属 owner，Day 24 会用 metadata-action 自动生成多个 tag。

## 7. 安全 checklist

- [ ] workflow 顶部声明 `permissions: packages: write`，不要全开
- [ ] 不在日志里 echo token / PAT
- [ ] 本地 PAT 走 keyring 或 stdin，不写进 `.env` 提交
- [ ] 私有包最小协作者，团队用 team 分配
- [ ] 定期 review `gh auth status` / 撤销不再用的 PAT

## 8. 自测清单

- [ ] 能说出 `GITHUB_TOKEN` 和 PAT 的本质区别
- [ ] 能解释 `permissions: packages: write` 的作用
- [ ] 能在本地用 PAT 完成一次 `docker login ghcr.io` 并 `docker pull` 自己的镜像
- [ ] 能解释 `denied: requested access to the resource is denied` 至少 2 个可能原因
- [ ] 能写出最小可用的 GHCR push workflow
