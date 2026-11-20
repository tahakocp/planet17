# Design notes

## Layout

Sun on the motor shaft, ring fixed in the housing, output on the carrier. With the ring held, ratio = 1 + ring / sun. The carrier is two plates joined by the planet pins, supported by one 608 bearing in the cover and the base of the housing. Two plates because a single plate would leave the pins cantilevered.

## Gear rules

All gears are module 1, 20 degree pressure angle, full-depth (addendum 1.0, dedendum 1.25), herringbone with a 20 degree helix. Herringbone cancels axial thrust, so there is no thrust bearing and the housing stays a single print.

- ring = sun + 2 * planet, so the planets fit in the gap.
- (sun + ring) / planets must be an integer, otherwise equally spaced planets cannot all mesh with the same sun and ring.
- Planets must not touch each other: the file checks centre spacing against tip diameter.
- Fewer than 17 teeth undercuts at 20 degrees. The default sun and planets have 15, which cuts into the root slightly but still passes the clash test. If you go below 13, check it.
- The sun root circle has to leave wall around the 5 mm shaft. At module 1, 15 teeth leaves a 1.25 mm wall; fewer needs a bigger module.

## Meshing phase

At the mid-plane of the herringbone, a sun tooth points at planet 0 and the planet has a gap there. For planet i at angle theta_i the planet spins theta_i * (1 + sun/planet) beyond that, and the ring is turned half a tooth when the planet tooth count is even. When the sun turns by a, the carrier turns a * sun / (sun + ring) and a planet spins c - (a - c) * sun / planet relative to the fixed frame. Those four lines are the entire kinematic model, and the clash sweep in `scripts/check.sh` is what tests them.

## Backlash and the ring

Each gear gives up `backlash / 2` of tooth thickness at the pitch circle, so each mesh has `backlash` of play. The ring cavity is drawn as an external gear of the ring tooth count with the addendum and dedendum swapped. That is the exact shape of an involute internal gear, which is why no extra clearance was needed on the ring side.

## Mesh sizes

The r4 housing is 52,740 triangles because the herringbone is a stack of twisted slices. A higher `slices` value in `gear.scad` gives smoother helices and bigger files. 10 slices per half keeps the helix error under 0.01 mm at module 1.

## Things I did not do

Profile shift, root fillets, tip relief, and a helix-aware load calculation. All would improve life on a real print. PRs welcome, preferably with a photo of what broke.
