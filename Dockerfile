FROM aiidalab/full-stack:latest

USER root

ENV PATH="/opt/install/bin:$PATH"
ENV PYTHONPATH="${PYTHONPATH:-}:/opt/install"
ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600

RUN mkdir /opt/install

# ----------------------------------------------------------------------
# 🧩 System dependencies: CP2K, SIESTA, compilers, math libs, build tools
# ----------------------------------------------------------------------
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cp2k \
        cmake \
        build-essential \
        git \
        gfortran \
        pkg-config \
        libmpich-dev \
        libopenmpi-dev \
        liblapack-dev \
        libblas-dev \
        libfftw3-dev \
        libscalapack-openmpi-dev \
        libnetcdff-dev && \
        ln -sf /usr/lib/aarch64-linux-gnu/libscalapack-openmpi.so.2.1.0 /usr/lib/libscalapack-openmpi.so.2.1.0 && \
        ln -sf /usr/lib/aarch64-linux-gnu/libscalapack-openmpi.so /usr/lib/libscalapack-openmpi.so && \
    apt-get clean -y

# Do not install things in user space.
RUN pip config set install.user false

RUN pip install --upgrade --no-cache-dir \
    cp2k-spm-tools \
    mdtraj \
    nglview \
    optuna \
    pandas \
    plotly==5.24.1 \
    pymatgen \
    scikit-image \
    xgboost

# ----------------------------------------------------------------------
# 🧩 Build SIESTA from source (CMake-based build, flook disabled)
# ----------------------------------------------------------------------
RUN cd /opt/install

# clone and build SIESTA
RUN set -ex && \
    git clone https://gitlab.com/siesta-project/siesta.git && \
    cd siesta && \
    cmake -S . -B _build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_Fortran_COMPILER=mpif90 \
        -DCMAKE_C_COMPILER=mpicc \
        -DSIESTA_MPI=ON \
        -DLAPACK_LIBRARIES="-llapack -lblas" \
        -DFORTRAN_FLAGS="-O2" \
        -DSIESTA_WITH_FLOOK=OFF && \
    cmake --build _build -j$(nproc) && \
    cmake --install _build && \
    cd /opt/install && rm -rf siesta

# quick test to verify it was installed correctly
#RUN siesta < /dev/null | head -n 5 || echo "SIESTA compiled and installed successfully"

# ----------------------------------------------------------------------
# Optional: install aiida-siesta plugin
# ----------------------------------------------------------------------
RUN pip install --no-cache-dir aiida-siesta

RUN cd /opt/install && \
    git clone https://github.com/aoterodelaroza/critic2.git && \
    cd /opt/install/critic2 && mkdir build && cd build && \
    cmake .. && \
    make && \
    mv /opt/install/critic2/build/src/critic2 /usr/local/bin/critic2 && \
    chmod a+rx /usr/local/bin/critic2 && \
    rm -rf /opt/install/critic2

# Copy from local computer to Docker.
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
COPY configs /opt/configs
RUN chmod -R a+rx /opt/configs /usr/local/bin/before-notebook.d/

RUN chown -R ${NB_USER}:users /home/jovyan

# Switch back to install Python programs to user space.
RUN pip config set install.user true

# Switch back to the jovyan user.
USER ${NB_USER}
