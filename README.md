# husarnet-arduino-builder

This repository compiles and releases Arduino and PlatformIO Husarnet libraries. Resulting files can be found in the [husarnet-esp32-arduino](https://github.com/husarnet/husarnet-esp32-arduino) and [husarnet-esp32-platformio](https://github.com/husarnet/husarnet-esp32-platformio) repositories and in Arduino and PIO package registries.

## Architecture

In the root of the repository there are 4 folders used in the build process:
* `util/` - contains scripts used to perform all required actions in the release process
* `esp32-arduino-lib-builder` - submodule containing ESP32 Arduino builder, used to create prebuilt Husarnet libraries
* `husarnet-esp32-arduino` - submodule containing generated Husarnet ESP32 Arduino library
* `husarnet-esp32-platformio` - submodule containing generated Husarnet ESP32 PlatformIO library

## Steps

The release process is automated and involves the following steps:

### Build

```
util/build.sh full
```

This script ensures that we have the latest version of the ESP32 Arduino Lib Builder. It optimises the `idf_component.yml` file to speed up the build and copies the output artifacts to library folders.

It can be run either in the `full` mode, which will download all components and toolchain files (very slow during first run) or in the `local_deps` mode, which will use the locally available ESP-IDF toolchain (needs to be sourced beforehand) and does not build as many unneccessary files, including the Arduino component as the full mode. Main drawback is possible incompatibility of the generated library with the Arduino IDE. Should be used for testing purposes only.

### (Optionally) Edit library files

Changes to the files in libraries should be done after the build step. Please note that currently `include` and `src` folders are removed and replaced with the ones from the ESP32 Arduino Lib Builder by the `util/build.sh` script.

### Bump version

```
util/bump_version.sh get
util/bump_version.sh set {arduino/pio/all} X.X.X
util/bump_version.sh bump {arduino/pio/all} {major/minor/patch}
```

This script allows to fetch, set and bump the version of the Arduino/PlatformIO Husarnet library. It will update the version in both libraries manifest files. Usually running the `bump all patch` command is enough.

### Release

```
util/release.sh {arduino/pio/all}
```

This script will release the Husarnet library to the PlatformIO package registry and tag new release in the Arduino library repository.


## Requirements

Clone the repository:

```
git clone --recurse-submodules
```

### Packages and libraries

Run:

``` 
sudo apt install python3 python3-pip jq gh
```

```
pip install -r requirements.txt
```

### PlatformIO

Is only required to release the PlatformIO library.

Could be installed via [pip](https://docs.platformio.org/en/latest/core/installation.html#python-package-manager) or a [installer script](https://docs.platformio.org/en/latest/core/installation.html#installer-script). Follow official instructions.

Alternatively, you can run `util/release.sh` script from the CLI bundled with the full VSCode PlatformIO extension, launched via `>PlatformIO: Open PlatformIO Core CLI` command.

### Service login

To release the Arduino library, you need to be logged in to the GitHub CLI. Run the following command and follow the instructions:

```
gh auth login
```


Uploading libraries to the PlatformIO registry also requires authentication. Run the following command and follow the instructions:
```
pio account login
```

## TODO
- [ ] Output library size optimization
- [ ] Verify that the version has been bumped before releasing

