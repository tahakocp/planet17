#!/usr/bin/env bash
# Export every printable part of a preset to stl/<preset>/.
# usage: scripts/build.sh [preset ...]   (default: all presets)
set -euo pipefail
source "$(dirname "$0")/env.sh"

presets=("$@")
[ ${#presets[@]} -gt 0 ] || presets=(r4 r5)
parts=(housing cover sun planet carrier_rear carrier_front flange)

for p in "${presets[@]}"; do
  mkdir -p "$ROOT/stl/$p"
  for part in "${parts[@]}"; do
    scad -p "$PRESETS" -P "$p" -D "part=\"$part\"" --export-format binstl \
         -o "$ROOT/stl/$p/$part.stl" "$SCAD" > /dev/null
  done
  echo "built stl/$p"
done
