# 构建流程说明（agents.md）

本文汇总 `docker-opencode` 镜像的构建流程与验证结论，供后续维护参考。

## 1. 镜像用途

基于 Docker 的 [opencode](https://opencode.ai) 运行环境，预装 Node 24、Git、Python、skills CLI、docker/compose CLI、PHP、gh、busybox，以及 pi agent（pi.dev）。

## 2. 构建方式（已验证成功）

镜像**通过 GitHub Actions 自动构建并推送**，不建议在本地手动 `docker build`（本地拉取 Debian 源 / npm 包网络不稳定，易超时）。

### 构建来源
- 仓库：`jcleng/action-sync-images`
- 工作流文件：`build-repo.yml`
- 工作流名称：**RUN Repo Url && PUSH AliYun**
- 运行地址：https://github.com/jcleng/action-sync-images/actions/workflows/build-repo.yml

### 输入参数（本项目取值）
| 参数 | 含义 | 取值 |
| --- | --- | --- |
| `arg_repo_url` | 源码 git 仓库地址 | `https://github.com/jcleng/docker-opencode` |
| `arg_branch_name` | 构建分支 | `master` |
| `arg_username` | 镜像名前缀 | `gitbuild` |
| `arg_name` | 镜像名称 | `docker-opencode` |
| `arg_aliyunurl` | 阿里云仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `arg_aliyunuser` | 阿里云用户名 | `jcleng` |

### 触发命令（GitHub CLI）
```bash
gh workflow run build-repo.yml --repo jcleng/action-sync-images \
  -f arg_repo_url="https://github.com/jcleng/docker-opencode" \
  -f arg_branch_name="master" \
  -f arg_username="gitbuild" \
  -f arg_name="docker-opencode" \
  -f arg_aliyunurl="registry.cn-hangzhou.aliyuncs.com" \
  -f arg_aliyunuser="jcleng"
```

## 3. 镜像地址（重要）

`build-repo.yml` 将镜像名拼为 `arg_aliyunurl/arg_aliyunuser/arg_username-arg_name`，
因此**最终产物地址**为：

```
registry.cn-hangzhou.aliyuncs.com/jcleng/gitbuild-docker-opencode
```

注意含 `gitbuild-` 前缀（由 `arg_username` 决定）。`docker-compose.yml` 中的 `image` 已与此对齐。

## 4. 构建过程踩坑记录（已解决）

1. **apt 源连接失败**：底包为 Debian 12，原 `apt-get` 连 `deb.debian.org` 超时。
   解决：本地需换源（源文件路径为 `/etc/apt/sources.list.d/debian.sources`，非老式 `sources.list`）；
   GitHub Actions 环境网络正常，不受影响。
2. **npm 安装 pi 包超时（ETIMEDOUT）**：本地网络拉 `@earendil-works/pi-coding-agent` 超时；Actions 环境正常。
3. **npm `allow-scripts` 机制**：新版 npm 默认不执行 `@opencode/cli` 的 `postinstall` 脚本，
   若本地构建需显式允许（`--allow-scripts=@opencode/cli`），否则 opencode 二进制可能未装入 `~/.local/bin`。
   当前 Dockerfile 中 pi agent 已移除 `--ignore-scripts`，正常执行其安装脚本。
4. **pi-web 安装**：需以 `--allow-scripts=node-pty` 安装 `@jmfederico/pi-web`，
   否则 `node-pty` 原生模块不会编译 / 准备，导致终端功能不可用。安装后运行 `pi-web install`
   注册服务并写入默认配置（host `127.0.0.1` / 端口 `8504`）。该命令可能依赖 systemd 等宿主能力，
   在容器内若失败可忽略（用 `|| true`），运行时仍以 `pi-web-server` 直接启动 Web UI 即可。

## 5. 环境组成

- 底包：`registry.cn-hangzhou.aliyuncs.com/jcleng/library-node:24`（Debian 12）
- 系统依赖：`git`、`python3`（`python` 由 python-is-python3 提供）、`curl`、`ca-certificates`、`tar`、`unzip`
- 全局工具：`skills`、`@opencode/cli`（~/.local/bin）、`docker`/`docker-compose`、`php` 8.4.1、`gh` v2.101.0、`busybox`
- pi agent：`@earendil-works/pi-coding-agent`（命令 `pi`）
- pi-web：`@jmfederico/pi-web`（命令 `pi-web` / `pi-web-server`，Web UI，默认 `127.0.0.1:8504`，监听地址/端口由 `PI_WEB_HOST` / `PI_WEB_PORT` 控制）
- 内置启动脚本 `scripts/pi-web-start` → 镜像内 `/usr/local/bin/pi-web-start`（无 systemd 环境手动拉起 `pi-web-sessiond` + `pi-web-server`，支持 start/stop/restart/status）
- 运行用户：`root`；工作目录：`/home/jcleng/work/mywork/`

## 6. 使用

```bash
docker compose up -d
docker compose exec docker-opencode bash
# 容器内
opencode   # 启动 opencode
pi         # 启动 pi agent
pi-web-server   # 启动 pi-web Web UI（默认 http://127.0.0.1:8504）
```

## 7. 通知

构建完成通过钉钉机器人（`tools-dingtalk_notify`，access_token 来自环境变量 `DINGTALK_ACCESS_TOKEN`）通知。
