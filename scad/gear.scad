// Involute spur/herringbone gears, no dependencies.
// All angles in degrees, lengths in mm.

function inv(a) = (tan(a) - a * PI / 180) * 180 / PI;

// Half tooth angle at radius rho. Backlash thins the tooth: bl is the total
// circumferential play at the pitch circle that this gear gives up.
function half_tooth(z, pa, rb, rho, bl, r) =
    90 / z + inv(pa) - inv(acos(min(1, rb / rho))) - (bl / 4) / r * 180 / PI;

function rad_pts(a, rho, side) = [rho * cos(a * side), rho * sin(a * side)];

// Profile of one tooth centred on angle 0, counter-clockwise, from the
// root of the right flank to the root of the left flank.
function tooth(z, m, pa, add, ded, bl, steps = 6) =
    let (r = z * m / 2,
         rb = r * cos(pa),
         ra = r + add * m,
         rr = r - ded * m,
         r0 = max(rb, rr),
         rhos = [for (i = [0 : steps]) r0 + (ra - r0) * i / steps],
         hs = [for (rho = rhos) half_tooth(z, pa, rb, rho, bl, r)],
         tip = [for (i = [1 : 2]) let (f = i / 3)
                    [ra * cos(-hs[steps] + 2 * hs[steps] * f),
                     ra * sin(-hs[steps] + 2 * hs[steps] * f)]])
    concat(
        rr < rb ? [[rr * cos(-hs[0]), rr * sin(-hs[0])]] : [],
        [for (i = [0 : steps]) [rhos[i] * cos(-hs[i]), rhos[i] * sin(-hs[i])]],
        tip,
        [for (i = [steps : -1 : 0]) [rhos[i] * cos(hs[i]), rhos[i] * sin(hs[i])]],
        rr < rb ? [[rr * cos(hs[0]), rr * sin(hs[0])]] : []);

function gear_pts(z, m, pa, add, ded, bl) =
    let (t = tooth(z, m, pa, add, ded, bl),
         r_root = z * m / 2 - ded * m,
         h0 = atan2(t[0][1], t[0][0]),
         pitch = 360 / z)
    [for (k = [0 : z - 1])
        each concat(
            [for (p = t) let (c = cos(k * pitch), s = sin(k * pitch))
                [p[0] * c - p[1] * s, p[0] * s + p[1] * c]],
            // two points on the root circle between teeth
            [for (f = [1 : 2]) let (b = k * pitch + abs(h0) + (pitch - 2 * abs(h0)) * f / 3)
                [r_root * cos(b), r_root * sin(b)]])];

module gear2d(z, m = 1, pa = 20, add = 1, ded = 1.25, bl = 0) {
    polygon(gear_pts(z, m, pa, add, ded, bl));
}

// Herringbone: two mirrored helical halves. hand = +1 or -1.
// Extruded from z = 0 up to z = width, centred on width / 2.
module herringbone(z, m, width, helix, hand, add = 1, ded = 1.25, bl = 0, slices = 10) {
    r = z * m / 2;
    half = width / 2;
    twist = hand * half * tan(helix) / r * 180 / PI;
    translate([0, 0, half]) {
        linear_extrude(height = half, twist = -twist, slices = slices, convexity = 10)
            gear2d(z, m, 20, add, ded, bl);
        mirror([0, 0, 1])
            linear_extrude(height = half, twist = -twist, slices = slices, convexity = 10)
                gear2d(z, m, 20, add, ded, bl);
    }
}
