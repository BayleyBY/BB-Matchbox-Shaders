// BB_FutureHUD
// Animated sci-fi HUD overlay for Autodesk Flame 2026.
//
// Based on "Future HUD" (Shadertoy) – original author unknown.
// Flame port: entry point, uniforms, time source, and camera adapted for Matchbox.
// Camera locked to screen. All major elements individually enabled/disabled.

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_time;

// Render
uniform float time_scale;
uniform float time_offset;

// Rings
uniform int   rings_enable;
uniform float ring_glow;
uniform float ring_speed;
uniform float rings_opacity;
uniform float ring_depth;        // ring cross-section half-thickness

// Camera orbit
uniform float cam_tilt;         // YZ plane tilt in degrees — lifts camera above ring plane
uniform float cam_orbit_base;   // XZ base angle in degrees
uniform float cam_orbit_speed;  // XZ sine swing speed
uniform float cam_orbit_amount; // XZ sine swing amplitude in degrees
uniform int   ring0_enable;
uniform float ring0_depth;
uniform vec3  ring0_color;
uniform float ring0_opacity;
uniform float ring0_speed;
uniform int   ring1_enable;
uniform float ring1_depth;
uniform vec3  ring1_color;
uniform float ring1_opacity;
uniform float ring1_speed;
uniform int   ring2_enable;
uniform float ring2_depth;
uniform vec3  ring2_color;
uniform float ring2_opacity;
uniform float ring2_speed;
uniform int   ring3_enable;
uniform float ring3_depth;
uniform vec3  ring3_color;
uniform float ring3_opacity;
uniform float ring3_speed;
uniform int   ring4_enable;
uniform float ring4_depth;
uniform vec3  ring4_color;
uniform float ring4_opacity;
uniform float ring4_speed;
uniform int   ring5_enable;
uniform float ring5_depth;
uniform vec3  ring5_color;
uniform float ring5_opacity;
uniform float ring5_speed;
uniform int   ring6_enable;
uniform float ring6_depth;
uniform vec3  ring6_color;
uniform float ring6_opacity;
uniform float ring6_speed;
uniform int   ring7_enable;
uniform float ring7_depth;
uniform vec3  ring7_color;
uniform float ring7_opacity;
uniform float ring7_speed;

// Background
// Background — Dot Grid
uniform int   bg_dots_enable;
uniform vec3  bg_dots_color;
uniform float bg_dots_glow;
uniform float bg_dots_opacity;
uniform float bg_dots_speed;
uniform float bg_dots_time_offset;
uniform float bg_dots_scale;
uniform float bg_dots_pos_x;
uniform float bg_dots_pos_y;

// Background — Cross Grid
uniform int   bg_crosses_enable;
uniform vec3  bg_crosses_color;
uniform float bg_crosses_glow;
uniform float bg_crosses_opacity;
uniform float bg_crosses_speed;
uniform float bg_crosses_time_offset;
uniform float bg_crosses_scale;
uniform float bg_crosses_pos_x;
uniform float bg_crosses_pos_y;

// Background — Box Grid
uniform int   bg_boxes_enable;
uniform vec3  bg_boxes_color;
uniform float bg_boxes_glow;
uniform float bg_boxes_opacity;
uniform float bg_boxes_speed;
uniform float bg_boxes_time_offset;
uniform int   bg_boxes_cols;
uniform int   bg_boxes_rows;
uniform float bg_boxes_gap;
uniform float bg_boxes_scale;
uniform float bg_boxes_pos_x;
uniform float bg_boxes_pos_y;

// Overlay — per-element controls
uniform int   ov_numbers_enable;
uniform vec3  ov_numbers_color;
uniform float ov_numbers_glow;
uniform float ov_numbers_opacity;
uniform float ov_numbers_speed;
uniform float ov_numbers_scale;
uniform float ov_numbers_rot;
uniform float ov_numbers_pos_x;
uniform float ov_numbers_pos_y;
uniform float ov_numbers_time_offset;

uniform int   ov_blocks0_enable;
uniform vec3  ov_blocks0_color;
uniform float ov_blocks0_glow;
uniform float ov_blocks0_opacity;
uniform float ov_blocks0_speed;
uniform float ov_blocks0_time_offset;
uniform float ov_blocks0_scale;
uniform float ov_blocks0_rot;
uniform float ov_blocks0_pos_x;
uniform float ov_blocks0_pos_y;

uniform int   ov_blocks1_enable;
uniform vec3  ov_blocks1_color;
uniform float ov_blocks1_glow;
uniform float ov_blocks1_opacity;
uniform float ov_blocks1_speed;
uniform float ov_blocks1_time_offset;
uniform float ov_blocks1_scale;
uniform float ov_blocks1_rot;
uniform float ov_blocks1_pos_x;
uniform float ov_blocks1_pos_y;

uniform int   ov_arrows0_enable;
uniform vec3  ov_arrows0_color;
uniform float ov_arrows0_glow;
uniform float ov_arrows0_opacity;
uniform float ov_arrows0_speed;
uniform float ov_arrows0_time_offset;
uniform float ov_arrows0_scale;
uniform float ov_arrows0_rot;
uniform float ov_arrows0_pos_x;
uniform float ov_arrows0_pos_y;
uniform int   ov_arrows1_enable;
uniform vec3  ov_arrows1_color;
uniform float ov_arrows1_glow;
uniform float ov_arrows1_opacity;
uniform float ov_arrows1_speed;
uniform float ov_arrows1_time_offset;
uniform float ov_arrows1_scale;
uniform float ov_arrows1_rot;
uniform float ov_arrows1_pos_x;
uniform float ov_arrows1_pos_y;

uniform int   ov_graph0_enable;
uniform vec3  ov_graph0_color;
uniform float ov_graph0_glow;
uniform float ov_graph0_opacity;
uniform float ov_graph0_speed;
uniform float ov_graph0_bounce_speed;
uniform float ov_graph0_time_offset;
uniform float ov_graph0_scale;
uniform float ov_graph0_rot;
uniform float ov_graph0_pos_x;
uniform float ov_graph0_pos_y;
uniform int   ov_graph1_enable;
uniform vec3  ov_graph1_color;
uniform float ov_graph1_glow;
uniform float ov_graph1_opacity;
uniform float ov_graph1_speed;
uniform float ov_graph1_bounce_speed;
uniform float ov_graph1_time_offset;
uniform float ov_graph1_scale;
uniform float ov_graph1_rot;
uniform float ov_graph1_pos_x;
uniform float ov_graph1_pos_y;

uniform int   ov_circles0_enable;
uniform vec3  ov_circles0_color;
uniform float ov_circles0_glow;
uniform float ov_circles0_opacity;
uniform float ov_circles0_speed;
uniform float ov_circles0_time_offset;
uniform int   ov_circles0_number;
uniform float ov_circles0_scale;
uniform float ov_circles0_rot;
uniform float ov_circles0_pos_x;
uniform float ov_circles0_pos_y;

uniform int   ov_circles1_enable;
uniform vec3  ov_circles1_color;
uniform float ov_circles1_glow;
uniform float ov_circles1_opacity;
uniform float ov_circles1_speed;
uniform float ov_circles1_time_offset;
uniform int   ov_circles1_number;
uniform float ov_circles1_scale;
uniform float ov_circles1_rot;
uniform float ov_circles1_pos_x;
uniform float ov_circles1_pos_y;

uniform int   ov_rect_enable;
uniform vec3  ov_rect_color;
uniform float ov_rect_glow;
uniform float ov_rect_opacity;
uniform float ov_rect_speed;
uniform float ov_rect_time_offset;
uniform float ov_rect_inner_speed;
uniform float ov_rect_pulse_speed;
uniform float ov_rect_arrow_size;
uniform float ov_rect_scale;
uniform float ov_rect_rot;
uniform float ov_rect_pos_x;
uniform float ov_rect_pos_y;

uniform int   ov_static_enable;
uniform int   ov_static_mirror;
uniform vec3  ov_static_color;
uniform float ov_static_glow;
uniform float ov_static_opacity;
uniform int   ov_static_number;
uniform float ov_static_scale;
uniform float ov_static_rot;
uniform float ov_static_pos_x;
uniform float ov_static_pos_y;

uniform int   ov_side_enable;
uniform vec3  ov_side_color;
uniform float ov_side_glow;
uniform float ov_side_opacity;
uniform int   ov_side_number;
uniform float ov_side_scale;
uniform float ov_side_rot;
uniform float ov_side_pos_x;
uniform float ov_side_pos_y;

// Global computed time — set once in main(), read by all functions
float gTime;
float gRingTime;
float gOvTime;        // per-element overlay time — scroll/animation, set before each element
float gOvBounceTime;  // waveform bounce time — set independently of scroll

// ----------------------------------------------------------------
// Macros
// ----------------------------------------------------------------

#define MAX_STEPS 64
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(adsk_result_h,adsk_result_w)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define Tri(p,s,a) max(-dot(p,vec2(cos(-a),sin(-a))),max(dot(p,vec2(cos(a),sin(a))),max(abs(p).x-s.x,abs(p).y-s.y)))
#define DF(a,b) length(a)*cos(mod(atan(a.y,a.x)+6.28/(b*8.0),6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0)+vec2(0,11))
#define SkewX(a) mat2(1.0,tan(a),0.0,1.0)
#define seg_0 0
#define seg_1 1
#define seg_2 2
#define seg_3 3
#define seg_4 4
#define seg_5 5
#define seg_6 6
#define seg_7 7
#define seg_8 8
#define seg_9 9
#define seg_DP 39

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

float Hash21(vec2 p) {
    p = fract(p * vec2(234.56, 789.34));
    p += dot(p, p + 34.56);
    return fract(p.x + p.y);
}

float cubicInOut(float t) {
    return t < 0.5 ? 4.0*t*t*t : 0.5*pow(2.0*t - 2.0, 3.0) + 1.0;
}

float getTime(float t, float duration) {
    return clamp(t, 0.0, duration) / duration;
}

// ----------------------------------------------------------------
// Segment font (no time references)
// ----------------------------------------------------------------

float segBase(vec2 p) {
    vec2 prevP = p;
    float padding = 0.05;
    float w = padding * 3.0;
    float h = padding * 5.0;
    p = mod(p, 0.05) - 0.025;
    float gridMask = min(abs(p.x) - 0.005, abs(p.y) - 0.005);
    p = prevP;
    float d = B(p, vec2(w * 0.5, h * 0.5));
    float a = radians(45.0);
    p.x = abs(p.x) - 0.1;
    p.y = abs(p.y) - 0.05;
    float d2 = dot(p, vec2(cos(a), sin(a)));
    d = max(d2, d);
    d = max(-gridMask, d);
    return d;
}

float seg0(vec2 p) { float d=segBase(p); float s=0.03; float m=B(p,vec2(s,s*2.7)); return max(-m,d); }
float seg1(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.x+=s; p.y+=s; float m=B(p,vec2(s*2.,s*3.7)); d=max(-m,d); p=q; p.x+=s*1.8; p.y-=s*3.5; m=B(p,vec2(s)); return max(-m,d); }
float seg2(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.x+=s; p.y-=0.05; float m=B(p,vec2(s*2.,s)); d=max(-m,d); p=q; p.x-=s; p.y+=0.05; m=B(p,vec2(s*2.,s)); return max(-m,d); }
float seg3(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.y=abs(p.y); p.x+=s; p.y-=0.05; float m=B(p,vec2(s*2.,s)); d=max(-m,d); p=q; p.x+=0.05; m=B(p,vec2(s,s)); return max(-m,d); }
float seg4(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.x+=s; p.y+=0.08; float m=B(p,vec2(s*2.,s*2.)); d=max(-m,d); p=q; p.y-=0.08; m=B(p,vec2(s,s*2.)); return max(-m,d); }
float seg5(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.x-=s; p.y-=0.05; float m=B(p,vec2(s*2.,s)); d=max(-m,d); p=q; p.x+=s; p.y+=0.05; m=B(p,vec2(s*2.,s)); return max(-m,d); }
float seg6(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.x-=s; p.y-=0.05; float m=B(p,vec2(s*2.,s)); d=max(-m,d); p=q; p.y+=0.05; m=B(p,vec2(s,s)); return max(-m,d); }
float seg7(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.x+=s; p.y+=s; float m=B(p,vec2(s*2.,s*3.7)); return max(-m,d); }
float seg8(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.y=abs(p.y); p.y-=0.05; float m=B(p,vec2(s,s)); return max(-m,d); }
float seg9(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.03; p.y-=0.05; float m=B(p,vec2(s,s)); d=max(-m,d); p=q; p.x+=s; p.y+=0.05; m=B(p,vec2(s*2.,s)); return max(-m,d); }
float segDecimalPoint(vec2 p) { vec2 q=p; float d=segBase(p); float s=0.028; p.y+=0.1; float m=B(p,vec2(s,s)); return max(m,d); }

float drawFont(vec2 p, int c) {
    p *= 2.0;
    float d = 10.0;
    if      (c == seg_0)  d = seg0(p);
    else if (c == seg_1)  d = seg1(p);
    else if (c == seg_2)  d = seg2(p);
    else if (c == seg_3)  d = seg3(p);
    else if (c == seg_4)  d = seg4(p);
    else if (c == seg_5)  d = seg5(p);
    else if (c == seg_6)  d = seg6(p);
    else if (c == seg_7)  d = seg7(p);
    else if (c == seg_8)  d = seg8(p);
    else if (c == seg_9)  d = seg9(p);
    else if (c == seg_DP) d = segDecimalPoint(p);
    return d;
}

// ----------------------------------------------------------------
// Rings — all time references use gRingTime
// ----------------------------------------------------------------

float ring0(vec2 p) {
    vec2 prevP = p;
    p *= Rot(radians(-gRingTime*30.+50.));
    p = DF(p, 16.0);
    p -= vec2(0.35);
    float d = B(p * Rot(radians(45.0)), vec2(0.005, 0.03));
    p = prevP;
    p *= Rot(radians(-gRingTime*30.+50.));
    float deg = 165.0;
    float a = radians(deg);
    d = max(dot(p, vec2(cos(a), sin(a))), d);
    a = radians(-deg);
    d = max(dot(p, vec2(cos(a), sin(a))), d);
    p = prevP;
    p *= Rot(radians(gRingTime*30.+30.));
    float d2 = abs(length(p) - 0.55) - 0.015;
    d2 = max(-(abs(p.x) - 0.4), d2);
    d = min(d, d2);
    p = prevP;
    d2 = abs(length(p) - 0.55) - 0.001;
    d = min(d, d2);
    p = prevP;
    p *= Rot(radians(-gRingTime*50.+30.));
    p += sin(p*25. - radians(gRingTime*80.)) * 0.01;
    d2 = abs(length(p) - 0.65) - 0.0001;
    d = min(d, d2);
    p = prevP;
    a = radians(-sin(gRingTime*1.2)) * 120.0;
    a += radians(-70.0);
    p.x += cos(a)*0.58;
    p.y += sin(a)*0.58;
    d2 = abs(Tri(p*Rot(-a)*Rot(radians(90.0)), vec2(0.03), radians(45.))) - 0.003;
    d = min(d, d2);
    p = prevP;
    a = radians(sin(gRingTime*1.3)) * 100.0;
    a += radians(-10.0);
    p.x += cos(a)*0.58;
    p.y += sin(a)*0.58;
    d2 = abs(Tri(p*Rot(-a)*Rot(radians(90.0)), vec2(0.03), radians(45.))) - 0.003;
    d = min(d, d2);
    return d;
}

float ring1(vec2 p) {
    vec2 prevP = p;
    float size = 0.45; float deg = 140.0; float thickness = 0.02;
    float d = abs(length(p) - size) - thickness;
    p *= Rot(radians(gRingTime*60.));
    float a = radians(deg);
    d = max(dot(p, vec2(cos(a), sin(a))), d);
    a = radians(-deg);
    d = max(dot(p, vec2(cos(a), sin(a))), d);
    p = prevP;
    float d2 = abs(length(p) - size) - 0.001;
    return min(d, d2);
}

float ring2(vec2 p) {
    float size = 0.3; float deg = 120.0; float thickness = 0.02;
    p *= Rot(-radians(gRingTime * 60.));
    float d = abs(length(p) - size) - thickness;
    float a = radians(-deg);
    d = max(dot(p, vec2(cos(a), sin(a))), d);
    a = radians(deg);
    d = max(dot(p, vec2(cos(a), sin(a))), d);
    float d2 = abs(length(p) - size) - thickness;
    a = radians(-deg);
    d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    a = radians(deg);
    d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    return min(d, d2);
}

float ring3(vec2 p) {
    p *= Rot(radians(-gRingTime*80. - 120.));
    vec2 prevP = p; float deg = 140.0;
    p = DF(p, 6.0); p -= vec2(0.3);
    float d = abs(B(p*Rot(radians(45.0)), vec2(0.03, 0.025))) - 0.003;
    p = prevP;
    float a = radians(-deg); d = max(dot(p, vec2(cos(a), sin(a))), d);
    a = radians(deg);        d = max(dot(p, vec2(cos(a), sin(a))), d);
    p = prevP;
    p = DF(p, 6.0); p -= vec2(0.3);
    float d2 = abs(B(p*Rot(radians(45.0)), vec2(0.03, 0.025))) - 0.003;
    p = prevP;
    a = radians(-deg); d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    a = radians(deg);  d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    return min(d, d2);
}

float ring4(vec2 p) {
    p *= Rot(radians(gRingTime*75. - 220.));
    vec2 prevP = p; float deg = 20.0;
    float d = abs(length(p) - 0.25) - 0.01;
    p = DF(p, 2.0); p -= vec2(0.1);
    float a = radians(-deg); d = max(-dot(p, vec2(cos(a), sin(a))), d);
    a = radians(deg);        d = max(-dot(p, vec2(cos(a), sin(a))), d);
    return d;
}

float ring5(vec2 p) {
    p *= Rot(radians(-gRingTime*70. + 170.));
    vec2 prevP = p; float deg = 150.0;
    float d = abs(length(p) - 0.16) - 0.02;
    float a = radians(-deg); d = max(dot(p, vec2(cos(a), sin(a))), d);
    a = radians(deg);        d = max(dot(p, vec2(cos(a), sin(a))), d);
    p = prevP;
    p *= Rot(radians(-30.));
    float d2 = abs(length(p) - 0.136) - 0.02;
    deg = 60.0;
    a = radians(-deg); d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    a = radians(deg);  d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    return min(d, d2);
}

float ring6(vec2 p) {
    vec2 prevP = p;
    p *= Rot(radians(gRingTime*72. + 110.));
    float d = abs(length(p) - 0.95) - 0.001;
    d = max(-(abs(p.x) - 0.4), d);
    d = max(-(abs(p.y) - 0.4), d);
    p = prevP;
    p *= Rot(radians(-gRingTime*30. + 50.));
    p = DF(p, 16.0); p -= vec2(0.6);
    float d2 = B(p*Rot(radians(45.0)), vec2(0.02, 0.03));
    p = prevP;
    p *= Rot(radians(-gRingTime*30. + 50.));
    float deg = 155.0;
    float a = radians(deg);
    d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    a = radians(-deg);
    d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    return min(d, d2);
}

float ring7(vec2 p) {
    vec2 prevP = p;
    float r = 0.75;

    // Thin continuous base circle
    float d = abs(length(p) - r) - 0.001;

    // 8 radial ticks rotating clockwise — compass bezel
    p *= Rot(radians(gRingTime * 52.));
    vec2 q = DF(p, 2.0);
    q -= vec2(r, 0.0);
    float d2 = B(q, vec2(0.005, 0.022));
    d = min(d, d2);

    // 12-segment dashed inner ring counter-rotating
    p = prevP;
    p *= Rot(radians(-gRingTime * 35.));
    float ang = mod(atan(p.y, p.x), 6.28318);
    float dash = abs(mod(ang * 12.0 / 6.28318, 1.0) - 0.5) - 0.3;
    float d3 = abs(length(p) - (r - 0.06)) - 0.003;
    d = min(d, max(d3, dash));

    return d;
}

// ----------------------------------------------------------------
// Scene SDF — single-ring variant; n selects which ring (0-7)
// Rings are spaced 0.2 apart in Z starting at +0.7
// ----------------------------------------------------------------

float GetDistRing(vec3 p, int n) {
    p.z += 0.7 - float(n) * 0.2;
    float thick = ring_depth * 0.012;
    float baseTime = gTime * ring_speed;
    if      (n == 0) { gRingTime = baseTime * ring0_speed; thick *= ring0_depth; return max(abs(p.z) - thick, ring0(p.xy)); }
    else if (n == 1) { gRingTime = baseTime * ring1_speed; thick *= ring1_depth; return max(abs(p.z) - thick, ring1(p.xy)); }
    else if (n == 2) { gRingTime = baseTime * ring2_speed; thick *= ring2_depth; return max(abs(p.z) - thick, ring2(p.xy)); }
    else if (n == 3) { gRingTime = baseTime * ring3_speed; thick *= ring3_depth; return max(abs(p.z) - thick, ring3(p.xy)); }
    else if (n == 4) { gRingTime = baseTime * ring4_speed; thick *= ring4_depth; return max(abs(p.z) - thick, ring4(p.xy)); }
    else if (n == 5) { gRingTime = baseTime * ring5_speed; thick *= ring5_depth; return max(abs(p.z) - thick, ring5(p.xy)); }
    else if (n == 6) { gRingTime = baseTime * ring6_speed; thick *= ring6_depth; return max(abs(p.z) - thick, ring6(p.xy)); }
    else             { gRingTime = baseTime * ring7_speed; thick *= ring7_depth; return max(abs(p.z) - thick, ring7(p.xy)); }
}

// ----------------------------------------------------------------
// Raymarcher — marches a single ring; called once per enabled ring
// ----------------------------------------------------------------

vec3 RayMarch(vec3 ro, vec3 rd, int ringIdx) {
    float steps = 0.0;
    float alpha = 0.0;
    float t = 0.0;
    float tmax = 5.0;

    for (float i = 0.0; i < float(MAX_STEPS); i++) {
        steps = i;
        vec3 p = ro + rd * t;
        float d = GetDistRing(p, ringIdx);
        if (t > tmax) break;
        alpha += 1.0 - smoothstep(0.0, ring_glow * 0.005, d);
        t += max(0.0001, abs(d) * 0.6);
    }
    alpha /= max(steps, 1.0);
    return alpha * vec3(1.5);
}

// ----------------------------------------------------------------
// Camera
// ----------------------------------------------------------------

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p);
    vec3 r = normalize(cross(vec3(0, 1, 0), f));
    vec3 u = cross(f, r);
    vec3 c = p + f * z;
    vec3 i = c + uv.x * r + uv.y * u;
    return normalize(i - p);
}

// ----------------------------------------------------------------
// Background elements — three independent tiling layers
// ----------------------------------------------------------------

// Tiny square dot grid — dense, no rotation
float bgDots(vec2 p) {
    float bt = gTime * bg_dots_speed + bg_dots_time_offset;
    p.y -= bt * 0.1;
    p += vec2(bg_dots_pos_x, bg_dots_pos_y);
    p *= bg_dots_scale;
    p = mod(p, 0.02) - 0.01;
    return B(p, vec2(0.001));
}

// Small cross grid — scrolling, denser tiling
float bgCrosses(vec2 p) {
    float bt = gTime * bg_crosses_speed + bg_crosses_time_offset;
    p.y -= bt * 0.1;
    p += vec2(bg_crosses_pos_x, bg_crosses_pos_y);
    p *= 2.8 * bg_crosses_scale;
    vec2 gv2 = fract(p * 3.) - 0.5;
    return min(B(gv2, vec2(0.02, 0.09)), B(gv2, vec2(0.09, 0.02)));
}

// Rotating square frame grid — N columns x M rows, centered in frame, random CW/CCW per cell
float bgBoxes(vec2 p) {
    float bt = gTime * bg_boxes_speed + bg_boxes_time_offset;
    p.y -= bt * 0.1;
    p += vec2(bg_boxes_pos_x, bg_boxes_pos_y);
    float aspect = adsk_result_w / adsk_result_h;
    p.x *= float(bg_boxes_cols) / (aspect * bg_boxes_scale);
    p.y *= float(bg_boxes_rows) / bg_boxes_scale;
    vec2 gv = fract(p) - 0.5;
    vec2 id = floor(p);
    float n = Hash21(id);
    float hs = clamp(0.5 - bg_boxes_gap, 0.02, 0.49);
    float cut = hs * 0.318;
    float d = abs(B(gv, vec2(hs))) - 0.015;
    if (n < 0.5) {
        gv *= Rot(radians(bt * 60.));
    } else {
        gv *= Rot(radians(-bt * 60.));
    }
    d = max(-(abs(gv.x) - cut), d);
    d = max(-(abs(gv.y) - cut), d);
    return d;
}

// ----------------------------------------------------------------
// Overlay elements — all time references use gTime
// ----------------------------------------------------------------

float numberWithCIrcleUI(vec2 p) {
    vec2 prevP = p;
    p *= SkewX(radians(-15.0));

    // Stopwatch display: AB.CD
    // A = tens of seconds (slowest), B = ones, C = tenths, D = hundredths (fastest)
    // Each digit is 10x the adjacent — digits carry over naturally like a real counter.
    // gOvTime is already signed by speed: positive = count up, negative = count down.
    float t = gOvTime + ov_numbers_time_offset;
    int dTens       = int(mod(t * 0.1,   10.0));
    int dOnes       = int(mod(t,         10.0));
    int dTenths     = int(mod(t * 10.0,  10.0));
    int dHundredths = int(mod(t * 100.0, 10.0));

    float d  = drawFont(p - vec2(-0.16, 0.0), dTens);
    float d2 = drawFont(p - vec2(-0.08, 0.0), dOnes);
    d = min(d, d2);
    d2 = drawFont(p - vec2(-0.02, 0.0), seg_DP);
    d = min(d, d2);
    p *= 1.5;
    d2 = drawFont(p - vec2(0.04, -0.03), dTenths);
    d = min(d, d2);
    d2 = drawFont(p - vec2(0.12, -0.03), dHundredths);
    d = abs(min(d, d2)) - 0.002;
    p = prevP;
    p.x -= 0.07;
    p *= Rot(radians(-gOvTime * 50.));
    p = DF(p, 4.0);
    p -= vec2(0.085);
    d2 = B(p * Rot(radians(45.0)), vec2(0.015, 0.018));
    p = prevP;
    d2 = max(-B(p, vec2(0.13, 0.07)), d2);
    d = min(d, abs(d2) - 0.0005);
    return d;
}

float blockUI(vec2 p) {
    // 3 rows via Y mod: centers at p.y = -0.04, 0, +0.04
    float py = mod(p.y + 0.06, 0.04) - 0.02;

    // Two interleaved X-scrolling layers — combined give 20 cols within ±0.2
    float phase = gOvTime * 0.05;
    float px1 = mod(p.x + phase,        0.04) - 0.02;
    float px2 = mod(p.x + phase + 0.02, 0.04) - 0.02;
    float d  = min(B(vec2(px1, py), vec2(0.0085)),
                   B(vec2(px2, py), vec2(0.0085)));

    // Clip to 20 cols × 3 rows  (±0.2 × ±0.06)
    d = max(d, abs(p.x) - 0.2);
    d = max(d, abs(p.y) - 0.06);
    return abs(d) - 0.0002;
}

float smallCircleUI(vec2 p) {
    p *= 1.1;
    vec2 prevP = p;
    float deg = 20.0;
    p *= Rot(radians(sin(gOvTime * 3.) * 50.));
    float d = abs(length(p) - 0.1) - 0.003;
    p = DF(p, 0.75);
    p -= vec2(0.02);
    float a = radians(-deg); d = max(-dot(p, vec2(cos(a), sin(a))), d);
    a = radians(deg);        d = max(-dot(p, vec2(cos(a), sin(a))), d);
    p = prevP;
    p *= Rot(radians(-sin(gOvTime * 2.) * 80.));
    float d2 = abs(length(p) - 0.08) - 0.001;
    d2 = max(-p.x, d2);
    d = min(d, d2);
    p = prevP;
    p *= Rot(radians(-gOvTime * 50.));
    d2 = abs(length(p) - 0.05) - 0.015;
    deg = 170.0;
    a = radians(deg);  d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    a = radians(-deg); d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    d = min(d, abs(d2) - 0.0005);
    return d;
}

float smallCircleUI2(vec2 p) {
    vec2 prevP = p;
    float d  = abs(length(p) - 0.04) - 0.0001;
    float d2 = length(p) - 0.03;
    p *= Rot(radians(gOvTime * 30.));
    float deg = 140.0;
    float a = radians(deg);
    d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    a = radians(-deg);
    d2 = max(-dot(p, vec2(cos(a), sin(a))), d2);
    d = min(d, d2);
    d2 = length(p) - 0.03;
    a = radians(deg);
    d2 = max(dot(p, vec2(cos(a), sin(a))), d2);
    a = radians(-deg);
    d2 = max(dot(p, vec2(cos(a), sin(a))), d2);
    d = min(d, d2);
    d = max(-(length(p) - 0.02), d);
    return d;
}

float rectUI(vec2 p) {
    p *= Rot(radians(45.));
    vec2 prevP = p;
    float d = abs(B(p, vec2(0.12))) - 0.003;
    p *= Rot(radians(gOvTime * 60.));
    d = max(-(abs(p.x) - 0.05), d);
    d = max(-(abs(p.y) - 0.05), d);
    p = prevP;
    float d2 = abs(B(p, vec2(0.12))) - 0.0005;
    d = min(d, d2);
    d2 = abs(B(p, vec2(0.09))) - 0.003;
    p *= Rot(radians(-gOvTime * 50. * ov_rect_inner_speed));
    d2 = max(-(abs(p.x) - 0.03), d2);
    d2 = max(-(abs(p.y) - 0.03), d2);
    d = min(d, d2);
    p = prevP;
    d2 = abs(B(p, vec2(0.09))) - 0.0005;
    d = min(d, d2);
    p *= Rot(radians(-45.));
    p.y = abs(p.y) - 0.07 - sin(gOvTime * ov_rect_pulse_speed) * 0.01;
    d2 = Tri(p, vec2(ov_rect_arrow_size), radians(45.));
    d = min(d, d2);
    p = prevP;
    p *= Rot(radians(45.));
    p.y = abs(p.y) - 0.07 - sin(gOvTime * ov_rect_pulse_speed) * 0.01;
    d2 = Tri(p, vec2(ov_rect_arrow_size), radians(45.));
    d = min(d, d2);
    p = prevP;
    p *= Rot(radians(45.));
    d2 = abs(B(p, vec2(0.025))) - 0.0005;
    d2 = max(-(abs(p.x) - 0.01), d2);
    d2 = max(-(abs(p.y) - 0.01), d2);
    d = min(d, d2);
    return d;
}

float graphUI(vec2 p) {
    vec2 prevP = p;
    p.x += 0.5;
    p.y -= gOvTime * 0.25;        // scroll driven by gOvTime
    p *= vec2(1., 100.);
    vec2 gv = fract(p) - 0.5;
    vec2 id = floor(p);
    // Traveling waves: each bar's amplitude is a function of (time - position),
    // Two-timescale model: a slow gate creates active/silent periods per bar,
    // a fast oscillation produces spikes only when the gate is open.
    // Result: bursts of spikes separated by quiet pauses — voice/speech cadence.
    float h1 = fract(sin(id.y * 127.1)  * 43758.5453);
    float h2 = fract(sin(id.y * 311.7)  * 74236.1789);
    float h3 = fract(sin(id.y * 457.3)  * 31847.9321);
    // Gate: rectified sine — zero during the negative half, smooth bump during positive.
    // Power > 1 narrows each burst so more time is spent near zero (pauses).
    float gate = pow(max(sin(gOvBounceTime * 0.22 + h3 * 6.2832), 0.0), 2.0);
    // Fast oscillation at ~2-3x rate to get multiple spikes per burst.
    float wave1 = sin(gOvBounceTime * 2.3 + h1 * 6.2832);
    float wave2 = sin(gOvBounceTime * 1.7 + h2 * 6.2832) * 0.6;
    float amp = (wave1 + wave2) / 1.6 * gate;
    float w = pow(abs(amp), 0.4) * 0.055 + 0.003;  // sharp peaks, fast-attack character
    float d = B(gv, vec2(w, 0.45));       // tall bars with narrow gaps — spectrum feel
    p = prevP;
    d = max(abs(p.x) - 0.2, d);
    d = max(abs(p.y) - 0.2, d);
    return d;
}

float staticUI(vec2 p) {
    vec2 prevP = p;
    float d  = B(p, vec2(0.005, 0.13));
    p -= vec2(0.02, -0.147);
    p *= Rot(radians(-45.));
    float d2 = B(p, vec2(0.005, 0.028));
    d = min(d, d2);
    p = prevP;
    d2 = B(p - vec2(0.04, -0.2135), vec2(0.005, 0.049));
    d = min(d, d2);
    p -= vec2(0.02, -0.28);
    p *= Rot(radians(45.));
    d2 = B(p, vec2(0.005, 0.03));
    d = min(d, d2);
    p = prevP;
    d2 = length(p - vec2(0., 0.13)) - 0.012;
    d = min(d, d2);
    d2 = length(p - vec2(0., -0.3)) - 0.012;
    d = min(d, d2);
    return d;
}

float arrowUI(vec2 p) {
    vec2 prevP = p;
    p.x *= -1.;
    p.x -= gOvTime * 0.12;
    p.x = mod(p.x, 0.07) - 0.035;
    p.x -= 0.0325;
    p *= vec2(0.9, 1.5);
    p *= Rot(radians(90.));
    float d = Tri(p, vec2(0.05), radians(45.));
    d = max(-Tri(p - vec2(0., -0.03), vec2(0.05), radians(45.)), d);
    d = abs(d) - 0.0005;
    p = prevP;
    d = max(abs(p.x) - 0.15, d);
    return d;
}

float sideLine(vec2 p) {
    p.x *= -1.0;
    vec2 prevP = p;
    p.y = abs(p.y) - 0.17;
    p *= Rot(radians(45.));
    float d = B(p, vec2(0.035, 0.01));
    p = prevP;
    float d2 = B(p - vec2(0.0217, 0.), vec2(0.01, 0.152));
    d = min(d, d2);
    return abs(d) - 0.0005;
}

float sideUI(vec2 p) {
    vec2 prevP = p;
    p.x *= -1.;
    p.x += 0.025;
    float d = sideLine(p);
    p = prevP;
    p.y = abs(p.y) - 0.275;
    float d2 = sideLine(p);
    return min(d, d2);
}

// ----------------------------------------------------------------
// Per-element overlay compositing helper
// ----------------------------------------------------------------

float ov_alpha(float d, float glow) {
    float aa   = antialiasing(1.0);
    float edge = smoothstep(aa, -aa, d);                      // crisp AA edge at shape boundary
    float halo = exp(-max(d, 0.0) / max(glow * 0.005, 0.00001));  // exponential glow falloff (slider 0-10, scaled)
    return max(edge, halo);
}

// ----------------------------------------------------------------
// Main
// ----------------------------------------------------------------

void main() {
    gTime     = adsk_time / 25.0 * time_scale + time_offset;
    gRingTime = gTime * ring_speed;

    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv  = (gl_FragCoord.xy - 0.5 * res) / res.y;

    vec3 col = vec3(0.0);

    // Background — Dot Grid
    if (bg_dots_enable == 1) {
        float d = bgDots(uv);
        col = mix(col, bg_dots_color, ov_alpha(d, bg_dots_glow) * bg_dots_opacity);
    }

    // Background — Cross Grid
    if (bg_crosses_enable == 1) {
        float d = bgCrosses(uv);
        col = mix(col, bg_crosses_color, ov_alpha(d, bg_crosses_glow) * bg_crosses_opacity);
    }

    // Background — Box Grid
    if (bg_boxes_enable == 1) {
        float d = bgBoxes(uv);
        col = mix(col, bg_boxes_color, ov_alpha(d, bg_boxes_glow) * bg_boxes_opacity);
    }

    // Raymarched rings
    if (rings_enable == 1) {
        vec3 ro = vec3(0.0, 0.0, -2.1);
        ro.yz *= Rot(radians(cam_tilt));
        ro.y   = max(-0.9, ro.y);
        ro.xz *= Rot(radians(cam_orbit_base));
        ro.xy *= Rot(radians(sin(gTime * cam_orbit_speed) * cam_orbit_amount));
        vec3 rd = R(uv, ro, vec3(0.0, 0.0, 0.0), 1.0);
        // Each ring raymarched independently so it can carry its own colour and opacity.
        if (ring0_enable == 1) col += RayMarch(ro, rd, 0) * ring0_color * ring0_opacity * rings_opacity;
        if (ring1_enable == 1) col += RayMarch(ro, rd, 1) * ring1_color * ring1_opacity * rings_opacity;
        if (ring2_enable == 1) col += RayMarch(ro, rd, 2) * ring2_color * ring2_opacity * rings_opacity;
        if (ring3_enable == 1) col += RayMarch(ro, rd, 3) * ring3_color * ring3_opacity * rings_opacity;
        if (ring4_enable == 1) col += RayMarch(ro, rd, 4) * ring4_color * ring4_opacity * rings_opacity;
        if (ring5_enable == 1) col += RayMarch(ro, rd, 5) * ring5_color * ring5_opacity * rings_opacity;
        if (ring6_enable == 1) col += RayMarch(ro, rd, 6) * ring6_color * ring6_opacity * rings_opacity;
        if (ring7_enable == 1) col += RayMarch(ro, rd, 7) * ring7_color * ring7_opacity * rings_opacity;
    }

    // Gamma correction (pre-overlay, matching original)
    col = pow(col, vec3(0.9545));

    // Overlay — each element composited independently with its own time, color, glow.
    // Transform order: translate to element center → rotate → scale → call function.
    // For mirrored elements the fold happens first (before rotate/scale) so each
    // copy rotates and scales around its own center, not the screen center.
    vec2 p, q;
    float d;

    // Rolling numbers + orbital ring — natural center (0.56, -0.34)
    if (ov_numbers_enable == 1) {
        gOvTime = gTime * ov_numbers_speed;
        p = uv - vec2(ov_numbers_pos_x, ov_numbers_pos_y);
        p *= Rot(radians(ov_numbers_rot));
        p /= ov_numbers_scale;
        d = numberWithCIrcleUI(p) * ov_numbers_scale;
        col = mix(col, ov_numbers_color, ov_alpha(d, ov_numbers_glow) * ov_numbers_opacity);
    }

    // Scrolling block ticker — left set (blocks0) and right set (blocks1), each independent
    if (ov_blocks0_enable == 1) {
        gOvTime = gTime * ov_blocks0_speed + ov_blocks0_time_offset;
        p = uv - vec2(ov_blocks0_pos_x, ov_blocks0_pos_y);
        p *= Rot(radians(ov_blocks0_rot));
        p /= ov_blocks0_scale;
        d = blockUI(p) * ov_blocks0_scale;
        col = mix(col, ov_blocks0_color, ov_alpha(d, ov_blocks0_glow) * ov_blocks0_opacity);
    }
    if (ov_blocks1_enable == 1) {
        gOvTime = gTime * ov_blocks1_speed + ov_blocks1_time_offset;
        p = uv - vec2(ov_blocks1_pos_x, ov_blocks1_pos_y);
        p *= Rot(radians(ov_blocks1_rot));
        p /= ov_blocks1_scale;
        d = blockUI(p) * ov_blocks1_scale;
        col = mix(col, ov_blocks1_color, ov_alpha(d, ov_blocks1_glow) * ov_blocks1_opacity);
    }

    // Arrow ticker — left set (arrows0) and right set (arrows1), each independent
    if (ov_arrows0_enable == 1) {
        gOvTime = gTime * ov_arrows0_speed + ov_arrows0_time_offset;
        p = uv - vec2(ov_arrows0_pos_x, ov_arrows0_pos_y);
        p *= Rot(radians(ov_arrows0_rot));
        p /= ov_arrows0_scale;
        d = arrowUI(p) * ov_arrows0_scale;
        col = mix(col, ov_arrows0_color, ov_alpha(d, ov_arrows0_glow) * ov_arrows0_opacity);
    }
    if (ov_arrows1_enable == 1) {
        gOvTime = gTime * ov_arrows1_speed + ov_arrows1_time_offset;
        p = uv - vec2(ov_arrows1_pos_x, ov_arrows1_pos_y);
        p *= Rot(radians(ov_arrows1_rot));
        p /= ov_arrows1_scale;
        d = arrowUI(p) * ov_arrows1_scale;
        col = mix(col, ov_arrows1_color, ov_alpha(d, ov_arrows1_glow) * ov_arrows1_opacity);
    }

    // Waveform graph — left set (graph0) and right set (graph1), each independent
    if (ov_graph0_enable == 1) {
        gOvTime       = gTime * ov_graph0_speed        + ov_graph0_time_offset;
        gOvBounceTime = gTime * ov_graph0_bounce_speed + ov_graph0_time_offset;
        p = uv - vec2(ov_graph0_pos_x, ov_graph0_pos_y);
        p *= Rot(radians(ov_graph0_rot));
        p /= ov_graph0_scale;
        d = graphUI(p) * ov_graph0_scale;
        col = mix(col, ov_graph0_color, ov_alpha(d, ov_graph0_glow) * ov_graph0_opacity);
    }
    if (ov_graph1_enable == 1) {
        gOvTime       = gTime * ov_graph1_speed        + ov_graph1_time_offset;
        gOvBounceTime = gTime * ov_graph1_bounce_speed + ov_graph1_time_offset;
        p = uv - vec2(ov_graph1_pos_x, ov_graph1_pos_y);
        p *= Rot(radians(ov_graph1_rot));
        p /= ov_graph1_scale;
        d = graphUI(p) * ov_graph1_scale;
        col = mix(col, ov_graph1_color, ov_alpha(d, ov_graph1_glow) * ov_graph1_opacity);
    }

    // Circles 1 — arc/wedge style (smallCircleUI2), N random instances
    if (ov_circles0_enable == 1) {
        gOvTime = gTime * ov_circles0_speed + ov_circles0_time_offset;
        q = uv - vec2(ov_circles0_pos_x, ov_circles0_pos_y);
        q *= Rot(radians(ov_circles0_rot));
        q /= ov_circles0_scale;
        d = 1e9;
        for (int i = 0; i < ov_circles0_number; i++) {
            float fi = float(i);
            vec2 off = vec2(fract(sin(fi * 127.1) * 43758.5) * 2.0 - 1.0,
                            fract(sin(fi * 311.7) * 74236.2) * 2.0 - 1.0) * vec2(0.75, 0.42);
            p = q - off;
            d = min(d, smallCircleUI2(p));
        }
        d *= ov_circles0_scale;
        col = mix(col, ov_circles0_color, ov_alpha(d, ov_circles0_glow) * ov_circles0_opacity);
    }

    // Circles 2 — multi-ring complex style (smallCircleUI), N random instances
    if (ov_circles1_enable == 1) {
        gOvTime = gTime * ov_circles1_speed + ov_circles1_time_offset;
        q = uv - vec2(ov_circles1_pos_x, ov_circles1_pos_y);
        q *= Rot(radians(ov_circles1_rot));
        q /= ov_circles1_scale;
        d = 1e9;
        for (int i = 0; i < ov_circles1_number; i++) {
            float fi = float(i);
            vec2 off = vec2(fract(sin(fi * 457.3) * 31847.9) * 2.0 - 1.0,
                            fract(sin(fi * 183.3) * 62831.8) * 2.0 - 1.0) * vec2(0.75, 0.42);
            p = q - off;
            d = min(d, smallCircleUI(p));
        }
        d *= ov_circles1_scale;
        col = mix(col, ov_circles1_color, ov_alpha(d, ov_circles1_glow) * ov_circles1_opacity);
    }

    // Diamond frame — natural center (-0.58, -0.3)
    if (ov_rect_enable == 1) {
        gOvTime = gTime * ov_rect_speed + ov_rect_time_offset;
        p = uv - vec2(ov_rect_pos_x, ov_rect_pos_y);
        p *= Rot(radians(ov_rect_rot));
        p /= ov_rect_scale;
        d = rectUI(p) * ov_rect_scale;
        col = mix(col, ov_rect_color, ov_alpha(d, ov_rect_glow) * ov_rect_opacity);
    }

    // Static — antenna icon, cascade: copy N at pos*N, rot*N, scale^N
    if (ov_static_enable == 1) {
        d = 1e9;
        for (int i = 0; i < ov_static_number; i++) {
            float n  = float(i + 1);
            float sc = pow(max(ov_static_scale, 0.001), n);
            p = uv - vec2(ov_static_pos_x, ov_static_pos_y) * n;
            p *= Rot(radians(ov_static_rot * n));
            p /= sc;
            d = min(d, staticUI(p) * sc);
            if (ov_static_mirror == 1) {
                // Mirror cascade steps from original copy 1 position toward center:
                // n=1 → at +pos_x (same as original), n=2 → center, n=3 → −pos_x, etc.
                p = vec2(-uv.x, uv.y) - vec2(ov_static_pos_x * (n - 2.0), ov_static_pos_y * n);
                p *= Rot(radians(ov_static_rot * n));
                p /= sc;
                d = min(d, staticUI(p) * sc);
            }
        }
        col = mix(col, ov_static_color, ov_alpha(d, ov_static_glow) * ov_static_opacity);
    }

    // Side brackets — each cascade copy is a mirrored group of 3 (both sides), pos*N, rot*N, scale^N
    if (ov_side_enable == 1) {
        d = 1e9;
        for (int i = 0; i < ov_side_number; i++) {
            float n  = float(i + 1);
            float sc = pow(max(ov_side_scale, 0.001), n);
            p = uv - vec2(ov_side_pos_x, ov_side_pos_y) * n;
            p.x = abs(p.x) - 0.82;
            p *= Rot(radians(ov_side_rot * n));
            p /= sc;
            d = min(d, sideUI(p) * sc);
        }
        col = mix(col, ov_side_color, ov_alpha(d, ov_side_glow) * ov_side_opacity);
    }

    gl_FragColor = vec4(col, 1.0);
}
