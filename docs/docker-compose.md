# Docker Compose 知识点总结

本文整理 Docker Compose 的核心概念、文件结构、关键字段、常用命令与进阶特性，配合本项目 `app/` 的多容器场景说明。

## 1. 它是什么，解决什么问题

Docker Compose 用一份 **YAML 文件**定义并运行**多容器应用**，把网络、卷、环境变量、依赖关系、端口映射全部声明式地写进文件，一键拉起或销毁整套环境。

没有 Compose 时，启动 web + 数据库 + 缓存要敲一堆命令：

```bash
docker network create myapp
docker run -d --name db --network myapp -e POSTGRES_PASSWORD=xxx postgres:16
docker run -d --name redis --network myapp redis:7
docker run -d --name web --network myapp -p 8080:80 -e DB_HOST=db myapp:latest
```

用 Compose 只需一份 `compose.yaml` 加一条命令：

```bash
docker compose up -d
```

## 2. 核心概念

| 概念 | 说明 | 对应 docker 命令 |
| --- | --- | --- |
| service（服务） | 一类容器，如 web/db | `docker run` |
| network（网络） | 服务间通信的虚拟网络 | `docker network` |
| volume（卷） | 持久化数据 | `docker volume` |
| project（项目） | 一份 compose 文件构成的整体 | 无（Compose 特有） |

关键点：同一个 compose 项目里的服务默认共享一个网络，可用**服务名当主机名**互相访问（如 web 里连 `db:5432`，无需 IP）。

## 3. 文件结构：完整示例

```yaml
# compose.yaml
services:
  web:
    build: .                    # 用当前目录 Dockerfile 构建
    ports:
      - "8080:80"               # 宿主机:容器
    environment:
      - DB_HOST=db
      - DB_PORT=5432
    env_file:
      - .env                    # 从文件加载环境变量
    depends_on:
      db:
        condition: service_healthy  # 等 db 健康后再启动
    restart: unless-stopped
    networks:
      - backend

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: myapp
    volumes:
      - db-data:/var/lib/postgresql/data   # 命名卷持久化
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - backend

volumes:
  db-data:                      # 声明命名卷

networks:
  backend:                      # 声明网络
```

## 4. 关键字段详解

### 4.1 `build` vs `image`

```yaml
build: .                        # 简写：当前目录
build:                          # 完整写法
  context: ./app
  dockerfile: Dockerfile.prod
  args:
    VERSION: "1.0"
image: myapp:latest             # 拉取现成镜像；与 build 并存时作为构建后的 tag
```

### 4.2 `ports` vs `expose`

```yaml
ports:
  - "8080:80"      # 对外暴露，宿主机能访问
expose:
  - "80"           # 仅容器间可见，不映射到宿主机
```

### 4.3 `volumes` 三种形式

```yaml
volumes:
  - db-data:/var/lib/postgresql/data   # 命名卷（Docker 管理，推荐持久化）
  - ./config:/etc/app                  # 绑定挂载（宿主机目录，适合开发热更新）
  - /var/lib/mysql                     # 匿名卷
```

### 4.4 `depends_on` 的坑

```yaml
depends_on:
  - db              # 只保证启动顺序，不等 db 真正就绪
depends_on:
  db:
    condition: service_healthy   # 配合 healthcheck 才真正等就绪
```

常见误区：光写 `depends_on: [db]`，web 启动时 db 可能还没准备好接受连接，需配合 `healthcheck` 加 `condition`。

### 4.5 `environment` vs `env_file`

```yaml
environment:                     # 直接写（明文，进版本库）
  - LOG_LEVEL=debug
env_file:                        # 从文件读（敏感信息，.env 加 .gitignore）
  - .env
```

### 4.6 `restart` 重启策略

```yaml
restart: "no"            # 默认，不重启
restart: always          # 总是重启
restart: on-failure      # 仅失败时
restart: unless-stopped  # 除非手动停止（生产常用）
```

## 5. 常用命令速查

```bash
# 启动 / 停止
docker compose up -d              # 后台启动全部
docker compose up -d web          # 只启动 web（及其依赖）
docker compose down               # 停止并删除容器 + 网络
docker compose down -v            # 连同卷一起删（清数据）
docker compose stop / start       # 停/起但不删

# 构建
docker compose build              # 构建镜像
docker compose up -d --build      # 构建并启动

# 查看
docker compose ps                 # 服务状态
docker compose logs -f web        # 跟踪 web 日志
docker compose top                # 各服务进程

# 进入 / 执行
docker compose exec web sh        # 进入运行中的 web
docker compose run --rm web env   # 临时跑一次性命令

# 伸缩
docker compose up -d --scale web=3   # web 起 3 个实例

# 配置校验
docker compose config             # 展开并校验最终配置
```

## 6. 进阶特性

### 6.1 多文件覆盖（环境差异化）

```bash
# base 加覆盖文件，后者覆盖前者
docker compose -f compose.yaml -f compose.prod.yaml up -d
```

`compose.override.yaml` 会被自动合并，开发常用于加 volume 挂载、debug 端口。

### 6.2 `profiles`（按需启用服务）

```yaml
services:
  debug-tools:
    image: busybox
    profiles: ["debug"]   # 默认不启动
```

```bash
docker compose --profile debug up -d   # 显式启用才起
```

### 6.3 `.env` 变量插值

```yaml
# .env 文件内容：TAG=1.2.3
services:
  web:
    image: myapp:${TAG:-latest}   # 引用 .env，:-latest 是默认值
```

### 6.4 资源限制

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 512M
```

## 7. Compose V1 vs V2

| 对比项 | V1（旧） | V2（现行） |
| --- | --- | --- |
| 命令 | `docker-compose`（独立工具） | `docker compose`（Docker CLI 子命令） |
| 文件名 | `docker-compose.yml` | `compose.yaml`（推荐），旧名仍兼容 |
| `version:` 字段 | 必填（如 `version: "3.8"`） | 已废弃，不用再写 |
| 状态 | 已停止维护 | 官方推荐 |

新项目：文件名用 `compose.yaml`、不写 `version:`、命令用 `docker compose`。

## 8. 和本项目的关联

本项目 `scripts/deploy.sh` 里 `deploy_docker` 是手动 `docker pull` 加 `docker run` 单容器。引入 Compose 后可整合为：

```bash
docker compose pull
docker compose up -d
```

更适合多服务（web + db + redis）一起部署的场景。
