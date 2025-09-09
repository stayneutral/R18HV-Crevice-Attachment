// RYOBI R18HV Crevice Tool Nozzle
// Designed to fit RYOBI R18HV handheld vacuum inlet
// Total length: 100mm
// Crevice tip: 10mm round

// --- PARAMETERS ---
// Adjust these values as needed
// Connector dimensions (for vacuum inlet) - These are the *external* dimensions of the vacuum's inlet.
// Our nozzle's connector will be slightly smaller to fit *into* it.
v_long_edge = 45;   // Vacuum inlet long edge
v_top_edge = 24;    // Vacuum inlet top edge
v_height = 13;      // Vacuum inlet height

// Tolerance for a snug fit. Adjust if print is too loose or tight.
// Negative value means the nozzle will be bigger than the inlet.
fit_tolerance_start = 0.5; // mm - starts 0.5mm smaller for easy insertion
fit_tolerance_end = -2.0;  // mm - ends 2mm bigger for strong wedge fit

// Nozzle Connector Dimensions at start (looser for easy insertion)
nozzle_long_edge_start = v_long_edge - fit_tolerance_start;
nozzle_top_edge_start = v_top_edge - fit_tolerance_start;
nozzle_height_start = v_height - fit_tolerance_start;

// Nozzle Connector Dimensions at end (tighter for snug fit)
nozzle_long_edge_end = v_long_edge - fit_tolerance_end;
nozzle_top_edge_end = v_top_edge - fit_tolerance_end;
nozzle_height_end = v_height - fit_tolerance_end;

// Nozzle insertion depth into the vacuum
insertion_depth = 20; // mm

// Straw tip dimensions
straw_diameter = 10; // mm
straw_wall_thickness = 1.5; // mm (Adjust for strength vs. airflow)

// Total length of the nozzle
total_length = 100; // mm

// Wall thickness for the main body of the adapter
body_wall_thickness = 1.5; // mm

// Number of facets for circular parts (higher = smoother, but larger file)
$fn = 64;

// --- MODULES ---
module trapezoid_connector_tapered(l_edge_start, t_edge_start, h_start, l_edge_end, t_edge_end, h_end, depth) {
    hull() {
        // Start face (loose fit)
        linear_extrude(height = 0.1) {
            polygon(points = [
                [-l_edge_start/2, -h_start/2],
                [l_edge_start/2, -h_start/2],
                [t_edge_start/2, h_start/2],
                [-t_edge_start/2, h_start/2]
            ]);
        }
        // End face (tight fit)
        translate([0, 0, depth - 0.1]) {
            linear_extrude(height = 0.1) {
                polygon(points = [
                    [-l_edge_end/2, -h_end/2],
                    [l_edge_end/2, -h_end/2],
                    [t_edge_end/2, h_end/2],
                    [-t_edge_end/2, h_end/2]
                ]);
            }
        }
    }
}

// --- MAIN BODY DESIGN ---
module custom_crevice_nozzle() {
    // Calculate lengths
    // The adapter section connects the trapezoid to the circular straw
    // We assume the transition happens over the remaining length after insertion_depth and some straw length
    
    // For simplicity, let's make the straw section a reasonable length at the end.
    // Let's say the straw part is 30mm long.
    straw_actual_length = 30; // Length of the final 10mm diameter straw section
    
    // The transition from trapezoid to circle
    // This is the total length minus the insertion depth and the straw's actual length
    transition_length = total_length - insertion_depth - straw_actual_length;
    
    // Ensure transition_length is not negative
    if (transition_length < 0) {
        echo("Warning: transition_length is negative. Adjust total_length, insertion_depth, or straw_actual_length.");
        transition_length = 10; // Default to a small transition if calculation fails
    }

    // --- 1. Trapezoidal Connection (Male connector that fits into vacuum inlet) ---
    // Now with taper for progressive wedge fit
    difference() {
        // Outer tapered shape
        trapezoid_connector_tapered(
            nozzle_long_edge_start, nozzle_top_edge_start, nozzle_height_start,
            nozzle_long_edge_end, nozzle_top_edge_end, nozzle_height_end,
            insertion_depth
        );
        
        // Inner void - also tapered to maintain consistent wall thickness
        translate([0, 0, -0.01]) {
            trapezoid_connector_tapered(
                nozzle_long_edge_start - 2 * body_wall_thickness,
                nozzle_top_edge_start - 2 * body_wall_thickness,
                nozzle_height_start - 2 * body_wall_thickness,
                nozzle_long_edge_end - 2 * body_wall_thickness,
                nozzle_top_edge_end - 2 * body_wall_thickness,
                nozzle_height_end - 2 * body_wall_thickness,
                insertion_depth + 0.02
            );
        }
    }

    // --- 2. Transition Body from Trapezoid to Circle ---
    // This connects the trapezoidal opening to the circular straw
    translate([0, 0, insertion_depth]) {
        difference() {
            hull() {
                // Start of hull (end of trapezoidal connector)
                linear_extrude(height = 0.1) { // Small height for hull start
                    polygon(points = [
                        [-(nozzle_long_edge_end/2), -(nozzle_height_end/2)],
                        [(nozzle_long_edge_end/2), -(nozzle_height_end/2)],
                        [(nozzle_top_edge_end/2), (nozzle_height_end/2)],
                        [-(nozzle_top_edge_end/2), (nozzle_height_end/2)]
                    ]);
                }
                
                // End of hull (start of circular straw)
                translate([0, 0, transition_length]) {
                    linear_extrude(height = 0.1) {
                        circle(d = straw_diameter + 2*straw_wall_thickness);
                    }
                }
            }
            
            // Inner void for the transition
            hull() {
                // Inner void start (matching the trapezoid inner dimensions)
                linear_extrude(height = 0.1) {
                    polygon(points = [
                        [-(nozzle_long_edge_end/2 - body_wall_thickness), -(nozzle_height_end/2 - body_wall_thickness)],
                        [(nozzle_long_edge_end/2 - body_wall_thickness), -(nozzle_height_end/2 - body_wall_thickness)],
                        [(nozzle_top_edge_end/2 - body_wall_thickness), (nozzle_height_end/2 - body_wall_thickness)],
                        [-(nozzle_top_edge_end/2 - body_wall_thickness), (nozzle_height_end/2 - body_wall_thickness)]
                    ]);
                }
                
                // Inner void end (circular)
                translate([0, 0, transition_length]) {
                    linear_extrude(height = 0.1) {
                        circle(d = straw_diameter);
                    }
                }
            }
        }
    }
    
    // --- 3. Straw Tip ---
    translate([0, 0, insertion_depth + transition_length]) {
        difference() {
            cylinder(d = straw_diameter + 2*straw_wall_thickness, h = straw_actual_length);
            translate([0, 0, -0.01]) { // Slight overlap to ensure clean cut
                cylinder(d = straw_diameter, h = straw_actual_length + 0.02);
            }
        }
    }
}

// Render the full nozzle
custom_crevice_nozzle();