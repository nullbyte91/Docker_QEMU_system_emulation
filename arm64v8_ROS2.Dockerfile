FROM arm64v8/ubuntu:focal
COPY ./bin/qemu-system-aarch64 /usr/bin/qemu-system-aarch64

ARG DEBIAN_FRONTEND=noninteractive

# Basic apt update
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates 
 
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
    build-essential \
    cmake \
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

RUN apt-get update && apt install -y software-properties-common && add-apt-repository main && add-apt-repository universe && add-apt-repository restricted && add-apt-repository multiverse

RUN apt update && apt install -y curl && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt update && apt install -y \
  python3-flake8-docstrings \
  python3-pip \
  python3-pytest-cov \
  ros-dev-tools

RUN python3 -m pip install -U \
   flake8-blind-except \
   flake8-builtins \
   flake8-class-newline \
   flake8-comprehensions \
   flake8-deprecated \
   flake8-import-order \
   flake8-quotes \
   pytest-repeat \
   pytest-rerunfailures

RUN apt-get update && apt-get -y upgrade

RUN mkdir -p ~/ros2_rolling/src && cd ~/ros2_rolling && vcs import --input https://raw.githubusercontent.com/ros2/ros2/rolling/ros2.repos src && \
    apt upgrade && rosdep init 
RUN rosdep update && cd ~/ros2_rolling/ && rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers" 

RUN cd ~/ros2_rolling/ && colcon build --symlink-install