#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -x "$base/build/aetherium" ]; then
    exec "$base/build/aetherium" "$@"
fi
printf '%s\n' 'Build the game with make, then run ./run.sh.' >&2
exit 1
