FROM aiidalab/full-stack:v2024.1016

USER root

RUN apt-get update -y && apt-get install -y cp2k && apt-get clean -y

USER ${NB_USER}

RUN pip install --user aiida-cp2k

RUN pip install --user spglib

COPY configs /home/${NB_USER}/configs

COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
