
#!/bin/bash -e

# Debugging.
set -x

if verdi code list | grep -q 'cp2k@localhost'; then
    echo "CP2K code found"
else
    echo "CP2K code not found, creating"
    verdi code create core.code.installed --config /home/${NB_USER}/configs/cp2k.yaml
fi