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
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
        libnetcdff-dev \
        ca-certificates \
        curl \
        gpg && \
    \
    curl -fsSL https://packages.smallstep.com/keys/apt/repo-signing-key.gpg \
        -o /etc/apt/trusted.gpg.d/smallstep.asc && \
    \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/smallstep.asc] \
https://packages.smallstep.com/stable/debian debs main" \
        > /etc/apt/sources.list.d/smallstep.list && \
    \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        step-cli && \
    \
    ln -sf /usr/lib/aarch64-linux-gnu/libscalapack-openmpi.so.2.1.0 \
           /usr/lib/libscalapack-openmpi.so.2.1.0 && \
    ln -sf /usr/lib/aarch64-linux-gnu/libscalapack-openmpi.so \
           /usr/lib/libscalapack-openmpi.so && \
    \
    rm -rf /var/lib/apt/lists/*

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
#aiida-pseudo install pseudo-dojo -v 0.4 -x PBE -r SR -p standard -f psml
RUN cd /opt/install

# clone and build SIESTA
RUN set -ex && \
    curl -L https://gitlab.com/siesta-project/siesta/-/releases/5.4.1/downloads/siesta-5.4.1.tar.gz -o siesta-5.4.1.tar.gz && \
    tar -xzf siesta-5.4.1.tar.gz && \
    rm -rf siesta-5.4.1.tar.gz && \
    cd siesta-5.4.1 && \
    cmake -S . -B _build \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DLIBGRIDXC_WITH_MPI=ON \
    -DSIESTA_WITH_MPI=ON \
    -DSCALAPACK_LIBRARY="-lscalapack-openmpi" \
    -DSIESTA_WITH_FLOOK=OFF && \
    cmake --build _build -j$(nproc) && \
    cmake --install _build && \
    cd /opt/install && rm -rf siesta-5.4.1

# quick test to verify it was installed correctly
#RUN siesta < /dev/null | head -n 5 || echo "SIESTA compiled and installed successfully"

# ----------------------------------------------------------------------
# Optional: install aiida-siesta plugin
# ----------------------------------------------------------------------
RUN pip install --no-cache-dir aiida-siesta

# Copy from local computer to Docker.
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
COPY configs /opt/configs
#COPY step /usr/local/bin/step
RUN chmod -R a+rx /opt/configs /usr/local/bin/before-notebook.d/

RUN chown -R ${NB_USER}:users /home/jovyan

# Switch back to install Python programs to user space.
RUN pip config set install.user true

# Switch back to the jovyan user.
USER ${NB_USER}
