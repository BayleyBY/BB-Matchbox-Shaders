// BokehGenerator.glsl
// Procedural bokeh generator for Autodesk Flame (Matchbox)
// GLSL 120 compatible (macOS/Linux)

uniform float adsk_result_w, adsk_result_h;

// --- Background input ---
uniform sampler2D bg_input;

// --- Bokeh count & seed ---
uniform float bokeh_count;
uniform float rand_seed;

// --- Shape ---
uniform float bokeh_sides;
uniform float bokeh_size;
uniform float bokeh_size_var;
uniform float bokeh_aspect;
uniform float bokeh_rotation;
uniform float bokeh_rotation_var;
uniform float edge_softness;
uniform float hollow_amount;
uniform float rim_brightness;

// --- Color ---
uniform float bokeh_r;
uniform float bokeh_g;
uniform float bokeh_b;
uniform float color_var;
uniform float brightness;
uniform float brightness_var;

// --- Optical ---
uniform float chroma_amount;
uniform float diff_spikes;
uniform float spike_count;
uniform float spike_blur;
uniform float spike_length;

// --- Distribution ---
uniform float density_falloff;
uniform float dist_cx;
uniform float dist_cy;

// --- Blend ---
uniform float global_opacity;
uniform float mix_amount;
uniform int blend_mode; // 0=Add, 1=Screen, 2=Normal, 3=Multiply, 4=Overlay

// --- Near/Far layers ---
uniform float near_scale;
uniform float near_opacity;
uniform float far_opacity;

// --- Animation ---
uniform float time_offset;
uniform float drift_x;
uniform float drift_y;
uniform float flicker_amount;
uniform float fade_amount;
uniform float fade_variation;

// -------------------------------------------------------
// Utility
// -------------------------------------------------------

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float polyDist(vec2 p, float n, float r) {
    if (n < 2.5) return length(p) - r;
    float angle = 3.14159265 * 2.0 / n;
    float a = atan(p.y, p.x) + 3.14159265;
    float sector = floor(a / angle);
    float a2 = a - sector * angle - angle * 0.5;
    return length(p) * cos(a2) - r * cos(angle * 0.5);
}

vec2 rotate2D(vec2 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Spike blur: wider angular smoothstep = softer spikes
float spikeMask(vec2 p, float nSpikes, float size, float sharpness, float blur) {
    float a = atan(p.y, p.x);
    float interval = 3.14159265 / nSpikes;
    float spike = abs(mod(a + interval * 0.5, interval) - interval * 0.5);
    float r = length(p);
    float edgeWidth = mix(0.005, 1.2, blur);
    float spikeShape = smoothstep(edgeWidth, 0.0, spike) * smoothstep(size * 2.0, 0.0, r);
    return spikeShape * sharpness;
}

vec3 drawBokeh(vec2 uv, vec2 pos, float size, float sides, float rotation,
               vec3 color, float softness, float hollow, float rimBright,
               float spikes, float spikeN, float spikeBlur, float spikeLen) {

    float ar = adsk_result_w / adsk_result_h;
    float safeAspect = max(0.01, bokeh_aspect);
    vec2 local = (uv - pos);
    local.x *= ar / safeAspect;

    local = rotate2D(local, rotation);

    float n = max(2.5, sides);
    float blendToCircle = clamp(1.0 - sides / 3.0, 0.0, 1.0);
    float polyD = polyDist(local, n, size * 0.5);
    float circD = length(local) - size * 0.5;
    float d = mix(polyD, circD, blendToCircle);

    float soft = mix(0.001, size * 0.3, softness);
    float shape = smoothstep(soft, -soft, d);

    if (hollow > 0.001) {
        float innerR = size * 0.5 * (1.0 - hollow * 0.85);
        float polyDi = polyDist(local, n, innerR);
        float circDi = length(local) - innerR;
        float di = mix(polyDi, circDi, blendToCircle);
        float inner = smoothstep(soft, -soft, di);
        shape = max(0.0, shape - inner * (1.0 - soft));
    }

    float rim = 0.0;
    if (rimBright > 0.001) {
        rim = smoothstep(size * 0.12, 0.0, abs(d)) * rimBright;
    }

    float spikeLum = 0.0;
    if (spikes > 0.001) {
        spikeLum = spikeMask(local, spikeN, size * spikeLen, spikes, spikeBlur);
    }

    float alpha = clamp(shape + rim + spikeLum, 0.0, 1.0);
    return color * alpha;
}

// -------------------------------------------------------
// MAIN
// -------------------------------------------------------
void main() {
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    float t = time_offset;

    vec3 bokeh_color = vec3(bokeh_r, bokeh_g, bokeh_b);
    float uvSize = bokeh_size / adsk_result_w;

    vec3 col = texture2D(bg_input, uv).rgb;
    int count = int(max(1.0, bokeh_count));
    int halfCount = count / 2;

    for (int i = 0; i < 200; i++) {
        if (i >= count) break;

        bool isNear = (i >= halfCount);
        float fi = float(i) + rand_seed * 100.0;

        // Depth factor: near layer drifts faster, far layer slower
        float depthRand = hash(fi * 37.3);
        float depth = isNear
            ? (1.2 + depthRand * 0.8)
            : (0.2 + depthRand * 0.5);

        // Base position from hash (no drift yet)
        vec2 bpos = vec2(hash(fi * 1.3 + 0.1), hash(fi * 2.7 + 0.5));

        // Distribution: remap base position before drift is applied
        if (abs(density_falloff) > 0.001) {
            vec2 center = vec2(dist_cx, dist_cy);
            vec2 fromCenter = bpos - center;
            float d = length(fromCenter);
            if (d > 0.001) {
                float power = (density_falloff > 0.0)
                    ? 1.0 + density_falloff * 3.0
                    : 1.0 / (1.0 - density_falloff * 0.9);
                float newDist = pow(d, power) * (1.0 / pow(0.7, power - 1.0));
                newDist = clamp(newDist, 0.0, 0.7);
                bpos = center + normalize(fromCenter) * newDist;
            }
        }

        // Apply drift on top of distributed position, wrap with fract
        bpos = fract(bpos + vec2(drift_x, drift_y) * t * 0.05 * depth);

        // Size with variation
        float sz = uvSize * (1.0 + (hash(fi * 3.9) - 0.5) * 2.0 * bokeh_size_var);
        if (isNear) sz *= near_scale;
        sz = max(0.001, sz);

        // Rotation: variation now scales ±180 degrees at var=1.0
        float rot = (bokeh_rotation + (hash(fi * 7.3) - 0.5) * 360.0 * bokeh_rotation_var) * 3.14159265 / 180.0;

        // Color with variation
        vec3 baseHSV = vec3(
            fract(hash(fi * 11.1) * color_var + dot(bokeh_color, vec3(0.299, 0.587, 0.114))),
            clamp(0.7 - color_var * 0.3, 0.0, 1.0),
            1.0
        );
        vec3 bColor = mix(bokeh_color, hsv2rgb(baseHSV), color_var);

        // Flicker: time-driven sine wave, per-bokeh frequency and phase
        // No keyframing needed — just animate time_offset
        float flickerPhase = hash(fi * 19.3) * 6.28318;
        float flickerFreq  = 1.0 + hash(fi * 23.1) * 4.0; // 1-5 Hz equivalent
        float flickerVal   = 1.0 + sin(t * flickerFreq + flickerPhase) * 0.5 * flicker_amount;

        bColor *= brightness * (1.0 + (hash(fi * 17.3) - 0.5) * 2.0 * brightness_var) * flickerVal;

        // Fade in/out: time-driven sine, per-bokeh speed variation
        float fadePhase = hash(fi * 29.7) * 6.28318;
        float fadeFreq  = 0.2 + hash(fi * 31.1) * fade_variation * 1.5;
        float fadeAlpha = 0.5 + 0.5 * sin(t * fadeFreq + fadePhase);
        float layerOp   = (isNear ? near_opacity : far_opacity) * mix(1.0, fadeAlpha, fade_amount);

        // Chromatic aberration
        if (chroma_amount > 0.001) {
            float offset = sz * chroma_amount * 0.3;
            vec3 colR = drawBokeh(uv, bpos + vec2(offset, 0.0), sz, bokeh_sides, rot,
                vec3(1,0,0) * bColor.r, edge_softness, hollow_amount, rim_brightness,
                diff_spikes, spike_count, spike_blur, spike_length);
            vec3 colG = drawBokeh(uv, bpos, sz, bokeh_sides, rot,
                vec3(0,1,0) * bColor.g, edge_softness, hollow_amount, rim_brightness,
                diff_spikes, spike_count, spike_blur, spike_length);
            vec3 colB = drawBokeh(uv, bpos - vec2(offset, 0.0), sz, bokeh_sides, rot,
                vec3(0,0,1) * bColor.b, edge_softness, hollow_amount, rim_brightness,
                diff_spikes, spike_count, spike_blur, spike_length);
            col += (colR + colG + colB) * layerOp;
        } else {
            col += drawBokeh(uv, bpos, sz, bokeh_sides, rot,
                bColor, edge_softness, hollow_amount, rim_brightness,
                diff_spikes, spike_count, spike_blur, spike_length) * layerOp;
        }
    }

    vec3 bg = texture2D(bg_input, uv).rgb;
    col *= global_opacity;

    // Blend bokeh layer over background
    vec3 blended;
    int bmode = blend_mode;

    if (bmode == 1) {
        // Screen: 1 - (1-a)(1-b)
        blended = 1.0 - (1.0 - bg) * (1.0 - col);
    } else if (bmode == 2) {
        // Normal: standard alpha composite
        blended = mix(bg, col, clamp(length(col) * 2.0, 0.0, 1.0));
    } else if (bmode == 3) {
        // Multiply
        blended = bg * col;
    } else if (bmode == 4) {
        // Overlay
        vec3 dark = 2.0 * bg * col;
        vec3 light = 1.0 - 2.0 * (1.0 - bg) * (1.0 - col);
        blended = mix(dark, light, step(0.5, bg));
    } else {
        // Add (default, bmode == 0)
        blended = bg + col;
    }

    col = mix(bg, blended, mix_amount);
    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
