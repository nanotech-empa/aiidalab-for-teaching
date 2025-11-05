FROM aiidalab/full-stack:latest

USER root

ENV PATH="/opt/install/bin:$PATH"
ENV PYTHONPATH="${PYTHONPATH:-}:/opt/install"
ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600

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
    scikit-image \
    xgboost

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
