#!/usr/bin/env python3
# setup.py — AMP build-step entry point.
#
# AMP run_session tasks execute this script inside the Python kernel, where
# __file__ is not always defined. All install logic lives in setup.sh; this
# wrapper just shells out to it.

import os
import subprocess
import sys

project_dir = os.environ.get("HOME", "/home/cdsw")
setup_sh = os.path.join(project_dir, "setup.sh")

print(f"[setup.py] running: bash {setup_sh}", flush=True)
result = subprocess.run(["bash", setup_sh], cwd=project_dir)
print(f"[setup.py] setup.sh exited with code {result.returncode}", flush=True)
sys.exit(result.returncode)
