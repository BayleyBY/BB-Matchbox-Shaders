// BB_ColorDiagnostics - physically-based analysis overlays for grading.
// Per-pixel diagnostics Flame's scopes don't show: exposure false-colour,
// clipping zebras, out-of-gamut / sub-black flags, saturation heat, and a
// luminance view. Mode "Off" is a pass-through (identity at default).

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

uniform int   colorSpace;   // 0 Rec.709, 1 Scene-Linear, 2 ACEScg, 3 ACEScct, 4 ARRI LogC4
uniform int   mode;         // 0 Off, 1 Exposure, 2 Clipping, 3 Out-of-Gamut, 4 Saturation, 5 Luminance
uniform float highThresh;   // upper limit (clip / over)
uniform float lowThresh;    // lower limit (crush / under)
uniform bool  desatContext; // dim unflagged pixels so flags pop (gamut/clip modes)

const vec3 REC709 = vec3(0.2126, 0.7152, 0.0722);
const vec3 AP1    = vec3(0.2722, 0.6741, 0.0537);
// AWG4 (ARRI LogC4): negative blue per ARRI spec, sums to 1.0
const vec3 AWG4   = vec3(0.2545, 0.7815, -0.0360);

vec3 lumaCoeff(int cs){ if (cs == 4) return AWG4; return (cs >= 2) ? AP1 : REC709; }

// small discrete-band false colour by scalar t in [0,1]
vec3 falseColour(float t){
   if (t < lowThresh + 0.02)          return vec3(0.45, 0.0, 0.65);   // black clip - purple
   if (t < 0.045)                     return vec3(0.15, 0.25, 0.9);   // deep shadow - blue
   if (t > 0.38 && t < 0.42)          return vec3(0.1, 0.85, 0.25);   // 18% grey - green
   if (t > 0.52 && t < 0.56)          return vec3(0.95, 0.5, 0.7);    // skin / key+1 - pink
   if (t > 0.90 && t < highThresh-0.01) return vec3(0.95, 0.85, 0.2); // near clip - yellow
   if (t >= highThresh - 0.01)        return vec3(0.95, 0.1, 0.1);    // clip - red
   return vec3(t);                                                    // in-range - greyscale
}

vec3 heat(float t){   // blue -> cyan -> green -> yellow -> red
   t = clamp(t, 0.0, 1.0);
   return clamp(vec3(1.5 - abs(4.0*t - 3.0),
                     1.5 - abs(4.0*t - 2.0),
                     1.5 - abs(4.0*t - 1.0)), 0.0, 1.0);
}

void main()
{
   vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
   vec4 src = texture2D(front, uv);
   vec3 c = src.rgb;
   float L = dot(c, lumaCoeff(colorSpace));

   vec3 outc = c;

   if (mode == 1) {                 // exposure false colour
      outc = falseColour(L);
   }
   else if (mode == 2) {            // clipping zebra
      float stripe = step(8.0, mod(gl_FragCoord.x + gl_FragCoord.y, 16.0));
      vec3 ctx = desatContext ? vec3(L*0.6) : c;
      if (L >= highThresh)      outc = mix(ctx, vec3(1.0, 0.1, 0.1), stripe);
      else if (L <= lowThresh)  outc = mix(ctx, vec3(0.2, 0.4, 1.0), stripe);
      else                      outc = ctx;
   }
   else if (mode == 3) {            // out-of-gamut / sub-black / super-white
      bool over  = any(greaterThan(c, vec3(highThresh)));
      bool under = any(lessThan(c, vec3(lowThresh)));
      vec3 ctx = desatContext ? vec3(L*0.55) : c;
      if (under)     outc = vec3(1.0, 0.15, 0.9);   // sub-black / negative - magenta
      else if (over) outc = vec3(0.15, 0.95, 1.0);  // super-white / over - cyan
      else           outc = ctx;
   }
   else if (mode == 4) {            // saturation heat
      float mx = max(max(c.r, c.g), c.b);
      float mn = min(min(c.r, c.g), c.b);
      float sat = (mx > 1e-4) ? (mx - mn)/mx : 0.0;
      outc = heat(sat);
   }
   else if (mode == 5) {            // luminance
      outc = vec3(L);
   }

   gl_FragColor = vec4(outc, src.a);
}
