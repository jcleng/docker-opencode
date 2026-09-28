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
        curl \
        ca-certificates \
        tar \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# 全局安装 skills CLI（支持 `npx skills` / `skills` 命令）
# 安装 opencode
RUN npm install -g skills @opencode/cli

# ! 自定义自己的命令
# busybox
ADD https://busybox.net/downloads/binaries/1.21.1/busybox-x86_64 /bin/busybox_new
RUN chmod +x /bin/busybox_new && mv /bin/busybox_new /bin/busybox
# docker 记得映射宿主机 /var/run/docker.sock
COPY --from=registry.cn-hangzhou.aliyuncs.com/jcleng/library-docker:24.0.9-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=registry.cn-hangzhou.aliyuncs.com/jcleng/library-docker:24.0.9-cli /usr/local/bin/docker-compose /usr/local/bin/docker-compose
# php
RUN curl -fsSL https://dl.static-php.dev/static-php-cli/common/php-8.4.1-cli-linux-x86_64.tar.gz | tar -xz -C /usr/local/bin

# opencode 安装脚本默认将二进制放到 ~/.local/bin
# 写入 PATH，保证容器内可直接调用 opencode
ENV PATH="/root/.local/bin:${PATH}"

# 工作目录与 docker-compose 挂载路径保持一致
WORKDIR /home/jcleng/work/mywork/

# 默认进入交互 shell，方便在容器内启动 opencode
CMD ["bash"]
