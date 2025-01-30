FROM aiidalab/full-stack:2025.1025

USER root

#RUN apt-get update -y && apt-get install -y cp2k && apt-get clean -y
# Install required system dependencies, including MPI development libraries
RUN apt-get update -y && apt-get install -y  cp2k libmpich-dev libopenmpi-dev  build-essential  && apt-get clean -y

USER ${NB_USER}

RUN mkdir /home/${NB_USER}/opt

RUN cd /home/${NB_USER}/opt &&  git clone https://github.com/lammps/lammps && cd lammps/src && make lib-pace args="-b" && make yes-molecule && make yes-reaxff && make yes-rigid && make yes-ml-pace && make yes-manybody && make lib-voronoi args="-b" && make yes-voronoi && make mpi

USER root

RUN cp /home/${NB_USER}/opt/lammps/src/lmp_mpi /usr/bin/lmp_mpi

USER ${NB_USER}

ENV JUPYTER_TERMINAL_IDLE_TIMEOUT=3600
ENV ASE_LAMMPSRUN_COMMAND="/opt/conda/bin/mpirun --np 2 /usr/bin/lmp_mpi"

RUN rm -rf /home/${NB_USER}/opt/lammps/

RUN pip install --user skmatter

RUN cd opt && git clone https://github.com/lab-cosmo/librascal.git && cd librascal && pip install --user .

RUN pip install --user scikit-learn

RUN pip install --user aiida-cp2k

RUN pip install --user spglib

RUN pip install pythtb

RUN conda install -c conda-forge mpi4py

COPY configs /home/${NB_USER}/configs

COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

RUN pip install scikit-learn optuna xgboost lightgbm sympy pandas

RUN pip install torch  torchmetrics torchvision
