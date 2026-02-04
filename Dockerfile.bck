FROM aiidalab/full-stack:latest

USER root

# -------------------------------------------------
# Global environment
# -------------------------------------------------
ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600
ENV ASE_LAMMPSRUN_COMMAND=/usr/local/bin/lmp

ENV PATH=/opt/install/bin:$PATH
ENV PYTHONPATH=/opt/install:${PYTHONPATH:-}

RUN mkdir -p /opt/install

# -------------------------------------------------
# System dependencies
# -------------------------------------------------
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates \
        git \
        curl \
        unzip \
        cp2k \
        cmake \
        automake \
        autoconf \
        build-essential \
        libmpich-dev \
        libopenmpi-dev \
        libblas-dev \
        liblapack-dev \
        libgsl-dev \
        libyaml-cpp-dev \
        libeigen3-dev \
        pybind11-dev \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Python stack (system-wide, Python 3.9)
# -------------------------------------------------
RUN pip config set install.user false

RUN pip install --no-cache-dir --upgrade \
    cp2k-spm-tools \
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
    torch \
    torchmetrics \
    torchvision \
    xgboost \
    mace-torch

# -------------------------------------------------
# libtorch (CPU, required by pair_style mace)
# -------------------------------------------------
#RUN cd /opt/install && \
#    curl -L https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-2.1.0%2Bcpu.zip \
#        -o libtorch.zip && \
#    unzip libtorch.zip && \
#    rm libtorch.zip
#
#ENV LD_LIBRARY_PATH=/opt/install/libtorch/lib:${LD_LIBRARY_PATH:-}

# -------------------------------------------------
# PLUMED (standalone)
# -------------------------------------------------
RUN cd /opt/install && \
    git clone https://github.com/plumed/plumed2.git && \
    cd plumed2 && \
    ./configure \
        --prefix=/opt/install/plumed \
        --enable-modules=all \
        CC=gcc CXX=g++ FC=gfortran && \
    make -j$(nproc) && \
    make install && \
    rm -rf /opt/install/plumed2

ENV PATH=/opt/install/plumed/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/install/plumed/lib:${LD_LIBRARY_PATH}
ENV PKG_CONFIG_PATH=/opt/install/plumed/lib/pkgconfig:${PKG_CONFIG_PATH:-}
ENV PLUMED_KERNEL=/opt/install/plumed/lib/libplumedKernel.so

# -------------------------------------------------
# LAMMPS (with PLUMED + MACE)
# -------------------------------------------------
RUN cd /opt/install && \
    git clone https://github.com/empa-scientific-it/lammps.git && \
    cd lammps && \
    mkdir build && cd build && \
    cmake ../cmake \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_PREFIX_PATH="/opt/install/libtorch;/opt/install/plumed" \
        -D CMAKE_C_COMPILER=gcc \
        -D CMAKE_CXX_COMPILER=g++ \
        -D CMAKE_Fortran_COMPILER=gfortran \
        -D BUILD_MPI=ON \
        -D BUILD_OMP=ON \
        -D BUILD_SHARED_LIBS=ON \
        -D PKG_ML-MACE=ON \
        -D PKG_ML-QUIP=OFF \
        -D DOWNLOAD_QUIP=OFF \
        -D PKG_ML-PACE=ON \
        -D PKG_MANYBODY=ON \
        -D PKG_BODY=ON \
        -D PKG_MOLECULE=ON \
        -D PKG_OPT=ON \
        -D PKG_KSPACE=ON \
        -D PKG_RIGID=ON \
        -D PKG_EXTRA-FIX=ON \
        -D PKG_PLUMED=ON && \
    make -j$(nproc) && \
    make install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/lammps.conf && \
    ldconfig && \
    rm -rf /opt/install/lammps

# -------------------------------------------------
# wigxjpf (system install)
# -------------------------------------------------
RUN cd /opt/install && \
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


# -------------------------------------------------
# CMake find module for wigxjpf
# -------------------------------------------------
COPY Findwigxjpf.cmake /usr/local/lib/cmake/Findwigxjpf.cmake

# -------------------------------------------------
# librascal (use system wigxjpf via Findwigxjpf.cmake)
# -------------------------------------------------
ENV CMAKE_ARGS="\
-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
-DCMAKE_PREFIX_PATH=/usr/share/eigen3/cmake:/usr/share/cmake/pybind11"

RUN cd /opt/install && \
    git clone https://github.com/lab-cosmo/librascal.git && \
    cp /usr/local/lib/cmake/Findwigxjpf.cmake librascal/cmake/ && \
    cd librascal && \
    pip install . -v

# -------------------------------------------------
# Hooks / configs
# -------------------------------------------------
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
COPY configs /opt/configs
RUN chmod -R a+rx /opt/configs /usr/local/bin/before-notebook.d/

RUN chown -R ${NB_USER}:users /home/jovyan

RUN pip config set install.user true

USER ${NB_USER}
