// BB_MelaninHemoglobin - separate skin into its two real pigment layers
// (melanin + haemoglobin) and grade them independently.
//
// Model: in linear light, optical density OD = -ln(rgb). Skin OD is well
// described by a shading term plus two pigment vectors:
//     OD = s*[1,1,1] + m*MEL + h*HEM
// The basis [1 | MEL | HEM] is inverted once (BINV, hardcoded) to recover
// (s, m, h) per pixel; the pigment amounts are scaled and OD recomposed.
// Identity when Melanin = Haemoglobin = Density = 0. Physiologically-motivated
// fixed pigment vectors (eumelanin ~lambda^-3.48; oxy-haemoglobin green-peaked)
// at R/G/B band centres - a plausible separation, not a per-image ICA.

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

uniform int   colorSpace;    // 0 Rec.709, 1 Scene-Linear, 2 ACEScg, 3 ACEScct, 4 ARRI LogC4
uniform float melAmount;     // melanin gain offset   (result *= 1+melAmount)
uniform float hemAmount;     // haemoglobin gain offset
uniform float densAmount;    // shading / overall density gain offset
uniform float mixAmount;     // blend with original
uniform int   outputMode;    // 0 Result, 1 Melanin map, 2 Haemoglobin map

// pigment density vectors at ~610/540/460 nm (linear Rec.709 RGB)
const vec3 MEL = vec3(0.375, 0.572, 1.000);
const vec3 HEM = vec3(0.150, 1.000, 0.550);

// inverse of [1 | MEL | HEM] (column-major): smh = BINV * OD
const mat3 BINV = mat3(1.514864, -0.994585, -0.945961, 0.124323, -0.884076, 1.381368, -0.639187, 1.878661, -0.435407);

// ACEScct log (AP1) <-> linear. max() guards log2 against NaN (mix evaluates both branches).
vec3 acescct2lin(vec3 c){ return mix((c - 0.0729055341958355) / 10.5402377416545, exp2(c * 17.52 - 9.72), step(0.155251141552511, c)); }
vec3 lin2acescct(vec3 c){ return mix(10.5402377416545 * c + 0.0729055341958355, (log2(max(c, 1e-10)) + 9.72) / 17.52, step(0.0078125, c)); }

// ARRI LogC4 (EI800, AWG4 primaries) <-> linear, constants folded from the 2022 spec.
vec3 logc42lin(vec3 c){ return mix(c * 0.1135972086 - 0.0180569961, (exp2(c * 15.4331897 + 4.5668103) - 64.0) / 2231.8263091, step(0.0, c)); }
vec3 lin2logc4(vec3 c){ return mix((c + 0.0180569961) / 0.1135972086, log2(max(c * 2231.8263091 + 64.0, 1e-6)) * 0.0647954196 - 0.2959083927, step(-0.0180569961, c)); }

// MEL/HEM pigment vectors are defined in linear Rec.709 RGB, so AP1 (ACEScg/ACEScct)
// and AWG4 (LogC4) inputs are matrix-converted to a Rec.709 working space and restored
// with the exact inverse (identity at default is preserved). The AP1 pair is
// Bradford-adapted D60->D65 so ACES neutrals stay neutral in the working space.
const mat3 AP1_TO_709   = mat3(1.7048666, -0.1302640, -0.0240109, -0.6216296, 1.1408072, -0.1289904, -0.0832368, -0.0105433, 1.1530014);
const mat3 M709_TO_AP1  = mat3(0.6131612, 0.0702049, 0.0206230, 0.3394696, 0.9163477, 0.1095845, 0.0473692, 0.0134475, 0.8697925);
const mat3 AWG4_TO_709  = mat3(1.8928226, -0.2057053, -0.0127088, -0.7807574, 1.3402885, -0.1522214, -0.1122241, -0.1345602, 1.1651702);
const mat3 M709_TO_AWG4 = mat3(0.5659265, 0.0886398, 0.0177529, 0.3403232, 0.8093282, 0.1094451, 0.0938100, 0.1020030, 0.8725929);

vec3 toLinear(vec3 c, int cs){
   vec3 lin = c;                                                 // Scene-Linear / ACEScg
   if (cs == 0) lin = sign(c) * pow(abs(c), vec3(2.4));          // Rec.709 -> linear
   if (cs == 3) lin = acescct2lin(c);
   if (cs == 4) lin = logc42lin(c);
   if (cs == 2 || cs == 3) lin = AP1_TO_709 * lin;
   if (cs == 4) lin = AWG4_TO_709 * lin;
   return lin;
}
vec3 fromLinear(vec3 lin, int cs){
   vec3 c = lin;
   if (cs == 2 || cs == 3) c = M709_TO_AP1 * c;
   if (cs == 4) c = M709_TO_AWG4 * c;
   if (cs == 0) c = sign(c) * pow(abs(c), vec3(1.0/2.4));
   if (cs == 3) c = lin2acescct(c);
   if (cs == 4) c = lin2logc4(c);
   return c;
}

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
   vec4 src = texture2D(front, uv);

   vec3 lin = toLinear(src.rgb, colorSpace);
   vec3 OD  = -log(max(lin, vec3(1e-4)));

   vec3 smh = BINV * OD;                 // shading, melanin, haemoglobin
   float s = smh.x, m = smh.y, h = smh.z;

   vec3 outCol;
   if (outputMode == 1) {                // melanin map
      outCol = vec3(clamp(m * 0.5, 0.0, 1.0));
   } else if (outputMode == 2) {         // haemoglobin map
      outCol = vec3(clamp(h * 1.4, 0.0, 1.0));
   } else {                              // graded result
      float s2 = s * (1.0 + densAmount);
      float m2 = m * (1.0 + melAmount);
      float h2 = h * (1.0 + hemAmount);
      vec3 ODp    = vec3(s2) + m2 * MEL + h2 * HEM;
      vec3 outLin = exp(-ODp);
      outCol = fromLinear(outLin, colorSpace);
      if (colorSpace == 0) outCol = clamp(outCol, 0.0, 1.0);   // display-referred clamp
      outCol = mix(src.rgb, outCol, mixAmount);
   }

   gl_FragColor = vec4(outCol, src.a);
}
