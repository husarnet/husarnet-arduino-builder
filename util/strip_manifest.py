import yaml
from os import environ

# Fetch path to the ESP32 Arduino Lib Builder
lib_builder_base = environ.get('lib_builder_base')

if lib_builder_base is None:
  raise Exception("Environment variables not set")


with open(f"{lib_builder_base}/main/idf_component.yml", "r+") as f:
  manifest = yaml.safe_load(f)
  
  # Remove all espressif components to speed up the build
  for component in list(manifest["dependencies"]):
    if component.startswith("espressif/"):
      print(f"Removing {component}")
      del manifest["dependencies"][component]
          
  # Append Husarnet component
  manifest["dependencies"]["husarnet/esp_husarnet"] = dict()
  
  # Write the modified manifest back to the file
  f.seek(0)
  f.truncate(0)
  yaml.dump(manifest, f)