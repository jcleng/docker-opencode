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
- pi agent：通过 npm `@earendil-works/pi-coding-agent`（pi.dev 官方包，`--ignore-scripts` 安装）提供 `pi` 命令，容器内直接 `pi` 即可启动
- 运行用户：`root`
- 工作目录：`/home/jcleng/work/mywork/`

## 构建镜像

镜像通过 GitHub Actions 自动构建并推送到阿里云镜像仓库，**不建议在本地手动 `docker build`**（本地环境拉取 Debian 源 / npm 包时网络不稳定，易出现超时）。

### 构建来源

构建由 [`jcleng/action-sync-images`](https://github.com/jcleng/action-sync-images) 仓库的
[`build-repo.yml`](https://github.com/jcleng/action-sync-images/actions/workflows/build-repo.yml) 工作流完成，
工作流名称为 **RUN Repo Url && PUSH AliYun**，输入参数说明：

| 参数 | 含义 | 本项目取值 |
| --- | --- | --- |
| `arg_repo_url` | 源码 git 仓库地址 | `https://github.com/jcleng/docker-opencode` |
| `arg_branch_name` | 构建分支 | `master` |
| `arg_username` | 镜像名前缀 | `gitbuild` |
| `arg_name` | 镜像名称 | `docker-opencode` |
| `arg_aliyunurl` | 阿里云仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `arg_aliyunuser` | 阿里云用户名 | `jcleng` |

工作流会将镜像名拼为 `arg_aliyunurl/arg_aliyunuser/arg_username-arg_name`，因此最终产物为：

```
registry.cn-hangzhou.aliyuncs.com/jcleng/gitbuild-docker-opencode
```

### 手动触发

在 `action-sync-images` 仓库的 Actions 页面选择 `build-repo.yml`，填好上述参数后 `Run workflow` 即可；
也可通过 GitHub CLI 触发：

```bash
gh workflow run build-repo.yml --repo jcleng/action-sync-images \
  -f arg_repo_url="https://github.com/jcleng/docker-opencode" \
  -f arg_branch_name="master" \
  -f arg_username="gitbuild" \
  -f arg_name="docker-opencode" \
  -f arg_aliyunurl="registry.cn-hangzhou.aliyuncs.com" \
  -f arg_aliyunuser="jcleng"
```

### 本地构建（仅调试用）

如确有本地构建需要，注意底包为 Debian 12，apt 源在 `/etc/apt/sources.list.d/debian.sources`，
且 npm 安装 `@opencode/cli` 时新版 npm 的 `allow-scripts` 机制会跳过其 `postinstall` 脚本，需显式允许：

```bash
docker build -t registry.cn-hangzhou.aliyuncs.com/jcleng/gitbuild-docker-opencode .
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
pi                                # 启动 pi agent（pi.dev）
skills --help                     # 查看 skills CLI 用法
npx skills add <repo> -a opencode # 把技能安装到 opencode
```

## 注意事项

- 镜像完整地址为 `registry.cn-hangzhou.aliyuncs.com/jcleng/gitbuild-docker-opencode`（含 `gitbuild-` 前缀，由 `build-repo.yml` 拼接规则决定），`docker-compose.yml` 中的 `image` 已与此对齐。
- 镜像基于 Debian 系，系统依赖使用 `apt-get` 安装；若底包改为 Alpine 系，需将包管理命令替换为 `apk add`。
- opencode 与 skills 的详细用法参见官方文档：https://opencode.ai 与 https://skills.sh；pi agent 参见 https://pi.dev

## 宿主机`opencode`命令

```shell
#!/usr/bin/env bash
docker exec -it docker-opencode bash -c "cd '$PWD' && opencode"
```
