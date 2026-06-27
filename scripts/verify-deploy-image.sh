#!/usr/bin/env bash
set -euo pipefail

/usr/local/bin/verify-image.sh
rsync --version >/dev/null
ssh -V >/dev/null 2>&1
