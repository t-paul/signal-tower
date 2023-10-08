/*
 *  Multi-Level Signal Tower for RGB-LED Rings
 *  (c) 2022 Torsten Paul <Torsten.Paul@gmx.de>
 *  License: CC-BY-SA 4.0
 */

// https://github.com/rcolyer/threads-scad
use <rcolyer-threads/threads.scad>
// https://github.com/UBaer21/UB.scad
use <UB/libraries/ub.scad>

/* [Hidden] */
$fa = 4; $fs = 0.4;

/* [Part Selection] */
selection = 0; // [0:Assembly, 1:Bottom, 2:Ring Plate, 3:Ring Screw, 4:Cable Guide, 5:Tube, 6:Cap ]

/* [Parameters] */
layer_height = 0.15;
nozzle_diameter = 0.4;
tolerance = 0.35;
eps = 0.01;

wall = nozzle_diameter * 4;

/* begin params first print */
//base_height = 12;
//tube_height = 60;
//thread_pitch = 3;
//thread_tooth_angle = 55;
/* end params first print */

case_dia = 80;
center_dia = 16; // diameter of the center thread
center_hole = 12; // diameter of the center hole

base_height = 15;

bottom_height = 25;
bottom_screw_dia = 2;
bottom_hole_dia = 5;
bottom_has_ldr = true;
bottom_has_led = true;
bottom_led_angle = 20;

cap_radius = 5;
cap_height = wall + cap_radius + 1;

tube_height = 65;

// LED Ring 5V RGB WS2812B 12-Bit 37mm
// https://www.az-delivery.de/products/rgb-led-ring-ws2812-mit-12-rgb-leds-5v-fuer-arduino
// LED Ring, inner diameter in mm
ring_id = 27;
// LED Ring, outer diameter in mm
ring_od = 40;

ring_screw_size = 5 * layer_height;

thread_pitch = 2.5;
thread_tooth_angle = 50;
thread_inset = sin(thread_tooth_angle) * thread_pitch / 2;
thread_dia = case_dia - 2 * wall - thread_inset;

parts = [
    [ "assembly",    [0, 0,   0 ], [  0, 0, 0], undef],
    [ "bottom",      [0, 0,   0 ], [  0, 0, 0], undef],
    [ "ring_plate",  [0, 0,  40 ], [  0, 0, 0], undef],
    [ "ring_screw",  [0, 0,  95 ], [180, 0, 0], ["darkgray", 0.8]],
    [ "cable_guide", [0, 0, 165 ], [180, 0, 0], ["darkgray", 0.9]],
    [ "tube",        [0, 0, 125 ], [  0, 0, 0], ["darkgray", 0.8]],
    [ "cap",         [0, 0, 215 ], [  0, 0, 0], undef]
];

module screw_hole(height, position = [0, 0, 0]) {
    ScrewHole(thread_dia, height, position = position, pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance)
        children();
} 

module screw_thread(height) {
    ScrewThread(thread_dia, height, pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance);
}

module led() {
    difference() {
        color("darkgray") linear_extrude(1) square(5, center = true);
        color("white") translate([0, 0, 0.2]) cylinder(h = 1, r = 2);
    }
    color("white", 0.8) translate([0, 0, 0.2]) cylinder(h = 0.7, r = 2 - eps);
}

module ring(h = 1, id = ring_id, od = ring_od) {
    cnt = 12;
    color("black") linear_extrude(h + eps, convexity = 2) {
        difference() {
            circle(d = od + tolerance);
            circle(d = id - tolerance);
        }
    }
    if ($preview)
        for (a = [0:1:cnt - 1])
            rotate(a * 360 / cnt)
                translate([(id + od)/4, 0, h])
                    led();
}

module center_bore() {
    cylinder(d = 10, h = 100, center = true);
}

// Mounting hole positions for esp12f-led PCB
// https://aisler.net/torsten/finished/esp12f-led-controller/board
module pcb_holes() {
    x = 28 / 2;
    y = 25.5 / 2;
    for (xx = [-x, x], yy = [-y, y])
        translate([xx, yy])
            children();
}

// 5mm LED mounting
// https://www.kingbright.com/attachments/file/psearch/000/00/00/RTC-52(Ver.12).pdf
module kingbright_rtc_52(d, h) {
    w = 2; // panel thickness (max 3mm?)
    hole = 6.4 + tolerance;
    assert(d > 10, "Diameter must be > 10 as the access hole is 10mm");
    difference() {
        translate([0, 0, -h]) cylinder(d = d, h = h);
        translate([0, 0, -h - w]) cylinder(d = 10, h = h);
        cylinder(d = hole, h = 3 * h, center = true);
    }
}

module bottom() {
    r = 3;
    ldr_dia = 10 + 2 * eps;
    cut_dia = case_dia - 6 * wall;

    module led_hole() {
        translate([0, 1, ldr_dia / 2 + wall + tolerance]) rotate([-90, 0, 0]) cylinder(d = ldr_dia - 2 * eps, h = case_dia);
    }

    module led_plate() {
        o1 = case_dia / 2 - sqrt((case_dia / 2) ^ 2 - (ldr_dia / 2) ^ 2);
        o2 = case_dia / 2 - cut_dia / 2 - o1;
        translate([0, case_dia/2 - o1, ldr_dia / 2 + tolerance]) rotate([-90, 0, 0]) kingbright_rtc_52(ldr_dia, o2);
    }

    difference() {
        h = bottom_height - base_height /2;
        screw_hole(height = base_height / 2, position = [0, 0, h + eps])
           cylinder(d = case_dia, h = bottom_height);
        translate([0, 0, wall]) cylinder(d = cut_dia, h = bottom_height);
        translate([0, 0, wall + 2 + bottom_hole_dia / 2 + eps]) rotate([90, 0, 0]) cylinder(d = bottom_hole_dia, h = case_dia);
        if (bottom_has_ldr) {
            led_hole();
        }
        if (bottom_has_led) {
            rotate(bottom_led_angle) led_hole();
            rotate(-bottom_led_angle) led_hole();
        }
    }
    translate([0, 0, wall]) {
        h = 10;
        spiel = 0.2;
        translate([0, -20]) {
            difference() {
                union() {
                    Rundrum([4, 20],r=2, fn = 36) Kehle(rad = 2, 2D = true, spiel = [3, 0.2], fn2 = 36);
                    linear_extrude(h - 2) hull($fn = 36) for (y = [-8, 8]) translate([0, y]) circle(d = 4);
                }
                for (y = [-4, 4])
                    translate([0, y, 2 + bottom_hole_dia / 2])
                        rotate([0, 90, 0])
                            cylinder(d = bottom_hole_dia, h = 2 * h, center = true);
            }
        }
        if (bottom_has_ldr) {
            led_plate();
        }
        if (bottom_has_led) {
            rotate(bottom_led_angle) led_plate();
            rotate(-bottom_led_angle) led_plate();
        }
        pcb_holes()
            difference() {
                Strebe(d = bottom_screw_dia + 2 * wall, rad = r, h = h, single = true, spiel = spiel);
                LinEx(h + spiel + eps, bottom_screw_dia, scale2 = 1.2) WStern(r = 1);
            }
    }
}

module ring_plate() {
    module spokes(rot, angle, dia, l, h) {
        for (a = [0:1:2])
            rotate(a * 120 + rot)
                rotate_extrude(angle = angle)
                    translate([l, 0])
                        square([dia/2, h]);
    }

    ir = ring_od / 2 + 2 * wall;
    or = case_dia / 2 - thread_inset - 3 * wall;
    ScrewHole(center_dia, base_height + 2, position = [0, 0, -1], pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance) {
        difference() {
            screw_thread(height = base_height);
            translate([0, 0, -eps]) {
                ring(2 * base_height);
                if (or - ir > 3 * wall) {
                    translate([0, 0, wall])
                        rotate_extrude()
                            translate([ir, 0]) square([or - ir, base_height + 1]);
                }
            } 
        }
        translate([0, 0, eps])
            spokes(0, 30, 2 * or - 2 + eps, 1, base_height - 1.5);
    }
}

module ring_screw() {
    ScrewHole(center_hole, 3 * base_height, position = [0, 0, -1], pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance) {
        union() {
            cylinder(d = ring_od + 2, h = ring_screw_size);
            translate([0, 0, ring_screw_size - eps]) ScrewThread(center_dia, base_height + 2,pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance);
        }
    }
}

module cable_guide() {
    s = 3 * nozzle_diameter;
    r = (ring_id + ring_od) / 4;
    h = tube_height - 1.5 * base_height - 1;
    hole = center_hole / 2 - thread_inset - tolerance - nozzle_diameter;
    difference() {
        union() {
            translate([0, 0, h - eps]) ScrewThread(center_hole, 0.6 * base_height, pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance);
            cylinder(h, r, center_hole / 2);
        }
        translate([0, 0, -eps]) cylinder(h + 2 * eps, r - s, center_hole / 2 - s);
        cylinder(5 * h, r = hole, center = true);
    }
}

module tube() {
    module thread_extra(h) {
        i = thread_inset + eps;
        polygon([[0, 0], [0, h], [i, h + i], [i, 0]]);
    }
        
    h = base_height / 2;
    screw_hole(height = h + thread_pitch / 2)
    screw_hole(height = h, position = [0, 0, tube_height - h])
        rotate_extrude($fs=0.2, $fa = 1) {
            translate([case_dia / 2 - wall, 0])
                square([wall, tube_height]);
            translate([case_dia / 2 - wall - thread_inset, 0])
                thread_extra(h);
            translate([case_dia / 2 - wall - thread_inset, tube_height])
                mirror([0, 1, 0])
                    thread_extra(h + wall);
        }
}

module cap() {
    l1 = case_dia / 2 - wall / 2 - cap_radius;
    l2 = cap_height - wall / 2 - cap_radius;
    difference() {
        union() {
            screw_thread(height = cap_radius + 1 + eps);
            translate([0, 0, cap_radius + 1]) hull() rotate_extrude() {
                translate([l1, l2])
                    rotate(90)
                        Bogen(rad = cap_radius, 2D = true, l1 = l1, l2 = l2, d = wall, grad = 90, messpunkt = false);
            }
        }
        r = (thread_dia - 2 * thread_inset - wall) / 2;
        h = cap_height + cap_radius + 1 - wall;
        translate([0, 0, -eps]) cylinder(r1 = r, r2 = r - (h * 2 / 3), h = h);
    }
}

module part_select() {
    for (idx = [0:1:$children-1]) {
        if (selection == 0) {
            col = parts[idx][3];
            translate(parts[idx][1])
                rotate(parts[idx][2])
                    if (is_undef(col))
                        children(idx);
                    else
                        color(col[0], col[1])
                            children(idx);
        } else {
            if (selection == idx)
                children(idx);
        }
    }
}

part_select() {
    union() {
        if ($preview) translate([0, 0, 65]) ring();
    }
    bottom();
    ring_plate();
    ring_screw();
    cable_guide();
    tube();
    cap();
}

// Test print for fitting LED Ring
// !translate([0, 0, 30]) intersection() {translate([0, 0, base_height -5]) cylinder(h = 10, d = ring_od + 5); ring_plate();}
