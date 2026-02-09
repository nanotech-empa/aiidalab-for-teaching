#!/bin/bash

set -x

if ! verdi computer list -a | awk '{print $1}' | grep -qx "localhost-legacy"; then

    # Disable and rename the default localhost
    verdi computer disable localhost aiida@localhost
    verdi computer relabel localhost localhost-legacy

    # Setup new localhost with HyperQueue
    verdi computer setup        \
      --non-interactive                                                   \
      --label "${COMPUTER_LABEL}"                                         \
      --description "local computer with hyperqueue scheduler"            \
      --hostname "localhost"                                              \
      --transport core.local                                              \
      --scheduler hyperqueue                                              \
      --work-dir /home/${NB_USER}/aiida_run/                               \
      --mpiprocs-per-machine 2                                             \
      --mpirun-command "mpirun -np {num_cpus}"

    # Configure transport (ONLY when setup happened)
    verdi computer configure core.local "${COMPUTER_LABEL}"               \
      --non-interactive                                                   \
      --safe-interval 5.0

else
    echo "localhost-legacy already exists → skipping computer setup & configure"
fi
