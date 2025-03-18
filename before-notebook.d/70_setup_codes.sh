set -x

# List of codes to check
codes=("critic2" "cp2k" "python-py39" "stm-n")

# Loop through each code
for code in "${codes[@]}"; do
    if verdi code list | grep -q "${code}@localhost"; then
        echo "$code code found"
    else
        echo "$code code not found, creating"
        verdi code create core.code.installed --config "/opt/configs/${code}.yml"
    fi
done
