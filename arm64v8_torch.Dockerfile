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
# Install the dependencies
RUN apt-get install -y clang ninja-build git cmake libjpeg-dev libopenmpi-dev libomp-dev ccache \
    libopenblas-dev libblas-dev libeigen3-dev 

RUN apt-get install -y python3-pip

RUN pip3 install -U --user wheel mock pillow

RUN pip3 install setuptools==58.3.0

RUN mkdir ~/torch/ && cd ~/torch/ && \
    git clone -b v1.13.0 --depth=1 --recursive https://github.com/pytorch/pytorch.git && \
    cd pytorch && pip3 install -r requirements.txt

ENV BUILD_CAFFE2_OPS=OFF
ENV USE_FBGEMM=OFF
ENV USE_FAKELOWP=OFF
ENV BUILD_TEST=OFF
ENV USE_MKLDNN=OFF
ENV USE_NNPACK=ON
ENV USE_XNNPACK=ON
ENV USE_QNNPACK=ON
ENV MAX_JOBS=12
ENV USE_NUMPY=ON
ENV USE_OPENCV=OFF
ENV USE_NCCL=OFF
ENV BUILD_SHARED_LIBS=ON
ENV PATH=/usr/lib/ccache:$PATH
ENV CC=clang
#ENV CXX=clang++

RUN cd ~/torch/ && ./tools/build_libtorch.py