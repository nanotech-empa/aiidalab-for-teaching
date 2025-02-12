FROM aiidalab/full-stack:2025.1025

USER root


#RUN apt-get update -y && apt-get install -y cp2k && apt-get clean -y
# Install required system dependencies, including MPI development libraries
RUN apt-get update -y && apt-get install -y  cp2k libmpich-dev libopenmpi-dev  build-essential  && apt-get clean -y

USER ${NB_USER}




RUN mkdir /home/${NB_USER}/opt

RUN pip install virtualenv

ENV deepmd_root=/home/${NB_USER}/opt/deepmd-kit
ENV deepmd_source_dir=/home/${NB_USER}/opt/deepmd-kit
ENV tensorflow_venv=/home/${NB_USER}/opt/tensorflow_venv
ENV deepmd_root=/home/${NB_USER}/opt/deepmd-kit

RUN cd /home/${NB_USER}/opt && git clone https://github.com/deepmodeling/deepmd-kit.git deepmd-kit



RUN virtualenv -p python3 $tensorflow_venv

RUN source $tensorflow_venv/bin/activate


RUN pip install --upgrade tensorflow

RUN cd $deepmd_source_dir && pip install .

RUN cd $deepmd_source_dir/source && mkdir build && cd build

RUN cd $deepmd_source_dir/source/build && pwd && pip install -U cmake && cmake -DUSE_TF_PYTHON_LIBS=TRUE -DCMAKE_INSTALL_PREFIX=$deepmd_source_dir .. && make && make install

RUN cd $deepmd_source_dir/source/build && make lammps


RUN cd /home/${NB_USER}/opt &&  git clone https://github.com/lammps/lammps && cd lammps/src && cp -r $deepmd_source_dir/source/build/USER-DEEPMD . && make lib-pace args="-b" && make yes-molecule && make yes-reaxff && make yes-rigid && make yes-ml-pace && make yes-manybody && make lib-voronoi args="-b" && make yes-voronoi && make lib-plumed args="-b" CC=gcc CXX=g++ && make yes-plumed && make yes-kspace && make yes-extra-fix && make yes-user-deepmd && make serial

RUN deactivate 

USER root

RUN cp /home/${NB_USER}/opt/lammps/src/lmp_serial /usr/bin/lmp_serial

USER ${NB_USER}

ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600
ENV ASE_LAMMPSRUN_COMMAND="/usr/bin/lmp_serial"

RUN rm -rf /home/${NB_USER}/opt/lammps/

RUN pip install nglview

RUN pip install mdtraj

RUN pip install --user skmatter

RUN cd opt && git clone https://github.com/lab-cosmo/librascal.git && cd librascal && pip install --user .

RUN pip install --user scikit-learn

RUN pip install --user aiida-cp2k

RUN pip install --user spglib

RUN pip install pythtb

#RUN conda install -c conda-forge mpi4py
RUN pip install cp2k-spm-tools

COPY configs /home/${NB_USER}/configs

COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

RUN pip install scikit-learn optuna xgboost lightgbm sympy pandas

RUN pip install torch  torchmetrics torchvision


RUN cd /home/${NB_USER}/opt && git clone https://github.com/aoterodelaroza/critic2.git

RUN cd /home/${NB_USER}/opt/critic2 && mkdir build && cd build && cmake .. && make 

RUN pip install pymatgen scikit-image
