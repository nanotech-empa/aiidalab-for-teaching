
#!/bin/bash -e

# Debugging.
set -x

if verdi code list | grep -q 'python-py39@localhost'; then
    echo "python-py39 code found"
else
    echo "python-py39 code not found, creating"
    verdi code create core.code.installed --config /home/${NB_USER}/configs/python.yml
fi
