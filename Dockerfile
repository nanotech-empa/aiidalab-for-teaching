FROM aiidalab/full-stack:v2024.1016

USER root

RUN apt-get update -y && apt-get install -y cp2k && apt-get clean -y

USER ${NB_USER}

RUN pip install --user skmatter

RUN mkdir opt && cd opt && git clone https://github.com/lab-cosmo/librascal.git && cd librascal && pip install --user .

RUN pip install --user scikit-learn

RUN pip install --user aiida-cp2k

COPY configs /home/${NB_USER}/configs

COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
