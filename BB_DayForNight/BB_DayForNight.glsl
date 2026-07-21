// Day-for-Night Shader (Purkinje mesopic model)
// Physically-motivated day-for-night: as the scene darkens, human vision shifts from
// cone-dominated (photopic) to rod-dominated (scotopic). Rods are colour-blind, peak
// toward blue-green (~507nm) and are nearly insensitive to red, so night vision
// desaturates, shifts blue, and makes reds go dark (the Purkinje shift) while losing
// acuity and gaining noise. This models that transition instead of the usual
// crush-and-tint-blue fake. Identity at Night = 0.

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h, adsk_time;

uniform int   colorSpace;   // 0 Rec.709, 1 Scene-Linear, 2 ACEScg, 3 ACEScct, 4 ARRI LogC4
uniform float night;        // master day->night amount (0..1)
uniform float purkinje;     // strength of the scotopic luminance shift (reds darken)
uniform float nightSat;     // residual saturation at full night
uniform float exposure;     // output level at full night (day-for-night is darker)
uniform vec3  nightTint;    // colour of the night monochrome (moonlight)
uniform float softness;     // acuity loss (detail softening)
uniform float grain;        // scotopic noise

const vec3 PHOTOPIC = vec3(0.2126, 0.7152, 0.0722);  // cone / daylight luminance
const vec3 SCOTOPIC = vec3(0.0600, 0.4400, 0.5000);  // rod / night luminance (blue-shifted)

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

// PHOTOPIC/SCOTOPIC weights above are Rec.709-linear, so AP1 (ACEScg/ACEScct) and
// AWG4 (LogC4) inputs are matrix-converted to a Rec.709 working space and restored
// with the exact inverse (Night 0 stays an exact identity). The AP1 pair is
// Bradford-adapted D60->D65 so ACES neutrals stay neutral in the working space.
const mat3 AP1_TO_709   = mat3(1.7048666, -0.1302640, -0.0240109, -0.6216296, 1.1408072, -0.1289904, -0.0832368, -0.0105433, 1.1530014);
const mat3 M709_TO_AP1  = mat3(0.6131612, 0.0702049, 0.0206230, 0.3394696, 0.9163477, 0.1095845, 0.0473692, 0.0134475, 0.8697925);
const mat3 AWG4_TO_709  = mat3(1.8928226, -0.2057053, -0.0127088, -0.7807574, 1.3402885, -0.1522214, -0.1122241, -0.1345602, 1.1651702);
const mat3 M709_TO_AWG4 = mat3(0.5659265, 0.0886398, 0.0177529, 0.3403232, 0.8093282, 0.1094451, 0.0938100, 0.1020030, 0.8725929);

// Decode any supported space to the Rec.709-primaries linear working space, and back.
vec3 toWorking(vec3 c) {
    vec3 lin = c;
    if (colorSpace == 0) lin = srgb2lin(c);
    if (colorSpace == 3) lin = acescct2lin(c);
    if (colorSpace == 4) lin = logc42lin(c);
    if (colorSpace == 2 || colorSpace == 3) lin = AP1_TO_709 * lin;
    if (colorSpace == 4) lin = AWG4_TO_709 * lin;
    return lin;
}
vec3 fromWorking(vec3 lin) {
    vec3 c = lin;
    if (colorSpace == 2 || colorSpace == 3) c = M709_TO_AP1 * c;
    if (colorSpace == 4) c = M709_TO_AWG4 * c;
    if (colorSpace == 0) c = lin2srgb(c);
    if (colorSpace == 3) c = lin2acescct(c);
    if (colorSpace == 4) c = lin2logc4(c);
    return c;
}

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv = gl_FragCoord.xy / res;

    vec4 tex = texture2D(front, uv);
    vec3 c = tex.rgb;

    // Acuity loss: rods pool signal, so night vision is softer. Small blur, gated by night.
    if (softness > 0.001) {
        vec2 r = (1.5 + softness * 3.0) / res;
        vec3 b = texture2D(front, uv + vec2( r.x,  r.y)).rgb
               + texture2D(front, uv + vec2(-r.x,  r.y)).rgb
               + texture2D(front, uv + vec2( r.x, -r.y)).rgb
               + texture2D(front, uv + vec2(-r.x, -r.y)).rgb
               + texture2D(front, uv + vec2( r.x, 0.0)).rgb
               + texture2D(front, uv + vec2(-r.x, 0.0)).rgb
               + texture2D(front, uv + vec2(0.0,  r.y)).rgb
               + texture2D(front, uv + vec2(0.0, -r.y)).rgb;
        c = mix(c, b / 8.0, softness * night);
    }

    vec3 lin = toWorking(c);

    float Yp = dot(lin, PHOTOPIC);
    float Ys = dot(lin, SCOTOPIC);
    float Yn = mix(Yp, Ys, night * purkinje);        // Purkinje luminance shift
    vec3  tint = mix(vec3(1.0), nightTint, night);    // toward moonlight
    float sat  = mix(1.0, nightSat, night);           // desaturate toward monochrome

    vec3 chroma = lin - vec3(Yp);
    vec3 result = Yn * tint + chroma * sat;

    // Scotopic noise (animated), gated by night
    if (grain > 0.001) {
        float n = hash(gl_FragCoord.xy + fract(adsk_time) * vec2(37.0, 17.0)) - 0.5;
        result += n * grain * 0.15 * night;
    }

    // Night is darker
    result *= mix(1.0, exposure, night);

    vec3 outc = fromWorking(result);
    gl_FragColor = vec4(outc, tex.a);
}
