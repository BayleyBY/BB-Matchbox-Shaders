// BB_SpectralFilter - apply a physically-modelled gel / filter spectrally.
//
// Reconstruct a plausible reflectance spectrum from the pixel's RGB, integrate it
// with and without the filter transmission T(lambda) against the CIE observer, and
// apply the per-XYZ ratio. Because the ratio cancels the reconstruction, a neutral
// filter (or Strength 0) is an EXACT identity - and different colours receive
// different treatment (true spectral behaviour a channel-mixer can't reproduce).
//
// All spectra are ANALYTIC functions of lambda evaluated inside a bounded loop -
// no arrays, no dynamic indexing (GLSL 1.20 safe).

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

uniform int   colorSpace;   // 0 Rec.709, 1 Scene-Linear, 2 ACEScg, 3 ACEScct, 4 ARRI LogC4
uniform int   filterType;   // 0 None, 1 CTB (cool), 2 CTO (warm), 3 Plus Green, 4 Minus Green
uniform float strength;     // 0..1 filter density
uniform float amount;       // blend with original

const int NW = 24;
const mat3 RGB2XYZ = mat3(0.4124,0.2126,0.0193, 0.3576,0.7152,0.1192, 0.1805,0.0722,0.9505);
const mat3 XYZ2RGB = mat3(3.240625,-0.968931,0.055710, -1.537208,1.875756,-0.204021, -0.498629,0.041518,1.056996);

float gau(float x, float mu, float s1, float s2){
   float s = (x < mu) ? s1 : s2;
   float d = (x-mu)/s;
   return exp(-0.5*d*d);
}
float xbar(float l){ return 1.056*gau(l,599.8,37.9,31.0)+0.362*gau(l,442.0,16.0,26.7)-0.065*gau(l,501.1,20.4,26.2); }
float ybar(float l){ return 0.821*gau(l,568.8,46.9,40.5)+0.286*gau(l,530.9,16.3,31.1); }
float zbar(float l){ return 1.217*gau(l,437.0,11.8,36.0)+0.681*gau(l,459.0,26.0,13.8); }
float bR(float l){ return exp(-0.5*pow((l-610.0)/55.0,2.0)); }
float bG(float l){ return exp(-0.5*pow((l-550.0)/45.0,2.0)); }
float bB(float l){ return exp(-0.5*pow((l-465.0)/40.0,2.0)); }

float filterT(float l, int f, float s){
   float Tf = 1.0;
   if      (f == 1) Tf = clamp(1.0 - 0.75*(l-400.0)/300.0, 0.15, 1.0);   // CTB (cool)
   else if (f == 2) Tf = clamp(0.25 + 0.75*(l-400.0)/300.0, 0.25, 1.0);  // CTO (warm)
   else if (f == 3) Tf = 0.5 + 0.5*exp(-pow((l-540.0)/60.0,2.0));        // Plus Green
   else if (f == 4) Tf = 1.0 - 0.5*exp(-pow((l-540.0)/60.0,2.0));        // Minus Green
   return 1.0 + (Tf - 1.0)*s;
}

// ACEScct log (AP1) <-> linear. max() guards log2 against NaN (mix evaluates both branches).
vec3 acescct2lin(vec3 c){ return mix((c - 0.0729055341958355) / 10.5402377416545, exp2(c * 17.52 - 9.72), step(0.155251141552511, c)); }
vec3 lin2acescct(vec3 c){ return mix(10.5402377416545 * c + 0.0729055341958355, (log2(max(c, 1e-10)) + 9.72) / 17.52, step(0.0078125, c)); }

// ARRI LogC4 (EI800, AWG4 primaries) <-> linear, constants folded from the 2022 spec.
vec3 logc42lin(vec3 c){ return mix(c * 0.1135972086 - 0.0180569961, (exp2(c * 15.4331897 + 4.5668103) - 64.0) / 2231.8263091, step(0.0, c)); }
vec3 lin2logc4(vec3 c){ return mix((c + 0.0180569961) / 0.1135972086, log2(max(c * 2231.8263091 + 64.0, 1e-6)) * 0.0647954196 - 0.2959083927, step(-0.0180569961, c)); }

// The spectral basis and RGB2XYZ/XYZ2RGB above are defined for Rec.709 primaries, so
// AP1 (ACEScg/ACEScct) and AWG4 (LogC4) inputs are matrix-converted to a Rec.709
// working space and restored with the exact inverse (Strength 0 stays an exact
// identity). The AP1 pair is Bradford-adapted D60->D65 so ACES neutrals stay neutral.
const mat3 AP1_TO_709   = mat3(1.7048666, -0.1302640, -0.0240109, -0.6216296, 1.1408072, -0.1289904, -0.0832368, -0.0105433, 1.1530014);
const mat3 M709_TO_AP1  = mat3(0.6131612, 0.0702049, 0.0206230, 0.3394696, 0.9163477, 0.1095845, 0.0473692, 0.0134475, 0.8697925);
const mat3 AWG4_TO_709  = mat3(1.8928226, -0.2057053, -0.0127088, -0.7807574, 1.3402885, -0.1522214, -0.1122241, -0.1345602, 1.1651702);
const mat3 M709_TO_AWG4 = mat3(0.5659265, 0.0886398, 0.0177529, 0.3403232, 0.8093282, 0.1094451, 0.0938100, 0.1020030, 0.8725929);

vec3 toLinear(vec3 c, int cs){
   vec3 lin = c;
   if (cs == 0) lin = sign(c)*pow(abs(c), vec3(2.4));
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
   if (cs == 0) c = sign(c)*pow(abs(c), vec3(1.0/2.4));
   if (cs == 3) c = lin2acescct(c);
   if (cs == 4) c = lin2logc4(c);
   return c;
}

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
   vec4 src = texture2D(front, uv);
   vec3 lin = toLinear(src.rgb, colorSpace);
   vec3 XYZin = RGB2XYZ * lin;

   vec3 den = vec3(0.0), num = vec3(0.0);
   for (int i = 0; i < NW; i++){
      float l = 400.0 + float(i)*(300.0/float(NW-1));
      float refl = lin.r*bR(l) + lin.g*bG(l) + lin.b*bB(l);
      float T = filterT(l, filterType, strength);
      vec3 cmf = vec3(xbar(l), ybar(l), zbar(l));
      den += refl * cmf;
      num += refl * T * cmf;
   }

   vec3 ratio  = num / max(den, vec3(1e-5));
   vec3 linOut = XYZ2RGB * (XYZin * ratio);

   vec3 outc = fromLinear(linOut, colorSpace);
   if (colorSpace == 0) outc = clamp(outc, 0.0, 1.0);
   outc = mix(src.rgb, outc, amount);
   gl_FragColor = vec4(outc, src.a);
}
