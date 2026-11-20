// planet17: single-stage herringbone planetary gearbox for NEMA 17 steppers.
// Ring fixed, sun on the motor shaft, output on the carrier.
// Usage: openscad -D 'part="assembly"' scad/planet17.scad

include <gear.scad>

/* [Gear train] */
sun_teeth = 15;
planet_teeth = 15;
ring_teeth = 45;       // must equal sun_teeth + 2 * planet_teeth
planets = 3;           // (sun_teeth + ring_teeth) / planets must be an integer
module_mm = 1;
helix_angle = 20;
face_width = 10;       // herringbone width of every gear
backlash = 0.25;       // circumferential play per mesh at the pitch circle

/* [Motor and bearing] */
shaft_d = 5;
shaft_flat = 4.5;      // across-flats size of the shaft D cut
                       // shaft must reach z = 21 from the motor face (24 mm shafts do)
pilot_d = 22;          // NEMA 17 pilot boss
screw_square = 31;     // NEMA 17 hole pattern
bearing_od = 22;       // 608
bearing_id = 8;
bearing_w = 7;

/* [Printing] */
fit = 0.2;             // radial clearance for sliding fits
gap = 0.5;             // axial clearance between moving parts

/* [Selection] */
part = "assembly"; // [assembly, exploded, section, housing, cover, sun, planet, carrier_rear, carrier_front, flange, check_clash]
angle = 0;             // sun angle for assembly and check_clash, degrees
hand = 1;              // helix hand of the sun; flip only for the clash test
/* [Hidden] */
// Mutation switches used by scripts/check.sh to prove the clash test can fail.
planet_hand_flip = false;
phase_error = 0;
clash_a = -1;          // check_clash: restrict to one pair of part indices
clash_b = -1;

$fn = 64;

add = 1;
ded = 1.25;
pin_d = 3;
plate_t = 5;
base_t = 5;
cover_t = 1.5 + bearing_w;
r_sun = sun_teeth * module_mm / 2;
r_planet = planet_teeth * module_mm / 2;
r_ring = ring_teeth * module_mm / 2;
orbit = r_sun + r_planet;
ratio = 1 + ring_teeth / sun_teeth;
relief_r = r_ring + ded * module_mm;
out_r = relief_r + 6;
bolt_r = relief_r + 3;

pilot_h = 2;
z_sun_bottom = pilot_h + 0.4;
z_rear = base_t + gap;
z_gears = z_rear + plate_t + gap;
z_front = z_gears + face_width + gap;
z_cover = z_front + plate_t + gap;
z_bearing = z_cover + 1.5;
z_flange = z_bearing + bearing_w;

assert(ring_teeth == sun_teeth + 2 * planet_teeth, "ring_teeth must be sun_teeth + 2 * planet_teeth");
assert((sun_teeth + ring_teeth) % planets == 0, "(sun_teeth + ring_teeth) must be divisible by planets");
assert(planets < 3 || 2 * orbit * sin(180 / planets) > 2 * (r_planet + module_mm) + 0.4,
       "planets would touch each other");

module d_bore(d, flat, h) {
    intersection() {
        cylinder(d = d + 2 * fit / 2, h = h);
        translate([-d, -d, -0.01]) cube([d + flat - d / 2 + 0.15, 2 * d, h + 0.02]);
    }
}

module d_stub(d, flat, h) {
    intersection() {
        cylinder(d = d, h = h);
        translate([-d, -d, -0.01]) cube([d + flat - d / 2, 2 * d, h + 0.02]);
    }
}

function theta(i) = i * 360 / planets;
function carrier_angle(a) = a * sun_teeth / (sun_teeth + ring_teeth);
function planet_spin(i, a) =
    let (c = carrier_angle(a))
    phase_error + 180 - 180 / planet_teeth + theta(i) * (1 + sun_teeth / planet_teeth)
    + c - (a - c) * sun_teeth / planet_teeth;

module sun() {
    difference() {
        union() {
            translate([0, 0, z_gears])
                herringbone(sun_teeth, module_mm, face_width, helix_angle, hand, add, ded, backlash);
            translate([0, 0, z_sun_bottom]) cylinder(d = 11, h = z_gears - z_sun_bottom + 0.01);
        }
        translate([0, 0, z_sun_bottom - 0.1]) d_bore(shaft_d, shaft_flat, z_gears + face_width);
        translate([0, 0, z_sun_bottom + 4]) rotate([0, 90, 0]) cylinder(d = 2.7, h = 8, $fn = 24);
    }
}

module planet() {
    difference() {
        translate([0, 0, z_gears])
            herringbone(planet_teeth, module_mm, face_width, helix_angle, planet_hand_flip ? hand : -hand, add, ded, backlash);
        translate([0, 0, z_gears - 1]) cylinder(d = pin_d + 2 * fit, h = face_width + 2, $fn = 32);
    }
}

module ring_cavity() {
    psi = planet_teeth % 2 == 0 ? 180 / ring_teeth : 0;
    translate([0, 0, z_gears]) rotate(psi)
        herringbone(ring_teeth, module_mm, face_width, helix_angle, -hand, ded, add, -backlash, 14);
}

module housing() {
    difference() {
        cylinder(r = out_r, h = z_cover);
        translate([0, 0, -1]) cylinder(d = pilot_d + 0.4, h = base_t + 2);
        translate([0, 0, base_t]) cylinder(r = relief_r, h = z_gears - base_t + 0.01);
        translate([0, 0, z_gears + face_width - 0.01]) cylinder(r = relief_r, h = z_cover);
        translate([0, 0, 0]) ring_cavity();
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * screw_square / 2, sy * screw_square / 2, -1]) {
                cylinder(d = 3.4, h = base_t + 2, $fn = 24);
                translate([0, 0, 1 + base_t - 3.2]) cylinder(d = 6.4, h = 4, $fn = 24);
            }
        for (k = [0 : 3])
            rotate(k * 90) translate([bolt_r, 0, z_cover - 12]) cylinder(d = 2.7, h = 13, $fn = 24);
    }
}

module cover() {
    difference() {
        translate([0, 0, z_cover]) cylinder(r = out_r, h = cover_t);
        translate([0, 0, z_cover - 1]) cylinder(d = 14, h = cover_t + 2);
        translate([0, 0, z_bearing]) cylinder(d = bearing_od + 2 * fit / 2, h = cover_t);
        for (k = [0 : 3])
            rotate(k * 90) translate([bolt_r, 0, z_cover - 1]) cylinder(d = 3.4, h = cover_t + 2, $fn = 24);
    }
}

module plate_r() {
    r = relief_r - 0.75;
    difference() {
        translate([0, 0, z_rear]) cylinder(r = r, h = plate_t);
        translate([0, 0, z_rear - 1]) cylinder(d = 11 + 2 * fit + 1, h = plate_t + 2);
        for (i = [0 : planets - 1])
            rotate(theta(i)) translate([orbit, 0, z_rear - 1]) {
                cylinder(d = pin_d + 0.1, h = plate_t + 2, $fn = 24);
                cylinder(d = 6, h = 1 + 3.2, $fn = 24);
            }
    }
}

module plate_f() {
    r = relief_r - 0.75;
    top = z_front + plate_t;
    difference() {
        union() {
            translate([0, 0, z_front]) cylinder(r = r, h = plate_t);
            cylinder(d = 13, h = 0.01);
            translate([0, 0, top - 0.01]) cylinder(d = 13, h = z_bearing - top + 0.01);
            translate([0, 0, z_bearing - 0.01]) d_stub(bearing_id, 7, z_flange + 6.3 - z_bearing + 0.01);
        }
        translate([0, 0, z_front - 1]) cylinder(d = 6.6, h = 1 + 3.5);
        for (i = [0 : planets - 1])
            rotate(theta(i)) translate([orbit, 0, z_front - 1]) {
                cylinder(d = pin_d + 0.1, h = plate_t + 2, $fn = 24);
                translate([0, 0, 1 + plate_t - 2.6]) cylinder(d = 6.6, h = 3, $fn = 6);
            }
    }
}

module flange() {
    difference() {
        union() {
            translate([0, 0, z_flange]) cylinder(d = 10, h = 1);
            translate([0, 0, z_flange + 0.8]) cylinder(d = 20, h = 6);
        }
        translate([0, 0, z_flange - 1]) d_bore(bearing_id, 7, 10);
        translate([0, 0, z_flange + 4]) rotate([0, 90, 0]) cylinder(d = 2.7, h = 12, $fn = 24);
        for (k = [0 : 3])
            rotate(45 + k * 90) translate([7, 0, z_flange + 1]) cylinder(d = 2.7, h = 7, $fn = 24);
    }
}

module pins() {
    for (i = [0 : planets - 1])
        rotate(theta(i)) translate([orbit, 0, z_rear + 3.2]) cylinder(d = pin_d, h = 18, $fn = 24);
}

module bearing() {
    translate([0, 0, z_bearing]) difference() {
        cylinder(d = bearing_od, h = bearing_w);
        translate([0, 0, -1]) cylinder(d = bearing_id, h = bearing_w + 2);
    }
}

module carrier(c, lift = 0) {
    rotate(c) {
        translate([0, 0, 3 * lift]) { plate_r(); plate_f(); pins(); }
        translate([0, 0, 7 * lift]) flange();
    }
}

module gearbox(a = 0, lift = 0) {
    c = carrier_angle(a);
    color("#6b7280") housing();
    color("#9ca3af") translate([0, 0, 4.5 * lift]) cover();
    color("#f59e0b") translate([0, 0, lift]) rotate(a) sun();
    for (i = [0 : planets - 1])
        color("#38bdf8") translate([0, 0, 2 * lift])
            rotate(theta(i) + c) translate([orbit, 0, 0]) rotate(planet_spin(i, a) - theta(i) - c) planet();
    color("#34d399") carrier(c, lift);
    color("#e5e7eb") translate([0, 0, 5.5 * lift]) bearing();
}

module clash_pair(i, j, a) {
    c = carrier_angle(a);
    intersection() { pose(i, a, c); pose(j, a, c); }
}

// 0 housing, 1 cover, 2 sun, 3 carrier rear, 4 carrier front, 5 flange, 6.. planets
module pose(k, a, c) {
    if (k == 0) housing();
    else if (k == 1) cover();
    else if (k == 2) rotate(a) sun();
    else if (k == 3) rotate(c) plate_r();
    else if (k == 4) rotate(c) plate_f();
    else if (k == 5) rotate(c) flange();
    else let (i = k - 6) rotate(theta(i) + c) translate([orbit, 0, 0]) rotate(planet_spin(i, a) - theta(i) - c) planet();
}

module check_clash(a) {
    n = 6 + planets;
    union() {
        for (i = [0 : n - 2], j = [i + 1 : n - 1])
            if (!(i <= 1 && j <= 1) && (clash_a < 0 || (i == clash_a && j == clash_b)))
                clash_pair(i, j, a);
    }
}

module section() {
    difference() {
        gearbox(angle);
        translate([-100, -200, -10]) cube([200, 200, 200]);
    }
}

module print_pose(z0, flip = false) {
    if (flip) translate([0, 0, 0]) mirror([0, 0, 1]) translate([0, 0, -z0]) children();
    else translate([0, 0, -z0]) children();
}

if (part == "assembly") gearbox(angle);
else if (part == "exploded") gearbox(angle, 14);
else if (part == "section") section();
else if (part == "housing") housing();
else if (part == "cover") print_pose(z_cover) cover();
else if (part == "sun") print_pose(z_sun_bottom) sun();
else if (part == "planet") print_pose(z_gears) planet();
else if (part == "carrier_rear") print_pose(z_rear) plate_r();
else if (part == "carrier_front") print_pose(z_front) plate_f();
else if (part == "flange") print_pose(z_flange + 6.8, true) flange();
else if (part == "check_clash") check_clash(angle);
