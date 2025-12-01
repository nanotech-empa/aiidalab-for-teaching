set -x

SIESTA_DIR="/home/jovyan/apps/aiidalab-empa-siesta"
NEEDS_INSTALL=0

# ----------------------------------------
# Clone only if missing
# ----------------------------------------
if [ ! -d "$SIESTA_DIR" ]; then
    echo "Directory $SIESTA_DIR not found, cloning repository..."
    git -C /home/jovyan/apps clone https://github.com/nanotech-empa/aiidalab-empa-siesta.git
    NEEDS_INSTALL=1
else
    echo "$SIESTA_DIR already exists, skipping clone."
fi

# ----------------------------------------
# Run installation steps only if we cloned
# ----------------------------------------
if [ "$NEEDS_INSTALL" -eq 1 ]; then
(
    cd "$SIESTA_DIR" || exit 1

    echo "Installing aiidalab-empa-siesta..."
    pip install .

    if aiida-pseudo list | grep -q "psf_family"; then
        echo "psf_family already installed"
    else
        echo "Installing psf_family"
        aiida-pseudo install family pseudos psf_family -P pseudo.psf
    fi
    if aiida-pseudo list | grep -q "PseudoDojo/0.4/PBE/SR/standard/psml"; then
        echo "PseudoDojo/0.4/PBE/SR/standard/psml already installed"
    else
        echo "Installing PseudoDojo/0.4/PBE/SR/standard/psml"
        aiida-pseudo install pseudo-dojo -v 0.4 -x PBE -r SR -p standard -f psml
    fi
)
fi

# ----------------------------------------
# Install codes
# ----------------------------------------
codes=("siesta")

for code in "${codes[@]}"; do
    if verdi code list | grep -q "${code}@localhost"; then
        echo "$code code found"
    else
        echo "$code code not found, creating"
        verdi code create core.code.installed --config "/opt/configs/${code}.yml"
    fi
done
