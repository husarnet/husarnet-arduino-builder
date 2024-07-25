#!/bin/bash

source $(dirname "$0")/base.sh

release_platformio() {
  pushd ${pio_base}

  echo "--- Releasing PlatformIO library ---"
  echo "Checking for PlatformIO CLI"
  pio version

  echo "Pushing changes to the repository"
  git add .
  git commit -m "Release v$(get_pio_version)"
  git push

  echo "Packaging the library"
  pio package pack -o husarnet-esp32.tar.gz
  tar --list -f husarnet-esp32.tar.gz

  echo "Publishing the library"
  pio package publish --no-interactive --owner husarnet husarnet-esp32.tar.gz

  echo "Creating tagged release"
  gh release create v$(get_pio_version) -t "Husarnet v$(get_pio_version)"

  popd
}

release_arduino() {
  pushd ${arduino_base}

  echo "--- Releasing Arduino library ---"
  echo "Pushing changes to the repository"
  # git add .
  # git commit -m "Release v$(get_arduino_version)"
  # git push

  echo "Creating tagged release"
  gh release create v$(get_arduino_version) -t "Husarnet v$(get_arduino_version)"

  popd
}

if [ $# -ne 1 ]; then
  echo "Usage: $0 {pio/arduino/all}"
  exit 1
fi

if [ "$1" == "pio" ]; then
  release_platformio
elif [ "$1" == "arduino" ]; then
  release_arduino
elif [ "$1" == "all" ]; then
  release_platformio
  release_arduino
else
  echo "Invalid library to be released: $1"
  echo "Usage: $0 {pio/arduino/all}"
  exit 1
fi
