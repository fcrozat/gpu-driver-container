#!/bin/bash

# Test suite for nvidia-driver-selector.sh
# Mocks sysfs and supported-gpus.json to verify driver selection logic.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SELECTOR_SCRIPT="${SCRIPT_DIR}/nvidia-driver-selector.sh"
TEST_TMP_DIR=$(mktemp -d)
MOCK_SYSFS="${TEST_TMP_DIR}/sysfs"
MOCK_JSON="${TEST_TMP_DIR}/supported-gpus.json"

trap "rm -rf ${TEST_TMP_DIR}" EXIT

# Setup Mock JSON
cat > "${MOCK_JSON}" <<EOF
{
  "chips": [
    { "devid": "0x1234", "features": ["kernelopen"] },
    { "devid": "0x5678", "features": ["kernelopen", "gsp_proprietary_supported"] },
    { "devid": "0x9ABC", "features": [] },
    { "devid": "0xDEFF", "features": ["kernelopen"] }
  ]
}
EOF

setup_mock_gpu() {
    local id=$1
    local name=$2
    local dev_path="${MOCK_SYSFS}/${name}"
    mkdir -p "${dev_path}"
    echo "0x10de" > "${dev_path}/vendor"
    echo "0x030000" > "${dev_path}/class"
    echo "${id}" > "${dev_path}/device"
}

run_test() {
    local name=$1
    local expected=$2
    shift 2
    local gpus=("$@")

    rm -rf "${MOCK_SYSFS}"
    mkdir -p "${MOCK_SYSFS}"
    
    for gpu in "${gpus[@]}"; do
        setup_mock_gpu ${gpu%%:*} ${gpu##*:}
    done

    echo -n "Test Case: ${name}... "
    export SYSFS_PATH="${MOCK_SYSFS}"
    result=$("${SELECTOR_SCRIPT}" "${MOCK_JSON}" 2>&1)
    exit_code=$?

    if [ "${result}" == "${expected}" ]; then
        echo "PASS"
    else
        echo "FAIL"
        echo "  Expected: ${expected}"
        echo "  Got:      ${result}"
        return 1
    fi
}

# --- Test Cases ---

# 1. Single Open Only (Turing/Ampere+)
run_test "Single Open Only" "open" "0x1234:gpu1"

# 2. Single Hybrid (Ada+)
run_test "Single Hybrid" "open" "0x5678:gpu1"

# 3. Single Closed Only (Pascal/Maxwell)
run_test "Single Closed Only" "proprietary" "0x9ABC:gpu1"

# 4. Mixed Hybrid and Closed (Prioritizes compatibility)
run_test "Mixed Hybrid and Closed" "proprietary" "0x5678:gpu1" "0x9ABC:gpu2"

# 5. Mixed Open Only and Closed (Decision Logic Conflict default)
run_test "Mixed Open Only and Closed" "open" "0x1234:gpu1" "0x9ABC:gpu2"

# 6. Unknown GPU (Defaults to Open)
run_test "Unknown GPU" "open" "0x9999:gpu1"

# 7. No GPUs
run_test "No GPUs" "No NVIDIA GPUs detected."

echo "All tests completed."
