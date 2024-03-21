
#!/bin/bash -e

# Debugging.
set -x


if [ -d "/home/jovyan/soft/" ]; then
    echo "Directory /home/jovyan/soft/ exists."
else
    echo "Directory does not exist. Creating"
    mkdir /home/jovyan/soft
    mkdir /home/jovyan/soft/cp2k-spm-tools
fi

if [ -f "/home/jovyan/soft/cp2k-spm-tools/cube_from_wfn.py" ]; then
    echo "cp2k-spm-tools found"
else
    echo "cp2k-spm-tools not found, installing"
    git clone https://github.com/nanotech-empa/cp2k-spm-tools.git /home/jovyan/soft/cp2k-spm-tools
fi
