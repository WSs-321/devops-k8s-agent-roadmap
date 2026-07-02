# Docker 配置外置

## 什么是配置外置？

**把配置从代码里抽出来**，运行时通过外部注入（环境变量、配置文件、密钥管理），实现配置与代码分离。

## 为什么需要配置外置？

| 问题 | 后果 |
|---|---|
| 配置硬编码在代码中 | 改配置必须改代码、重建镜像、重新部署 |
| 密码/API key 进镜像 | 镜像泄露 = 密码泄露 |
| 每套环境一套配置 | 需要构建 3 个不同镜像 |
| 配置变化频繁 | 镜像版本失控 |

**核心原则**（12-Factor App）：配置变了不应该改代码。

## 配置外置的三种方式

### 方式 1：环境变量（最常用）

```js
// 代码从环境变量读取
const dbHost = process.env.DB_HOST || "localhost";
const port = parseInt(process.env.PORT) || 3000;
```

```bash
# docker run 时注入
docker run -e DB_HOST=192.168.1.10 -e PORT=3000 my-app:latest
```

### 方式 2：配置文件挂载

```js
// 代码读取配置文件
const config = JSON.parse(fs.readFileSync('/etc/app/config.json'));
```

```bash
# 挂载不同环境的配置文件
docker run -v /host/config/prod.json:/etc/app/config.json my-app:latest
```

### 方式 3：密钥管理服务

```js
// 从 Vault / Secrets Manager 拉取
const apiKey = await secretsClient.get('api-key');
```

用于管理敏感配置（密码、token、证书）。

## Docker 中的环境变量使用

### Dockerfile 设置默认值

```dockerfile
FROM node:22-slim
WORKDIR /app
COPY . .

ENV NODE_ENV=production
ENV PORT=3000
ENV LOG_LEVEL=info

EXPOSE 3000
CMD ["node", "index.js"]
```

### docker run 覆盖

```bash
# 覆盖单个变量
docker run -e NODE_ENV=development -e PORT=4000 my-app:latest

# 从文件加载
docker run --env-file .env my-app:latest
```

### .env 文件格式

```bash
NODE_ENV=production
DB_HOST=db.example.com
DB_PORT=5432
DB_PASSWORD=secret
API_KEY=sk-abc123
LOG_LEVEL=info
```

`.env` 文件不要进 git，加到 `.gitignore`。

### docker-compose 配置

```yaml
services:
  app:
    image: my-app:latest
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    env_file:
      - .env
    volumes:
      - ./config/prod.json:/etc/app/config.json
```

## K8s 中的配置外置

### ConfigMap（非敏感配置）

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DB_HOST: "db.example.com"
  LOG_LEVEL: "info"
```

### Secret（敏感配置）

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  DB_PASSWORD: cGFzc3dvcmQ=
  API_KEY: c2stYWJjMTIz
```

### Deployment 引用

```yaml
spec:
  containers:
  - name: app
    image: my-app:latest
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: app-secret
```

## 配置外置的好处

| 好处 | 说明 |
|---|---|
| 一镜像多环境 | dev/staging/prod 用同一个镜像 |
| 配置可变 | 改配置不需要重建镜像 |
| 安全 | 密钥（API key、密码、证书）不进镜像 |
| 可审计 | 配置版本由管理系统跟踪 |

## kube_config.key 属于哪种？

```text
kube_config.key = 一份敏感配置文件（数据本身，不是服务）
配置外置方式 = 文件挂载（运行时挂到 ~/.kube/config）
密钥管理服务 = GitHub Secrets / Vault / K8s Secret（用于存放、分发和轮换它）

kube_config.key 不是密钥管理服务，
但它应该被密钥管理服务管理。
```

## 常见错误

### 把 .env 文件提交到 git

```bash
# .gitignore 必须加
.env
.env.local
.env.*.local
```

### 把密码硬编码在 docker-compose.yml

```yaml
# ❌ 不要这样写
environment:
  - DB_PASSWORD=my-real-password

# ✅ 应该用变量引用
environment:
  - DB_PASSWORD=${DB_PASSWORD}
```

### 把敏感配置写到 Dockerfile

```dockerfile
# ❌ 千万不要，镜像层可被任何人查看
ENV API_KEY=sk-real-key-here
```

### 没有提供 .env.example

```bash
# .env.example 提交到 git，作为配置模板
DB_HOST=
DB_PORT=5432
DB_USER=
DB_PASSWORD=
API_KEY=
```

## 配置外置 vs 镜像标签

| 概念 | 作用 |
|---|---|
| 配置外置 | 同一份镜像 + 不同配置 = 不同环境 |
| 镜像标签 | 用 tag（latest、sha、semver）追踪不同版本 |

两者配合实现"一份镜像部署到 dev/staging/prod"。

## 一句话总结

```text
配置外置 = 配置和代码分离
环境变量是最简单的实现
"一份镜像，多种环境"是核心目标
密码、密钥永远不进镜像
```
