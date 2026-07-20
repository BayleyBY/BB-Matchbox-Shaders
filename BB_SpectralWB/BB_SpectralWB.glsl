// Spectral White Balance Shader
// A physically-based white balance that RECONSTRUCTS a plausible reflectance spectrum for
// every pixel, then re-lights it under a target illuminant - instead of the tristimulus
// (3-channel) tint that ordinary white balance applies. This captures spectral behaviour a
// matrix cannot: recovering colour under spiky/low-CRI sources (sodium, fluorescent, cheap
// LED) and the metameric colour-collapse those sources cause.
//
// Pipeline (per pixel): normalise by the source white -> reflectance estimate; reconstruct a
// smooth reflectance spectrum (Smits 1999 basis); integrate it under both the source and the
// target illuminant against the CIE observer; apply the ratio (target/source) to the pixel.
// Using the ratio makes reconstruction error cancel, so Source == Target is an exact identity.
//
// NOTE: this is a plausible reconstruction (the RGB->spectrum inverse is under-determined) and
// uses the CIE 1931 observer as a stand-in for the camera. It is the heaviest shader in the set
// (two 20-sample wavelength loops per pixel).

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

uniform int   colorSpace;   // 0 = Rec.709 (sRGB), 1 = Scene-Linear
uniform int   srcIllum;     // light the footage was shot under
uniform int   tgtIllum;     // light to re-render under
uniform float srcKelvin;    // used when srcIllum = Custom Kelvin
uniform float tgtKelvin;    // used when tgtIllum = Custom Kelvin
uniform float mixAmount;    // blend with original

// Illuminant enum: 0 Tungsten, 1 Daylight D65, 2 Custom Kelvin, 3 Sodium, 4 White LED, 5 Fluorescent

// CIE 1931 colour-matching functions, sampled at 20 wavelengths 380..730nm
const float XBAR[20] = float[20](0.00020, 0.00887, 0.10516, 0.33102, 0.32521, 0.17165, 0.02912, 0.01315, 0.13290, 0.36755, 0.67593, 0.95251, 1.05509, 0.86338, 0.49631, 0.20042, 0.05686, 0.01133, 0.00159, 0.00016);
const float YBAR[20] = float[20](0.00025, 0.00112, 0.00431, 0.01425, 0.04038, 0.09845, 0.21725, 0.47913, 0.83512, 0.98293, 0.97824, 0.84619, 0.62037, 0.38027, 0.19234, 0.07959, 0.02684, 0.00736, 0.00164, 0.00030);
const float ZBAR[20] = float[20](0.00675, 0.05093, 0.46579, 1.65280, 1.75999, 1.19031, 0.45304, 0.16616, 0.05212, 0.01266, 0.00237, 0.00034, 0.00004, 0.00000, 0.00000, 0.00000, 0.00000, 0.00000, 0.00000, 0.00000);

// Smits 1999 RGB->reflectance basis (interpolated to the same 20 wavelengths)
const float B_WHITE[20]   = float[20](1.0000, 1.0000, 1.0000, 1.0000, 0.9999, 0.9996, 0.9993, 0.9993, 0.9992, 0.9994, 0.9997, 0.9999, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000);
const float B_CYAN[20]    = float[20](0.9710, 0.9572, 0.9433, 0.9695, 0.9978, 1.0007, 1.0007, 1.0007, 1.0007, 1.0007, 1.0007, 0.6936, 0.2819, 0.1034, 0.0271, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000);
const float B_MAGENTA[20] = float[20](1.0000, 1.0000, 1.0000, 0.9854, 0.9701, 0.6419, 0.2783, 0.1308, 0.0221, 0.0178, 0.0401, 0.3336, 0.7193, 0.8922, 0.9717, 1.0000, 1.0000, 0.9988, 0.9968, 0.9959);
const float B_YELLOW[20]  = float[20](0.0001, 0.0001, 0.0000, 0.0504, 0.1034, 0.3525, 0.6238, 0.8035, 0.9668, 1.0000, 1.0000, 0.9999, 0.9997, 0.9857, 0.9657, 0.9617, 0.9665, 0.9730, 0.9805, 0.9840);
const float B_RED[20]     = float[20](0.1012, 0.0770, 0.0527, 0.0277, 0.0026, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.3028, 0.7088, 0.8943, 0.9833, 1.0149, 1.0149, 1.0149, 1.0149, 1.0149);
const float B_GREEN[20]   = float[20](0.0000, 0.0000, 0.0000, 0.0126, 0.0259, 0.3630, 0.7368, 0.8790, 0.9796, 0.9774, 0.9490, 0.6617, 0.2863, 0.1136, 0.0298, 0.0000, 0.0000, 0.0007, 0.0019, 0.0025);
const float B_BLUE[20]    = float[20](1.0000, 1.0000, 1.0000, 0.9498, 0.8970, 0.6466, 0.3739, 0.1950, 0.0329, 0.0000, 0.0000, 0.0001, 0.0003, 0.0127, 0.0306, 0.0405, 0.0460, 0.0487, 0.0493, 0.0496);

const mat3 XYZ2RGB = mat3(3.2406, -0.9689, 0.0557, -1.5372, 1.8758, -0.2040, -0.4986, 0.0415, 1.0570);

vec3 srgb2lin(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }
vec3 lin2srgb(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}
float gaussl(float x, float mu, float s) { float t = (x - mu) / s; return exp(-0.5 * t * t); }
float planck(float w, float T) { float lu = w * 0.001; return pow(lu, -5.0) / (exp(14388.0 / (lu * T)) - 1.0); }

// Spectral power distribution of an illuminant at wavelength w (nm)
float illum(int which, float w, float K) {
    if (which == 0) return planck(w, 3200.0);                 // Tungsten
    else if (which == 1) return planck(w, 6500.0);            // Daylight D65 (blackbody approx)
    else if (which == 2) return planck(w, K);                 // Custom Kelvin
    else if (which == 3) return gaussl(w, 589.0, 14.0) + 0.02;                                   // Sodium vapor
    else if (which == 4) return 0.85 * gaussl(w, 452.0, 20.0) + gaussl(w, 560.0, 55.0);          // White LED
    return 0.6 * gaussl(w, 440.0, 12.0) + gaussl(w, 546.0, 12.0)
         + 0.7 * gaussl(w, 611.0, 14.0) + 0.5 * gaussl(w, 580.0, 45.0) + 0.02;                   // Fluorescent
}

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec4 tex = texture2D(front, gl_FragCoord.xy / res);
    vec3 C = (colorSpace == 0) ? srgb2lin(tex.rgb) : tex.rgb;

    const float dl = 18.421053;

    // Loop A: illuminant luminance normalisers + source white point
    float ysS = 0.0, ysT = 0.0;
    vec3 WsX = vec3(0.0);
    for (int i = 0; i < 20; i++) {
        float w = 380.0 + float(i) * dl;
        float ls = illum(srcIllum, w, srcKelvin);
        float lt = illum(tgtIllum, w, tgtKelvin);
        vec3 cm = vec3(XBAR[i], YBAR[i], ZBAR[i]);
        ysS += ls * cm.y * dl;
        ysT += lt * cm.y * dl;
        WsX += ls * cm * dl;
    }
    ysS = max(ysS, 1e-8);
    ysT = max(ysT, 1e-8);
    vec3 WsRGB = XYZ2RGB * (WsX / ysS);
    vec3 Rrgb = clamp(C / max(WsRGB, vec3(1e-4)), 0.0, 1.0);

    // Smits decomposition weights: white, cyan, magenta, yellow, red, green, blue
    float w0 = 0.0, w1 = 0.0, w2 = 0.0, w3 = 0.0, w4 = 0.0, w5 = 0.0, w6 = 0.0;
    float r = Rrgb.r, g = Rrgb.g, b = Rrgb.b;
    if (r <= g && r <= b) { w0 = r; if (g <= b) { w1 = g - r; w6 = b - g; } else { w1 = b - r; w5 = g - b; } }
    else if (g <= r && g <= b) { w0 = g; if (r <= b) { w2 = r - g; w6 = b - r; } else { w2 = b - g; w4 = r - b; } }
    else { w0 = b; if (r <= g) { w3 = r - b; w5 = g - r; } else { w3 = g - b; w4 = r - g; } }

    // Loop B: integrate the reconstructed spectrum under source and target
    vec3 CsX = vec3(0.0), CtX = vec3(0.0);
    for (int i = 0; i < 20; i++) {
        float w = 380.0 + float(i) * dl;
        float spec = w0 * B_WHITE[i] + w1 * B_CYAN[i] + w2 * B_MAGENTA[i] + w3 * B_YELLOW[i]
                   + w4 * B_RED[i] + w5 * B_GREEN[i] + w6 * B_BLUE[i];
        vec3 cm = vec3(XBAR[i], YBAR[i], ZBAR[i]);
        float ls = illum(srcIllum, w, srcKelvin) / ysS;
        float lt = illum(tgtIllum, w, tgtKelvin) / ysT;
        CsX += spec * ls * cm * dl;
        CtX += spec * lt * cm * dl;
    }
    vec3 CsRGB = XYZ2RGB * CsX;
    vec3 CtRGB = XYZ2RGB * CtX;

    // Ratio makes reconstruction error cancel -> Source == Target is exact identity
    vec3 ratio = (CtRGB + vec3(1e-4)) / (CsRGB + vec3(1e-4));
    vec3 result = C * mix(vec3(1.0), ratio, mixAmount);

    vec3 outc = (colorSpace == 0) ? lin2srgb(result) : result;
    gl_FragColor = vec4(outc, tex.a);
}
