FROM aiidalab/full-stack:2025.1025

USER root

ENV PATH="/opt/install/bin:$PATH"
ENV PYTHONPATH="${PYTHONPATH:-}:/opt/install"
ENV deepmd_source_dir=/opt/install/deepmd-kit
ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600
ENV ASE_LAMMPSRUN_COMMAND="/usr/bin/lmp_serial"

RUN mkdir /opt/install

RUN apt-get update -y && \
    apt-get install -y  cp2k \
                        libmpich-dev \
                        libopenmpi-dev \
                        build-essential && \
    apt-get clean -y

# Do not install things in user space.
RUN pip config set install.user false

RUN pip install --upgrade --no-cache-dir \
    cmake \
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
    tensorflow \
    torch \
    torchmetrics \
    torchvision \
    xgboost

RUN cd /opt/install && \
    git clone https://github.com/deepmodeling/deepmd-kit.git deepmd-kit

RUN cd $deepmd_source_dir && \
    pip install .

RUN cd $deepmd_source_dir/source && \
    mkdir build && \
    cd build

RUN cd $deepmd_source_dir/source/build && \
    cmake -DUSE_TF_PYTHON_LIBS=TRUE -DCMAKE_INSTALL_PREFIX=$deepmd_source_dir .. && \
    make && \
    make install

RUN cd $deepmd_source_dir/source/build && make lammps

RUN cd /opt/install && \
    git clone https://github.com/lammps/lammps && \
    cd lammps/src && \
    cp -r $deepmd_source_dir/source/build/USER-DEEPMD . && \
    make lib-pace args="-b" && \
    make yes-molecule && \
    make yes-reaxff && \
    make yes-rigid && \
    make yes-ml-pace && \
    make yes-manybody && \
    make lib-voronoi args="-b" && \
    make yes-voronoi && \
    make lib-plumed args="-b" CC=gcc CXX=g++ && \
    make yes-plumed && \
    make yes-kspace && \
    make yes-extra-fix && \
    make yes-user-deepmd && \
    make serial

RUN cp /opt/install/lammps/src/lmp_serial /usr/bin/lmp_serial

RUN rm -rf /opt/install/lammps/

RUN cd /opt/install && \
    git clone https://github.com/lab-cosmo/librascal.git && \
    cd librascal && \
    pip install  .

RUN cd /opt/install && \
    git clone https://github.com/aoterodelaroza/critic2.git && \
    cd /opt/install/critic2 && mkdir build && cd build && \
    cmake .. && \
    make

RUN mv /opt/install/critic2/build/src/critic2 /usr/local/bin/critic2 && \
    chmod a+rx /usr/local/bin/critic2 && \
    rm -rf /opt/install/critic2

# Copy from local computer to Docker.
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
COPY configs /opt/configs
RUN chmod a+x /usr/local/bin/before-notebook.d/*
RUN chmod a+rx /opt/configs
RUN chmod a+rx /opt/configs/*

RUN chown -R ${NB_USER}:users /home/jovyan

# Switch back to install Python programs to user space.
RUN pip config set install.user true

# Switch back to the jovyan user.
USER ${NB_USER}
