
#!/bin/bash -e

# Debugging.
set -x


if [ -d "/home/jovyan/soft/" ]; then
    echo "Directory /home/jovyan/soft/ exists."
else
    echo "Directory does not exist. Creating"
    mkdir /home/jovyan/soft
fi

if [ -f "/home/jovyan/soft/cp2k-spm-tools/cube_from_wfn.py" ]; then
    echo "cp2k-spm-tools found"
else
    echo "cp2k-spm-tools not found, installing"
    git clone https://github.com/nanotech-empa/cp2k-spm-tools.git
    mv cp2k-spm-tools /home/jovyan/soft/
    chmod a+x /home/jovyan/soft/cp2k-spm-tools/*py
fi
