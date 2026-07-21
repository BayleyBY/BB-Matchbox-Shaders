// Film DIR-Coupler Shader
// Emulates the inhibitor chemistry that makes film colour "work" - the part every
// curve/LUT-based film emulation skips. Colour negative film uses DIR (Development-
// Inhibitor-Releasing) couplers: where a dye layer develops, it releases inhibitor
// that suppresses development in the OTHER layers and in NEIGHBOURING areas. That
// produces two signature effects:
//   1. Inter-layer effects  - cross-channel coupling that increases colour separation
//                             and saturation in a film-characteristic way.
//   2. Adjacency effects    - the inhibitor diffuses spatially, giving edge acutance
//                             and local contrast (film's "sharpness" beyond its MTF).
// Neutrals are untouched (couplers only act where the layers differ). Identity when
// Coupling and Acutance are 0.

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h, adsk_time;

uniform int   colorSpace;   // 0 Rec.709, 1 Scene-Linear, 2 ACEScg, 3 ACEScct, 4 ARRI LogC4
uniform float coupling;     // inter-layer effect strength
uniform float acutance;     // adjacency / edge effect strength
uniform float radius;       // inhibitor diffusion radius (pixels)
uniform float grain;        // film grain
uniform float mixAmount;    // blend with the original

vec3 srgb2lin(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}
vec3 lin2srgb(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// ACEScct log (AP1) <-> linear. max() guards log2 against NaN (mix evaluates both
// branches, and NaN*0 would poison the linear-segment result).
vec3 acescct2lin(vec3 c) { return mix((c - 0.0729055341958355) / 10.5402377416545, exp2(c * 17.52 - 9.72), step(0.155251141552511, c)); }
vec3 lin2acescct(vec3 c) { return mix(10.5402377416545 * c + 0.0729055341958355, (log2(max(c, 1e-10)) + 9.72) / 17.52, step(0.0078125, c)); }

// ARRI LogC4 (EI800, AWG4 primaries) <-> linear, constants folded from the 2022 spec.
vec3 logc42lin(vec3 c) { return mix(c * 0.1135972086 - 0.0180569961, (exp2(c * 15.4331897 + 4.5668103) - 64.0) / 2231.8263091, step(0.0, c)); }
vec3 lin2logc4(vec3 c) { return mix((c + 0.0180569961) / 0.1135972086, log2(max(c * 2231.8263091 + 64.0, 1e-6)) * 0.0647954196 - 0.2959083927, step(-0.0180569961, c)); }

// Decode to native linear light and back. Unlike the spectral shaders, the coupler
// math is per-channel with no Rec.709-specific constants, so the dye "layers" are
// the native RGB channels of the selected space - no primaries conversion needed.
vec3 toLin(vec3 c) {
    vec3 lin = c;
    if (colorSpace == 0) lin = srgb2lin(c);
    if (colorSpace == 3) lin = acescct2lin(c);
    if (colorSpace == 4) lin = logc42lin(c);
    return lin;
}
vec3 fromLin(vec3 lin) {
    vec3 c = lin;
    if (colorSpace == 0) c = lin2srgb(lin);
    if (colorSpace == 3) c = lin2acescct(lin);
    if (colorSpace == 4) c = lin2logc4(lin);
    return c;
}

// Inter-layer effect in log-density space: each layer is separated from the mean
// development of the other two (cross-layer inhibitor). Zero for neutrals.
vec3 interlayer(vec3 lin) {
    vec3 d = log2(max(lin, 1e-4));
    vec3 others = vec3(d.g + d.b, d.r + d.b, d.r + d.g) * 0.5;
    return exp2(d + coupling * (d - others));
}

// Coupled linear colour at a UV (used by the adjacency blur)
vec3 coupledAt(vec2 uv) {
    vec3 c = texture2D(front, uv).rgb;
    return interlayer(toLin(c));
}

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv = gl_FragCoord.xy / res;
    vec4 tex = texture2D(front, uv);

    vec3 center = coupledAt(uv);
    vec3 result = center;

    // Adjacency: inhibitor diffuses -> unsharp of the coupled signal (acutance)
    if (acutance > 0.001) {
        vec2 r = radius / res;
        vec3 blur = coupledAt(uv + vec2( r.x,  r.y)) + coupledAt(uv + vec2(-r.x,  r.y))
                  + coupledAt(uv + vec2( r.x, -r.y)) + coupledAt(uv + vec2(-r.x, -r.y))
                  + coupledAt(uv + vec2( r.x, 0.0))  + coupledAt(uv + vec2(-r.x, 0.0))
                  + coupledAt(uv + vec2( 0.0, r.y))  + coupledAt(uv + vec2( 0.0, -r.y));
        result = center + acutance * (center - blur * 0.125);
    }
    result = max(result, 0.0);

    if (grain > 0.001) {
        float n = hash(gl_FragCoord.xy + fract(adsk_time) * vec2(37.0, 17.0)) - 0.5;
        result += n * grain * 0.06;
    }

    vec3 orig = toLin(tex.rgb);
    result = mix(orig, result, mixAmount);

    vec3 outc = fromLin(result);
    gl_FragColor = vec4(outc, tex.a);
}
