FROM arm64v8/ubuntu:bionic
COPY qemu-aarch64-static /usr/bin/qemu-aarch64-static

# Basic apt update
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates &&  rm -rf /var/lib/apt/lists/*
 
# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Python3.6 Support
RUN apt-get update && apt-get install -y python3.6 python3-distutils python3-pip python3-apt

# set python 3 as the default python version
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
RUN pip3 install --upgrade pip requests setuptools pipenv

# Get basic packages
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

RUN rm -rf /tmp
RUN mkdir /tmp
RUN chmod 1777 /tmp

RUN apt-get update && apt-get install -y libtool
# Build and Install Google Protobuf lib
RUN mkdir $HOME/armnn-devenv && cd $HOME/armnn-devenv && git clone -b v3.12.0 https://github.com/google/protobuf.git protobuf && \
    cd protobuf && git submodule update --init --recursive && ./autogen.sh && \
    mkdir x86_64_build && cd x86_64_build && ../configure --prefix=$HOME/armnn-devenv/google/x86_64_pb_install && \
    make install -j8 && \
    cd .. && \
    mkdir arm64_build && cd arm64_build && \
    CC=aarch64-linux-gnu-gcc \
    CXX=aarch64-linux-gnu-g++ \
    ../configure --host=aarch64-linux \
    --prefix=$HOME/armnn-devenv/google/arm64_pb_install \
    --with-protoc=$HOME/armnn-devenv/google/x86_64_pb_install/bin/protoc && \
    make install -j16

# Compile Compute Lib
RUN cd $HOME/armnn-devenv && git clone https://github.com/ARM-software/ComputeLibrary.git

RUN cd $HOME/armnn-devenv && git clone https://github.com/ARM-software/armnn.git && cd armnn && \
    git checkout branches/armnn_21_08 && bash scripts/get_compute_library.sh

RUN apt-get update && apt install -y scons
RUN cd $HOME/armnn-devenv/ComputeLibrary/ && scons arch=arm64-v8a neon=1 opencl=1 embed_kernels=1 extra_cxx_flags="-fPIC" -j4 internal_only=0

# Compile Flatbuffer
RUN apt-get update && apt install -y wget
RUN cd $HOME/armnn-devenv && wget -O flatbuffers-1.12.0.tar.gz https://github.com/google/flatbuffers/archive/v1.12.0.tar.gz && tar xf flatbuffers-1.12.0.tar.gz 
RUN cd $HOME/armnn-devenv/flatbuffers-1.12.0 && rm -f CMakeCache.txt && mkdir build-arm64 && cd build-arm64 && \
    CXXFLAGS="-fPIC" cmake .. -DCMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc \
     -DCMAKE_CXX_COMPILER=/usr/bin/aarch64-linux-gnu-g++ \
     -DFLATBUFFERS_BUILD_FLATC=1 \
     -DCMAKE_INSTALL_PREFIX:PATH=$HOME/armnn-devenv/flatbuffers-arm64 \
     -DFLATBUFFERS_BUILD_TESTS=0 && \
     make all install

# Build onxx
RUN cd $HOME/armnn-devenv && git clone https://github.com/onnx/onnx.git && cd onnx && \
    git fetch https://github.com/onnx/onnx.git 553df22c67bee5f0fe6599cff60f1afc6748c635 && git checkout FETCH_HEAD && \
    LD_LIBRARY_PATH=$HOME/armnn-devenv/google/x86_64_pb_install/lib:$LD_LIBRARY_PATH \
    $HOME/armnn-devenv/google/x86_64_pb_install/bin/protoc \
    onnx/onnx.proto --proto_path=. --proto_path=../google/x86_64_pb_install/include --cpp_out $HOME/armnn-devenv/onnx

# Build TFLite
RUN cd $HOME/armnn-devenv && git clone https://github.com/tensorflow/tensorflow.git
RUN cd $HOME/armnn-devenv/tensorflow/ && git checkout fcc4b966f1265f466e82617020af93670141b009 && cd .. && \
    mkdir tflite && cd tflite && cp ../tensorflow/tensorflow/lite/schema/schema.fbs . && ../flatbuffers-1.12.0/build-arm64/flatc -c --gen-object-api --reflect-types --reflect-names schema.fbs

# Build ARMNN
RUN cd $HOME/armnn-devenv/armnn && mkdir build && cd build && \
    CXX=aarch64-linux-gnu-g++ CC=aarch64-linux-gnu-gcc cmake .. \
    -DARMCOMPUTE_ROOT=$HOME/armnn-devenv/ComputeLibrary \
    -DARMCOMPUTE_BUILD_DIR=$HOME/armnn-devenv/ComputeLibrary/build/ \
    -DARMCOMPUTENEON=1 -DARMCOMPUTECL=1 -DARMNNREF=1 \
    -DONNX_GENERATED_SOURCES=$HOME/armnn-devenv/onnx \
    -DBUILD_ONNX_PARSER=1 \
    -DBUILD_TF_LITE_PARSER=1 \
    -DTF_LITE_GENERATED_PATH=$HOME/armnn-devenv/tflite \
    -DFLATBUFFERS_ROOT=$HOME/armnn-devenv/flatbuffers-arm64 \
    -DFLATC_DIR=$HOME/armnn-devenv/flatbuffers-1.12.0/build-arm64 \
    -DPROTOBUF_ROOT=$HOME/armnn-devenv/google/x86_64_pb_install \
    -DPROTOBUF_ROOT=$HOME/armnn-devenv/google/x86_64_pb_install/ \
    -DPROTOBUF_LIBRARY_DEBUG=$HOME/armnn-devenv/google/arm64_pb_install/lib/libprotobuf.so.23.0.0 \
    -DPROTOBUF_LIBRARY_RELEASE=$HOME/armnn-devenv/google/arm64_pb_install/lib/libprotobuf.so.23.0.0
RUN cd $HOME/armnn-devenv/armnn/build/ && make -j8

RUN cd $HOME/armnn-devenv/armnn/samples/ObjectDetection/ && mkdir build && cd build && cmake  -DARMNN_LIB_DIR=$HOME/armnn-devenv/armnn/build/ .. && make -j2