# BB_ViewingCondition v1.0

Autodesk Flame Matchbox shader. Re-renders an image so it **looks the same in a different
viewing environment** — dark cinema vs dim TV vs bright phone vs HDR — using the **CAM16**
colour appearance model.
Files: `BB_ViewingCondition.glsl` + `BB_ViewingCondition.xml`

---

## Why use this?

The same pixels look **more colourful and more contrasty in a bright room** than in a dark cinema — that's your visual system, not the display. Grade in a dim suite and the shot can read washed-out on a phone, or over-cooked back in the theatre. This node compensates for the *viewing environment* using a real appearance model, so a look you approved in one condition is preserved in another. No NLE exposes this.

---

## What It Does

CAM16 maps a colour, plus its **viewing condition**, to perceptual correlates — lightness `J`,
chroma `C`, hue `h`. This shader:

1. Runs CAM16 **forward** under the **Source** viewing condition (where the image already looks
   right) to get its appearance `(J, C, h)`.
2. Runs CAM16 **inverse** under the **Target** viewing condition to find the pixels that
   *reproduce that same appearance* there.

Holding the appearance fixed while the environment changes reproduces, automatically, the
effects colourists compensate for by eye:

- **Hunt effect** — colourfulness rises with luminance.
- **Stevens effect** — contrast rises with luminance.
- **Surround effect** — a dark surround lowers apparent contrast (Bartleson–Breneman).

It uses **full chromatic adaptation** (both ends adapted to display white), so **neutrals are
preserved** — only the luminance/surround appearance shifts. **Source = Target is an exact
identity.**

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Source | Rec.709 or Scene-Linear — the model runs in linear light (D65) |
| Source | Source | The environment the image already looks right in (usually your grading suite) |
| Target | Target | Where it will actually be seen |
| Amount | Target | Blend the re-rendered result with the original |

Viewing conditions: **Cinema (dark)**, **TV / dim**, **Average / grading**, **Bright / phone**,
**HDR** — each sets the adapting luminance and surround CAM16 uses.

---

## Notes & honest limitations

- **Direction matters.** *Source* is where it looks right; *Target* is where it's going. To
  preview "my cinema grade on a phone," set Source = Cinema, Target = Bright. Swap them to invert.
- **Appearance model, not a display transform.** It compensates for the *environment*, not for a
  gamut/EOTF change — keep your normal ODT/output transform in the chain. Pair it as a trim.
- **D65 working white** (Rec.709 / Scene-Linear). The presets set adapting luminance + surround;
  they are representative, not calibrated to your exact suite.
- Validated against a numpy port of the exact GLSL: Source = Target round-trips to ~1e-6; the
  hardcoded CAM16 matches the reference model across all presets.
- Identity when Source = Target; no animation (`adsk_time` unused).
