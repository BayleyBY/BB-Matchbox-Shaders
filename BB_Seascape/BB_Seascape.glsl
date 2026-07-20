// BB_Seascape
// Procedural animated ocean for Autodesk Flame 2026.
//
// Based on "Seascape" by Alexander Alekseev aka TDM – 2014
// https://www.shadertoy.com/view/Ms2SD1
// License: CC BY-NC-SA 3.0 Unported
// Original contact: tdmaav@gmail.com
//
// Flame port: entry point, uniforms, and time source adapted for Matchbox.
// Sea shape and colour parameters exposed as UI controls.

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_time;

// Sea shape
uniform float sea_height;
uniform float sea_choppy;
uniform float sea_speed;
uniform float sea_freq;

// Sea colour
uniform vec3  sea_base;
uniform vec3  sea_water_color;

// Camera
uniform float cam_x;        // lateral position
uniform float cam_y;        // height above sea
uniform float cam_z;        // forward position (keyframe to fly forward)
uniform float cam_pitch;    // tilt up/down in degrees
uniform float cam_yaw;      // pan left/right in degrees
uniform float cam_roll;     // roll in degrees

// Animation
uniform float time_scale;   // wave speed multiplier (1.0 = original speed at 25 fps)
uniform float time_offset;  // wave animation offset in seconds

// Quality
uniform int   aa_enable;    // 0 = off, 1 = 3x3 supersampling

// ----------------------------------------------------------------

const int   NUM_STEPS     = 32;
const float PI            = 3.141592;
const float EPSILON       = 1e-3;
const int   ITER_GEOMETRY = 3;
const int   ITER_FRAGMENT = 5;
const mat2  octave_m      = mat2(1.6, 1.2, -1.2, 1.6);

// ----------------------------------------------------------------
// Math
// ----------------------------------------------------------------

mat3 fromEuler(vec3 ang) {
    vec2 a1 = vec2(sin(ang.x), cos(ang.x));
    vec2 a2 = vec2(sin(ang.y), cos(ang.y));
    vec2 a3 = vec2(sin(ang.z), cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y + a1.x*a2.x*a3.x,  a1.y*a2.x*a3.x + a3.y*a1.x, -a2.y*a3.x);
    m[1] = vec3(-a2.y*a1.x,                    a1.y*a2.y,                    a2.x);
    m[2] = vec3(a3.y*a1.x*a2.x + a1.y*a3.x,   a1.x*a3.x - a1.y*a3.y*a2.x,  a2.y*a3.y);
    return m;
}

float hash(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

float noise(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

// ----------------------------------------------------------------
// Lighting
// ----------------------------------------------------------------

float diffuse(vec3 n, vec3 l, float p) {
    return pow(dot(n, l) * 0.4 + 0.6, p);
}

float specular(vec3 n, vec3 l, vec3 e, float s) {
    float nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
}

// ----------------------------------------------------------------
// Sky
// ----------------------------------------------------------------

vec3 getSkyColor(vec3 e) {
    e.y = (max(e.y, 0.0) * 0.8 + 0.2) * 0.8;
    return vec3(pow(1.0 - e.y, 2.0), 1.0 - e.y, 0.6 + (1.0 - e.y) * 0.4) * 1.1;
}

// ----------------------------------------------------------------
// Sea
// ----------------------------------------------------------------

float sea_octave(vec2 uv, float choppy) {
    uv += noise(uv);
    vec2 wv  = 1.0 - abs(sin(uv));
    vec2 swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

float map(vec3 p, float sea_time) {
    float freq   = sea_freq;
    float amp    = sea_height;
    float choppy = sea_choppy;
    vec2  uv     = p.xz;
    uv.x *= 0.75;
    float d, h = 0.0;
    for (int i = 0; i < ITER_GEOMETRY; i++) {
        d  = sea_octave((uv + sea_time) * freq, choppy);
        d += sea_octave((uv - sea_time) * freq, choppy);
        h += d * amp;
        uv     *= octave_m;
        freq   *= 1.9;
        amp    *= 0.22;
        choppy  = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

float map_detailed(vec3 p, float sea_time) {
    float freq   = sea_freq;
    float amp    = sea_height;
    float choppy = sea_choppy;
    vec2  uv     = p.xz;
    uv.x *= 0.75;
    float d, h = 0.0;
    for (int i = 0; i < ITER_FRAGMENT; i++) {
        d  = sea_octave((uv + sea_time) * freq, choppy);
        d += sea_octave((uv - sea_time) * freq, choppy);
        h += d * amp;
        uv     *= octave_m;
        freq   *= 1.9;
        amp    *= 0.22;
        choppy  = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) {
    float fresnel = clamp(1.0 - dot(n, -eye), 0.0, 1.0);
    fresnel = min(fresnel * fresnel * fresnel, 0.5);

    vec3 reflected = getSkyColor(reflect(eye, n));
    vec3 refracted = sea_base + diffuse(n, l, 80.0) * sea_water_color * 0.12;

    vec3 color = mix(refracted, reflected, fresnel);

    float atten = max(1.0 - dot(dist, dist) * 0.001, 0.0);
    color += sea_water_color * (p.y - sea_height) * 0.18 * atten;
    color += specular(n, l, eye, 600.0 * inversesqrt(dot(dist, dist)));

    return color;
}

// ----------------------------------------------------------------
// Tracing
// ----------------------------------------------------------------

vec3 getNormal(vec3 p, float eps, float sea_time) {
    vec3 n;
    n.y = map_detailed(p, sea_time);
    n.x = map_detailed(vec3(p.x + eps, p.y, p.z), sea_time) - n.y;
    n.z = map_detailed(vec3(p.x, p.y, p.z + eps), sea_time) - n.y;
    n.y = eps;
    return normalize(n);
}

float heightMapTracing(vec3 ori, vec3 dir, out vec3 p, float sea_time) {
    float tm = 0.0;
    float tx = 1000.0;
    float hx = map(ori + dir * tx, sea_time);
    if (hx > 0.0) {
        p = ori + dir * tx;
        return tx;
    }
    float hm = map(ori, sea_time);
    for (int i = 0; i < NUM_STEPS; i++) {
        float tmid = mix(tm, tx, hm / (hm - hx));
        p = ori + dir * tmid;
        float hmid = map(p, sea_time);
        if (hmid < 0.0) {
            tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
        if (abs(hmid) < EPSILON) break;
    }
    return mix(tm, tx, hm / (hm - hx));
}

// ----------------------------------------------------------------
// Per-pixel colour
// ----------------------------------------------------------------

vec3 getPixel(in vec2 coord, float time) {
    vec2  res         = vec2(adsk_result_w, adsk_result_h);
    float EPSILON_NRM = 0.1 / adsk_result_w;

    vec2 uv = coord / res;
    uv = uv * 2.0 - 1.0;
    uv.x *= res.x / res.y;

    float sea_time = 1.0 + time * sea_speed;

    vec3 ori = vec3(cam_x, cam_y, cam_z);
    vec3 ang = radians(vec3(cam_pitch, cam_yaw, cam_roll));
    vec3 dir = normalize(vec3(uv.xy, -2.0));
    dir.z += length(uv) * 0.14;
    dir = normalize(dir) * fromEuler(ang);

    vec3  p;
    heightMapTracing(ori, dir, p, sea_time);
    vec3  dist  = p - ori;
    vec3  n     = getNormal(p, dot(dist, dist) * EPSILON_NRM, sea_time);
    vec3  light = normalize(vec3(0.0, 1.0, 0.8));

    return mix(
        getSkyColor(dir),
        getSeaColor(p, n, light, dir, dist),
        pow(smoothstep(0.0, -0.02, dir.y), 0.2));
}

// ----------------------------------------------------------------
// Main
// ----------------------------------------------------------------

void main() {
    vec2  coord = gl_FragCoord.xy;

    // adsk_time is in frames; divide by 25 to get seconds at 25 fps.
    // Adjust time_scale if your project runs at a different frame rate.
    float secs = adsk_time / 25.0;
    float time = secs * 0.3 * time_scale + time_offset;

    vec3 color;

    if (aa_enable == 1) {
        color = vec3(0.0);
        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                color += getPixel(coord + vec2(float(i), float(j)) / 3.0, time);
            }
        }
        color /= 9.0;
    } else {
        color = getPixel(coord, time);
    }

    gl_FragColor = vec4(pow(color, vec3(0.65)), 1.0);
}
