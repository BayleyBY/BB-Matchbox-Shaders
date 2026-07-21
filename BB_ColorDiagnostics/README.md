# BB_ColorDiagnostics v1.0

Autodesk Flame Matchbox shader. Physically-based **analysis overlays** for grading —
exposure false-colour, clipping zebras, out-of-gamut / sub-black flags, saturation heat,
and a luminance view. A *diagnostic* node, not a corrective one.
Files: `BB_ColorDiagnostics.glsl` + `BB_ColorDiagnostics.xml`

---

## Why use this?

See at a glance what a scope only hints at: exactly **which pixels clip, go sub-black, fall out of gamut, or sit at 18% grey / skin** — right on the image, where it happens. Flame's built-in scopes read the whole frame; these overlays are spatial and per-pixel, so you can point at the problem. Every other shader in this set corrects or creates — this one *measures*.

---

## What It Does

Pick a **Mode**; the shader replaces the image with a per-pixel diagnostic:

- **Exposure (false colour)** — luminance mapped to discrete zones: purple (black clip), blue
  (deep shadow), green (18% grey), pink (skin / key+1 stop), yellow (near clip), red (clip);
  everything else greyscale.
- **Clipping (zebra)** — diagonal stripes over pixels at/above the High Threshold (red) and
  at/below the Low Threshold (blue).
- **Out-of-Gamut** — flags any pixel with a channel **below** the low limit (sub-black / negative
  — magenta) or **above** the high limit (super-white / over — cyan). Unflagged pixels dim to grey.
- **Saturation** — a blue→red heat map of chroma; the hot regions are the most gamut- and
  white-balance-fragile.
- **Luminance** — the plain luma the other modes threshold on.

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Mode | Rec.709 / Scene-Linear / ACEScg / ACEScct — sets the luminance coefficients |
| Mode | Mode | Off (pass-through) or one of the five diagnostics |
| Dim Context | Mode | Grey-out unflagged pixels so flags pop (Clipping / Out-of-Gamut) |
| High Threshold | Thresholds | Clip / over-range / super-white limit |
| Low Threshold | Thresholds | Crush / sub-black / negative limit (can go negative for wide-gamut) |

---

## Notes

- **Off = pass-through** (identity at default), so it's safe to leave in a setup and flip on when
  checking.
- Thresholds are in the working space's code values — for **Scene-Linear / ACEScg** push the High
  Threshold above 1.0 to find true HDR clipping, and the Low Threshold negative to catch
  wide-gamut negative values.
- The false-colour exposure bands assume a display-referred signal (≈ Rec.709 / log). On
  scene-linear the zones read as linear code values, not IRE.
- No animation (`adsk_time` unused); no matte output.
