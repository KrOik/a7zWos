FROM docker.m.daocloud.io/library/debian:bookworm-slim

# 安装构建依赖
RUN apt-get update && apt-get install -y     build-essential     debootstrap     qemu-user-static     binfmt-support     debian-keyring     debian-archive-keyring     gnupg     wget     curl     git     make     parted     dosfstools     e2fsprogs     btrfs-progs     jq     python3     python3-pip     rsync     squashfs-tools     zip     unzip     xz-utils     && rm -rf /var/lib/apt/lists/*

# 安装jsonnet
RUN pip3 install jsonnet

# 创建工作目录
WORKDIR /workspace

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

CMD ["/bin/bash"]
