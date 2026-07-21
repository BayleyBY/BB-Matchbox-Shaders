# BB_SpectralWB v1.0

Autodesk Flame Matchbox shader. **Spectral** white balance — reconstructs a plausible
reflectance spectrum per pixel and re-lights it under a target illuminant.
Files: `BB_SpectralWB.glsl` + `BB_SpectralWB.xml`

---

## Why use this?

Recover colour under **spiky, low-CRI light sources** — sodium-vapor street lights, cheap LEDs, fluorescents — where an ordinary white balance physically can't. A normal (tristimulus) WB is a 3-channel tint; it can neutralise a smooth cast but it can't undo what a bad-spectrum source does to individual colours. This tool models the actual source spectrum and re-renders the scene under a clean target, so it holds skin and saturated colours through big illuminant changes that make channel-gain WB go waxy or green.

---

## What It Does

Every ordinary white balance — including [BB_WhiteBalance] with its Bradford adaptation — is
**tristimulus**: it works on the 3 numbers per pixel and applies one transform to all colours.
That's a simplification, because a captured colour is a **reflectance spectrum multiplied by the
light source's spectrum**, collapsed to RGB — and once collapsed, a matrix can't fully undo it.

BB_SpectralWB works spectrally instead:

1. Normalise the pixel by the **source** white → a reflectance estimate.
2. Reconstruct a smooth **reflectance spectrum** from that RGB (Smits 1999 basis).
3. Integrate it under both the **source** and **target** illuminant against the CIE observer.
4. Apply the ratio (target ÷ source) to the pixel.

Using the ratio makes the reconstruction error cancel, so **Source = Target is an exact
identity**. Illuminants are analytic: blackbody by Kelvin (Tungsten, Daylight, Custom), plus
Sodium, White LED and Fluorescent spectra.

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Source | Rec.709 (sRGB) or Scene-Linear — sets the gamma decode |
| Source Light | Source | The illuminant the footage was actually shot under |
| Source Kelvin | Source | Colour temperature when Source Light = Custom Kelvin |
| Target Light | Target | The illuminant to re-render under (usually Daylight) |
| Target Kelvin | Target | Colour temperature when Target Light = Custom Kelvin |
| Amount | Target | Blend the spectral correction with the original |

Typical use: set **Source Light** to what you shot under and **Target Light** to Daylight (D65).

---

## Recommended Pipeline Order

This is a **corrective** tool — a white balance — so it belongs *early*, at the front of the chain,
not at the finishing end:

1. **BB_SpectralWB** — neutralise the source illuminant first, ideally on a clean scene-referred /
   linear signal before heavy contrast or saturation moves. Those distort the per-pixel reflectance
   estimate the correction is built on, so re-lighting works best on the rawest colour you have.
2. **Primary grade** — exposure, contrast, creative colour, now that the scene reads under a neutral
   target light.
3. **Look / finishing** — print emulation, [BB_FilmCoupler], halation, grain. Film-colour "life"
   effects come *after* the image is correct.

Set **Color Space** to match the image *at this point in the chain* (Scene-Linear for a linear/ACES
signal, Rec.709 for a display-referred one) so the gamma decode is correct.

For an ordinary smooth cast a tristimulus WB ([BB_WhiteBalance]) is lighter and enough; reach for
this specifically when the source is spiky / low-CRI (sodium, fluorescent, cheap LED) and channel-gain
WB goes waxy or green.

---

## Notes & honest limitations

- **It's a plausible reconstruction, not ground truth.** The RGB→spectrum inverse is
  under-determined (infinitely many spectra map to one RGB), so it uses a smoothness prior, and
  the CIE 1931 observer stands in for the camera's real spectral sensitivities. It beats
  tristimulus on hard sources, but it isn't a physics oracle.
- **Heaviest shader in the set** — two 20-sample wavelength loops per pixel. Fine for Flame, but
  noticeably more GPU than the others.
- Coarse (20-sample) spectra mean the narrow **Sodium**/**Fluorescent** lines are widened
  approximations of the real spikes.
- Validated in a numpy port of this exact math: identity is exactly 0 for every illuminant when
  Source = Target.
- `showcase/` — `Showcase_1_Correction` (the use case) and `Showcase_2_SpectralBehavior`
  (re-lighting one scene under three illuminants, showing sodium's metameric colour-collapse).
