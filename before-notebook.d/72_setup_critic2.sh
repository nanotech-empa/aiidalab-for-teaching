
#!/bin/bash -e

# Debugging.
set -x

if verdi code list | grep -q 'critic2@localhost'; then
    echo "critic2 code found"
else
    echo "critic2 code not found, creating"
    verdi code create core.code.installed --config /home/${NB_USER}/configs/critic2.yml
fi
