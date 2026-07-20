# BB_WhiteBalance v1.0 (work in progress)

Autodesk Flame Matchbox shader. Physically-based **dual-illuminant white balance** using a
Bradford chromatic adaptation transform.
Files: `BB_WhiteBalance.glsl` + `BB_WhiteBalance.xml`

---

## What It Does

Corrects colour casts and mixed lighting the *right* way. Instead of naive per-channel gains,
it adapts the image with a **Bradford chromatic adaptation transform (CAT)** in linear light —
the same cone-response model cameras and colour-management systems use — driven by
**Temperature** and **Tint**.

Its headline feature is **dual-illuminant** mode: independent white balances for **shadows** and
**highlights**, blended by a luminance mask. That fixes the classic on-set problem no single
tool handles — tungsten practicals under a daylight window, warm firelight against a cool sky —
in one node.

This is the correct instrument for a global cast (e.g. wrong white-balance setting), which the
highlight-only [BB_PathToWhite] shader deliberately can't address.

---

## How It Works

1. The image is linearised (per colour space) and mapped into Bradford cone space.
2. **Temperature/Tint** define an illuminant white point on the **Planckian locus** (Temperature
   slides along it; Tint moves perpendicular, green↔magenta).
3. The image is adapted from that white point toward the working neutral. At Temperature 0 /
   Tint 0 the transform is a mathematical identity (a true no-op).
4. In **Dual-Illuminant** mode, a shadow adaptation and a highlight adaptation are computed
   (global Temperature/Tint plus per-zone offsets) and blended by a luminance mask
   (Split Pivot + Softness).

Because it works through a proper cone-space adaptation, it holds hue relationships far better
than a temperature "gain" hack, especially on saturated colours and skin.

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Global | Rec.709 / Scene-Linear / ACEScg / ACEScct — sets gamma, primaries, neutral |
| Temperature | Global | + warms (counters blue cast), − cools |
| Tint | Global | + magenta, − green |
| Mix | Global | Blend the correction with the original |
| Dual-Illuminant | Global | Enable independent shadow / highlight balance |
| Split Pivot / Softness | Global | Luminance split point and transition width (dual mode) |
| Temperature / Tint | Zones → Shadows | Offset added to the global balance in the shadows |
| Temperature / Tint | Zones → Highlights | Offset added to the global balance in the highlights |

---

## Status / TODO

- [ ] Compile-test in Flame (GLSL is written to be GLSL 1.20-safe; not yet run on Flame's runtime)
- [x] Proxy icon (`.png` + `.p`)
- [x] Before/after showcase (`showcase/Showcase_1_MixedLighting.png` — dual-illuminant on a mixed-lighting frame; plus ACEScg/ACEScct working-space showcases)
- [x] ACEScct color space (Rec.709 / Scene-Linear / ACEScg / ACEScct all supported)
- [ ] Optional auto white-picker (needs a multi-pass reduction; manual Temp/Tint for now)

Working-space validation: a numpy port of this exact GLSL confirms the correction is
space-invariant — the display result matches across Rec.709, ACEScg and ACEScct to within
1e-5 (primaries round-trip), and ACEScct↔ACEScg agree to 1e-15 (the log encode/decode is exact).

Colour-science note: the Bradford matrices, Planckian approximation and identity-at-default
behaviour were validated in a numpy port of this exact GLSL before the UI was written.
