// BB_ShadowDensity
// Shadow density and saturation control for Autodesk Flame 2026.
//
// Isolates the shadow region via a smooth luminance mask — full strength
// at black, rolling off to zero at shadowPivot — then applies two
// independent effects within that zone:
//   1. Luminance pull-down  (shadow density / lift)
//   2. Saturation reduction toward neutral grey
//
// Both effects are driven by the same derived mask so lift and desat
// are always spatially consistent. Single-pass, no dependencies.
//
// Color space handling:
//   0 = Rec.709      — gamma-encoded, Rec.709 primaries. Operations in input space.
//   1 = Scene-Linear — linear, Rec.709 primaries. Converted to γ2.4 for operations.
//   2 = ACEScg       — linear, AP1 primaries. Converted to γ2.4 for operations.
//   3 = ACEScct      — log, AP1 primaries. Operations in input space.
//   4 = ARRI LogC4   — log, AWG4 primaries. Operations in input space.

uniform sampler2D inputTexture;
uniform float adsk_result_w, adsk_result_h;

// 0=Rec.709  1=Scene-Linear  2=ACEScg  3=ACEScct  4=ARRI LogC4
uniform int   colorSpace;

uniform float shadowLift;         // pull-down strength: -1.0 (max) to 0.0 (off)
uniform float shadowPivot;        // luminance above which the effect has no influence
uniform float shadowDesatAmount;  // saturation reduction in shadow zone: 0.0–1.0

// Rec.709 primaries luminance coefficients
const vec3 REC709_LUMA = vec3(0.2126, 0.7152, 0.0722);
// AP1 primaries luminance coefficients (ACEScg, ACEScct)
const vec3 AP1_LUMA    = vec3(0.2722, 0.6741, 0.0537);
// ARRI Wide Gamut 4 luminance coefficients — second row of the AWG4-to-XYZ matrix
// (ARRI LogC4 spec eq. 5a). Blue is negative because AWG4 extends beyond the
// spectral locus; the coefficients still sum to 1.0 and are correct for linear AWG4.
const vec3 AWG4_LUMA   = vec3(0.2545, 0.7815, -0.0360);

// Return the correct luma weights for the active color space.
vec3 getLumaCoeff() {
    if (colorSpace == 2 || colorSpace == 3) {
        return AP1_LUMA;
    }
    if (colorSpace == 4) {
        return AWG4_LUMA;
    }
    return REC709_LUMA;
}

// Convert Scene-Linear / ACEScg to a perceptual working space (γ2.4).
// sign()/abs() handles out-of-gamut negative values without producing NaN.
// Rec.709 and ACEScct are already perceptual — pass through unchanged.
vec3 toPerceptual(vec3 c) {
    if (colorSpace == 1 || colorSpace == 2) {
        return sign(c) * pow(abs(c), vec3(1.0 / 2.4));
    }
    return c;
}

// Inverse of toPerceptual — only active for linear input spaces.
vec3 fromPerceptual(vec3 c) {
    if (colorSpace == 1 || colorSpace == 2) {
        return sign(c) * pow(abs(c), vec3(2.4));
    }
    return c;
}

void main() {
    vec2 resolution = vec2(adsk_result_w, adsk_result_h);
    vec2 uv = gl_FragCoord.xy / resolution;

    vec3 col = texture2D(inputTexture, uv).rgb;

    // Convert to perceptual working space so the pivot and lift values
    // are numerically consistent across all four color spaces. Linear
    // inputs (Scene-Linear, ACEScg) are gamma-encoded to γ2.4; Rec.709
    // and ACEScct pass through unchanged as they are already perceptual.
    vec3 working = toPerceptual(col);

    vec3 lumaCoeff = getLumaCoeff();

    // ----------------------------------------------------------------
    // Stage 1 — Luminance mask
    //
    // Compute the perceptual luminance of the working-space pixel.
    // This single value drives both the lift and the desaturation,
    // keeping them spatially locked to identical regions.
    // ----------------------------------------------------------------

    float lum = dot(working, lumaCoeff);

    // Shadow mask: 1.0 at black, smooth S-curve rolloff to 0.0 at the
    // pivot. No hard cutoff — smoothstep guarantees a continuous edge.
    // safePivot guards against undefined smoothstep behaviour at 0.
    float safePivot = max(shadowPivot, 0.001);
    float shadowMask = 1.0 - smoothstep(0.0, safePivot, lum);

    // ----------------------------------------------------------------
    // Stage 2 — Shadow lift
    //
    // Additive offset in perceptual space. shadowLift is always <= 0.0
    // so this only reduces luminance. Full strength at black, zero
    // effect at or above the pivot.
    // ----------------------------------------------------------------

    vec3 lifted = working + shadowLift * shadowMask;

    // ----------------------------------------------------------------
    // Stage 3 — Shadow desaturation
    //
    // Grey target is derived from the post-lift luminance so the neutral
    // point stays consistent with the already-lifted result. Mix toward
    // grey using the same spatial mask weighted by the desat strength.
    // At shadowDesatAmount = 0 this stage is a no-op.
    // ----------------------------------------------------------------

    float liftedLum = dot(lifted, lumaCoeff);
    vec3 grey   = vec3(liftedLum);
    vec3 result = mix(lifted, grey, shadowMask * shadowDesatAmount);

    // Convert from perceptual working space back to the input color space.
    result = fromPerceptual(result);

    // Rec.709 is a closed [0,1] domain — clamp to prevent sub-black values
    // from aggressive lift. Other spaces are HDR / wide-gamut safe and
    // are left unclamped.
    if (colorSpace == 0) {
        result = clamp(result, 0.0, 1.0);
    }

    gl_FragColor = vec4(result, 1.0);
}
