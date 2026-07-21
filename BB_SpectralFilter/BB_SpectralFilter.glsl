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

uniform int   colorSpace;   // 0 Rec.709 (gamma), 1 Scene-Linear
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

vec3 toLinear(vec3 c, int cs){ if(cs==0) return sign(c)*pow(abs(c), vec3(2.4)); return c; }
vec3 fromLinear(vec3 c, int cs){ if(cs==0) return sign(c)*pow(abs(c), vec3(1.0/2.4)); return c; }

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
