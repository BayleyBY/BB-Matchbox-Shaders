// BB_RetroHUD — Pass 2: CRT / Old TV Filter
// Applies scan lines, screen geometry distortion, colour effects, and VHS artefacts
// to the output of pass 1.

uniform float adsk_result_w;
uniform float adsk_result_h;
uniform float adsk_time;
uniform sampler2D adsk_results_pass1;

// Note: pass 2 derives time directly from adsk_time so no separate time
// uniforms are needed — VHS tears, sync roll, and edge warp animate automatically.

// ---------------------------------------------------------------------------
// Screen Geometry
// ---------------------------------------------------------------------------
uniform bool  geo_enable;
uniform float geo_barrel;        // barrel(+) / pincushion(-) strength, range -1..1
uniform float geo_edge_warp;     // sinusoidal edge warp amplitude
uniform float geo_corner_tl_x;
uniform float geo_corner_tl_y;
uniform float geo_corner_tr_x;
uniform float geo_corner_tr_y;
uniform float geo_corner_bl_x;
uniform float geo_corner_bl_y;
uniform float geo_corner_br_x;
uniform float geo_corner_br_y;

// ---------------------------------------------------------------------------
// Scan Lines
// ---------------------------------------------------------------------------
uniform bool  scanline_enable;
uniform float scanline_density;    // lines per screen height (10..800)
uniform float scanline_intensity;  // 0..1 darkening depth
uniform int   scanline_interlace;  // 0=off  1=on (alternate fields)

// ---------------------------------------------------------------------------
// Colour & Glow
// ---------------------------------------------------------------------------
uniform bool  color_enable;
uniform float color_chroma_ab;     // chromatic aberration radius 0..0.02
uniform float color_bloom;         // phosphor bloom radius  0..1
uniform float color_vignette;      // vignette strength 0..1
uniform float color_phosphor;      // phosphor tint 0=neutral 1=green 2=amber
uniform float color_brightness;
uniform float color_contrast;

// ---------------------------------------------------------------------------
// Artefacts
// ---------------------------------------------------------------------------
uniform bool  artifact_enable;
uniform float artifact_vhs_tears;   // VHS horizontal tear intensity 0..1
uniform float artifact_color_bleed; // chroma bleed (horizontal smear) 0..1
uniform float artifact_moire;       // moiré interference 0..1
uniform float artifact_static;      // static noise intensity 0..1
uniform float artifact_sync_roll;   // sync roll speed (lines/sec)  0=off

// ===========================================================================
// Helpers
// ===========================================================================

#define PI 3.14159265358979

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

// Bilinear sample with clamp-to-border (black outside [0,1])
vec3 sampleHUD(vec2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return vec3(0.0);
    return texture2D(adsk_results_pass1, uv).rgb;
}

// ===========================================================================
// Screen Geometry
// ===========================================================================

// Barrel / pincushion distortion (k > 0 = barrel, k < 0 = pincushion)
vec2 applyBarrel(vec2 uv, float k) {
    vec2 cc = uv - 0.5;
    float r2 = dot(cc, cc);
    cc *= 1.0 + k * r2;
    return cc + 0.5;
}

// Sinusoidal edge warp (wiggle on all four edges)
vec2 applyEdgeWarp(vec2 uv, float amp, float t) {
    uv.x += amp * sin(uv.y * PI * 3.0 + t * 0.7);
    uv.y += amp * sin(uv.x * PI * 3.0 + t * 0.5);
    return uv;
}

// Bilinear corner pinning (simple perspective-like warp via bilerp of corner offsets)
vec2 applyCornerPin(vec2 uv) {
    // Corner offsets from the user controls
    vec2 tl = vec2(geo_corner_tl_x, geo_corner_tl_y);
    vec2 tr = vec2(geo_corner_tr_x, geo_corner_tr_y);
    vec2 bl = vec2(geo_corner_bl_x, geo_corner_bl_y);
    vec2 br = vec2(geo_corner_br_x, geo_corner_br_y);

    float u = uv.x, v = uv.y;
    vec2 top = mix(tl, tr, u);
    vec2 bot = mix(bl, br, u);
    vec2 off = mix(top, bot, v);
    return uv + off;
}

// ===========================================================================
// Scan Lines
// ===========================================================================

float scanlineMultiplier(vec2 uv, float t) {
    float lineY = uv.y * scanline_density;
    if (scanline_interlace == 1) {
        // Alternate odd/even fields based on frame parity
        float field = mod(floor(adsk_time), 2.0);
        lineY += field * 0.5;
    }
    float s = sin(lineY * PI);
    // s in [-1,1]; remap so troughs darken by scanline_intensity
    return 1.0 - scanline_intensity * (1.0 - s * s);
}

// ===========================================================================
// Chromatic Aberration
// ===========================================================================

vec3 chromaticAberration(vec2 uv, float strength) {
    vec2 dir = (uv - 0.5);
    float r = sampleHUD(uv + dir * strength).r;
    float g = sampleHUD(uv).g;
    float b = sampleHUD(uv - dir * strength).b;
    return vec3(r, g, b);
}

// ===========================================================================
// Phosphor Bloom (simple box blur approximation)
// ===========================================================================

vec3 bloomSample(vec2 uv, float radius) {
    vec2 texel = 1.0 / vec2(adsk_result_w, adsk_result_h);
    vec3 sum = vec3(0.0);
    float total = 0.0;
    // 3x3 weighted sample
    for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
            float w = exp(-float(dx*dx + dy*dy) / (2.0 * radius * radius + 0.001));
            sum += sampleHUD(uv + vec2(float(dx), float(dy)) * texel * radius * 8.0) * w;
            total += w;
        }
    }
    return sum / total;
}

// ===========================================================================
// Artefacts
// ===========================================================================

// VHS horizontal tear: random horizontal bands shear the image
vec2 vhsTear(vec2 uv, float strength, float t) {
    float band = floor(uv.y * 60.0);
    float h = Hash11(band * 0.137 + floor(t * 8.0) * 0.5);
    if (h > 0.92) {
        // Tear band: shear horizontally
        float shear = (Hash11(band * 0.271 + t) - 0.5) * strength * 0.08;
        uv.x += shear;
    }
    return uv;
}

// Chroma bleed: smear colour horizontally
vec3 colorBleed(vec2 uv, float strength) {
    vec2 texel = vec2(1.0 / adsk_result_w, 0.0);
    vec3 col = sampleHUD(uv);
    // Sample several pixels to the left (bleed direction)
    for (int i = 1; i <= 6; i++) {
        float w = exp(-float(i) * 0.5) * strength;
        col = mix(col, col + sampleHUD(uv - texel * float(i) * 3.0), w * 0.3);
    }
    return col;
}

// Moiré: two sine interference patterns
float moirePattern(vec2 uv, float t) {
    float a = sin(uv.x * 80.0 + t * 0.3) * sin(uv.y * 80.0 + t * 0.2);
    float b = sin(uv.x * 83.0 - t * 0.15) * sin(uv.y * 77.0 - t * 0.25);
    return (a * b) * 0.5 + 0.5;
}

// Sync roll: image rolls vertically
vec2 syncRoll(vec2 uv, float speed, float t) {
    uv.y = fract(uv.y + t * speed * 0.01);
    return uv;
}

// ===========================================================================
// Vignette
// ===========================================================================

float vignetteVal(vec2 uv, float strength) {
    vec2 d = uv - 0.5;
    return 1.0 - strength * dot(d, d) * 3.5;
}

// ===========================================================================
// Phosphor tint
// ===========================================================================

vec3 phosphorTint(vec3 col, float tint) {
    // tint: 0=neutral, 1=green, 2=amber
    if (tint < 0.5) {
        // Neutral (no tint)
        return col;
    } else if (tint < 1.5) {
        // Green phosphor (P1)
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        return mix(col, vec3(0.0, luma * 1.2, luma * 0.1), 0.7);
    } else {
        // Amber phosphor (P3)
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        return mix(col, vec3(luma * 1.1, luma * 0.7, 0.0), 0.7);
    }
}

// ===========================================================================
// Main
// ===========================================================================
void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv = gl_FragCoord.xy / res;

    float t = adsk_time / 25.0;

    // --- Sync Roll ---
    if (artifact_enable && abs(artifact_sync_roll) > 0.001) {
        uv = syncRoll(uv, artifact_sync_roll, t);
    }

    // --- VHS Tears ---
    if (artifact_enable && artifact_vhs_tears > 0.001) {
        uv = vhsTear(uv, artifact_vhs_tears, t);
    }

    // --- Screen Geometry ---
    if (geo_enable) {
        uv = applyBarrel(uv, geo_barrel * 0.5);
        if (abs(geo_edge_warp) > 0.001) {
            uv = applyEdgeWarp(uv, geo_edge_warp * 0.01, t);
        }
        uv = applyCornerPin(uv);
    }

    // --- Sample with chromatic aberration ---
    vec3 col;
    if (color_enable && color_chroma_ab > 0.001) {
        col = chromaticAberration(uv, color_chroma_ab);
    } else {
        col = sampleHUD(uv);
    }

    // --- Color bleed ---
    if (artifact_enable && artifact_color_bleed > 0.001) {
        col = colorBleed(uv, artifact_color_bleed);
    }

    // --- Moiré ---
    if (artifact_enable && artifact_moire > 0.001) {
        float m = moirePattern(uv, t);
        col += artifact_moire * 0.08 * (m - 0.5);
    }

    // --- Static noise ---
    if (artifact_enable && artifact_static > 0.001) {
        float n = Hash21(uv * res + vec2(t * 37.0, t * 53.0));
        col += (n - 0.5) * artifact_static * 0.25;
    }

    // --- Phosphor bloom ---
    if (color_enable && color_bloom > 0.001) {
        vec3 bloom = bloomSample(uv, color_bloom);
        col = max(col, col + bloom * color_bloom * 0.5);
    }

    // --- Scan lines ---
    if (scanline_enable) {
        col *= scanlineMultiplier(uv, t);
    }

    // --- Phosphor tint ---
    if (color_enable) {
        col = phosphorTint(col, color_phosphor);
    }

    // --- Brightness / contrast ---
    if (color_enable) {
        col = (col - 0.5) * max(color_contrast, 0.0) + 0.5;
        col *= color_brightness;
    }

    // --- Vignette ---
    if (color_enable && color_vignette > 0.001) {
        col *= vignetteVal(uv, color_vignette);
    }

    col = clamp(col, 0.0, 1.0);
    gl_FragColor = vec4(col, 1.0);
}
