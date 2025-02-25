FROM aiidalab/full-stack:2025.1025

USER root

RUN apt-get update -y && apt-get install -y  cp2k libmpich-dev libopenmpi-dev  build-essential  && apt-get clean -y

RUN pip install virtualenv

ENV deepmd_root=/opt/deepmd-kit
ENV deepmd_source_dir=/opt/deepmd-kit
ENV tensorflow_venv=/opt/tensorflow_venv
ENV deepmd_root=/opt/deepmd-kit

RUN cd /opt && git clone https://github.com/deepmodeling/deepmd-kit.git deepmd-kit

RUN virtualenv -p python3 $tensorflow_venv

RUN source $tensorflow_venv/bin/activate


RUN pip install --upgrade tensorflow

RUN cd $deepmd_source_dir && pip install .

RUN cd $deepmd_source_dir/source && mkdir build && cd build

RUN cd $deepmd_source_dir/source/build && pwd && pip install -U cmake && cmake -DUSE_TF_PYTHON_LIBS=TRUE -DCMAKE_INSTALL_PREFIX=$deepmd_source_dir .. && make && make install

RUN cd $deepmd_source_dir/source/build && make lammps

RUN cd /opt &&  git clone https://github.com/lammps/lammps && cd lammps/src && cp -r $deepmd_source_dir/source/build/USER-DEEPMD . && make lib-pace args="-b" && make yes-molecule && make yes-reaxff && make yes-rigid && make yes-ml-pace && make yes-manybody && make lib-voronoi args="-b" && make yes-voronoi && make lib-plumed args="-b" CC=gcc CXX=g++ && make yes-plumed && make yes-kspace && make yes-extra-fix && make yes-user-deepmd && make serial

RUN deactivate

RUN cp /opt/lammps/src/lmp_serial /usr/bin/lmp_serial

RUN rm -rf /opt/lammps/

ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600
ENV ASE_LAMMPSRUN_COMMAND="/usr/bin/lmp_serial"


RUN pip install nglview

RUN pip install mdtraj

RUN pip install  skmatter

RUN cd /opt && git clone https://github.com/lab-cosmo/librascal.git && cd librascal && pip install  .

RUN pip install scikit-learn optuna xgboost lightgbm sympy pandas

RUN pip install torch  torchmetrics torchvision

RUN cd /opt && git clone https://github.com/aoterodelaroza/critic2.git

RUN cd /opt/critic2 && mkdir build && cd build && cmake .. && make



RUN pip install pymatgen scikit-image


RUN pip install  spglib

RUN pip install pythtb

RUN pip install cp2k-spm-tools

#### hyperqueue


RUN mv /opt/critic2/build/src/critic2 /usr/local/bin/critic2
RUN chmod a+rx /usr/local/bin/critic2
RUN rm -rf /opt/critic2

####
# Copy from local computer to Docker
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
COPY configs /opt/configs
RUN chmod a+rx /opt/configs
RUN chmod a+rx /opt/configs/*
RUN chown -R ${NB_USER}:users /home/jovyan
USER ${NB_USER}
