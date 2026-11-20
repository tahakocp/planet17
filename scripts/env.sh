# Sourced by the other scripts. Set OPENSCAD to override the binary.
OPENSCAD="${OPENSCAD:-openscad}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAD="$ROOT/scad/planet17.scad"
PRESETS="$ROOT/presets/planet17.json"
scad() { "$OPENSCAD" --backend=manifold "$@" 2>&1; }
