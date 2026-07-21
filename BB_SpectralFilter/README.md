# BB_SpectralFilter v1.0

Autodesk Flame Matchbox shader. Applies a physically-modelled lighting **gel / filter**
*spectrally* — CTB, CTO, Plus/Minus Green — the transmission sibling of [BB_SpectralWB].
Files: `BB_SpectralFilter.glsl` + `BB_SpectralFilter.xml`

---

## Why use this?

Add a **colour-temperature or CC gel** that behaves like real coloured glass: because it filters a reconstructed spectrum rather than scaling three channels, **different colours respond differently** — a warm gel warms skin and a blue sky by different, spectrally-correct amounts. A channel-mixer or curve applies one global rule to every pixel; a real gel doesn't.

---

## What It Does

For each pixel the shader:

1. Reconstructs a plausible **reflectance spectrum** from the RGB (a smooth analytic basis).
2. Integrates it against the CIE observer **with** and **without** the filter transmission
   `T(λ)`, under the observer.
3. Applies the resulting per-channel **ratio** to the pixel.

Using the ratio makes the reconstruction error cancel, so **Filter = None (or Strength 0) is an
exact identity**. Because the ratio depends on each pixel's spectrum, a saturated blue and a
neutral grey of the same luminance are filtered by *different* amounts — the spectral behaviour a
3×3 channel-mix fundamentally can't reproduce.

All spectra — the CIE colour-matching functions (Wyman 2013 Gaussian fits), the reflectance
basis, and the filter transmissions — are **analytic**, evaluated inside a bounded loop, so the
shader uses **no arrays and no dynamic indexing** (unlike BB_SpectralWB's spectral tables).

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Filter | Rec.709 / Scene-Linear / ACEScg / ACEScct / ARRI LogC4 — the filter runs in Rec.709 linear light |
| Filter | Filter | None / CTB (cool) / CTO (warm) / Plus Green / Minus Green |
| Strength | Adjust | Filter density — 0 = clear glass (identity), 1 = full gel |
| Amount | Adjust | Blend the filtered result with the original |

---

## Notes & honest limitations

- **Analytic gel curves, not measured Lee/Rosco data.** The transmissions are physically-motivated
  smooth approximations (CTB rising to blue, CTO to red, ±Green a bump/dip at ~540 nm) — the *shape*
  of a real gel, not a metameric match to a specific product.
- **Reflectance reconstruction is approximate.** Like BB_SpectralWB, the RGB→spectrum inverse is
  under-determined and uses a smoothness prior; the CIE observer stands in for the camera. The ratio
  trick keeps it well-behaved (identity when neutral), but it's a plausible model, not a measurement.
- **Pipeline placement:** a look/gel effect — use it to match a practical gel or add a spectrally
  honest wash. Not a white-balance corrector (use [BB_WhiteBalance] / [BB_SpectralWB] for casts).
- Identity when Filter = None; no animation (`adsk_time` unused).
