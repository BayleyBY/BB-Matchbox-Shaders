// Day-for-Night Shader (Purkinje mesopic model)
// Physically-motivated day-for-night: as the scene darkens, human vision shifts from
// cone-dominated (photopic) to rod-dominated (scotopic). Rods are colour-blind, peak
// toward blue-green (~507nm) and are nearly insensitive to red, so night vision
// desaturates, shifts blue, and makes reds go dark (the Purkinje shift) while losing
// acuity and gaining noise. This models that transition instead of the usual
// crush-and-tint-blue fake. Identity at Night = 0.

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h, adsk_time;

uniform int   colorSpace;   // 0 = Rec.709 (sRGB), 1 = Scene-Linear
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

    vec3 lin = (colorSpace == 0) ? srgb2lin(c) : c;

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

    vec3 outc = (colorSpace == 0) ? lin2srgb(result) : result;
    gl_FragColor = vec4(outc, tex.a);
}
