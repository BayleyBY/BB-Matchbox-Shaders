# BB_MelaninHemoglobin v1.0

Autodesk Flame Matchbox shader. Separates **skin** into its two real pigment layers —
**melanin** and **haemoglobin** — and lets you grade each independently.
Files: `BB_MelaninHemoglobin.glsl` + `BB_MelaninHemoglobin.xml`

---

## Why use this?

Adjust a face's **tan** and its **blood/ruddiness** as separate dials — calm a red flush without draining the tan, or deepen a tan without pushing the shot orange. Ordinary hue/sat and skin-tone tools can't do this because in RGB the two pigments are tangled together; this untangles them the way skin physically works. No dedicated tool for it exists in Flame or Resolve.

---

## What It Does

Human skin colour is, to a good approximation, produced by just two pigments over a
shading (brightness) term:

- **Melanin** — the brown pigment; sets tan and overall depth. Absorbs broadly, rising
  toward blue.
- **Haemoglobin** — the blood pigment; sets redness/flush. Absorbs in the green, so it
  lets red through (skin's ruddiness).

Working in **optical density** (`OD = -ln(linear RGB)`), skin sits on a plane spanned by
those two pigment vectors plus a neutral shading axis:

```
OD  =  s·[1,1,1]  +  m·MELANIN  +  h·HAEMOGLOBIN
```

The shader inverts that basis per pixel to recover the shading, melanin and haemoglobin
amounts `(s, m, h)`, scales the pigment amounts you ask for, and recomposes. Because the
basis is a true inverse, **Melanin = Haemoglobin = Density = 0 is an exact identity**.

View the isolated **Melanin Map** or **Haemoglobin Map** to see the separation directly.

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Setup | Rec.709 or Scene-Linear — the separation runs in linear light |
| Amount | Setup | Blend the result with the original |
| Output | Setup | Result, or the isolated Melanin / Haemoglobin map |
| Melanin | Pigments | − lightens / lifts tan, + deepens the brown pigment |
| Haemoglobin | Pigments | − calms redness, + adds blood flush |
| Density | Pigments | The shading term (overall skin density). Usually left at 0 |

---

## Notes & honest limitations

- **Skin only.** The pigment vectors describe *skin*; applied to a whole frame the separation
  is just an arbitrary basis decomposition of non-skin colours. Qualify it to skin with a
  matte/key upstream, or use it inside a face isolation.
- **Fixed pigment vectors, not per-image ICA.** Real melanin/haemoglobin separation (Tsumura
  et al.) derives the two directions per image with independent-component analysis. This uses
  **physiologically-motivated fixed vectors** — eumelanin (≈ λ⁻³·⁴⁸, rising to blue) and
  oxy-haemoglobin (green-peaked) at the R/G/B band centres. A plausible, well-behaved
  separation, not a spectral measurement.
- **Pipeline placement:** a grade/beauty-stage tool. Balance the shot first (so skin reads
  correctly), then split the pigments. The maps also make a useful qualifier source.
- Identity at default; no animation (`adsk_time` unused).
