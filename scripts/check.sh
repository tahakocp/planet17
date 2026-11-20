#!/usr/bin/env bash
# Mesh and motion checks for a preset.
#   1. every part exports as a watertight solid
#   2. at N sun angles, no two parts of the assembly overlap
#   3. with a mismatched helix hand or a 6 degree phase error, they do
# usage: scripts/check.sh [preset ...]
set -euo pipefail
source "$(dirname "$0")/env.sh"

presets=("$@")
[ ${#presets[@]} -gt 0 ] || presets=(r4 r5)
samples="${SAMPLES:-12}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0

clash_volume() { # preset angle extra -D flags...
  local p=$1 a=$2; shift 2
  rm -f "$tmp/clash.stl"
  scad -p "$PRESETS" -P "$p" -D 'part="check_clash"' -D "angle=$a" "$@" \
       --export-format binstl -o "$tmp/clash.stl" "$SCAD" > /dev/null || true
  if [ -s "$tmp/clash.stl" ]; then
    node "$ROOT/scripts/stlcheck.mjs" --volume "$tmp/clash.stl"
  else
    echo 0
  fi
}

for p in "${presets[@]}"; do
  echo "== $p"
  "$ROOT/scripts/build.sh" "$p" > /dev/null
  node "$ROOT/scripts/stlcheck.mjs" "$ROOT"/stl/"$p"/*.stl || fail=1

  # Sun angles are spread so that each sample meets a different tooth phase.
  worst=0
  for ((i = 0; i < samples; i++)); do
    a=$(awk -v i="$i" 'BEGIN { printf "%.3f", i * 37.31 }')
    v=$(clash_volume "$p" "$a")
    worst=$(awk -v a="$worst" -v b="$v" 'BEGIN { print (b > a ? b : a) }')
  done
  echo "clash sweep: $samples angles, worst overlap $worst mm3"
  awk -v w="$worst" 'BEGIN { exit !(w > 0.001) }' && fail=1

  v=$(clash_volume "$p" 0 -D planet_hand_flip=true)
  echo "negative control, wrong helix hand: $v mm3 (must be > 0)"
  awk -v w="$v" 'BEGIN { exit !(w <= 0.001) }' && fail=1
  v=$(clash_volume "$p" 0 -D phase_error=6)
  echo "negative control, 6 deg phase error: $v mm3 (must be > 0)"
  awk -v w="$v" 'BEGIN { exit !(w <= 0.001) }' && fail=1
done

[ $fail -eq 0 ] && echo "all checks passed" || { echo "CHECKS FAILED"; exit 1; }
