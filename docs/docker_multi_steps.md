# Docker 多阶段构建

## 什么是多阶段构建？

多阶段构建（Multi-stage Build）是一种 Dockerfile 写法，用**多个 `FROM` 指令**把构建过程分成多个阶段，最终只保留运行时需要的内容。

## 基本语法

### `AS` 给阶段起名字

```dockerfile
FROM node:22 AS builder
```

`builder` 是这个阶段的名字，后面 `COPY --from=builder` 要用到这个名字。

### `--from=阶段名` 从指定阶段复制

```dockerfile
COPY --from=builder /app/dist ./dist
```

从 `builder` 阶段把 `/app/dist` 复制到当前阶段的 `./dist`。

### 阶段可以命名也可以用数字

```dockerfile
FROM node:22 AS builder
FROM node:22
COPY --from=0 /app/dist ./dist   ← 从第0个阶段复制
```

## 典型示例

### Node.js

```dockerfile
# 阶段1：构建
FROM node:22 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# 阶段2：运行
FROM node:22-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Python

```dockerfile
# 阶段1：构建
FROM python:3.12 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# 阶段2：运行
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
CMD ["python", "main.py"]
```

### Java / Maven

```dockerfile
# 阶段1：构建
FROM maven:3.9 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY . .
RUN mvn package -DskipTests

# 阶段2：运行
FROM openjdk:17-slim
WORKDIR /app
COPY --from=builder /app/target/myapp.jar ./myapp.jar
EXPOSE 8080
CMD ["java", "-jar", "myapp.jar"]
```

### Go

```dockerfile
# 阶段1：构建
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o myapp .

# 阶段2：运行
FROM scratch
COPY --from=builder /app/myapp /myapp
CMD ["/myapp"]
```

## 优点

### 1. 镜像体积大幅减小

构建工具和运行时分离，最终镜像只包含必要文件。

| 方式 | 典型体积 |
|---|---|
| 单阶段（node:22 + 全部依赖） | ~900 MB |
| 多阶段（node:22-slim 只含运行） | ~200 MB |
| 多阶段（Go scratch） | ~10 MB |

- 拉取速度快 4 倍，CI/CD 部署更快
- 磁盘占用少，服务器成本降低
- 启动更快，容器启动时间缩短

### 2. 构建缓存高效

多阶段构建天然支持分层缓存：

```dockerfile
FROM node:22 AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:22 AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
```

修改源代码时，第1阶段（deps）命中缓存，跳过 npm ci，只有 builder 阶段重新构建。

### 3. 安全性提升

构建工具不进入最终镜像。镜像泄露时，攻击者拿不到源码、构建脚本、测试工具。

### 4. 构建环境与运行环境分离

可以在强大的 builder 机器上编译，在极简镜像上运行。

```dockerfile
FROM golang:1.22 AS builder
RUN CGO_ENABLED=0 GOOS=linux go build -o myapp .

FROM scratch
COPY --from=builder /app/myapp /myapp
CMD ["/myapp"]
```

### 5. 灵活切换基础镜像

不同阶段可以用不同的发行版或架构。

```dockerfile
FROM python:3.12 AS builder
RUN pip install pyinstaller
RUN pyinstaller --onefile main.py

FROM alpine:3.19
COPY --from=builder /app/dist/main /main
CMD ["/main"]
```

## 缺点

### 1. Dockerfile 复杂度增加

单阶段写起来简单直观。多阶段需要规划阶段划分、命名、COPY 路径。对于简单项目，这是不必要的复杂度。

### 2. 构建时间可能更长

第一次构建时，多阶段需要完整执行每个阶段。单阶段构建只需要一步。

### 3. 调试更困难

构建失败需要定位是哪个阶段出问题。进入容器调试也不方便，因为最终镜像可能没有调试工具。

### 4. COPY --from 的路径容易出错

需要精确知道上一个阶段输出的文件路径。路径写错了，Docker 不会报错，只是运行起来才发现文件不存在。

### 5. 不是所有项目都适合

如果项目是纯解释型语言（Python、Ruby），没有编译步骤，多阶段构建的优势很小，反而增加复杂度。

### 6. 基础镜像版本需要同步维护

如果用多个 `FROM node:22`，三个地方需要同时更新，漏一个可能导致兼容性问题。

## 什么时候用多阶段？

| 场景 | 推荐 |
|---|---|
| 编译型语言（Go、C、C++、Rust） | 强烈推荐 |
| 需要编译的前端项目（React、Vue 构建） | 推荐 |
| Node.js 有构建步骤（TypeScript 编译、打包） | 推荐 |
| Python/Ruby 纯解释型 | 可选 |
| 简单脚本、工具类项目 | 不需要 |
| 只需要源码直接运行 | 不需要 |

核心判断标准：**构建产物和构建环境是否不同？**

## 常用 Docker Actions

Docker 官方维护了 3 个常用 action：

| Action | 用途 |
|---|---|
| docker/login-action | 登录镜像仓库 |
| docker/build-push-action | 构建并推送镜像 |
| docker/metadata-action | 自动生成镜像标签和元数据 |

### GHCR 登录示例

```yaml
- uses: docker/login-action@v4
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### 完整构建推送 workflow

```yaml
steps:
  - uses: docker/login-action@v4
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}

  - uses: docker/metadata-action@v5
    id: meta
    with:
      images: ghcr.io/${{ github.repository }}/app
      tags: |
        type=sha,prefix=,suffix=,format=short
        type=ref,event=branch
        type=semver,pattern={{version}}

  - uses: docker/build-push-action@v5
    with:
      push: true
      tags: ${{ steps.meta.outputs.tags }}
      labels: ${{ steps.meta.outputs.labels }}
```

## 官方镜像类型

Node 官方镜像有三种：

| 镜像 | 大小 | 说明 |
|---|---|---|
| `node:22` | ~1.1 GB | 完整版，包含开发工具 |
| `node:22-alpine` | ~140 MB | Alpine 精简版 |
| `node:22-slim` | ~200 MB | Debian slim 版 |

推荐生产环境使用 `-slim` 或 `-alpine`，构建阶段可以使用完整版。
