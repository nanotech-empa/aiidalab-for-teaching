FROM aiidalab/full-stack:v2024.1016

USER root

RUN apt-get update -y && apt-get install -y cp2k && apt-get clean -y

USER ${NB_USER}

RUN mkdir /home/${NB_USER}/opt

RUN cd /home/${NB_USER}/opt &&  git clone https://github.com/lammps/lammps && cd lammps/src && make lib-pace args="-b" && make yes-ml-pace && make yes-manybody && make lib-voronoi args="-b" && make yes-voronoi && make serial

USER root

RUN cp /home/${NB_USER}/opt/lammps/src/lmp_serial /usr/bin/lmp_serial

USER ${NB_USER}

RUN rm -rf /home/${NB_USER}/opt/lammps/

RUN pip install --user skmatter

RUN cd opt && git clone https://github.com/lab-cosmo/librascal.git && cd librascal && pip install --user .

RUN pip install --user scikit-learn

RUN pip install --user aiida-cp2k

RUN pip install --user spglib

COPY configs /home/${NB_USER}/configs

COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
