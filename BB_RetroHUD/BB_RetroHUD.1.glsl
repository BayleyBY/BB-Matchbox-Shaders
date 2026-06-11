// BB_RetroHUD — Pass 1: HUD Elements
// Retro sci-fi HUD overlay inspired by Alien, Aliens, Blade Runner, 2001, TRON.
// No input image required.

uniform float adsk_result_w;
uniform float adsk_result_h;
uniform float adsk_time;

// ---------------------------------------------------------------------------
// Global Time
// ---------------------------------------------------------------------------
uniform float time_scale;
uniform float time_offset;

// ---------------------------------------------------------------------------
// Radar
// ---------------------------------------------------------------------------
uniform bool  radar_enable;
uniform float radar_speed;
uniform float radar_time_offset;
uniform float radar_sweep_start;
uniform float radar_scale;
uniform float radar_pos_x;
uniform float radar_pos_y;
uniform float radar_rot;
uniform vec3  radar_color;
uniform float radar_glow;
uniform float radar_opacity;
uniform int   radar_blips;

// ---------------------------------------------------------------------------
// Reticle
// ---------------------------------------------------------------------------
uniform bool  reticle_enable;
uniform float reticle_speed;
uniform float reticle_time_offset;
uniform float reticle_scale;
uniform float reticle_pos_x;
uniform float reticle_pos_y;
uniform float reticle_rot;
uniform vec3  reticle_color;
uniform float reticle_glow;
uniform float reticle_opacity;

// ---------------------------------------------------------------------------
// Oscilloscope
// ---------------------------------------------------------------------------
uniform bool  oscope_enable;
uniform float oscope_speed;
uniform float oscope_speed2;
uniform float oscope_time_offset;
uniform float oscope_width;
uniform float oscope_height;
uniform float oscope_scale;
uniform float oscope_pos_x;
uniform float oscope_pos_y;
uniform float oscope_rot;
uniform vec3  oscope_color;
uniform float oscope_glow;
uniform float oscope_opacity;
uniform int   oscope_mode;  // 0=Sine  1=Lissajous  2=Pulse

// ---------------------------------------------------------------------------
// Bar Meters
// ---------------------------------------------------------------------------
uniform bool  bars_enable;
uniform float bars_speed;
uniform float bars_time_offset;
uniform float bars_scale;
uniform float bars_pos_x;
uniform float bars_pos_y;
uniform float bars_rot;
uniform vec3  bars_color;
uniform float bars_glow;
uniform float bars_opacity;
uniform int   bars_count;

// ---------------------------------------------------------------------------
// Data Terminal
// ---------------------------------------------------------------------------
uniform bool  terminal_enable;
uniform float terminal_speed;
uniform float terminal_time_offset;
uniform float terminal_scale;
uniform float terminal_pos_x;
uniform float terminal_pos_y;
uniform float terminal_rot;
uniform vec3  terminal_color;
uniform float terminal_glow;
uniform float terminal_opacity;

// ---------------------------------------------------------------------------
// Perspective Grid
// ---------------------------------------------------------------------------
uniform bool  pgrid_enable;
uniform float pgrid_speed;
uniform float pgrid_time_offset;
uniform float pgrid_scale;
uniform float pgrid_pos_x;
uniform float pgrid_pos_y;
uniform float pgrid_rot;
uniform vec3  pgrid_color;
uniform float pgrid_glow;
uniform float pgrid_opacity;
uniform float pgrid_horizon;
uniform int   pgrid_cols;     // number of lateral cells (columns)
uniform float pgrid_spacing;  // depth spacing between cross lines

// ---------------------------------------------------------------------------
// Circuit Trace
// ---------------------------------------------------------------------------
uniform bool  circuit_enable;
uniform float circuit_speed;
uniform float circuit_time_offset;
uniform float circuit_scale;
uniform float circuit_pos_x;
uniform float circuit_pos_y;
uniform float circuit_rot;
uniform vec3  circuit_color;
uniform float circuit_glow;
uniform float circuit_opacity;
uniform float circuit_pulse_density;  // spacing of flowing pulses
uniform float circuit_pulse_size;     // length of each pulse along the trace
uniform float circuit_pulse_bright;   // pulse glow intensity

// ---------------------------------------------------------------------------
// Corner Brackets
// ---------------------------------------------------------------------------
uniform bool  brackets_enable;
uniform float brackets_speed;
uniform float brackets_time_offset;
uniform float brackets_scale;
uniform float brackets_pos_x;
uniform float brackets_pos_y;
uniform float brackets_rot;
uniform vec3  brackets_color;
uniform float brackets_glow;
uniform float brackets_opacity;
uniform float brackets_arm;
uniform float brackets_pulse_size;    // scanner dot size
uniform float brackets_pulse_bright;  // scanner dot glow intensity

// ---------------------------------------------------------------------------
// Compass Tape
// ---------------------------------------------------------------------------
uniform bool  compass_enable;
uniform float compass_speed;
uniform float compass_time_offset;
uniform float compass_scale;
uniform float compass_pos_x;
uniform float compass_pos_y;
uniform float compass_rot;
uniform vec3  compass_color;
uniform float compass_glow;
uniform float compass_opacity;

// ---------------------------------------------------------------------------
// Trajectory Arc
// ---------------------------------------------------------------------------
uniform bool  arc_enable;
uniform float arc_speed;
uniform float arc_time_offset;
uniform float arc_scale;
uniform float arc_pos_x;
uniform float arc_pos_y;
uniform float arc_rot;
uniform vec3  arc_color;
uniform float arc_glow;
uniform float arc_opacity;
uniform int   arc_nodes;

// ---------------------------------------------------------------------------
// Dial Gauge
// ---------------------------------------------------------------------------
uniform bool  dial_enable;
uniform float dial_speed;
uniform float dial_time_offset;
uniform float dial_scale;
uniform float dial_pos_x;
uniform float dial_pos_y;
uniform float dial_rot;
uniform vec3  dial_color;
uniform float dial_glow;
uniform float dial_opacity;

// ---------------------------------------------------------------------------
// Light Grid (TRON)
// ---------------------------------------------------------------------------
uniform bool  lgrid_enable;
uniform float lgrid_speed;
uniform float lgrid_time_offset;
uniform float lgrid_scale;
uniform float lgrid_pos_x;
uniform float lgrid_pos_y;
uniform float lgrid_rot;
uniform vec3  lgrid_color;
uniform float lgrid_glow;
uniform float lgrid_opacity;
uniform int   lgrid_cols;
uniform int   lgrid_rows;
uniform float lgrid_pulse_size;    // node pulse size
uniform float lgrid_pulse_bright;  // node pulse glow intensity

// ---------------------------------------------------------------------------
// Light Trail (TRON)
// ---------------------------------------------------------------------------
uniform bool  trail_enable;
uniform float trail_speed;
uniform float trail_time_offset;
uniform float trail_scale;
uniform float trail_pos_x;
uniform float trail_pos_y;
uniform float trail_rot;
uniform vec3  trail_color;
uniform float trail_glow;
uniform float trail_opacity;
uniform int   trail_count;    // number of lightcycles on screen
uniform float trail_length;   // total trail length (arc-length along the path)
uniform float trail_fade;     // length of the fade-out at the tail
uniform bool  trail_multicolor; // give each lightcycle its own colour
uniform vec3  trail_col1;       // per-cycle colours (used when multicolor on)
uniform vec3  trail_col2;
uniform vec3  trail_col3;
uniform vec3  trail_col4;
uniform vec3  trail_col5;

// ===========================================================================
// Helpers
// ===========================================================================

#define PI 3.14159265358979

float gTime;

mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float Hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float Hash21(vec2 p) {
    p = fract(p * vec2(0.1031, 0.1030));
    p += dot(p, p.yx + 33.33);
    return fract((p.x + p.y) * p.x);
}

vec2 Hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// Box SDF (half-extents b)
float B(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Segment SDF
float Seg(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Anti-aliased glow alpha
float aa;
float ov_alpha(float d, float glow) {
    return max(smoothstep(aa, -aa, d), exp(-max(d, 0.0) / max(glow * 0.005, 0.00001)));
}

// Dashed line helper: returns distance to dashed segment, dash = on fraction (0..1)
float DashSeg(vec2 p, vec2 a, vec2 b, float dashLen, float dashFrac) {
    vec2 ba = b - a;
    float len = length(ba);
    vec2 pa = p - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float along = t * len;
    float phase = mod(along, dashLen);
    float onLen = dashLen * dashFrac;
    float dist = length(p - (a + ba * t));
    return phase > onLen ? 1e9 : dist;
}

// ===========================================================================
// Element: Radar
// ===========================================================================
float radarUI(vec2 p, float t) {
    float d = 1e9;
    float r0 = 0.38;    // outer ring
    float r1 = 0.27;    // mid ring
    float r2 = 0.16;    // inner ring
    float r3 = 0.025;   // centre hub
    float lp = length(p);

    // Rings
    d = min(d, abs(lp - r0) - 0.006);
    d = min(d, abs(lp - r1) - 0.004);
    d = min(d, abs(lp - r2) - 0.003);
    // Centre hub
    d = min(d, lp - r3);

    // Cardinal tick marks (N / S / E / W)
    for (int i = 0; i < 4; i++) {
        float ang = float(i) * PI * 0.5;
        vec2 dir = vec2(cos(ang), sin(ang));
        d = min(d, Seg(p, dir * r0, dir * (r0 + 0.042)) - 0.004);
    }

    // Diagonal ticks (45° marks, shorter)
    for (int i = 0; i < 4; i++) {
        float ang = float(i) * PI * 0.5 + PI * 0.25;
        vec2 dir = vec2(cos(ang), sin(ang));
        d = min(d, Seg(p, dir * r0, dir * (r0 + 0.022)) - 0.003);
    }

    // Crosshair — clipped between centre hub and outer ring
    float hClip = max(lp - r0, r3 - lp);
    d = min(d, max(abs(p.y) - 0.0025, hClip));
    d = min(d, max(abs(p.x) - 0.0025, hClip));

    // Sweep arm
    float sweepAngle = t * 2.0 * PI + radians(radar_sweep_start);
    vec2 sweepDir = vec2(cos(sweepAngle), sin(sweepAngle));
    d = min(d, Seg(p, vec2(0.0), sweepDir * r0) - 0.005);

    // Angular distance of current pixel from sweep arm (0 = at arm, increases behind it)
    float pixAng  = atan(p.y, p.x);
    float sweep   = mod(sweepAngle, 2.0 * PI);
    float dAng    = mod(sweep - pixAng, 2.0 * PI);

    // Sweep trail — phosphor persistence fading 180° behind arm, inside disc
    // Uses a positive d value so glow formula creates the fade (no fill)
    if (dAng < PI && lp < r0 && lp > r3) {
        float fade   = 1.0 - dAng / PI;          // 1.0 at arm → 0.0 at 180°
        float trailD = 0.04 * (1.0 - fade * 0.95); // ~0.002 at arm → 0.04 at 180°
        d = min(d, trailD);
    }

    // Blips — fixed random contacts that light up when the sweep arm passes
    // and then fade over 270° of subsequent rotation (phosphor persistence)
    int nb = min(radar_blips, 12);
    for (int i = 0; i < 12; i++) {
        if (i >= nb) break;
        // Unique hashed position for each blip: random angle + random radius
        float bAngle  = Hash21(vec2(float(i) * 1.618, 0.5))  * 2.0 * PI;
        float bRadius = Hash21(vec2(float(i) * 2.399, 1.3))  * (r0 - r3 - 0.05) + r3 + 0.025;
        vec2  bPos    = vec2(cos(bAngle), sin(bAngle)) * bRadius;
        // How far (in angle) the sweep arm is ahead of this blip
        float bDiff   = mod(sweep - bAngle, 2.0 * PI);
        // Bright immediately after sweep passes, fades over 270°
        float bFade   = bDiff < PI * 1.5 ? exp(-bDiff * 1.0) : 0.0;
        if (bFade > 0.008) {
            float bd = length(p - bPos) - 0.018;
            // Shift SDF outward as fade drops so the dot shrinks gracefully
            d = min(d, bd + 0.014 * (1.0 - bFade));
        }
    }

    return d;
}

// ===========================================================================
// Element: Reticle
// ===========================================================================
float reticleUI(vec2 p, float t) {
    float d = 1e9;
    float r  = 0.32;    // outer ring
    float mr = 0.20;    // mid ring
    float lp = length(p);

    // Outer ring — static
    d = min(d, abs(lp - r) - 0.005);

    // Mid ring — thin reference circle
    d = min(d, abs(lp - mr) - 0.0015);

    // Outer tick scale — counter-rotating
    float tickRot = t * 2.0 * PI * -0.06;
    for (int i = 0; i < 36; i++) {
        float ang     = float(i) * PI / 18.0 + tickRot;
        vec2  dir     = vec2(cos(ang), sin(ang));
        float isMajor = mod(float(i), 9.0) == 0.0 ? 1.0 : 0.0;
        float tickLen = isMajor > 0.5 ? 0.028 : 0.012;
        float thick   = isMajor > 0.5 ? 0.0025 : 0.0015;
        d = min(d, Seg(p, dir * (r - tickLen), dir * r) - thick);
    }

    // Crosshair arms — from near centre to just inside outer ring
    for (int i = 0; i < 4; i++) {
        float ang = float(i) * PI * 0.5;
        vec2  dir = vec2(cos(ang), sin(ang));
        d = min(d, Seg(p, dir * 0.04, dir * (r - 0.012)) - 0.003);
    }

    // Cardinal outer ticks — static, extend beyond ring
    for (int i = 0; i < 4; i++) {
        float ang = float(i) * PI * 0.5;
        vec2  dir = vec2(cos(ang), sin(ang));
        d = min(d, Seg(p, dir * r, dir * (r + 0.042)) - 0.004);
    }

    // Centre dot — gently pulsing
    float pulse = 0.014 + 0.005 * sin(t * 2.0 * PI * 0.8);
    d = min(d, lp - pulse);

    return d;
}

// ===========================================================================
// Element: Oscilloscope
// ===========================================================================
float oscopeUI(vec2 p, float t, float t2) {
    float d = 1e9;
    float W = oscope_width;
    float H = oscope_height;

    // CRT frame
    d = min(d, abs(B(p, vec2(W, H))) - 0.006);
    // Inner border line
    d = min(d, abs(B(p, vec2(W - 0.025, H - 0.025))) - 0.002);

    // Only draw trace inside screen
    if (abs(p.x) < W && abs(p.y) < H) {
        float traceDist = 1e9;

        if (oscope_mode == 1) {
            // Lissajous: parametric curve
            int steps = 80;
            vec2 prev = vec2(sin(0.0 * 3.0 + t * 1.1) * (W - 0.05),
                            sin(0.0 * 2.0 + t * 0.9) * (H - 0.05));
            for (int i = 1; i <= steps; i++) {
                float s = float(i) / float(steps) * 2.0 * PI;
                vec2 cur = vec2(sin(s * 3.0 + t * 1.1) * (W - 0.05),
                               sin(s * 2.0 + t * 0.9) * (H - 0.05));
                traceDist = min(traceDist, Seg(p, prev, cur));
                prev = cur;
            }
        } else if (oscope_mode == 2) {
            // Pulse / square wave
            int steps = 48;
            float prevX = -W + 0.05;
            float segW = (2.0 * (W - 0.05)) / float(steps);
            for (int i = 0; i < steps; i++) {
                float x0 = -W + 0.05 + float(i) * segW;
                float x1 = x0 + segW;
                float ph = floor((x0 / segW + t * 4.0) * 1.0);
                float hi = mod(ph, 2.0) < 1.0 ? 1.0 : -1.0;
                float y = hi * 0.20;
                // Horizontal segment
                traceDist = min(traceDist, Seg(p, vec2(x0, y), vec2(x1, y)));
                // Vertical transition
                float prevH = mod(ph - 1.0, 2.0) < 1.0 ? 1.0 : -1.0;
                float prevY = prevH * 0.20;
                traceDist = min(traceDist, Seg(p, vec2(x0, prevY), vec2(x0, y)));
            }
        } else {
            // Sine wave 1 — fixed amplitude independent of frame size
            int steps = 64;
            float amp1 = 0.18;
            vec2 prev2 = vec2(-W + 0.05,
                sin((-W + 0.05) * 6.0 + t * 2.0 * PI) * amp1);
            for (int i = 1; i <= steps; i++) {
                float x = -W + 0.05 + float(i) / float(steps) * 2.0 * (W - 0.05);
                vec2 cur2 = vec2(x, sin(x * 6.0 + t * 2.0 * PI) * amp1);
                traceDist = min(traceDist, Seg(p, prev2, cur2));
                prev2 = cur2;
            }
            // Sine wave 2 — fixed amplitude, higher frequency
            float amp2 = 0.12;
            vec2 prev3 = vec2(-W + 0.05,
                sin((-W + 0.05) * 9.0 + t2 * 2.0 * PI) * amp2);
            for (int i = 1; i <= steps; i++) {
                float x = -W + 0.05 + float(i) / float(steps) * 2.0 * (W - 0.05);
                vec2 cur3 = vec2(x, sin(x * 9.0 + t2 * 2.0 * PI) * amp2);
                traceDist = min(traceDist, Seg(p, prev3, cur3));
                prev3 = cur3;
            }
        }
        d = min(d, traceDist - 0.004);
    }

    // Fixed-spacing grid — cell size stays constant, more cells appear as frame grows
    float gridX = 0.22;
    float gridY = 0.14;
    float frameClip = max(abs(p.x) - (W - 0.015), abs(p.y) - (H - 0.015));
    float hLineDist = (abs(fract(p.y / gridY + 0.5) - 0.5) * gridY);
    float vLineDist = (abs(fract(p.x / gridX + 0.5) - 0.5) * gridX);
    d = min(d, max(hLineDist - 0.0008, frameClip));
    d = min(d, max(vLineDist - 0.0008, frameClip));

    return d;
}

// ===========================================================================
// Element: Bar Meters
// ===========================================================================
float barsUI(vec2 p, float t) {
    float d = 1e9;
    int nb = min(max(bars_count, 2), 8);
    float totalW = 0.5;
    float barW = totalW / float(nb) * 0.55;
    float gap = totalW / float(nb);
    float H = 0.30;
    int segs = 10;

    for (int i = 0; i < 8; i++) {
        if (i >= nb) break;
        float bx = (float(i) - float(nb - 1) * 0.5) * gap;
        // Animated level using hash + time
        float lvl = Hash11(float(i) * 1.37 + 0.1) * 0.4 + 0.3;
        lvl += sin(t * (1.5 + Hash11(float(i) * 0.77)) * 2.0 * PI + float(i)) * 0.25;
        lvl = clamp(lvl, 0.05, 1.0);
        int lit = int(lvl * float(segs));

        for (int s = 0; s < 10; s++) {
            if (s >= segs) break;
            float sy = (-H + float(s) * H * 2.0 / float(segs - 1));
            float segH = H / float(segs) * 0.6;
            vec2 bPos = vec2(bx, sy);
            float bd = B(p - bPos, vec2(barW, segH));
            if (s <= lit) {
                d = min(d, bd - 0.002);
            } else {
                // Unlit segments as faint outlines
                d = min(d, abs(bd) - 0.001);
            }
        }
        // Outer frame
        d = min(d, abs(B(p - vec2(bx, 0.0), vec2(barW + 0.01, H + 0.01))) - 0.003);
    }

    return d;
}

// ===========================================================================
// Element: Data Terminal
// ===========================================================================
// Draws a grid of small rectangular "character" blocks to simulate scrolling text
float terminalUI(vec2 p, float t) {
    float d = 1e9;
    float W = 0.45, H = 0.30;

    // Outer CRT frame
    d = min(d, abs(B(p, vec2(W, H))) - 0.005);

    // Character grid inside
    float cW = 0.035, cH = 0.018;
    float cx = 0.045, cy = 0.025; // cell pitch
    int cols = 10, rows = 12;
    float startX = -(float(cols - 1) * 0.5) * cx;
    float startY = -(float(rows - 1) * 0.5) * cy;

    for (int r = 0; r < 12; r++) {
        for (int c = 0; c < 10; c++) {
            float px = startX + float(c) * cx;
            float py = startY + float(r) * cy;
            py += mod(t * 0.4, float(rows) * cy) - float(rows) * cy * 0.5;
            if (abs(py) < H - 0.02) {
                float h = Hash21(vec2(float(c) * 1.1 + 0.5, float(r) * 0.9 + floor(t * 0.4 / cy + 0.5)));
                if (h > 0.35) {
                    float charW = cW * (0.4 + h * 0.5);
                    d = min(d, B(p - vec2(px, py), vec2(charW, cH * 0.7)) - 0.001);
                }
            }
        }
    }

    // Cursor blinking line at bottom
    float cursorBlink = step(0.5, fract(t * 1.2));
    if (cursorBlink > 0.5) {
        float curY = startY - cy;
        d = min(d, B(p - vec2(startX, curY + float(rows) * cy * 0.5 - cy), vec2(cW * 1.5, cH * 0.7)) - 0.002);
    }

    return d;
}

// ===========================================================================
// Element: Perspective Grid
// ===========================================================================
float pgridUI(vec2 p, float t) {
    float d = 1e9;
    float aspect = adsk_result_w / adsk_result_h;
    float horizon = pgrid_horizon; // 0=centre, 1=top, -1=bottom

    // Vanishing point at the horizon, and the near (bottom) edge of the plane
    vec2  vp          = vec2(0.0, horizon * 0.35);
    float groundBottom = vp.y - 0.5;
    float halfSpan     = 0.45 * aspect;   // half-width of the plane at the near edge

    // Longitudinal lines (the rails) — static, converging on the VP.
    // pgrid_cols sets the number of lateral cells (columns); rails = cols + 1.
    int nCols = min(max(pgrid_cols, 1), 20);
    for (int i = 0; i <= 20; i++) {
        if (i > nCols) break;
        float fx = (float(i) / float(nCols) - 0.5) * 2.0 * halfSpan;
        d = min(d, Seg(p, vp, vec2(fx, groundBottom)) - 0.003);
    }

    // Cross lines — continuous travel across the ground toward the viewer.
    // Each line sits at world depth Z; perspective maps Z to screen Y as
    // y = vp.y - 0.5/Z, so Z = 1 is the near edge and Z -> inf is the horizon.
    // pgrid_spacing scales the world gap between lines (rows). Advancing
    // 'scroll' pulls every line forward (Z shrinks); the fractional recycle
    // spawns a new line at the horizon exactly as the nearest one passes
    // under the viewer, giving a seamless endless loop.
    float scroll = t * 2.5;
    float fpart  = fract(scroll);
    for (int j = 0; j < 18; j++) {
        float zw   = (float(j) + 1.0 - fpart) * pgrid_spacing; // world depth, > 0
        float yLine = vp.y - 0.5 / zw;          // perspective projection
        if (yLine < groundBottom - 0.001) continue;  // has passed the viewer
        float perspW = halfSpan / zw;           // width tracks the rails exactly
        float th     = 0.0025 * (0.35 + 0.65 / zw); // thinner toward the horizon
        d = min(d, Seg(p, vec2(-perspW, yLine), vec2(perspW, yLine)) - th);
    }

    // Horizon line
    d = min(d, abs(p.y - vp.y) - 0.003);

    return d;
}

// ===========================================================================
// Element: Circuit Trace
// ===========================================================================
// Returns vec2(trace SDF, additive energy glow). The glow channel carries the
// bright flowing pulses so they can read brighter than the static traces.
vec2 circuitUI(vec2 p, float t) {
    float d = 1e9;
    float glow = 0.0;
    float cell = 0.12;

    // Tile the space
    vec2 tileP = p / cell;
    vec2 id = floor(tileP);
    vec2 lp = fract(tileP) - 0.5;

    // Each cell has a hash-determined trace pattern
    float h    = Hash21(id);
    float h2   = Hash21(id + vec2(7.3, 2.1));
    float hv   = Hash21(id + vec2(1.1, 3.7));
    bool  hasH = h  > 0.3;   // horizontal trace through this cell
    bool  hasV = h2 > 0.4;   // vertical trace
    bool  hasVia = hv > 0.6; // via pad at centre

    // Static copper traces
    if (hasH)   d = min(d, abs(lp.y) - 0.025);
    if (hasV)   d = min(d, abs(lp.x) - 0.025);
    if (hasVia) d = min(d, abs(length(lp) - 0.07) - 0.018);

    // --- Flowing energy pulses ---
    // A bright packet travels along each trace. The along-axis coordinate
    // (p.x or p.y) is continuous across cell borders, so a pulse glides
    // smoothly down a whole row/column. Each row and column picks its own
    // direction, so the board reads as data routing every which way at once.
    // 'flow' carries a constant travel speed; density only changes the spacing
    // of packets, and the exponent sets each packet's length (size).
    float density = circuit_pulse_density;
    float expo    = 6.0 / max(circuit_pulse_size, 0.05); // smaller size -> sharper dot
    if (hasH) {
        float dir  = Hash21(vec2(0.0, id.y)) > 0.5 ? 1.0 : -1.0;
        float flow = p.x / cell - t * dir * 1.5;
        float bump = pow(0.5 + 0.5 * cos((flow * density + Hash11(id.y + 0.5)) * 2.0 * PI), expo);
        glow += bump * smoothstep(0.06, 0.0, abs(lp.y));    // confine to trace
    }
    if (hasV) {
        float dir  = Hash21(vec2(id.x, 0.0)) > 0.5 ? 1.0 : -1.0;
        float flow = p.y / cell - t * dir * 1.5;
        float bump = pow(0.5 + 0.5 * cos((flow * density + Hash11(id.x + 1.5)) * 2.0 * PI), expo);
        glow += bump * smoothstep(0.06, 0.0, abs(lp.x));
    }
    // Via pads blink independently
    if (hasVia) {
        float blink = 0.5 + 0.5 * sin(t * 3.0 + hv * 30.0);
        glow += smoothstep(0.025, 0.0, abs(length(lp) - 0.07)) * blink * 0.9;
    }

    return vec2(d * cell, glow);
}

// ===========================================================================
// Element: Corner Brackets
// ===========================================================================
// Returns vec2(bracket SDF, additive scanner glow).
vec2 bracketsUI(vec2 p, float t) {
    float d = 1e9;
    float glow = 0.0;
    float W = 0.50, H = 0.32;
    float arm = brackets_arm;
    float armX = W * arm;
    float armY = H * arm;
    float th = 0.004;

    // Four corners — explicitly unrolled to avoid variable array indexing
    vec2 cTL = vec2(-W,  H);
    vec2 cTR = vec2( W,  H);
    vec2 cBL = vec2(-W, -H);
    vec2 cBR = vec2( W, -H);

    // TL: arm right and down
    d = min(d, Seg(p, cTL, cTL + vec2( armX, 0.0)) - th);
    d = min(d, Seg(p, cTL, cTL + vec2(0.0, -armY)) - th);
    // TR: arm left and down
    d = min(d, Seg(p, cTR, cTR + vec2(-armX, 0.0)) - th);
    d = min(d, Seg(p, cTR, cTR + vec2(0.0, -armY)) - th);
    // BL: arm right and up
    d = min(d, Seg(p, cBL, cBL + vec2( armX, 0.0)) - th);
    d = min(d, Seg(p, cBL, cBL + vec2(0.0,  armY)) - th);
    // BR: arm left and up
    d = min(d, Seg(p, cBR, cBR + vec2(-armX, 0.0)) - th);
    d = min(d, Seg(p, cBR, cBR + vec2(0.0,  armY)) - th);

    // Side data tick marks — small horizontal ticks on left and right edges
    for (int i = 0; i < 5; i++) {
        float yOff = (float(i) / 4.0 - 0.5) * H * 1.6;
        // Left
        d = min(d, Seg(p, vec2(-W - 0.02, yOff), vec2(-W + 0.02, yOff)) - 0.002);
        // Right
        d = min(d, Seg(p, vec2(W - 0.02, yOff), vec2(W + 0.02, yOff)) - 0.002);
    }

    // --- Scanner pulse: a bright dot tracing the frame perimeter ---
    // Travels clockwise TL -> TR -> BR -> BL -> TL on a continuous loop,
    // passing over each corner bracket in turn. Rendered as additive glow.
    float perim   = 4.0 * (W + H);
    float topLen  = 2.0 * W;
    float rightLen = 2.0 * H;
    float botLen  = 2.0 * W;
    float s = mod(t * 0.5, perim);
    vec2 dotP;
    if (s < topLen) {
        dotP = vec2(-W + s, H);                                  // top: TL -> TR
    } else if (s < topLen + rightLen) {
        dotP = vec2(W, H - (s - topLen));                        // right: TR -> BR
    } else if (s < topLen + rightLen + botLen) {
        dotP = vec2(W - (s - topLen - rightLen), -H);            // bottom: BR -> BL
    } else {
        dotP = vec2(-W, -H + (s - topLen - rightLen - botLen));  // left: BL -> TL
    }
    float radius = 0.02 * brackets_pulse_size;
    float gd = length(p - dotP);
    glow += exp(-(gd * gd) / max(radius * radius, 1e-6));

    return vec2(d, glow);
}

// ===========================================================================
// Element: Compass Tape
// ===========================================================================
float compassUI(vec2 p, float t) {
    float d = 1e9;
    float W = 0.50, H = 0.045;

    // Tape frame
    d = min(d, abs(B(p, vec2(W, H))) - 0.004);

    // Scrolling heading ticks
    float heading = t * 30.0; // degrees per second
    float degPerUnit = 1.0 / (W * 2.0) * 60.0; // 60 deg visible range
    for (int i = -40; i <= 40; i++) {
        float deg = heading + float(i) * (60.0 / 80.0);
        float xPos = (float(i) / 80.0) * W * 2.0;
        if (abs(xPos) <= W - 0.01) {
            float isMajor = mod(deg, 10.0) < 1.5 ? 1.0 : 0.0;
            float tickH = isMajor > 0.5 ? H * 0.7 : H * 0.35;
            d = min(d, Seg(p, vec2(xPos, -tickH), vec2(xPos, tickH)) - 0.002);
        }
    }

    // Centre marker (triangle pointing down)
    vec2 tri[3];
    tri[0] = vec2(0.0,  H + 0.015);
    tri[1] = vec2(-0.012, H + 0.040);
    tri[2] = vec2( 0.012, H + 0.040);
    d = min(d, Seg(p, tri[0], tri[1]) - 0.003);
    d = min(d, Seg(p, tri[1], tri[2]) - 0.003);
    d = min(d, Seg(p, tri[2], tri[0]) - 0.003);

    return d;
}

// ===========================================================================
// Element: Trajectory Arc
// ===========================================================================
float arcUI(vec2 p, float t) {
    float d = 1e9;
    float R = 0.32;
    float startAng = PI * 0.1;
    float endAng = PI * 0.9;
    int nb = min(max(arc_nodes, 2), 8);

    // Dashed arc
    int arcSteps = 48;
    vec2 prev = vec2(cos(startAng) * R, sin(startAng) * R);
    for (int i = 1; i <= 48; i++) {
        if (i > arcSteps) break;
        float ang = startAng + (endAng - startAng) * float(i) / float(arcSteps);
        vec2 cur = vec2(cos(ang) * R, sin(ang) * R);
        float dashD = DashSeg(p, prev, cur, 0.03, 0.55);
        d = min(d, dashD - 0.004);
        prev = cur;
    }

    // Node markers along arc
    for (int n = 0; n < 8; n++) {
        if (n >= nb) break;
        float ang = startAng + (endAng - startAng) * float(n) / float(nb - 1);
        vec2 nodePos = vec2(cos(ang) * R, sin(ang) * R);
        d = min(d, abs(length(p - nodePos) - 0.018) - 0.004);
        d = min(d, length(p - nodePos) - 0.006);
    }

    // Moving dot traveling the arc
    float dotAng = startAng + (endAng - startAng) * fract(t * 0.3 + arc_time_offset);
    vec2 dotPos = vec2(cos(dotAng) * R, sin(dotAng) * R);
    d = min(d, length(p - dotPos) - 0.014);

    // Arrow head at end
    vec2 endP = vec2(cos(endAng) * R, sin(endAng) * R);
    vec2 endTan = vec2(-sin(endAng), cos(endAng));
    vec2 arrA = endP + endTan * 0.025 - normalize(endP) * 0.025;
    vec2 arrB = endP - endTan * 0.025 - normalize(endP) * 0.025;
    d = min(d, Seg(p, endP, arrA) - 0.003);
    d = min(d, Seg(p, endP, arrB) - 0.003);

    return d;
}

// ===========================================================================
// Element: Dial Gauge
// ===========================================================================
float dialUI(vec2 p, float t) {
    float d = 1e9;
    p.y = -p.y;   // flip across the horizontal axis: gauge opens downward, scale across the top
    float R = 0.30;
    float arcStart = PI * 0.75;   // 135 deg
    float arcEnd = PI * 2.25;     // 405 deg = 45 deg (sweeps 270 deg)

    // Outer ring
    d = min(d, abs(length(p) - R) - 0.005);

    // Scale arc ticks
    int nticks = 25;
    for (int i = 0; i <= 25; i++) {
        if (i > nticks) break;
        float ang = arcStart + (arcEnd - arcStart) * float(i) / float(nticks);
        vec2 dir = vec2(cos(ang), sin(ang));
        float major = mod(float(i), 5.0) == 0.0 ? 1.0 : 0.0;
        float tlen = major > 0.5 ? 0.040 : 0.018;
        d = min(d, Seg(p, dir * (R - tlen), dir * R) - (major > 0.5 ? 0.003 : 0.002));
    }

    // Needle sweeps straight from 0 to 100, then repeats
    float value = fract(t * 0.5);
    float needleAng = arcStart + (arcEnd - arcStart) * value;
    vec2 needleEnd = vec2(cos(needleAng), sin(needleAng)) * (R * 0.85);
    vec2 needleBack = vec2(cos(needleAng + PI), sin(needleAng + PI)) * (R * 0.12);
    d = min(d, Seg(p, needleBack, needleEnd) - 0.005);

    // Centre hub
    d = min(d, abs(length(p) - 0.030) - 0.006);
    d = min(d, length(p) - 0.010);

    // Minor arc highlight (filled arc from start to needle)
    // Approximated as thin arc
    int arcFillSteps = 20;
    vec2 prevA = vec2(cos(arcStart), sin(arcStart)) * (R - 0.022);
    for (int i = 1; i <= 20; i++) {
        if (i > arcFillSteps) break;
        float ang = arcStart + (needleAng - arcStart) * float(i) / float(arcFillSteps);
        vec2 curA = vec2(cos(ang), sin(ang)) * (R - 0.022);
        d = min(d, Seg(p, prevA, curA) - 0.007);
        prevA = curA;
    }

    return d;
}

// ===========================================================================
// Element: Light Grid (TRON)
// ===========================================================================
// Returns vec2(grid SDF, additive node glow).
vec2 lgridUI(vec2 p, float t) {
    float d = 1e9;
    float glow = 0.0;
    int nc = min(max(lgrid_cols, 2), 12);
    int nr = min(max(lgrid_rows, 2), 10);
    float aspect = adsk_result_w / adsk_result_h;
    float W = aspect * 0.5, H = 0.5;   // half-extents fill the frame at scale 1
    float cellW = W * 2.0 / float(nc);
    float cellH = H * 2.0 / float(nr);

    // Vertical lines
    for (int c = 0; c <= 12; c++) {
        if (c > nc) break;
        float x = -W + float(c) * cellW;
        d = min(d, abs(p.x - x) - 0.003);
    }
    // Horizontal lines
    for (int r = 0; r <= 10; r++) {
        if (r > nr) break;
        float y = -H + float(r) * cellH;
        d = min(d, abs(p.y - y) - 0.003);
    }

    // Glowing nodes at intersections — additive pulse glow (hot core)
    float radius = 0.02 * lgrid_pulse_size;
    for (int c = 0; c <= 12; c++) {
        if (c > nc) break;
        for (int r = 0; r <= 10; r++) {
            if (r > nr) break;
            float x = -W + float(c) * cellW;
            float y = -H + float(r) * cellH;
            // Pulse each node independently
            float ph = Hash21(vec2(float(c), float(r)));
            float pulse = 0.5 + 0.5 * sin(t * 2.0 * PI * (0.3 + ph * 0.4) + ph * 6.28);
            float gd = length(p - vec2(x, y));
            glow += pulse * exp(-(gd * gd) / max(radius * radius, 1e-6));
        }
    }

    return vec2(d, glow);
}

// ===========================================================================
// Element: Light Trail (TRON)
// ===========================================================================
// One trail segment: along-path fade + head detection. Screens this segment's
// alpha into the per-cycle accumulator so a trail's own corners stay smooth.
void trailSeg(vec2 ql, vec2 A, vec2 B, float distA, float segLen,
              float headDist, float total, float tdir, float trailLen, float fadeLen, float th,
              inout float cycA, inout vec2 headPos, inout float headFound) {
    vec2 AB = B - A;
    float denom = max(dot(AB, AB), 1e-9);
    float h = clamp(dot(ql - A, AB) / denom, 0.0, 1.0);
    float dist = length(ql - (A + AB * h));
    float aPos = distA + h * segLen;
    // How far this point sits behind the head, measured against travel direction
    // (tdir) so the trail always follows the head whichever way it goes.
    float behind = mod((headDist - aPos) * tdir, total);
    if (behind <= trailLen) {
        // Full brightness up to the head, fading over the last 'fadeLen'
        float fade = clamp((trailLen - behind) / max(fadeLen, 1e-4), 0.0, 1.0);
        float a = ov_alpha(dist - th, trail_glow) * fade;
        cycA = 1.0 - (1.0 - cycA) * (1.0 - a);           // screen within the cycle
    }
    // Head position, if the head currently lies on this segment
    if (headFound < 0.5 && headDist >= distA && headDist < distA + segLen) {
        headPos = A + AB * ((headDist - distA) / max(segLen, 1e-9));
        headFound = 1.0;
    }
}

// Returns vec2(trail alpha, head glow). Each lightcycle endlessly laps a fixed
// closed rectilinear circuit; the head advances along it, leaving a trail that
// stays put and fades out after 'trail_length'. Path geometry depends only on
// the cycle index, so the trail is laid down in place — only the head moves.
// Each cycle's alpha is screened internally; cycles are summed so crossing
// trails add/brighten instead of cutting each other out.
vec3 trailUI(vec2 p, float t) {
    vec3 emissive = vec3(0.0);
    float th = 0.006;
    int   nCyc = min(max(trail_count, 1), 5);
    float trailLen = max(trail_length, 0.02);
    float fadeLen = min(max(trail_fade, 0.0), trailLen);   // fade region <= trail

    for (int ci = 0; ci < 5; ci++) {
        if (ci >= nCyc) break;
        float cf = float(ci);

        // Hashed circuit dimensions — a notched-rectangle loop, all 90° turns
        vec2 hA = Hash22(vec2(cf * 2.13 + 1.7, cf * 3.71 + 0.9));
        vec2 hB = Hash22(vec2(cf * 1.31 + 4.2, cf * 2.07 + 2.3));
        float W1 = 0.25 + hA.x * 0.25;
        float H1 = 0.15 + hA.y * 0.15;
        float H2 = 0.10 + hB.x * 0.15;
        float W2 = 0.10 + hB.y * (W1 - 0.10) * 0.8;   // always < W1

        // Closed-loop vertices, centred on the origin
        vec2 ctr = vec2(W1 * 0.5, (H1 + H2) * 0.5);
        vec2 V0 = vec2(0.0,     0.0)     - ctr;
        vec2 V1 = vec2(W1,      0.0)     - ctr;
        vec2 V2 = vec2(W1,      H1)      - ctr;
        vec2 V3 = vec2(W1 - W2, H1)      - ctr;
        vec2 V4 = vec2(W1 - W2, H1 + H2) - ctr;
        vec2 V5 = vec2(0.0,     H1 + H2) - ctr;

        // Segment lengths and cumulative arc-length at each vertex
        float L0 = W1, L1 = H1, L2 = W2, L3 = H2, L4 = W1 - W2, L5 = H1 + H2;
        float c0 = 0.0;
        float c1 = c0 + L0;
        float c2 = c1 + L1;
        float c3 = c2 + L2;
        float c4 = c3 + L3;
        float c5 = c4 + L4;
        float total = c5 + L5;

        // Per-cycle placement, orientation, and travel direction
        float ang = floor(Hash11(cf * 7.0 + 0.5) * 4.0) * (PI * 0.5);
        vec2  cyclePos = (Hash22(vec2(cf * 5.5 + 3.3, cf * 4.4 + 6.6)) - 0.5) * vec2(0.6, 0.4);
        float tdir = Hash11(cf * 9.0 + 1.1) > 0.5 ? 1.0 : -1.0;
        vec2  ql = Rot(-ang) * (p - cyclePos);

        // Head advances at constant linear speed and loops; cycles desynced
        float headDist = mod(t * 0.4 * tdir + cf * 13.0, total);

        float cycA = 0.0;
        vec2  headPos = vec2(0.0);
        float headFound = 0.0;
        trailSeg(ql, V0, V1, c0, L0, headDist, total, tdir, trailLen, fadeLen, th, cycA, headPos, headFound);
        trailSeg(ql, V1, V2, c1, L1, headDist, total, tdir, trailLen, fadeLen, th, cycA, headPos, headFound);
        trailSeg(ql, V2, V3, c2, L2, headDist, total, tdir, trailLen, fadeLen, th, cycA, headPos, headFound);
        trailSeg(ql, V3, V4, c3, L3, headDist, total, tdir, trailLen, fadeLen, th, cycA, headPos, headFound);
        trailSeg(ql, V4, V5, c4, L4, headDist, total, tdir, trailLen, fadeLen, th, cycA, headPos, headFound);
        trailSeg(ql, V5, V0, c5, L5, headDist, total, tdir, trailLen, fadeLen, th, cycA, headPos, headFound);

        // Per-cycle colour from individual pickers (base Colour if disabled)
        vec3 picked = trail_col1;
        if      (ci == 1) picked = trail_col2;
        else if (ci == 2) picked = trail_col3;
        else if (ci == 3) picked = trail_col4;
        else if (ci == 4) picked = trail_col5;
        vec3 cycleColor = trail_multicolor ? picked : trail_color;
        emissive += cycleColor * cycA;   // add across cycles so crossings brighten

        if (headFound > 0.5) {
            float hd = length(ql - headPos);
            float hg = exp(-(hd * hd) / (0.022 * 0.022));
            emissive += mix(cycleColor, vec3(1.0), 0.6) * hg;   // hot head core
        }
    }

    return emissive;
}

// ===========================================================================
// Main
// ===========================================================================
void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv = (gl_FragCoord.xy - 0.5 * res) / res.y;
    aa = 1.5 / res.y;

    gTime = adsk_time / 25.0 * time_scale + time_offset;

    vec3 col = vec3(0.0);

    // --- Radar ---
    if (radar_enable) {
        vec2 p = uv - vec2(radar_pos_x, radar_pos_y);
        p *= Rot(radians(radar_rot));
        p /= radar_scale;
        float lt = gTime * radar_speed + radar_time_offset;
        float d = radarUI(p, lt);
        col = mix(col, radar_color, ov_alpha(d, radar_glow) * radar_opacity);
    }

    // --- Reticle ---
    if (reticle_enable) {
        vec2 p = uv - vec2(reticle_pos_x, reticle_pos_y);
        p *= Rot(radians(reticle_rot));
        p /= reticle_scale;
        float lt = gTime * reticle_speed + reticle_time_offset;
        float d = reticleUI(p, lt);
        col = mix(col, reticle_color, ov_alpha(d, reticle_glow) * reticle_opacity);
    }

    // --- Oscilloscope ---
    if (oscope_enable) {
        vec2 p = uv - vec2(oscope_pos_x, oscope_pos_y);
        p *= Rot(radians(oscope_rot));
        p /= oscope_scale;
        float lt  = gTime * oscope_speed  + oscope_time_offset;
        float lt2 = gTime * oscope_speed2 + oscope_time_offset;
        float d = oscopeUI(p, lt, lt2);
        col = mix(col, oscope_color, ov_alpha(d, oscope_glow) * oscope_opacity);
    }

    // --- Bar Meters ---
    if (bars_enable) {
        vec2 p = uv - vec2(bars_pos_x, bars_pos_y);
        p *= Rot(radians(bars_rot));
        p /= bars_scale;
        float lt = gTime * bars_speed + bars_time_offset;
        float d = barsUI(p, lt);
        col = mix(col, bars_color, ov_alpha(d, bars_glow) * bars_opacity);
    }

    // --- Data Terminal ---
    if (terminal_enable) {
        vec2 p = uv - vec2(terminal_pos_x, terminal_pos_y);
        p *= Rot(radians(terminal_rot));
        p /= terminal_scale;
        float lt = gTime * terminal_speed + terminal_time_offset;
        float d = terminalUI(p, lt);
        col = mix(col, terminal_color, ov_alpha(d, terminal_glow) * terminal_opacity);
    }

    // --- Perspective Grid ---
    if (pgrid_enable) {
        vec2 p = uv - vec2(pgrid_pos_x, pgrid_pos_y);
        p *= Rot(radians(pgrid_rot));
        p /= pgrid_scale;
        float lt = gTime * pgrid_speed + pgrid_time_offset;
        float d = pgridUI(p, lt);
        col = mix(col, pgrid_color, ov_alpha(d, pgrid_glow) * pgrid_opacity);
    }

    // --- Circuit Trace ---
    if (circuit_enable) {
        vec2 p = uv - vec2(circuit_pos_x, circuit_pos_y);
        p *= Rot(radians(circuit_rot));
        p /= circuit_scale;
        float lt = gTime * circuit_speed + circuit_time_offset;
        vec2 cr = circuitUI(p, lt);
        col = mix(col, circuit_color, ov_alpha(cr.x, circuit_glow) * circuit_opacity);
        // Flowing energy pulses — additive, with a hot core so they pop
        vec3 hot = mix(circuit_color, vec3(1.0), 0.5);
        col += hot * cr.y * circuit_opacity * circuit_pulse_bright;
    }

    // --- Corner Brackets ---
    if (brackets_enable) {
        vec2 p = uv - vec2(brackets_pos_x, brackets_pos_y);
        p *= Rot(radians(brackets_rot));
        p /= brackets_scale;
        float lt = gTime * brackets_speed + brackets_time_offset;
        vec2 br = bracketsUI(p, lt);
        col = mix(col, brackets_color, ov_alpha(br.x, brackets_glow) * brackets_opacity);
        // Scanner pulse — additive, with a hot core so it pops
        vec3 hotb = mix(brackets_color, vec3(1.0), 0.5);
        col += hotb * br.y * brackets_opacity * brackets_pulse_bright;
    }

    // --- Compass Tape ---
    if (compass_enable) {
        vec2 p = uv - vec2(compass_pos_x, compass_pos_y);
        p *= Rot(radians(compass_rot));
        p /= compass_scale;
        float lt = gTime * compass_speed + compass_time_offset;
        float d = compassUI(p, lt);
        col = mix(col, compass_color, ov_alpha(d, compass_glow) * compass_opacity);
    }

    // --- Trajectory Arc ---
    if (arc_enable) {
        vec2 p = uv - vec2(arc_pos_x, arc_pos_y);
        p *= Rot(radians(arc_rot));
        p /= arc_scale;
        float lt = gTime * arc_speed + arc_time_offset;
        float d = arcUI(p, lt);
        col = mix(col, arc_color, ov_alpha(d, arc_glow) * arc_opacity);
    }

    // --- Dial Gauge ---
    if (dial_enable) {
        vec2 p = uv - vec2(dial_pos_x, dial_pos_y);
        p *= Rot(radians(dial_rot));
        p /= dial_scale;
        float lt = gTime * dial_speed + dial_time_offset;
        float d = dialUI(p, lt);
        col = mix(col, dial_color, ov_alpha(d, dial_glow) * dial_opacity);
    }

    // --- Light Grid ---
    if (lgrid_enable) {
        vec2 p = uv - vec2(lgrid_pos_x, lgrid_pos_y);
        p *= Rot(radians(lgrid_rot));
        p /= lgrid_scale;
        float lt = gTime * lgrid_speed + lgrid_time_offset;
        vec2 lg = lgridUI(p, lt);
        col = mix(col, lgrid_color, ov_alpha(lg.x, lgrid_glow) * lgrid_opacity);
        // Pulsing nodes — additive, with a hot core so they pop
        vec3 hotg = mix(lgrid_color, vec3(1.0), 0.5);
        col += hotg * lg.y * lgrid_opacity * lgrid_pulse_bright;
    }

    // --- Light Trail ---
    if (trail_enable) {
        vec2 p = uv - vec2(trail_pos_x, trail_pos_y);
        p *= Rot(radians(trail_rot));
        p /= trail_scale;
        float lt = gTime * trail_speed + trail_time_offset;
        // Per-cycle coloured trails, additive so crossings add/brighten
        col += trailUI(p, lt) * trail_opacity;
    }

    gl_FragColor = vec4(col, 1.0);
}
