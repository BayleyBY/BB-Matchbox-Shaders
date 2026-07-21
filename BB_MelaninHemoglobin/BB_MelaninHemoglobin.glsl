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

uniform int   colorSpace;    // 0 = Rec.709 (gamma), 1 = Scene-Linear
uniform float melAmount;     // melanin gain offset   (result *= 1+melAmount)
uniform float hemAmount;     // haemoglobin gain offset
uniform float densAmount;    // shading / overall density gain offset
uniform float mixAmount;     // blend with original
uniform int   outputMode;    // 0 Result, 1 Melanin map, 2 Haemoglobin map

// pigment density vectors at ~610/540/460 nm (linear Rec.709 RGB)
const vec3 MEL = vec3(0.375, 0.572, 1.000);
const vec3 HEM = vec3(0.150, 1.000, 0.550);
const vec3 ONE = vec3(1.0);

// inverse of [ONE | MEL | HEM] (column-major): smh = BINV * OD
const mat3 BINV = mat3( 1.514864, -0.994585, -0.945961,
                        0.124323, -0.884076,  1.381368,
                       -0.639187,  1.878661, -0.435407 );

vec3 toLinear(vec3 c, int cs){
   if (cs == 0) return sign(c) * pow(abs(c), vec3(2.4));   // Rec.709 -> linear
   return c;                                               // Scene-Linear
}
vec3 fromLinear(vec3 c, int cs){
   if (cs == 0) return sign(c) * pow(abs(c), vec3(1.0/2.4));
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

   // visualisation of the isolated pigment maps
   if (outputMode == 1) { gl_FragColor = vec4(vec3(clamp(m * 0.5, 0.0, 1.0)), src.a); return; }
   if (outputMode == 2) { gl_FragColor = vec4(vec3(clamp(h * 1.4, 0.0, 1.0)), src.a); return; }

   float s2 = s * (1.0 + densAmount);
   float m2 = m * (1.0 + melAmount);
   float h2 = h * (1.0 + hemAmount);

   vec3 ODp    = s2 * ONE + m2 * MEL + h2 * HEM;
   vec3 outLin = exp(-ODp);

   vec3 outCol = fromLinear(outLin, colorSpace);
   if (colorSpace == 0) outCol = clamp(outCol, 0.0, 1.0);   // display-referred clamp

   outCol = mix(src.rgb, outCol, mixAmount);
   gl_FragColor = vec4(outCol, src.a);
}
