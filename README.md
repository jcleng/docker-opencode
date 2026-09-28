# docker-opencode

基于 Docker 的 [opencode](https://opencode.ai) 运行环境。opencode 是一款终端 AI 编程助手，本项目将其打包为可直接运行的镜像，预装 Node 24、Git、Python 以及 skills CLI。

## 目录结构

```
docker-opencode/
├── Dockerfile          # 镜像构建文件
├── docker-compose.yml  # 容器编排（host 网络，挂载工作目录）
└── README.md
```

## 环境组成

- 底包：`registry.cn-hangzhou.aliyuncs.com/jcleng/library-node:24`（Debian 系）
- 系统依赖：`git`、`python3`（`python` 命令由 python-is-python3 提供）、`curl`、`ca-certificates`、`tar`、`unzip`
- 全局工具：
  - `skills`（open agent skills 生态 CLI，安装后 `npx skills` / `skills` 均可用）
  - `docker` / `docker-compose`（CLI，从 `library-docker:24.0.9-cli` 复制）
  - `php` 8.4.1（static PHP，静态编译，无需扩展管理）
  - `gh` v2.101.0（GitHub CLI）
  - `busybox`（从自定义 release 下载，替换系统 busybox）
- opencode：通过npm `@opencode/cli` 安装到 `~/.local/bin`
- 运行用户：`root`
- 工作目录：`/home/jcleng/work/mywork/`

## 构建镜像

```bash
docker build -t registry.cn-hangzhou.aliyuncs.com/jcleng/docker-opencode:latest .
```

构建完成后可推送到镜像仓库：

```bash
docker push registry.cn-hangzhou.aliyuncs.com/jcleng/docker-opencode:latest
```

## 启动容器

项目已提供 `docker-compose.yml`，使用 `host` 网络模式（每个终端复用宿主机端口），并把本地工作目录挂载进容器。

```bash
docker compose up -d
# 进入容器交互式 shell
docker compose exec docker-opencode bash
```

进入容器后即可运行：

```bash
opencode                          # 启动 opencode
skills --help                     # 查看 skills CLI 用法
npx skills add <repo> -a opencode # 把技能安装到 opencode
```

## 注意事项

- 镜像基于 Debian 系，系统依赖使用 `apt-get` 安装；若底包改为 Alpine 系，需将包管理命令替换为 `apk add`。
- opencode 与 skills 的详细用法参见官方文档：https://opencode.ai 与 https://skills.sh

## 宿主机`opencode`命令

```shell
#!/usr/bin/env bash
docker exec -it docker-opencode bash -c "cd '$PWD' && opencode"
```
