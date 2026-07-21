// Path to White Shader
// Direct artist control over the HUE PATH saturated colors take as they
// desaturate toward clipping / white. Counteracts the Abney / Bezold-Brucke
// hue shift ("notorious six": blue->cyan, red->yellow, magenta breakup) that
// tone-mappers and display transforms bake in implicitly.
//
// A highlight factor (brightness through Pivot + Rolloff) gates the effect so
// it only acts on colors climbing toward white. Per hue band (RGBCMY) you can
// steer the hue and hold/drop saturation along that path. A global Path
// Desaturation pulls residual chroma to clean white.

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

// Color space selection (matches BB_ColorDensity)
// 0 = Rec.709 (gamma-encoded)
// 1 = Scene-Linear (Rec.709 primaries)
// 2 = ACEScg (AP1 primaries, linear)
// 3 = ACEScct (AP1 primaries, log encoding)
// 4 = ARRI LogC4 (AWG4 primaries, log encoding)
uniform int colorSpace;

// Highlight isolation
uniform float pivot;        // brightness at which the path-to-white effect is centered
uniform float rolloff;      // softness / width of the highlight transition
uniform float hueFalloff;   // hue-band width in degrees (narrow = distinct bands, wide = continuous)
uniform float strength;     // master amount
uniform float pathDesat;    // global pull of residual chroma toward white
uniform bool  preserveLuma; // keep original luminance, apply only the hue/sat shaping
uniform int   outputMode;   // 0 = Result, 1 = Highlight Mask

// Per-band hue steer (degrees) - rotates the band's hue in the highlights
uniform float steerRed, steerGreen, steerBlue;
uniform float steerCyan, steerMagenta, steerYellow;

// Per-band saturation shaping in the highlights (0 = no change)
uniform float satRed, satGreen, satBlue;
uniform float satCyan, satMagenta, satYellow;

// Luminance coefficients per color space
vec3 getLumaCoeff() {
    if (colorSpace == 2 || colorSpace == 3) { // ACEScg or ACEScct (AP1 primaries)
        return vec3(0.2722, 0.6741, 0.0537);
    }
    if (colorSpace == 4) { // ARRI LogC4 (AWG4 primaries; negative blue per ARRI spec, sums to 1.0)
        return vec3(0.2545, 0.7815, -0.0360);
    }
    return vec3(0.2126, 0.7152, 0.0722); // Rec.709 primaries
}

// Convert linear to perceptual space for brightness / shaping (linear spaces only)
vec3 toPerceptual(vec3 color) {
    if (colorSpace == 1 || colorSpace == 2) { // Scene-Linear or ACEScg
        return sign(color) * pow(abs(color), vec3(1.0 / 2.4));
    }
    return color; // Rec.709 and Log are already perceptual-ish
}

vec3 fromPerceptual(vec3 color) {
    if (colorSpace == 1 || colorSpace == 2) {
        return sign(color) * pow(abs(color), vec3(2.4));
    }
    return color;
}

float getLuma(vec3 color) {
    return dot(color, getLumaCoeff());
}

// RGB -> HSV (Sam Hocevar). Returns hue 0..1, sat 0..1, value.
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Smooth hue-band membership. h and center in degrees; full at center, 0 at >=hueFalloff.
float bandWeight(float h, float center) {
    float d = abs(mod(h - center + 540.0, 360.0) - 180.0); // wrapped distance 0..180
    return smoothstep(hueFalloff, 0.0, d);
}

// Rotate a color vector around the neutral (1,1,1) axis by `ang` radians.
// Preserves the luminance/neutral projection => a pure hue rotation.
vec3 rotateHue(vec3 v, float ang) {
    vec3 k = vec3(0.5773502691896258); // normalize(vec3(1.0))
    float cs = cos(ang);
    float sn = sin(ang);
    return v * cs + cross(k, v) * sn + k * dot(k, v) * (1.0 - cs);
}

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec4 texColor = texture2D(front, uv);
    vec3 color = texColor.rgb;

    // Work in perceptual space (consistent with the brightness metric)
    vec3 workingColor = toPerceptual(color);

    // Hue / saturation from the non-negative color
    vec3 hsv = rgb2hsv(max(workingColor, 0.0));
    float hueDeg = hsv.x * 360.0;
    float satMask = clamp(hsv.y, 0.0, 1.0); // fade the hue effect out on near-neutral pixels

    // Highlight factor: how far along the path to white this pixel is
    float brightness = max(max(workingColor.r, workingColor.g), workingColor.b);
    float lo = pivot - rolloff;
    float hi = pivot + rolloff;
    float t = smoothstep(lo, hi, brightness);

    // Blend the six band parameters by hue membership
    float wR = bandWeight(hueDeg, 0.0);
    float wY = bandWeight(hueDeg, 60.0);
    float wG = bandWeight(hueDeg, 120.0);
    float wC = bandWeight(hueDeg, 180.0);
    float wB = bandWeight(hueDeg, 240.0);
    float wM = bandWeight(hueDeg, 300.0);
    float totalW = wR + wY + wG + wC + wB + wM;
    totalW = max(totalW, 1.0e-4);

    float effSteer = (wR * steerRed + wY * steerYellow + wG * steerGreen +
                      wC * steerCyan + wB * steerBlue + wM * steerMagenta) / totalW;
    float effSat   = (wR * satRed + wY * satYellow + wG * satGreen +
                      wC * satCyan + wB * satBlue + wM * satMagenta) / totalW;

    // Split into luma + chroma; shape the chroma along the highlight path
    float luma = getLuma(workingColor);
    vec3 chroma = workingColor - vec3(luma);

    float gate = t * strength * satMask;

    // 1) Steer the hue in the highlights
    chroma = rotateHue(chroma, radians(effSteer) * gate);

    // 2) Hold / drop saturation for this band in the highlights
    chroma *= max(1.0 + effSat * gate, 0.0);

    // 3) Global path desaturation - pull residual chroma toward clean white
    chroma *= (1.0 - pathDesat * t);

    vec3 result = vec3(luma) + chroma;

    // Optionally keep the original luminance (shape color only, no brightness change)
    if (preserveLuma) {
        float newLuma = getLuma(result);
        result = result - vec3(newLuma) + vec3(luma);
    }

    result = fromPerceptual(result);

    // Highlight mask preview for dialing Pivot / Rolloff. Selected here rather
    // than by an early return - Matchbox breaks if main() returns before its
    // injected epilogue, so gl_FragColor is written exactly once at the end.
    if (outputMode == 1) {
        result = vec3(t);
    }

    gl_FragColor = vec4(result, texColor.a);
}
