set -x

# List of codes to check
codes=("critic2" "cp2k" "siesta" "python-py39" "stm" "overlap")

# Loop through each code
for code in "${codes[@]}"; do
    if verdi code list | grep -q "${code}@localhost"; then
        echo "$code code found"
    else
        echo "$code code not found, creating"
        verdi code create core.code.installed --config "/opt/configs/${code}.yml"
    fi
done
if aiida-pseudo list | grep -q "PseudoDojo/0.4/PBE/SR/standard/psml"; then
    echo "PseudoDojo/0.4/PBE/SR/standard/psml already installed"
else
    echo "Installing PseudoDojo/0.4/PBE/SR/standard/psml"
    aiida-pseudo install pseudo-dojo -v 0.4 -x PBE -r SR -p standard -f psml
fi
