import yaml
import json
import argparse
from os import environ
from semver import Version

# Fetch paths to submodule directories
pio_base         = environ.get('pio_base')
arduino_base     = environ.get('arduino_base')
lib_builder_base = environ.get('lib_builder_base')

if pio_base is None or arduino_base is None or lib_builder_base is None:
  raise Exception("Environment variables not set, run wrapper script 'util/version.sh'")

# Paths to version files
component_manifest_path = f"{lib_builder_base}/managed_components/husarnet__esp_husarnet/idf_component.yml"
arduino_manifest_path   = f"{arduino_base}/library.properties"
pio_manifest_path       = f"{pio_base}/library.json"

# File manipulation functions

def read_component_version() -> Version:
  with open(component_manifest_path, 'r') as file:
    return Version.parse(yaml.safe_load(file)["version"])


def read_arduino_version() -> Version:
  with open(arduino_manifest_path, 'r') as file:
    for line in file:
      if line.startswith("version="):
        return Version.parse(line.split("=")[1].strip())

   
def read_pio_version() -> Version:
  with open(pio_manifest_path, 'r') as file:
    return Version.parse(json.load(file)["version"])


def write_arduino_version(version: Version):
  with open(arduino_manifest_path, 'r') as file:
    lines = file.readlines()
  with open(arduino_manifest_path, 'w') as file:
    for line in lines:
      if line.startswith("version="):
        file.write(f"version={str(version)}\n")
      else:
        file.write(line)


def write_pio_version(version: Version):
  with open(pio_manifest_path, 'r') as file:
    manifest = json.load(file)
  manifest["version"] = str(version)
  with open(pio_manifest_path, 'w') as file:
    json.dump(manifest, file, indent=2)


# Command handlers
def get_version(args):
  arduino_version = read_arduino_version()
  pio_version = read_pio_version()
  
  print(f"Component version: \t{read_component_version()}")
  print("---")
  print(f"Arduino version: \t{arduino_version}")
  print(f"PlatformIO version: \t{pio_version}")


def set_version(args):
  try:
    new_version = Version.parse(args.version)
  except:
    print("ERROR: Invalid SemVer version")
    exit(1)
  
  arduino_version = read_arduino_version()
  pio_version = read_pio_version()
  
  if new_version.compare(arduino_version) < 0 or new_version.compare(pio_version) < 0:
    print("WARNING: New version is lower than the current version")
  
  if args.library == "arduino" or args.library == "all":
    print(f"Arduino: \t{arduino_version} -> {new_version}")
    
    if not args.dry_run:
      write_arduino_version(new_version)
      
  if args.library == "pio" or args.library == "all":
    print(f"PlatformIO: \t{pio_version} -> {new_version}")
    
    if not args.dry_run:
      write_pio_version(new_version)


def bump_version_by_str(version: Version, bump_type: str) -> Version:
  if bump_type == "major":
    return version.bump_major()
  elif bump_type == "minor":
    return version.bump_minor()
  elif bump_type == "patch":
    return version.bump_patch()
  elif bump_type == "prerelease":
    return version.bump_prerelease()
  else:
    raise Exception("Invalid bump type")


def bump_version(args):
  arduino_version = read_arduino_version()
  pio_version = read_pio_version()
  
  if args.library == "arduino" or args.library == "all":
    new_version = bump_version_by_str(arduino_version, args.type)
    print(f"Arduino: \t{arduino_version} -> {new_version}")
    
    if not args.dry_run:
      write_arduino_version(new_version)
      
  if args.library == "pio" or args.library == "all":
    new_version = bump_version_by_str(pio_version, args.type)
    print(f"PlatformIO: \t{pio_version} -> {new_version}")
    
    if not args.dry_run:
      write_pio_version(new_version)


# Parse arguments
parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers()
parser.add_argument("--dry-run", help="Prints resulting version numbers without updating the files",
                    action="store_true")

get_parser = subparsers.add_parser("get", help="Get the current version numbers")
get_parser.set_defaults(func=get_version)

set_parser = subparsers.add_parser("set", help="Set the version numbers")
set_parser.add_argument("library", help="Library to set the version for", choices=["arduino", "pio", "all"])
set_parser.add_argument("version", help="Version number to set")
set_parser.set_defaults(func=set_version)

bump_parser = subparsers.add_parser("bump", help="Bump the version numbers")
bump_parser.add_argument("library", help="Library to set the version for", choices=["arduino", "pio", "all"])
bump_parser.add_argument("type", help="Type of version bump", choices=["major", "minor", "patch", "prerelease"])
bump_parser.set_defaults(func=bump_version)

args = parser.parse_args()
args.func(args)
