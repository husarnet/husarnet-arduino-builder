#!/bin/bash

set -a
source $(dirname "$0")/base.sh
set +a

if [ $# -ne 1 ]; then
  echo "Usage: $0 [full/local_deps]"
  exit 1
fi

# local_deps skips ESP-IDF and Arduino component download.
# It speeds up the build but may result in output library
# incompatibilities with the Arduino framework
build_type=$1

if [ "$build_type" != "full" ] && [ "$build_type" != "local_deps" ]; then
  echo "Invalid build type: $1"
  echo "Usage: $0 [full/local_deps]"
  exit 1
fi

# Stash any local changes, we don't want to lose them accidentally
# git -C ${pio_base} stash
# git -C ${arduino_base} stash

# Update library repositories
echo "--- Synchronizing submodules ---"
git -C ${pio_base} fetch
git -C ${pio_base} checkout master

git -C ${arduino_base} fetch
git -C ${arduino_base} checkout master

# Update the library builder repository
echo "--- Updating library builder ---"
git -C ${lib_builder_base} fetch
git -C ${lib_builder_base} reset --hard
git -C ${lib_builder_base} pull
git -C ${lib_builder_base} clean -fdx

# Remove unnecessary components to speed up the build
# and add Husarnet library to the IDF manifest
echo "--- Stripping builder manifest ---"
python3 ${script_base}/strip_manifest.py

# Build the project
pushd ${lib_builder_base}

if [ "$build_type" == "full" ]; then
  echo "--- Building core (full) ---"
  ./build.sh -t esp32 -b idf-libs
else # local_deps
  echo "--- Building core (local dependencies) ---"
  
  # As we do not build Arduino component, we need to provide
  # a new entry point for the application.
  cp ${base_dir}/sketch.cpp main/sketch.cpp
  
  ./build.sh -t esp32 -b idf-libs -s
fi

popd

# Copy output files to the PIO library repository
echo "--- Copying output files ---"
lib_builder_output_base=${lib_builder_base}/out/tools/esp32-arduino-libs/esp32

cp ${lib_builder_output_base}/lib/libhusarnet__esp_husarnet.a ${pio_base}/lib/libhusarnet.a
rm -rf ${pio_base}/include
mkdir -p ${pio_base}/include
cp ${lib_builder_output_base}/include/husarnet__esp_husarnet/husarnet.h ${pio_base}/include/
cp -r ${lib_builder_output_base}/include/husarnet__esp_husarnet/husarnet/core/husarnet ${pio_base}/include/

# Copy output files to the Arduino IDE library repository
rm -rf ${arduino_base}/src
mkdir -p ${arduino_base}/src
cp ${lib_builder_output_base}/include/husarnet__esp_husarnet/husarnet.h ${arduino_base}/src/
cp -r ${lib_builder_output_base}/include/husarnet__esp_husarnet/husarnet/core/husarnet ${arduino_base}/src/

targets=(esp32 esp32s2 esp32s3 esp32c2 esp32c3 esp32c5 esp32c6 esp32p4)
for target in "${targets[@]}"; do
  mkdir -p ${arduino_base}/src/${target}
  cp ${lib_builder_output_base}/lib/libhusarnet__esp_husarnet.a ${arduino_base}/src/${target}/libhusarnet.a
done

echo "Done!"
