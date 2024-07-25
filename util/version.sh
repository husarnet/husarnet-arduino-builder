#!/bin/bash
# Serves as a wrapper for the version.py script.
# Makes different build system paths accessible from python.

set -a
source $(dirname "$0")/base.sh
set +a

python3 ${script_base}/version.py "$@"
