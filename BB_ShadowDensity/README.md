# BB_ShadowDensity v1.2 — Development Notes

Autodesk Flame 2026 Matchbox shader. Shadow density and saturation control for colour correction.
Files: `BB_ShadowDensity.glsl` + `BB_ShadowDensity.xml`

---

## Why use this?

Add spatially-consistent depth and density to shadows — a coordinated luminance pull-down and desaturation on a smooth shadow mask — without dragging down your midtones. It's a cleaner, more filmic way to weight shadows than a lift wheel or a keyed qualifier, and the lift and desaturation always stay in register.

---

## What It Does

Applies density (luminance pull-down) and desaturation independently within the shadow zone of an image. A smooth luminance mask isolates the affected region — full strength at black, fading smoothly to zero at a user-defined pivot — so midtones and highlights above the pivot are completely untouched. Both effects are driven by the same derived mask, ensuring lift and desat always track the same spatial region. Supports Rec.709, Scene-Linear, ACEScg, ACEScct, and ARRI LogC4 (AWG4) color spaces.

---

## Feature List

| Feature | Control location |
|---|---|
| Color space selection (Rec.709 / Scene-Linear / ACEScg / ACEScct / ARRI LogC4) | Shadow page — Density col |
| Shadow luminance pull-down | Shadow page — Density col |
| Luminance pivot (shadow zone boundary) | Shadow page — Density col |
| Shadow desaturation toward neutral grey | Shadow page — Saturation col |
| Smooth mask rolloff (no hard cutoff) | Automatic — smoothstep on luma |
| Per-space luminance coefficients (Rec.709, AP1, or AWG4) | Automatic |

---

## UI Structure

### Page 0 — Shadow
| Col | Name | Contents |
|---|---|---|
| 0 | Density | Color Space, Shadow Lift, Shadow Pivot |
| 1 | Saturation | Extra Desat |

**Color Space** (popup, default `Rec.709`) — sets luminance coefficients and whether a perceptual working space conversion is applied. Must match the color science of your Flame project.

| Value | Space | Primaries | Luma coefficients | Working space |
|---|---|---|---|---|
| Rec.709 | Gamma-encoded | Rec.709 | 0.2126 / 0.7152 / 0.0722 | Input space (no conversion) |
| Scene-Linear | Linear | Rec.709 | 0.2126 / 0.7152 / 0.0722 | Converted to/from γ2.4 |
| ACEScg | Linear | AP1 | 0.2722 / 0.6741 / 0.0537 | Converted to/from γ2.4 |
| ACEScct | Log | AP1 | 0.2722 / 0.6741 / 0.0537 | Input space (no conversion) |
| ARRI LogC4 | Log | AWG4 | 0.2545 / 0.7815 / −0.0360 | Input space (no conversion) |

**Shadow Lift** (`-1.0 → 0.0`, default `0.0`) — amount of luminance pull-down applied to the shadow zone. At `0.0` the shader is a pass-through. At `-1.0` the darkest pixels are pulled to black.

**Shadow Pivot** (`0.01 → 1.0`, default `0.35`) — the luminance level above which the effect has no influence. Pixels at or above this value are untouched. Lower values tighten the effect to only the deepest shadows; higher values bring the effect further up into the mid-tones.

**Extra Desat** (`0.0 → 1.0`, default `0.0`) — how aggressively saturation is reduced in the shadow zone. At `0.0` colours are preserved. At `1.0` the shadow zone is pulled to fully neutral grey. Operates independently of Shadow Lift — either can be used without the other.

---

## GLSL Architecture

**Coordinate system:** Standard Matchbox. `gl_FragCoord.xy` in pixel space, `adsk_result_w / adsk_result_h` for resolution. UV normalised to 0–1 for texture sampling.

### Color space helpers

```glsl
vec3 getLumaCoeff()         // returns REC709_LUMA, AP1_LUMA, or AWG4_LUMA based on colorSpace
vec3 toPerceptual(vec3 c)   // Scene-Linear / ACEScg → γ2.4; log/gamma spaces pass through
vec3 fromPerceptual(vec3 c) // γ2.4 → linear; pass through for non-linear spaces
```

`toPerceptual` uses `sign(c) * pow(abs(c), vec3(1.0/2.4))` rather than a plain `pow` so that out-of-gamut negative values (which are valid in ACEScg and Scene-Linear wide-gamut content) are handled without producing NaN.

All three stages operate on `working = toPerceptual(col)`. This means the Pivot slider always refers to a perceptual (gamma-like) luminance value regardless of whether the input is linear or log, keeping its behaviour numerically consistent across all five color spaces. `fromPerceptual` is applied after Stage 3 to restore the original encoding.

Rec.709 is clamped to `[0, 1]` after conversion back to prevent sub-black values from aggressive lift. The other four spaces are left unclamped to preserve HDR and wide-gamut headroom.

### Stage 1 — Luminance mask

```glsl
float lum = dot(working, lumaCoeff);
float safePivot = max(shadowPivot, 0.001);
float shadowMask = 1.0 - smoothstep(0.0, safePivot, lum);
```

`smoothstep` gives a smooth S-curve from 1.0 at black to 0.0 at the pivot. Inverting it means `shadowMask = 1.0` in the shadows and `shadowMask = 0.0` above the pivot. `safePivot` prevents undefined behaviour if the slider reaches zero.

This single mask value is reused for both the lift and the desat so both effects share an identical spatial boundary — there is no zone mismatch between them.

### Stage 2 — Shadow lift

```glsl
vec3 lifted = working + shadowLift * shadowMask;
```

Additive offset in perceptual working space. `shadowLift` is always `<= 0.0` (the XML slider caps at 0), so the operation can only reduce luminance. The mask tapers the effect to zero at the pivot, leaving highlights untouched.

### Stage 3 — Shadow desaturation

```glsl
float liftedLum = dot(lifted, lumaCoeff);
vec3 grey   = vec3(liftedLum);
vec3 result = mix(lifted, grey, shadowMask * shadowDesatAmount);
```

The neutral grey target is derived from the *post-lift* luminance rather than the original, so the greyscale value stays consistent with the already-lifted result. `mix()` blends between the lifted colour and neutral grey using the same spatial mask weighted by the user's desat amount. At `shadowDesatAmount = 0` this stage is a complete no-op.

---

## Typical Uses

**Film negative shadow density** — small negative Lift values (around `-0.05` to `-0.15`) with the Pivot at `0.2–0.3` add depth to shadows without touching skin or midtone detail. Equivalent to pulling the shadow node in a primary correction but with a softer spatial boundary.

**Desaturated shadows / teal-and-orange look** — leave Lift at `0.0` and bring Extra Desat up to `0.3–0.6`. Combined with a separate highlight warmth grade this creates the desaturated-shadow, saturated-highlight separation common in cinematic looks.

**Crushed blacks** — bring Pivot up to `0.4–0.5` and apply a moderate Lift (`-0.2` to `-0.4`). The wide pivot pulls a broader tonal range into the affected zone, crushing shadows and lower midtones aggressively while leaving highlights clean.

**Matching log-converted footage** — after a basic primary, add a gentle Lift (`-0.05`) with a narrow Pivot (`0.15`) to recover the blocked-up, slightly milky look that poorly converted log footage can have.

**Layered with BB_ColorDensity** — BB_ShadowDensity addresses the shadow zone specifically; BB_ColorDensity works per-colour-vector across the full tonal range. Stack both nodes to handle tonal density and per-hue density independently.

---

## Notes

- Set **Color Space** to match your Flame project's colour science before adjusting any other control. The Pivot value is always a perceptual luminance number (0–1 range, where 0 = black), but the underlying conversion differs per space — a pivot of `0.35` in Rec.709 and in Scene-Linear will isolate the same visible tonal region even though the raw values differ in linear encoding.
- `adsk_time` is not used — the shader has no animation.
- No input is required other than a standard front image connection. The node does not output a matte.
- The first four color spaces mirror the implementation of **BB_ColorDensity**: same popup values, same luma coefficients, same `sign()/abs()` perceptual conversion, same Rec.709-only clamp policy.
- **ARRI LogC4 / AWG4 luma coefficients** are taken from the second row of the AWG4-to-CIE XYZ matrix in the ARRI LogC4 specification (eq. 5a, January 2025 revision). The Blue coefficient is negative (−0.0360) because AWG4 extends its Blue primary beyond the spectral locus — this is colorimetrically correct for linear AWG4 scene-referred values. The three coefficients still sum to 1.0. In practice, the small negative Blue term has no visible effect in shadow regions, where channels are low and closely matched; it only becomes significant for highly saturated blue highlights, which are outside the shadow zone and masked out anyway.
