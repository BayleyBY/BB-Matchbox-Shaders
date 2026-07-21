// BB_ViewingCondition - re-render an image so it *looks the same* in a different
// viewing environment, using the CAM16 colour appearance model.
//
// forward(source VC) -> perceptual correlates (J lightness, C chroma, h hue)
// -> inverse(target VC). Holding the appearance constant while the viewing
// condition changes reproduces the Hunt effect (colourfulness rises with
// luminance), the Stevens effect (contrast rises with luminance) and the
// surround effect automatically. Same Source and Target = exact identity.
//
// Full chromatic adaptation (D = 1, discount-the-illuminant) so neutrals are
// preserved across conditions. Working white is D65; AP1/AWG4 inputs are
// matrix-converted to the Rec.709/D65 working space and restored losslessly.
// All scalar/vec math - no arrays (GLSL 1.20 safe).

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

uniform int   colorSpace;   // 0 Rec.709, 1 Scene-Linear, 2 ACEScg, 3 ACEScct, 4 ARRI LogC4
uniform int   srcVC;        // source viewing condition (where it looks right now)
uniform int   tgtVC;        // target viewing condition (where it will be seen)
uniform float amount;       // blend with original

// --- fixed matrices (column-major = numpy columns) ---
const mat3 M16     = mat3( 0.401288,-0.250268,-0.002079,  0.650173, 1.204414, 0.048952, -0.051461, 0.045854, 0.953127);
const mat3 M16i    = mat3( 1.862068, 0.387527,-0.015841, -1.011255, 0.621447,-0.034123,  0.149187,-0.008974, 1.049964);
const mat3 RGB2XYZ = mat3( 0.4124,   0.2126,   0.0193,     0.3576,   0.7152,   0.1192,     0.1805,   0.0722,   0.9505);
const mat3 XYZ2RGB = mat3( 3.240625,-0.968931, 0.055710,  -1.537208, 1.875756,-0.204021,  -0.498629, 0.041518, 1.056996);

// shared VC constants (n=0.2, Yb=20, D65, D=1)
const vec3  DR     = vec3(1.025056, 0.983798, 0.921717);
const float Z      = 1.927214;
const float NBB    = 1.000304;   // = Ncb
const float CHROMA = 0.895225;   // (1.64 - 0.29^n)^0.73

float spow(float x, float p){ return sign(x)*pow(abs(x), p); }
vec3  spow3(vec3 x, float p){ return sign(x)*pow(abs(x), vec3(p)); }

// ACEScct log (AP1) <-> linear. max() guards log2 against NaN (mix evaluates both branches).
vec3 acescct2lin(vec3 c){ return mix((c - 0.0729055341958355) / 10.5402377416545, exp2(c * 17.52 - 9.72), step(0.155251141552511, c)); }
vec3 lin2acescct(vec3 c){ return mix(10.5402377416545 * c + 0.0729055341958355, (log2(max(c, 1e-10)) + 9.72) / 17.52, step(0.0078125, c)); }

// ARRI LogC4 (EI800, AWG4 primaries) <-> linear, constants folded from the 2022 spec.
vec3 logc42lin(vec3 c){ return mix(c * 0.1135972086 - 0.0180569961, (exp2(c * 15.4331897 + 4.5668103) - 64.0) / 2231.8263091, step(0.0, c)); }
vec3 lin2logc4(vec3 c){ return mix((c + 0.0180569961) / 0.1135972086, log2(max(c * 2231.8263091 + 64.0, 1e-6)) * 0.0647954196 - 0.2959083927, step(-0.0180569961, c)); }

// RGB2XYZ above assumes Rec.709 primaries (D65), so AP1 (ACEScg/ACEScct) and AWG4
// (LogC4) inputs are matrix-converted to a Rec.709 working space and restored with
// the exact inverse (Source == Target stays an exact identity). The AP1 pair is
// Bradford-adapted D60->D65 so ACES neutrals stay neutral at the model's D65 white.
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

// viewing-condition params: (FL, Nc, c, Aw)
vec4 getVC(int i){
   if(i==0) return vec4(0.368405, 0.800, 0.525, 28.873523);  // Cinema (dark)
   if(i==1) return vec4(0.736806, 0.900, 0.590, 38.324212);  // TV / dim
   if(i==2) return vec4(1.000000, 1.000, 0.690, 43.383252);  // Average / grading
   if(i==3) return vec4(1.357209, 1.000, 0.690, 49.082388);  // Bright / phone
   return       vec4(1.259921, 0.900, 0.590, 47.631675);     // HDR
}

// XYZ (0..100) -> (J, C, h)
vec3 cam16_forward(vec3 XYZ, vec4 vc){
   float FL=vc.x, Nc=vc.y, c=vc.z, Aw=vc.w;
   vec3 RGBc = DR * (M16 * XYZ);
   vec3 t_   = spow3(FL*RGBc/100.0, 0.42);
   vec3 RGBa = 400.0*t_/(27.13+abs(t_)) + 0.1;
   float Ra=RGBa.r, Ga=RGBa.g, Ba=RGBa.b;
   float a = Ra - 12.0*Ga/11.0 + Ba/11.0;
   float b = (Ra + Ga - 2.0*Ba)/9.0;
   float h = atan(b, a);
   float et = 0.25*(cos(h+2.0)+3.8);
   float A = (2.0*Ra + Ga + Ba/20.0 - 0.305)*NBB;
   float J = 100.0*spow(A/Aw, c*Z);
   float tt = (50000.0/13.0*Nc*NBB*et*sqrt(a*a+b*b))/(Ra+Ga+1.05*Ba+1e-12);
   float C = spow(tt, 0.9)*sqrt(abs(J)/100.0)*CHROMA;
   return vec3(J, C, h);
}

// (J, C, h) -> XYZ (0..100)
vec3 cam16_inverse(vec3 JCh, vec4 vc){
   float FL=vc.x, Nc=vc.y, c=vc.z, Aw=vc.w;
   float J=JCh.x, C=JCh.y, h=JCh.z;
   float tt = pow(C/(sqrt(abs(J)/100.0)*CHROMA + 1e-12), 1.0/0.9);
   float et = 0.25*(cos(h+2.0)+3.8);
   float A  = Aw*spow(J/100.0, 1.0/(c*Z));
   float p1 = (50000.0/13.0*Nc*NBB)*et/max(tt, 1e-12);
   float p2 = A/NBB + 0.305;
   float sh=sin(h), ch=cos(h), p3=21.0/20.0;
   float a, b;
   if(abs(sh) >= abs(ch)){
      float ss = (sh==0.0)?1e-12:sh;
      float p4 = p1/ss;
      b = (p2*(2.0+p3)*(460.0/1403.0)) /
          (p4 + (2.0+p3)*(220.0/1403.0)*(ch/ss) - (27.0/1403.0) + p3*(6300.0/1403.0));
      a = b*(ch/ss);
   } else {
      float cc = (ch==0.0)?1e-12:ch;
      float p5 = p1/cc;
      a = (p2*(2.0+p3)*(460.0/1403.0)) /
          (p5 + (2.0+p3)*(220.0/1403.0) - ((27.0/1403.0) - p3*(6300.0/1403.0))*(sh/cc));
      b = a*(sh/cc);
   }
   if(tt <= 0.0){ a=0.0; b=0.0; }
   float Ra=(460.0*p2 + 451.0*a + 288.0*b)/1403.0;
   float Ga=(460.0*p2 - 891.0*a - 261.0*b)/1403.0;
   float Ba=(460.0*p2 - 220.0*a - 6300.0*b)/1403.0;
   vec3 RGBa = vec3(Ra, Ga, Ba);
   vec3 base = abs(RGBa - 0.1);
   vec3 RGBc = sign(RGBa-0.1)*(100.0/FL)*pow(27.13*base/max(400.0-base, 1e-9), vec3(1.0/0.42));
   return M16i * (RGBc/DR);
}

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
   vec4 src = texture2D(front, uv);

   vec3 lin = toLinear(src.rgb, colorSpace);
   vec3 XYZ = RGB2XYZ * (lin*100.0);

   vec3 JCh  = cam16_forward(XYZ, getVC(srcVC));
   vec3 XYZo = cam16_inverse(JCh, getVC(tgtVC));

   vec3 linOut = (XYZ2RGB * XYZo)/100.0;
   vec3 outc   = fromLinear(linOut, colorSpace);
   if(colorSpace == 0) outc = clamp(outc, 0.0, 1.0);

   outc = mix(src.rgb, outc, amount);
   gl_FragColor = vec4(outc, src.a);
}
