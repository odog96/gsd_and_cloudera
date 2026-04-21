#!/usr/bin/env python3
# setup.py — AMP build-step entry point.
#
# AMP run_session tasks invoke the Python kernel, which can't execute
# shell scripts directly. This wrapper just delegates to setup.sh so
# all install logic stays in one bash file for manual use.

import pathlib
import subprocess
import sys

here = pathlib.Path(__file__).resolve().parent
result = subprocess.run(["bash", str(here / "setup.sh")], cwd=str(here))
sys.exit(result.returncode)
