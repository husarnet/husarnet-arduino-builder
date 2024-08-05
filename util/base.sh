#!/bin/bash

set -euo pipefail

script_base="$(realpath $(dirname "$BASH_SOURCE[0]"))"
base_dir="$(realpath ${script_base}/..)"
pio_base="${base_dir}/husarnet-esp32-platformio"
arduino_base="${base_dir}/husarnet-esp32-arduino"
lib_builder_base="${base_dir}/esp32-arduino-lib-builder"

pushd() {
  builtin pushd "$@" > /dev/null
}

popd() {
  builtin popd "$@" > /dev/null
}

catch() {
  # In ERR catch this seems redundant
  if [ "$1" == "0" ]; then
    return
  fi

  local i
  echo "Error $1 happened. Stack trace:"

  # This should never be true but I still don't trust it
  if [ ${FUNCNAME[0]} != "catch" ]; then
    echo "$(realpath ${BASH_SOURCE[0]}):${LINENO} in ${FUNCNAME[0]}"
  fi

  for ((i = 1; i < ${#FUNCNAME[*]}; i++)); do
    echo "$(realpath ${BASH_SOURCE[$i]}):${BASH_LINENO[$i - 1]} in ${FUNCNAME[$i]}"
  done

  # Propagate the same exit status as before
  exit $1
}
trap 'catch $?' ERR

get_pio_version() {
  echo $(cat ${pio_base}/library.json | jq -r .version)
}

get_arduino_version() {
  echo $(cat ${arduino_base}/library.properties | grep version | cut -d= -f2)
}

confirm_action() {
  local action="$1"

  read -p "${action} (y/N)? " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting"
    exit 1
  fi
}