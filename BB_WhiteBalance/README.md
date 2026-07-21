# BB_WhiteBalance v1.0 (work in progress)

Autodesk Flame Matchbox shader. Physically-based **dual-illuminant white balance** using a
Bradford chromatic adaptation transform.
Files: `BB_WhiteBalance.glsl` + `BB_WhiteBalance.xml`

---

## Why use this?

Fix colour casts — and especially mixed lighting, like warm practicals against a cool window — in a single node, using proper chromatic adaptation that keeps skin and saturated colours natural. A single global white balance or a channel-gain temperature slider can't neutralise two light sources at once; the dual-illuminant shadow/highlight balance can.

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

The **neutral sampler** takes a colour sampled from the image (the swatch's eyedropper, or set
manually), normalises it to unit luminance (so it's a chroma-only correction, no exposure shift),
and builds an adaptation that maps that colour to neutral. Because it's also diagonal in Bradford
cone space, it composes with Temperature/Tint by multiplication — sample a rough neutral, then
trim to taste. Sampling pure white is an exact identity.

Because it works through a proper cone-space adaptation, it holds hue relationships far better
than a temperature "gain" hack, especially on saturated colours and skin.

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Global | Rec.709 / Scene-Linear / ACEScg / ACEScct / ARRI LogC4 — sets gamma, primaries, neutral |
| Temperature | Global | + warms (counters blue cast), − cools |
| Tint | Global | + magenta, − green |
| Mix | Global | Blend the correction with the original |
| Use Sampler | Sampler page | Enable the neutral sampler (colour eyedropper) |
| Sample Neutral | Sampler page (colour swatch) | Sample a colour that should be neutral grey/white with the swatch eyedropper (or set it manually); the image is balanced so that colour reads neutral. Temperature/Tint still trim on top |
| Dual-Illuminant | Global | Enable independent shadow / highlight balance |
| Split Pivot / Softness | Global | Luminance split point and transition width (dual mode) |
| Temperature / Tint | Zones → Shadows | Offset added to the global balance in the shadows |
| Temperature / Tint | Zones → Highlights | Offset added to the global balance in the highlights |

---

## Recommended Pipeline Order

This is a **corrective** tool — a white balance — so it belongs *early*, at the front of the chain,
not at the finishing end:

1. **BB_WhiteBalance** — neutralise the cast first, on a clean scene-referred / linear signal before
   heavy contrast or saturation moves. The Bradford adaptation is most predictable on raw scene
   colour; if you're also using [BB_SpectralWB] for a spiky source, that spectral pass comes first
   and this trims on top.
2. **Primary grade** — exposure, contrast, creative colour, now that the scene reads neutral.
3. **Look / finishing** — print emulation, [BB_FilmCoupler], halation, grain. Film-colour "life"
   effects come *after* the image is correct.

Set **Color Space** to match the image *at this point in the chain* (Rec.709 / Scene-Linear /
ACEScg / ACEScct / ARRI LogC4) so the gamma decode, primaries and neutral are correct — the
correction itself is space-invariant, but it has to know what it's being fed.

---

## Status / TODO

- [ ] Compile-test in Flame (GLSL is written to be GLSL 1.20-safe; not yet run on Flame's runtime)
- [x] Proxy icon (`.png` + `.p`)
- [x] Before/after showcase (`showcase/Showcase_1_MixedLighting.png` — dual-illuminant; plus ACEScg/ACEScct working-space and neutral-sampler showcases)
- [x] All five colour spaces supported (Rec.709 / Scene-Linear / ACEScg / ACEScct / ARRI LogC4)
- [x] Neutral sampler (single-pass colour eyedropper — sample a colour that should be neutral; Temperature/Tint trim on top)
- [ ] Fully-automatic gray-world / white-patch (needs a multi-pass reduction; the manual picker covers most cases)

Working-space validation: a numpy port of this exact GLSL confirms the correction is
space-invariant — the display result matches across Rec.709, ACEScg and ACEScct to within
1e-5 (primaries round-trip), and ACEScct↔ACEScg agree to 1e-15 (the log encode/decode is exact).

Colour-science note: the Bradford matrices, Planckian approximation and identity-at-default
behaviour were validated in a numpy port of this exact GLSL before the UI was written.
