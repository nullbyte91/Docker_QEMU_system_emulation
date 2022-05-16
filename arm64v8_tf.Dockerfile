FROM arm64v8/ubuntu:bionic
COPY ./bin/qemu-aarch64-static /usr/bin/qemu-aarch64-static

# Basic apt update
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates &&  rm -rf /var/lib/apt/lists/*

# Install Bazel
RUN apt-get update && apt-get install -y openjdk-11-jdk unzip zip && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y wget &&  rm -rf /var/lib/apt/lists/*
RUN cd /tmp/ && wget https://github.com/bazelbuild/bazel/releases/download/3.1.0/bazel-3.1.0-dist.zip && unzip -d bazel bazel-3.1.0-dist.zip

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

RUN cd /tmp/bazel/ && env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh && cp output/bazel /usr/local/bin/bazel



# TFLite installation from IMX mirror [Try Org source from Tensorflow]
RUN apt-get update && apt-get install -y unzip 
RUN cd /tmp && wget https://github.com/tensorflow/tensorflow/archive/refs/tags/v2.4.1.tar.gz && tar -xvf v2.4.1.tar.gz && mv tensorflow-2.4.1/ tensorflow
RUN apt-get update && apt-get install -y python3-pip  build-essential make cmake wget zip unzip libhdf5-dev libc-ares-dev libeigen3-dev libatlas-base-dev libopenblas-dev libblas-dev \
            gfortran liblapack-dev
RUN pip3 install --upgrade setuptools
RUN pip3 install keras_applications --no-deps
RUN pip3 install keras_preprocessing --no-deps
RUN pip3 install -U --user six wheel mock
RUN pip3 install --upgrade pip
RUN pip3 install cython numpy

RUN cd /tmp/tensorflow/ && export TMP=/tmp \
    PYTHON_BIN_PATH=$(which python3) \
    PYTHON_LIB_PATH=$(python3 -c 'import site; print(site.getsitepackages()[0])') \
    TENSORRT_INSTALL_PATH=/usr/lib/aarch64-linux-gnu \
    GCC_HOST_COMPILER_PATH=$(which gcc) \
    CC_OPT_FLAGS="-march=native" \
    TF_SET_ANDROID_WORKSPACE=0 && \
    ./configure
RUN cd /tmp/tensorflow/ && bazel build --jobs 9 --config=opt \
            --config=noaws \
            --local_cpu_resources=HOST_CPUS*0.75 \
            --local_ram_resources=HOST_RAM*0.75 \
            //tensorflow/tools/pip_package:build_pip_package