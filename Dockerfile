# 构建 opencode 运行环境
# 底包：Node 24（来自阿里云镜像仓库）
FROM registry.cn-hangzhou.aliyuncs.com/jcleng/library-node:24

# 使用 root 用户
USER root

# 系统依赖：git / python / curl 等
# python-is-python3 提供 `python` 命令（指向 python3）
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        python3 \
        python-is-python3 \
        python3-pip \
        curl \
        ca-certificates \
        tar \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# 全局安装 skills CLI（支持 `npx skills` / `skills` 命令）
# 安装 opencode
RUN npm install -g skills @opencode/cli
# 安装 pi agent（pi.dev 官方包）
RUN npm install -g @earendil-works/pi-coding-agent
# 安装 pi-web（Pi Coding Agent 的 Web UI，npm 包 @agegr/pi-web）
# --allow-scripts 允许 node-pty 准备其原生模块（终端所需），也放行 pi-web 的 postinstall
RUN npm install -g @agegr/pi-web@latest \
    --allow-scripts=@agegr/pi-web,node-pty,@google/genai,protobufjs
# @agegr/pi-web 为单进程架构，没有 `pi-web install` 注册步骤，
# 启动方式：pi-web --hostname 127.0.0.1 --port 8504（见 scripts/pi-web-start）
# 内置 pi-web 启动脚本（无 systemd 环境下手动拉起 pi-web 服务）
COPY scripts/pi-web-start /usr/local/bin/pi-web-start
RUN chmod +x /usr/local/bin/pi-web-start

# ! 自定义自己的命令
# docker 记得映射宿主机 /var/run/docker.sock
COPY --from=registry.cn-hangzhou.aliyuncs.com/jcleng/library-docker:24.0.9-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=registry.cn-hangzhou.aliyuncs.com/jcleng/library-docker:24.0.9-cli /usr/local/bin/docker-compose /usr/local/bin/docker-compose
# gh命令
RUN curl -fsSL https://github.com/cli/cli/releases/download/v2.101.0/gh_2.101.0_linux_amd64.tar.gz \
    | tar -xz -C /usr/local/bin --strip-components=2 gh_2.101.0_linux_amd64/bin/gh

# opencode 安装脚本默认将二进制放到 ~/.local/bin
# 写入 PATH，保证容器内可直接调用 opencode
ENV PATH="/root/.local/bin:${PATH}"

# pi-web 监听地址/端口（Web UI）。如需容器外可达，将下方 PI_WEB_HOSTNAME 改为 0.0.0.0
ENV PI_WEB_HOSTNAME=127.0.0.1 \
    PI_WEB_PORT=8504 \
    PI_WEB_NO_OPEN=1 \
    PI_WEB_SKIP_VERSION_CHECK=1

# 工作目录与 docker-compose 挂载路径保持一致
WORKDIR /home/jcleng/work/mywork/

# 默认进入交互 shell，方便在容器内启动 opencode / pi / pi-web
CMD ["bash"]
