# Docker 知识点总结

本文整理 Docker 镜像、容器运行、端口、挂载、资源限制、重启策略、调试和 CI/CD 中常见用法。

## 1. 镜像、Dockerfile 与目录位置

Docker 镜像不是直接“写在目录里”的，通常写的是 `Dockerfile`，然后用它构建镜像。

常见结构：

```text
project/
├── Dockerfile
├── package.json
├── src/
└── ...
```

构建命令：

```bash
docker build -t my-app .
```

如果应用在子目录，例如本项目的 `app/`，推荐：

```text
app/
├── Dockerfile
├── .dockerignore
├── package.json
├── package-lock.json
├── src/
└── test/
```

构建：

```bash
docker build -t ci-baseline-demo ./app
```

或者在 GitHub Actions 中：

```yaml
- run: docker build -t ci-baseline-demo:${{ github.sha }} .
  working-directory: app
```

## 2. Dockerfile、镜像、容器的关系

```text
Dockerfile --docker build--> Image --docker run--> Container
```

| 概念 | 含义 |
|---|---|
| Dockerfile | 构建镜像的说明书 |
| Image | 构建出来的只读模板 |
| Container | 镜像运行起来后的实例 |
| Tag | 镜像的名字或版本标签 |

示例：

```bash
docker build -t my-app:1.0 .
docker run my-app:1.0
```

## 3. docker build 多 tag

可以一次构建同时打多个 tag：

```bash
docker build \
  -t my-app:${{ github.sha }} \
  -t my-app:latest \
  .
```

含义：

```text
构建出同一个 image id
然后同时挂两个 tag：
- my-app:<commit-sha>
- my-app:latest
```

本地 build 阶段通常可以理解为：

```text
成功 → 两个 tag 都有
失败 → 两个 tag 都没有
```

但注意，后续 push 不是原子性的：

```bash
docker push my-app:${{ github.sha }}
docker push my-app:latest
```

这两条是两次网络操作，可能出现一个成功、一个失败。因此生产部署建议使用不可变 tag，例如 commit SHA，而不要依赖 `latest`。

## 4. github.sha 是什么

在 GitHub Actions 中：

```yaml
${{ github.sha }}
```

表示本次 workflow 关联的 commit SHA。

常见场景：

| 触发方式 | `github.sha` 指向 |
|---|---|
| `push` | 被 push 的最新 commit |
| `workflow_dispatch` | 手动选择分支的当前 HEAD |
| `pull_request` | GitHub 生成的临时 merge commit |

如果要拿 PR 分支自己的 commit，可以用：

```yaml
${{ github.event.pull_request.head.sha }}
```

## 5. docker run 基本格式

```bash
docker run [参数] 镜像名 [容器内启动命令]
```

常见示例：

```bash
docker run -d \
  --name web \
  -p 8080:80 \
  nginx
```

表示后台启动一个 nginx 容器，把宿主机 `8080` 映射到容器 `80`。

## 6. 常用 docker run 参数

| 参数 | 含义 | 示例 |
|---|---|---|
| `-d` | 后台运行 | `docker run -d nginx` |
| `--name` | 指定容器名 | `docker run --name web nginx` |
| `-p` / `--publish` | 手动端口映射 | `-p 8080:80` |
| `-P` / `--publish-all` | 随机映射所有 `EXPOSE` 端口 | `docker run -P nginx` |
| `-v` / `--volume` | 挂载目录或卷 | `-v data:/data` |
| `--mount` | 更明确的挂载写法 | `--mount type=bind,src=/host,dst=/app` |
| `-e` / `--env` | 设置环境变量 | `-e NODE_ENV=production` |
| `--env-file` | 从文件加载环境变量 | `--env-file .env` |
| `--rm` | 容器退出后自动删除 | `docker run --rm alpine echo hi` |
| `-it` | 交互式终端 | `docker run -it ubuntu bash` |
| `--restart` | 重启策略 | `--restart unless-stopped` |
| `--network` | 指定网络 | `--network app-net` |
| `-w` / `--workdir` | 指定工作目录 | `-w /app` |
| `--entrypoint` | 覆盖镜像默认入口 | `--entrypoint sh` |
| `--platform` | 指定平台架构 | `--platform linux/amd64` |
| `--pull` | 拉取策略 | `--pull always` |

注意：容器名参数是 `--name`，不是 `-name`。

## 7. `-p`、`-P` 和不写端口映射

### `-p`

手动指定端口映射：

```bash
docker run -p 8080:80 nginx
```

含义：

```text
宿主机 8080 → 容器 80
```

### `-P`

大写 `-P` 等价于 `--publish-all`，会把镜像中 `EXPOSE` 声明的端口随机映射到宿主机端口。

```bash
docker run -d -P nginx
```

可能得到：

```text
0.0.0.0:32768 -> 80/tcp
```

### 不写 `-p` / `-P`

容器内部服务仍然运行，但宿主机外部访问不到。

```bash
docker run -d nginx
```

容器内 nginx 可能监听 `80`，但宿主机没有端口映射。

### `EXPOSE` 不等于发布端口

Dockerfile 中：

```dockerfile
EXPOSE 3000
```

只是声明容器预计监听 `3000`，真正让宿主机访问仍然需要：

```bash
-p 3000:3000
```

或：

```bash
-P
```

## 8. `-v` 和 `--mount`

### bind mount：挂载宿主机目录

```bash
docker run -v /host/data:/container/data nginx
```

含义：

```text
宿主机 /host/data → 容器 /container/data
```

### volume：Docker 管理的数据卷

```bash
docker run -v mysql-data:/var/lib/mysql mysql:8
```

`mysql-data` 是 Docker 管理的命名卷，适合保存数据库数据。

### `--mount` 写法

```bash
docker run \
  --mount type=bind,src=/host/data,dst=/container/data \
  nginx
```

`--mount` 比 `-v` 更清晰，适合生产或复杂场景。

## 9. 环境变量

单个变量：

```bash
docker run -e NODE_ENV=production my-app
```

多个变量：

```bash
docker run \
  -e NODE_ENV=production \
  -e PORT=3000 \
  my-app
```

从文件加载：

```bash
docker run --env-file .env my-app
```

`.env` 示例：

```env
NODE_ENV=production
PORT=3000
```

不要把密钥直接写死在命令或 Dockerfile 中，生产环境应使用 CI secrets、Kubernetes Secret 或云厂商密钥管理。

## 10. `--entrypoint`

`--entrypoint` 用来临时覆盖镜像 Dockerfile 中的 `ENTRYPOINT`。

假设 Dockerfile：

```dockerfile
ENTRYPOINT ["node"]
CMD ["src/index.js"]
```

正常运行：

```bash
docker run my-app
```

实际执行：

```bash
node src/index.js
```

覆盖 entrypoint：

```bash
docker run --rm -it --entrypoint sh my-app
```

实际执行：

```bash
sh
```

这常用于进入镜像内部调试。

注意：这条命令是基于镜像新建一个临时容器，不是进入已有容器。进入已有容器要用：

```bash
docker exec -it 容器名 sh
```

对比：

| 命令 | 含义 |
|---|---|
| `docker run --rm -it --entrypoint sh 镜像名` | 用镜像新建临时容器并启动 shell |
| `docker exec -it 容器名 sh` | 进入已经运行中的容器 |

如果镜像是 `scratch` 或 distroless，可能没有 `sh`，会报：

```text
exec: "sh": executable file not found in $PATH
```

## 11. ENTRYPOINT 和 CMD

| 项 | ENTRYPOINT | CMD |
|---|---|---|
| 角色 | 主程序 | 默认参数 |
| 覆盖方式 | `--entrypoint` | `docker run 镜像 参数...` |
| 常见用途 | 固定应用入口 | 给入口提供默认参数 |

示例：

```dockerfile
ENTRYPOINT ["node"]
CMD ["src/index.js"]
```

```bash
docker run my-app scripts/build.js
```

实际执行：

```bash
node scripts/build.js
```

这里 `node` 没变，变的是 CMD 参数。

## 12. `--restart unless-stopped`

`--restart unless-stopped` 是容器重启策略：

```bash
docker run -d \
  --name web \
  --restart unless-stopped \
  nginx
```

含义：

```text
容器异常退出会自动重启；Docker 或宿主机重启后也会自动拉起；但如果用户手动 stop 过，就不会再自动启动。
```

常见策略：

| 策略 | 含义 |
|---|---|
| `no` | 默认，不自动重启 |
| `always` | 总是重启，手动停止后 Docker 重启也会拉起 |
| `unless-stopped` | 除非手动停止，否则自动重启 |
| `on-failure` | 只有非 0 退出码时重启 |
| `on-failure:3` | 失败最多重启 3 次 |

适合长期服务：

```bash
docker run -d \
  --name mysql \
  -v mysql-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=123456 \
  --restart unless-stopped \
  mysql:8
```

不适合一次性任务和 CI：

```bash
docker run --rm my-app npm test
```

## 13. 资源限制：`--memory` / `-m`

`--memory` 或 `-m` 限制容器总内存上限。

```bash
docker run -m 512m my-app
```

含义：

```text
容器最多使用 512MB 内存
```

超过限制可能触发 OOM kill：

```text
超过内存上限 → Linux cgroup 触发 OOM → 容器主进程被杀 → 容器退出
```

常见单位：

```bash
-m 128m
-m 512m
-m 1g
--memory 2g
```

可以结合 CPU 限制：

```bash
docker run -d \
  --name api \
  -m 512m \
  --cpus 1 \
  my-api
```

## 14. `--shm-size`

`--shm-size` 控制容器内 `/dev/shm` 共享内存大小。

```bash
docker run --shm-size=1g my-app
```

Docker 默认 `/dev/shm` 通常只有 `64MB`。一些程序依赖共享内存，例如：

- Chrome / Chromium
- Puppeteer
- Playwright
- PostgreSQL
- Python multiprocessing
- 部分测试或图像处理任务

如果 `/dev/shm` 太小，可能出现：

```text
No space left on device
DevToolsActivePort file doesn't exist
```

`--memory` 和 `--shm-size` 区别：

| 参数 | 控制对象 | 作用 |
|---|---|---|
| `--memory` / `-m` | 容器总内存上限 | 限制容器最多能用多少 RAM |
| `--shm-size` | `/dev/shm` 共享内存区域 | 限制共享内存文件系统大小 |

可以理解为：

```text
--memory   = 整个房子的面积上限
--shm-size = 房子里某个房间的面积
```

## 15. OOM 与调度

### 单机 Docker

单机 Docker 中：

```bash
docker run -m 512m my-app
```

只表示限制内存，不表示调度。

如果 OOM：

```text
容器超过 512MB → 被 kill → 容器退出
```

Docker 不会自动把容器迁移到别的机器，因为单机 Docker 没有调度器。

常见处理方式：

- 调大内存限制：

```bash
docker run -m 1g my-app
```

- 配合重启策略：

```bash
docker run -d \
  -m 512m \
  --restart unless-stopped \
  my-app
```

- 检查是否内存泄漏：

```bash
docker stats
docker logs 容器名
docker inspect 容器名
```

### Kubernetes

Kubernetes 里不使用 `docker run -m`，而使用 `requests` 和 `limits`：

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

| 字段 | 作用 |
|---|---|
| `requests.memory` | 调度依据，告诉调度器 Pod 至少需要多少内存 |
| `limits.memory` | 运行上限，超过会 OOMKilled |

口诀：

```text
Docker -m = 限制内存，不负责调度
K8s requests = 调度依据
K8s limits = OOM 上限
```

## 16. 健康检查

Docker 可以给容器配置健康检查：

```bash
docker run -d \
  --name web \
  --health-cmd="curl -f http://localhost:3000/health || exit 1" \
  --health-interval=30s \
  --health-timeout=5s \
  --health-retries=3 \
  my-web
```

| 参数 | 含义 |
|---|---|
| `--health-cmd` | 健康检查命令 |
| `--health-interval` | 检查间隔 |
| `--health-timeout` | 超时时间 |
| `--health-retries` | 失败几次后判定 unhealthy |
| `--no-healthcheck` | 禁用镜像内置健康检查 |

注意：单机 Docker 的健康检查只标记状态，不一定自动修复。生产环境通常由 Kubernetes、Docker Compose 或其他编排系统基于健康状态做重启、摘流或替换。

## 17. 日志限制

长期运行容器时建议限制日志大小：

```bash
docker run -d \
  --name app \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  my-app
```

含义：

| 参数 | 含义 |
|---|---|
| `--log-driver json-file` | 使用默认 JSON 日志驱动 |
| `--log-opt max-size=10m` | 单个日志文件最大 10MB |
| `--log-opt max-file=3` | 最多保留 3 个日志文件 |

如果不限制日志，容器输出过多可能占满宿主机磁盘。

## 18. 网络参数

指定网络：

```bash
docker run --network app-net my-app
```

创建网络：

```bash
docker network create app-net
```

同一个用户自定义网络内，容器可以通过容器名互相访问。例如：

```bash
docker run -d --name db --network app-net mysql:8
docker run -d --name api --network app-net my-api
```

`api` 容器中可以通过 `db` 这个主机名访问数据库。

## 19. 安全相关参数

| 参数 | 含义 | 建议 |
|---|---|---|
| `--privileged` | 特权模式，几乎拥有宿主机高级权限 | 慎用 |
| `--cap-add` | 增加 Linux capability | 按需添加 |
| `--cap-drop` | 删除 capability | 推荐最小权限 |
| `--read-only` | 容器根文件系统只读 | 适合安全加固 |
| `--security-opt no-new-privileges` | 禁止进程获得新权限 | 推荐 |
| `--user` / `-u` | 指定运行用户 | 避免 root 运行 |

示例：

```bash
docker run -d \
  --name app \
  --read-only \
  --security-opt no-new-privileges \
  --user 1000:1000 \
  my-app
```

## 20. 常见组合

### Web 服务

```bash
docker run -d \
  --name web \
  -p 8080:80 \
  --restart unless-stopped \
  nginx
```

### Node 应用

```bash
docker run -d \
  --name node-app \
  -p 3000:3000 \
  -e NODE_ENV=production \
  --restart unless-stopped \
  my-node-app
```

### MySQL

```bash
docker run -d \
  --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -v mysql-data:/var/lib/mysql \
  --restart unless-stopped \
  mysql:8
```

### 临时进入 Ubuntu

```bash
docker run --rm -it ubuntu bash
```

### 调试镜像

```bash
docker run --rm -it --entrypoint sh my-app
```

## 21. CI/CD 中的 Docker 建议

常见流水线顺序：

```text
lint → test → build app → docker build → docker push → deploy
```

构建镜像：

```yaml
- run: docker build -t my-app:${{ github.sha }} .
```

同时打多个 tag：

```yaml
- run: |
    docker build \
      -t my-app:${{ github.sha }} \
      -t my-app:latest \
      .
```

推送：

```yaml
- run: docker push my-app:${{ github.sha }}
- run: docker push my-app:latest
```

建议：

- 部署使用 `${{ github.sha }}` 这类不可变 tag
- `latest` 只作为辅助标签
- push 多个 tag 不是原子操作
- Dockerfile 和 `.dockerignore` 放在应用根目录
- 不要把密钥写进镜像

## 22. 排查命令

查看容器：

```bash
docker ps
docker ps -a
```

查看日志：

```bash
docker logs 容器名
docker logs -f 容器名
```

进入容器：

```bash
docker exec -it 容器名 sh
```

查看资源：

```bash
docker stats
```

查看详细配置：

```bash
docker inspect 容器名
```

查看镜像：

```bash
docker images
```

查看端口映射：

```bash
docker port 容器名
```

## 23. 重点口诀

```text
Dockerfile 定义镜像，docker build 构建镜像，docker run 启动容器。
-p 是手动映射端口，-P 是随机发布 EXPOSE 端口，不写则宿主机访问不到。
--entrypoint 是临时替换容器启动程序，常用于进入 shell 调试。
--restart unless-stopped 适合长期服务，不适合一次性任务。
-m 限制容器总内存，--shm-size 限制 /dev/shm。
Docker 单机只限制资源，不负责调度；K8s requests 才是调度依据。
构建时多个 tag 基本一起成功；push 多个 tag 可能部分成功。
生产部署优先使用 commit SHA 这类不可变 tag。
```
