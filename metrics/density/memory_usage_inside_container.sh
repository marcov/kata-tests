#!/bin/bash
# Copyright (c) 2017-2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#
#  Description of the test:
#  This test launches an alpine container and inside
#  memory free, memory available and total memory
#  is measured by using /proc/meminfo.

set -e

# General env
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/../lib/common.bash"

TEST_NAME="memory footprint inside container"
IMAGE="alpine:3.7"
CMD="cat /proc/meminfo"
TMP_FILE=$(mktemp meminfo.XXXXXXXXXX || true)

function main() {
	# Check tools/commands dependencies
	cmds=("awk" "docker")

	init_env
	check_cmds "${cmds[@]}"

	metrics_json_init

	docker run --rm --runtime=$RUNTIME $IMAGE $CMD > $TMP_FILE
	local output=$(cat $TMP_FILE)

	# Save configuration
	metrics_json_start_array

	local memtotal=$(echo "$output" | awk '/MemTotal/ {print $2}')
	local units_memtotal=$(echo "$output" | awk '/MemTotal/ {print $3}')
	local memfree=$(echo "$output" | awk '/MemFree/ {print $2}')
	local units_memfree=$(echo "$output" | awk '/MemFree/ {print $3}')
	local memavailable=$(echo "$output" | awk '/MemAvailable/ {print $2}')
	local units_memavailable=$(echo "$output" | awk '/MemAvailable/ {print $3}')

	local json="$(cat << EOF
	{
		"memtotal": {
			"Result" : $memtotal,
			"Units"  : "$units_memtotal"
		},
		"memfree": {
			"Result" : $memfree,
			"Units"  : "$units_memfree"
		},
		"memavailable": {
			"Result" : $memavailable,
			"Units"  : "$units_memavailable"
		}
	}
EOF
)"

	metrics_json_add_array_element "$json"
	metrics_json_end_array "Results"
	metrics_json_save
	clean_env
	rm -f $TMP_FILE
}

main "$@"
