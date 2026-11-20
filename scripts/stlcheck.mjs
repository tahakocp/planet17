#!/usr/bin/env node
// Reads STL files (binary or ASCII) and reports triangle count, bounding box,
// signed volume and whether every edge is shared by exactly two triangles.
import { readFileSync } from "node:fs";

export function parseStl(buf) {
  const head = buf.subarray(0, 5).toString("latin1");
  const binCount = buf.length >= 84 ? buf.readUInt32LE(80) : -1;
  if (head !== "solid" || 84 + binCount * 50 === buf.length) {
    const n = binCount;
    const tris = new Float64Array(n * 9);
    for (let i = 0; i < n; i++)
      for (let k = 0; k < 9; k++) tris[i * 9 + k] = buf.readFloatLE(84 + i * 50 + 12 + k * 4);
    return tris;
  }
  const nums = [...buf.toString("latin1").matchAll(/vertex\s+(\S+)\s+(\S+)\s+(\S+)/g)];
  const tris = new Float64Array(nums.length * 3);
  nums.forEach((m, i) => { tris[i * 3] = +m[1]; tris[i * 3 + 1] = +m[2]; tris[i * 3 + 2] = +m[3]; });
  return tris;
}

export function analyse(tris) {
  const n = tris.length / 9;
  const ids = new Map();
  const vid = (x, y, z) => {
    const key = `${x.toFixed(4)},${y.toFixed(4)},${z.toFixed(4)}`;
    let id = ids.get(key);
    if (id === undefined) { id = ids.size; ids.set(key, id); }
    return id;
  };
  const edges = new Map();
  const min = [Infinity, Infinity, Infinity], max = [-Infinity, -Infinity, -Infinity];
  let vol = 0, degenerate = 0;
  for (let t = 0; t < n; t++) {
    const p = [0, 1, 2].map((v) => tris.subarray(t * 9 + v * 3, t * 9 + v * 3 + 3));
    for (const q of p) for (let a = 0; a < 3; a++) { min[a] = Math.min(min[a], q[a]); max[a] = Math.max(max[a], q[a]); }
    vol += (p[0][0] * (p[1][1] * p[2][2] - p[1][2] * p[2][1])
          - p[0][1] * (p[1][0] * p[2][2] - p[1][2] * p[2][0])
          + p[0][2] * (p[1][0] * p[2][1] - p[1][1] * p[2][0])) / 6;
    const v = p.map((q) => vid(q[0], q[1], q[2]));
    if (v[0] === v[1] || v[1] === v[2] || v[0] === v[2]) { degenerate++; continue; }
    for (let e = 0; e < 3; e++) {
      const a = v[e], b = v[(e + 1) % 3];
      const k = a < b ? `${a}:${b}` : `${b}:${a}`;
      const dir = a < b ? 1 : -1;
      const rec = edges.get(k) || [0, 0];
      rec[dir === 1 ? 0 : 1]++;
      edges.set(k, rec);
    }
  }
  let open = 0;
  for (const [f, b] of edges.values()) if (f !== 1 || b !== 1) open++;
  return { triangles: n, volume: vol, degenerate, openEdges: open, min, max };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  let bad = 0;
  const args = process.argv.slice(2);
  const volumeOnly = args[0] === "--volume";
  for (const file of volumeOnly ? args.slice(1) : args) {
    const r = analyse(parseStl(readFileSync(file)));
    if (volumeOnly) { console.log(r.volume.toFixed(3)); continue; }
    const size = r.max.map((v, i) => (v - r.min[i]).toFixed(1)).join(" x ");
    const ok = r.openEdges === 0 && r.volume > 0;
    if (!ok) bad++;
    console.log(`${ok ? "ok  " : "FAIL"} ${file}  tris=${r.triangles} vol=${r.volume.toFixed(1)} mm3 size=${size} open_edges=${r.openEdges}`);
  }
  process.exit(bad ? 1 : 0);
}
