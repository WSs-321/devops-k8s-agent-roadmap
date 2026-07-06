# Secret 安全规范

## 1. 创建规范

### 最小权限原则

- `GITHUB_TOKEN` 用 `permissions:` 显式声明最小权限，不用默认
- 自定义 token 只给必要 scope
- 生产密钥用 environment secret，配审批

### 作用域选择

| 类型 | 放置位置 | 适用场景 |
| --- | --- | --- |
| `GITHUB_TOKEN` | 无需配置，自动注入 | 推 GHCR、创建 Release |
| 通用 token | repository secret | 所有 job 共用 |
| 环境密钥 | environment secret | 生产部署密钥（配审批） |

### 命名规范

- 环境密钥：`DEPLOY_KEY_<ENV>`（如 `DEPLOY_KEY_PROD`）
- 通用密钥：`<SERVICE>_<PURPOSE>`（如 `NPM_TOKEN`）

## 2. 使用规范

### 正确写法

```yaml
# 用 ${{ secrets.XXX }} 引用
env:
  SSH_PRIVATE_KEY: ${{ secrets.DEPLOY_KEY_DEV }}

# 用 env 注入，不直接写值
- name: Deploy
  run: ./scripts/deploy.sh
  env:
    IMAGE: ${{ steps.metadata.outputs.tags }}
```

### 禁止写法

```bash
# 禁止：echo secret
echo "$SSH_PRIVATE_KEY"

# 禁止：set -x 时操作 secret
set -x
ssh -i "$KEY_FILE" user@host

# 禁止：curl -v 带 secret header
curl -v -H "Authorization: Bearer $TOKEN" https://api.github.com

# 禁止：写入文件后 cat
echo "$SECRET" > key.txt
cat key.txt

# 禁止：派生值（截取、base64）
echo "${SECRET:0:10}"
echo "$SECRET" | base64
```

## 3. 日志规范

### 自动脱敏的边界

GitHub Actions 自动脱敏 `${{ secrets.XXX }}` 的**原始值**，但**派生值不脱敏**：

| 操作 | 是否脱敏 |
| --- | --- |
| `echo "$SECRET"` | ✅ 脱敏 |
| `echo "key=$SECRET"` | ✅ 脱敏（整体匹配） |
| `echo "${SECRET:0:10}"` | ❌ 泄露 |
| `echo "$SECRET" \| base64` | ❌ 泄露 |
| `cat key.txt`（写入后） | ❌ 泄露 |

### 手动脱敏派生值

```bash
TOKEN=$(jq -r '.token' response.json)
echo "::add-masker::$TOKEN"   # 告诉 GitHub 把这个值也脱敏
echo "Token is: $TOKEN"       # 日志：Token is: ***
```

## 4. 检查清单

### 创建前

- [ ] 用最小权限原则
- [ ] 生产密钥用 environment secret + 审批
- [ ] 不提交到代码仓库（`.gitignore` 排除 `.env`）
- [ ] 不在 PR 评论里贴 secret

### 使用中

- [ ] 用 `${{ secrets.XXX }}` 引用
- [ ] 用 `env:` 注入
- [ ] 不在 `name:` 里用 secret（name 进日志）
- [ ] 不 `echo $SECRET`
- [ ] 不 `set -x` 时操作 secret
- [ ] 不 `curl -v` 带 secret header
- [ ] 不把 secret 写入 artifact

### 定期

- [ ] 定期旋转（90 天建议）
- [ ] 离职/换岗后立即旋转
- [ ] 泄露后立即 revoke + 旋转 + 排查日志

## 5. 应急流程

```text
发现泄露
   ↓
1. 立即 revoke（在服务方平台禁用密钥）
   ↓
2. 旋转（创建新密钥，更新 GitHub secret）
   ↓
3. 排查（查 Actions 日志谁看过、PR 谁评论过）
   ↓
4. 强制推送历史清理（如密钥进了 git 历史）
   ↓
5. 通知相关方（如涉及第三方服务）
```

### 不要做的事

- 不要 `git push --force` 就以为删了（GitHub 仍缓存）
- 不要只删当前 commit（历史还在）
- 不要不改密钥（删了历史但密钥仍有效）

## 6. pull_request_target 陷阱

### 默认行为

`pull_request` 事件（来自 fork）自动拒绝访问 secrets。

### `pull_request_target` 的陷阱

```yaml
# 极度危险
on: pull_request_target
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # checkout PR 代码
      - run: npm install   # 跑 PR 的代码，能读 secrets！
```

攻击者可提恶意 PR，在 `npm install` 时偷走 secret。

### 规则

`pull_request_target` 永远不要 checkout PR 代码并执行。

## 7. Secret 扫描工具

| 工具 | 特点 |
| --- | --- |
| GitHub Secret Scanning | 公开仓库自动开启，push 时检查 |
| Trivy | `trivy fs --scanners secret .` |
| gitleaks | 最流行，速度快 |
| trufflehog | 支持云厂商 |
| detect-secrets | Yelp 出品 |

## 8. GITHUB_TOKEN 说明

### 三种引用方式（同一个 token）

```yaml
${{ secrets.GITHUB_TOKEN }}   # secrets 上下文
${{ github.token }}           # github 上下文（简写）
$GITHUB_TOKEN                 # 环境变量（自动注入）
```

三者完全等价。

### 特性

- GitHub Actions 每次运行自动创建
- 运行结束后自动失效
- 无需手动配置
- 仅限当前仓库

### 与 PAT 区别

| Token | 来源 | 范围 |
| --- | --- | --- |
| `GITHUB_TOKEN` | Actions 自动创建 | 仅当前仓库 |
| PAT | 手动创建 | 用户所有仓库 |

## 9. 项目隐患排查

### deploy.sh 的 `set -euo pipefail`

- ✅ 安全（无 `-x`）
- ❌ 若加 `-x` 会泄露 SSH key

### SSH 私钥处理

```bash
# 危险
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa

# 安全
echo "$SSH_PRIVATE_KEY" | ssh-add -
# 不落盘，只在 agent 内存
```

### docker login 错误信息

```bash
# 危险：stderr 可能含 password
docker login -u user -p "$PASSWORD" 2>&1

# 安全：不重定向 stderr 到日志
docker login -u user -p "$PASSWORD" 2>/dev/null
```
