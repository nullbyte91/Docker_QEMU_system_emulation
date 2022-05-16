FROM arm64v8/ubuntu:bionic
COPY ./bin/qemu-aarch64-static /usr/bin/qemu-aarch64-static

# Basic apt update
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates &&  rm -rf /var/lib/apt/lists/*
 
# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Get basic packages
RUN apt-get update && apt-get install -y \
    apparmor \
    aufs-tools \
    automake \
    bash-completion \
    btrfs-tools \
    build-essential \
    cmake \
    createrepo \
    curl \
    dpkg-sig \
    g++ \
    gcc \
    git \
    iptables \
    jq \
    libapparmor-dev \
    libc6-dev \
    libcap-dev \
    libsystemd-dev \
    libyaml-dev \
    mercurial \
    net-tools \
    parallel \
    pkg-config \
    golang-go \
    iproute2 \
    iputils-ping \
    vim-common \
    vim \
    --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get upgrade && apt-get install -y file
# Copy and compile CPP and check the binary extension
COPY example/hello_world.cpp /home/
RUN g++ /home/hello_world.cpp -o /home/outfile
RUN file /home/outfile