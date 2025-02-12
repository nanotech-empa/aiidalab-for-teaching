
#!/bin/bash -e

# Debugging.
set -x

if verdi code list | grep -q 'stm@localhost'; then
    echo "STM code found"
else
    echo "STM code not found, creating"
    verdi code create core.code.installed --config /home/${NB_USER}/configs/stm.yml
fi
