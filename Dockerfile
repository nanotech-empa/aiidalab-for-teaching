# Multi-stage build: AiiDAlab + LAMMPS+MACE (CPU, ARM64-compatible)

# ============================
# Stage 1: Builder
# ============================
FROM aiidalab/full-stack:latest AS builder

USER root

ARG PYTORCH_VERSION=2.5.1
ARG MACE_VERSION=0.3.14
ARG LAMMPS_REPO=https://github.com/empa-scientific-it/lammps.git
ARG LAMMPS_BRANCH=mace-features

# Build dependencies
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    unzip \
    cmake \
    automake \
    autoconf \
    build-essential \
    openmpi-bin \
    libopenmpi-dev \
    libblas-dev \
    liblapack-dev \
    libgsl-dev \
    libeigen3-dev \
    gfortran \
    pkg-config \
    wget \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# PyTorch from CPU wheel index
RUN pip install --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cpu \
    torch==${PYTORCH_VERSION} \
    torchvision \
    torchaudio

# Build tools
RUN pip install --no-cache-dir \
    scikit-build \
    ninja \
    cmake==3.28.1 \
    pybind11

RUN mkdir -p /opt/wheels

# ABI compatibility flags
ENV CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0"
ENV CPPFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0"

# yaml-cpp: manual build for ABI compatibility
RUN apt-get remove -y libyaml-cpp-dev libyaml-cpp* || true
RUN cd /opt && \
    git clone --depth 1 https://github.com/jbeder/yaml-cpp.git && \
    mkdir -p yaml-cpp/build && cd yaml-cpp/build && \
    cmake .. \
    -D CMAKE_BUILD_TYPE=Release \
    -D YAML_BUILD_SHARED_LIBS=ON \
    -D CMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 -fPIC" \
    -D CMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc) && \
    make install

# LAMMPS: clone custom branch
RUN cd /opt && \
    git clone --depth 1 --branch ${LAMMPS_BRANCH} ${LAMMPS_REPO} lammps

WORKDIR /opt/lammps

# Pre-build lib-pace
RUN CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 ${CXXFLAGS}" \
    CPPFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 ${CPPFLAGS}" \
    make -C src lib-pace args="-b"

# Build LAMMPS C++ and Python wheel
RUN export CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 ${CXXFLAGS}" \
    CPPFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 ${CPPFLAGS}" && \
    mkdir -p build && cd build && \
    cmake ../cmake \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/opt/lammps \
    -D CMAKE_C_STANDARD=11 \
    -D CMAKE_CXX_STANDARD=17 \
    -D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -D CMAKE_SHARED_LINKER_FLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" \
    -D CMAKE_EXE_LINKER_FLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" \
    -D CMAKE_PREFIX_PATH="/usr/local;/opt/conda;$(python -c 'import torch.utils; print(torch.utils.cmake_prefix_path)')" \
    -D MKL_INCLUDE_DIR="" \
    -D BUILD_MPI=ON \
    -D BUILD_OMP=ON \
    -D BUILD_SHARED_LIBS=ON \
    -D PKG_BODY=ON \
    -D PKG_EXTRA-FIX=ON \
    -D PKG_KSPACE=ON \
    -D PKG_MANYBODY=ON \
    -D PKG_ML-MACE=ON \
    -D PKG_ML-PACE=ON \
    -D PKG_ML-QUIP=OFF \
    -D PKG_MOLECULE=ON \
    -D PKG_OPT=ON \
    -D PKG_PLUMED=ON \
    -D PKG_RIGID=ON \
    -D DOWNLOAD_PLUMED=ON \
    -D DOWNLOAD_QUIP=OFF \
    -D PLUMED_MODE=static \
    && cmake --build . -j"$(nproc)" && cmake --install . && \
    cd /opt/lammps && \
    python python/install.py \
    -n \
    -p python/lammps \
    -l build/liblammps.so \
    -v src/version.h \
    -w /opt/wheels

# wigxjpf: static lib for librascal
RUN cd /opt && \
    git clone https://github.com/nd-nuclear-theory/wigxjpf.git && \
    cd wigxjpf && \
    make clean && \
    make -j$(nproc) && \
    cp lib/libwigxjpf.a /usr/local/lib/ && \
    make clean && \
    make -j$(nproc) OMP=1 && \
    cp lib/libwigxjpf.a /usr/local/lib/libwigxjpfo.a && \
    cp -r inc/* /usr/local/include/ && \
    cp gen/wigxjpf_auto_config.h /usr/local/include/

# librascal: CMake fixes + build wheel
COPY Findwigxjpf.cmake /usr/local/lib/cmake/Findwigxjpf.cmake
RUN mkdir -p /usr/local/lib/cmake/wigxjpf && \
    cp /usr/local/lib/cmake/Findwigxjpf.cmake /usr/local/lib/cmake/wigxjpf/wigxjpfConfig.cmake

ENV CMAKE_BUILD_PARALLEL_LEVEL=1

RUN cd /opt && \
    git clone https://github.com/lab-cosmo/librascal.git && \
    cd librascal && \
    sed -i 's/cmake_minimum_required.*/cmake_minimum_required(VERSION 3.18)/' CMakeLists.txt && \
    sed -i '/cmake_minimum_required/a find_package(wigxjpf REQUIRED)' CMakeLists.txt && \
    sed -i '/cmake_minimum_required/a find_package(pybind11 REQUIRED)' CMakeLists.txt && \
    echo "" > cmake/wigxjpf.cmake && \
    echo "" > cmake/pybind11.cmake && \
    PYBIND11_CMAKE_DIR=$(python -c 'import pybind11; print(pybind11.get_cmake_dir())') && \
    export CMAKE_ARGS="-DCMAKE_CXX_FLAGS='-D_GLIBCXX_USE_CXX11_ABI=0' \
    -DCMAKE_PREFIX_PATH='/usr/local;/usr/share/eigen3/cmake;/usr/share/cmake/pybind11;/opt/conda;$PYBIND11_CMAKE_DIR'" && \
    pip wheel . --no-deps -w /opt/wheels -v


# ============================
# Stage 2: Runtime
# ============================

FROM aiidalab/full-stack:latest AS runtime

# Configure HyperQueue (HQ)-related variables
ARG HQ_VER=0.19.0
ARG HQ_URL_AMD64="https://github.com/It4innovations/hyperqueue/releases/download/v${HQ_VER}/hq-v${HQ_VER}-linux-x64.tar.gz"
ARG HQ_URL_ARM64="https://github.com/It4innovations/hyperqueue/releases/download/v${HQ_VER}/hq-v${HQ_VER}-linux-arm64-linux.tar.gz"
ARG AIIDA_HQ_PKG="aiida-hyperqueue~=0.3.0"
ARG COMPUTER_LABEL="localhost"
# Docker sets TARGETARCH automatically (e.g. "amd64" or "arm64")
ARG TARGETARCH

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV COMPUTER_LABEL=$COMPUTER_LABEL
#
# Download and unpack the correct hq binary for the architecture:
#
RUN set -ex; \
    if [ "${TARGETARCH}" = "arm64" ]; then \
      echo "Downloading hyperqueue for ARM64..."; \
      wget -c -O hq.tar.gz "${HQ_URL_ARM64}"; \
    else \
      echo "Downloading hyperqueue for x86_64..."; \
      wget -c -O hq.tar.gz "${HQ_URL_AMD64}"; \
    fi && \
    tar xf hq.tar.gz -C /usr/local/bin/


# Runtime libs (libopenblas, libjpeg9 for torchvision)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    cp2k \
    openmpi-bin \
    libopenmpi3 \
    libgsl27 \
    libgslcblas0 \
    libblas3 \
    liblapack3 \
    libgfortran5 \
    libopenblas-base \
    libjpeg9 \
    libgomp1 \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Copy compiled artifacts
COPY --from=builder /opt/lammps /opt/lammps

# Custom ABI yaml-cpp
RUN rm -f /usr/lib/x86_64-linux-gnu/libyaml-cpp.so* /usr/lib/aarch64-linux-gnu/libyaml-cpp.so* || true
COPY --from=builder /usr/local/lib/libyaml-cpp.so* /usr/local/lib/

COPY --from=builder /opt/wheels /opt/wheels

ARG PYTORCH_VERSION=2.5.1
ARG MACE_VERSION=0.3.14

# Disable pip install in user folder
RUN pip config set install.user false

# Install Python packages + wheels
RUN pip install --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cpu \
    torch==${PYTORCH_VERSION} torchvision torchaudio && \
    pip install --no-cache-dir \
    mace-torch==${MACE_VERSION} \
    cp2k-spm-tools \
    ${AIIDA_HQ_PKG} \
    mdtraj \
    nglview \
    optuna \
    pandas \
    plotly==5.24.1 \
    pymatgen \
    pythtb \
    scikit-learn \
    scikit-image \
    skmatter \
    spglib \
    sympy \
    torchmetrics \
    xgboost && \
    pip install --no-cache-dir /opt/wheels/*.whl && \
    rm -rf /opt/wheels

# Dynamic linker config (critical for torch libs)
RUN TORCH_LIB_DIR=$(python3 -c "import torch; import os; print(os.path.join(os.path.dirname(torch.__file__), 'lib'))") && \
    if [ ! -d "$TORCH_LIB_DIR" ]; then echo "FATAL: Torch lib dir not found at $TORCH_LIB_DIR"; exit 1; fi && \
    printf "%s\n%s\n%s\n%s\n%s\n" \
    "/usr/local/lib" \
    "$TORCH_LIB_DIR" \
    "/opt/lammps/lib" \
    "/usr/lib/aarch64-linux-gnu" \
    "/usr/lib/x86_64-linux-gnu" \
    > /etc/ld.so.conf.d/aiidalab-libs.conf && \
    ldconfig

ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600
ENV ASE_LAMMPSRUN_COMMAND=/opt/lammps/bin/lmp
ENV PATH=/opt/lammps/bin:$PATH
ENV LD_LIBRARY_PATH="/opt/lammps/lib:/usr/local/lib:${LD_LIBRARY_PATH:-}"

COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
COPY configs /opt/configs
RUN chmod -R a+rx /opt/configs /usr/local/bin/before-notebook.d/

RUN chown -R ${NB_USER}:users /home/${NB_USER}

# Enable back pip install in user folder
RUN pip config set install.user true

USER ${NB_USER}
