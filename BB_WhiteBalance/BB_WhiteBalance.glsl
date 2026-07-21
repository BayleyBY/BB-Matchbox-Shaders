// White Balance Shader (dual-illuminant)
// Physically-based white balance using a Bradford chromatic adaptation transform
// (CAT) in linear light, NOT naive channel gains. Temperature + Tint drive a
// Planckian illuminant white point; the image is adapted from that white toward
// the working neutral.
//
// Dual-illuminant mode runs two independent white balances - one for shadows, one
// for highlights - blended by a luminance mask, to fix MIXED lighting (e.g. tungsten
// practicals under a daylight window) in a single node.

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

// 0 = Rec.709 (sRGB gamma), 1 = Scene-Linear (Rec.709 primaries),
// 2 = ACEScg (AP1 linear), 3 = ACEScct (AP1 log), 4 = ARRI LogC4 (AWG4 log)
uniform int colorSpace;

uniform float temp;        // global temperature: + warms, - cools
uniform float tint;        // global tint: + magenta, - green
uniform float strength;    // mix with original (0..1)

uniform bool  dualEnable;  // independent shadow / highlight white balance
uniform float splitPivot;  // luminance split point
uniform float splitSoftness;
uniform float shadowTemp, shadowTint;   // offsets added to global in shadows
uniform float highTemp,   highTint;     // offsets added to global in highlights

uniform bool  pickerEnable;   // balance so a sampled colour reads neutral
uniform vec3  pickerColor;    // sampled colour that should be neutral (swatch eyedropper)

// --- Bradford cone-response matrix and per-space primaries transforms ---
// A: working RGB -> Bradford cone.  B: cone -> working RGB.  (B*A == identity)
const mat3 Ma     = mat3(0.8951000, -0.7502000, 0.0389000, 0.2664000, 1.7135000, -0.0685000, -0.1614000, 0.0367000, 1.0296000);
const mat3 A_SRGB = mat3(0.4226580, 0.0556908, 0.0213792, 0.4913566, 0.9615563, 0.0876439, 0.0273645, 0.0231893, 0.9807435);
const mat3 B_SRGB = mat3(2.5384479, -0.1460003, -0.0422883, -1.2934823, 1.1166223, -0.0715901, -0.0402433, -0.0223285, 1.0225073);
const mat3 A_AP1  = mat3(0.6663842, -0.0307139, 0.0013822, 0.2988672, 1.0546582, -0.0367809, -0.0089622, 0.0119044, 1.0426431);
const mat3 B_AP1  = mat3(1.4812806, 0.0431430, -0.0004417, -0.4191517, 0.9355891, 0.0335601, 0.0175183, -0.0103113, 0.9587140);
const mat3 A_AWG4 = mat3(0.6987239, -0.0926575, 0.0099841, 0.3243341, 1.2417159, -0.0484835, -0.0816789, -0.1086220, 1.1282661);
const mat3 B_AWG4 = mat3(1.3826901, 0.1024921, -0.0078312, -0.3585960, 0.7817949, 0.0367683, 0.0655742, 0.0826858, 0.8892886);

vec3 srgb2lin(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}
vec3 lin2srgb(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}

// ACEScct log encoding (AP1 primaries) <-> linear. max() guards log2 against NaN
// (mix evaluates both branches, and NaN*0 would poison the linear-segment result).
vec3 acescct2lin(vec3 c) {
    return mix((c - 0.0729055341958355) / 10.5402377416545,
               exp2(c * 17.52 - 9.72),
               step(0.155251141552511, c));
}
vec3 lin2acescct(vec3 c) {
    return mix(10.5402377416545 * c + 0.0729055341958355,
               (log2(max(c, 1e-10)) + 9.72) / 17.52,
               step(0.0078125, c));
}

// ARRI LogC4 (EI800, AWG4 primaries) <-> linear. Constants folded from the 2022
// spec (a=(2^18-16)/117.45, b=928/1023, c=95/1023) with a linear extension below
// t. max() guards log2 against NaN for the same reason as lin2acescct above.
vec3 logc42lin(vec3 c) {
    return mix(c * 0.1135972086 - 0.0180569961,
               (exp2(c * 15.4331897 + 4.5668103) - 64.0) / 2231.8263091,
               step(0.0, c));
}
vec3 lin2logc4(vec3 c) {
    return mix((c + 0.0180569961) / 0.1135972086,
               log2(max(c * 2231.8263091 + 64.0, 1e-6)) * 0.0647954196 - 0.2959083927,
               step(-0.0180569961, c));
}

// Planckian locus: correlated colour temperature -> CIE xy (Kim et al. approximation)
vec2 kelvinToXY(float K) {
    float K2 = K * K, K3 = K2 * K;
    float xc = (K < 4000.0)
        ? (-0.2661239e9 / K3 - 0.2343589e6 / K2 + 0.8776956e3 / K + 0.179910)
        : (-3.0258469e9 / K3 + 2.1070379e6 / K2 + 0.2226347e3 / K + 0.240390);
    float x2 = xc * xc, x3 = x2 * xc;
    float yc;
    if (K < 2222.0)      yc = -1.1063814 * x3 - 1.34811020 * x2 + 2.18555832 * xc - 0.20219683;
    else if (K < 4000.0) yc = -0.9549476 * x3 - 1.37418593 * x2 + 2.09137015 * xc - 0.16748867;
    else                 yc =  3.0817580 * x3 - 5.87338670 * x2 + 3.75112997 * xc - 0.37001483;
    return vec2(xc, yc);
}

// Temperature/tint sliders -> illuminant white point in XYZ (Y = 1)
vec3 whiteXYZ(float tempS, float tintS) {
    float K = clamp(6500.0 * pow(2.0, (tempS / 100.0) * 1.2), 1667.0, 25000.0);
    vec2 xy = kelvinToXY(K);
    xy.y += (tintS / 100.0) * 0.05;   // + green source => + magenta result
    return vec3(xy.x / xy.y, 1.0, (1.0 - xy.x - xy.y) / xy.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec4 tex = texture2D(front, uv);
    vec3 c = tex.rgb;

    vec3 lin = (colorSpace == 0) ? srgb2lin(c)
             : (colorSpace == 3) ? acescct2lin(c)
             : (colorSpace == 4) ? logc42lin(c)
             : c;

    mat3 A, B; vec3 lumaCoeff;
    if      (colorSpace == 2 || colorSpace == 3) { A = A_AP1;  B = B_AP1;  lumaCoeff = vec3(0.2722, 0.6741, 0.0537); }
    else if (colorSpace == 4)                    { A = A_AWG4; B = B_AWG4; lumaCoeff = vec3(0.2545, 0.7815, -0.0360); }
    else                                         { A = A_SRGB; B = B_SRGB; lumaCoeff = vec3(0.2126, 0.7152, 0.0722); }

    // Destination = working neutral (temp=0, tint=0) -> guarantees identity at default
    vec3 coneDst = Ma * whiteXYZ(0.0, 0.0);

    // Neutral sampler: take the sampled colour and build a chromatic adaptation that maps
    // it to neutral RGB. Composes with Temperature/Tint (both are diagonal in the same
    // Bradford cone space, so they multiply). Sampling white (default) is an exact identity.
    vec3 Rpick = vec3(1.0);
    if (pickerEnable) {
        vec3 sl = (colorSpace == 0) ? srgb2lin(pickerColor)
                : (colorSpace == 3) ? acescct2lin(pickerColor)
                : (colorSpace == 4) ? logc42lin(pickerColor)
                : pickerColor;
        sl /= max(dot(sl, lumaCoeff), 1e-5);   // unit luma => chroma-only (no exposure shift)
        Rpick = (A * vec3(1.0)) / (A * sl);    // map the sampled colour to neutral (R=G=B)
    }

    vec3 D;
    if (dualEnable) {
        vec3 Dsh = Rpick * coneDst / (Ma * whiteXYZ(temp + shadowTemp, tint + shadowTint));
        vec3 Dhi = Rpick * coneDst / (Ma * whiteXYZ(temp + highTemp,   tint + highTint));
        float l = dot(clamp(lin, 0.0, 1.0), lumaCoeff);
        float m = smoothstep(splitPivot - splitSoftness, splitPivot + splitSoftness, l);
        D = mix(Dsh, Dhi, m);
    } else {
        D = Rpick * coneDst / (Ma * whiteXYZ(temp, tint));
    }

    vec3 cone = A * lin;
    vec3 outLin = B * (D * cone);

    outLin = mix(lin, outLin, strength);

    vec3 outc = (colorSpace == 0) ? lin2srgb(outLin)
              : (colorSpace == 3) ? lin2acescct(outLin)
              : (colorSpace == 4) ? lin2logc4(outLin)
              : outLin;
    gl_FragColor = vec4(outc, tex.a);
}
