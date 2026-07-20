# BB_PathToWhite v1.0

Autodesk Flame Matchbox shader. Direct artist control over the **hue path** saturated
colors take as they desaturate toward clipping / white.
Files: `BB_PathToWhite.glsl` + `BB_PathToWhite.xml`

---

## Why use this?

Fix the ugly way saturated colours shear as they blow out — blue LEDs and skies going cyan, skin and fire going lemon-yellow. It's a highlight-only hue control that neither Flame nor Resolve exposes, so you can hold a colour true right into the clip instead of masking and hand-fixing every hot highlight.

---

## What It Does

When a saturated color climbs toward white it *has* to lose saturation — but the hue
it travels through on the way is normally uncontrolled and usually wrong: blues shear to
cyan, reds shear to orange/yellow, magentas fall apart (the "notorious six"). This is the
Abney / Bezold–Brücke hue-shift, and every tone-mapper and display transform
(ACES, filmic curves, AgX, OpenDRT) bakes an implicit, un-editable version of it in.

No NLE — Flame or Resolve — exposes this as a knob. BB_PathToWhite does: per hue band you
steer the hue and hold or drop saturation *specifically in the highlights*, so you can keep
a blue stage light blue as it blows out instead of letting it go cyan.

The effect is gated by a **highlight factor** so shadows and midtones are untouched.

---

## How It Works

1. A perceptual-space brightness metric is passed through **Highlight Pivot** + **Rolloff**
   to build a highlight mask (`t`). All shaping scales by `t`, so only colors on the path
   to white are affected. View it with **Output → Highlight Mask**.
2. The pixel's hue selects a smooth blend of the six band parameters (R/Y/G/C/B/M).
3. The color is split into luminance + chroma. The chroma is hue-rotated around the neutral
   (1,1,1) axis (a true, luma-preserving hue rotation — no HSV wrap artifacts), then scaled
   by the band's saturation setting.
4. **Path Desaturation** optionally pulls residual chroma toward clean white.

Near-neutral pixels are automatically excluded from hue steering (their hue is undefined).

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Global | Rec.709 / Scene-Linear / ACEScg / ACEScct — sets luma + gamma handling |
| Highlight Pivot | Global | Brightness where the effect centers; lower reaches further down. Goes above 1.0 for HDR highlights in Scene-Linear / ACEScg |
| Rolloff | Global | Softness of the highlight transition |
| Hue Falloff | Global | Hue-band width (°): narrow = distinct bands, wide = smooth continuous blend |
| Strength | Global | Master amount for hue steer + saturation shaping |
| Path Desaturation | Global | Pull residual chroma to clean white (0 = keep color, 1 = full) |
| Preserve Luminance | Global | Shape color only, no brightness change |
| Output | Global | Result, or Highlight Mask (for dialing Pivot / Rolloff) |
| Hue Steer | per band, RGB + CMY pages | Rotate that band's hue in the highlights (±60°) |
| Saturation | per band, RGB + CMY pages | Hold (+) or drop (−) that band's saturation on the path to white |

Bands: **Highlights (RGB)** page = Red / Green / Blue; **Highlights (CMY)** page = Cyan /
Magenta / Yellow.

---

## Which way does Hue Steer go?

Hue Steer rotates around the colour wheel:

- **Positive** → rotates **toward blue / magenta** (increasing hue: R→Y→G→C→B→M).
- **Negative** → rotates **toward green / red** (decreasing hue).

So to hold a blue/cyan highlight *blue* (away from cyan), use **positive** steer on the Cyan
and Blue bands. To hold a warm highlight *warm* (away from lemon-yellow), use **negative**
steer on the Yellow and Red bands. When in doubt, watch the vectorscope and nudge either way.

---

## Typical Uses

- **Fix blue→cyan blowout**: Cyan/Blue Hue Steer **positive** + Saturation to hold deep blue
  as practicals / LEDs clip.
- **Fix warm skin / fire highlights**: Yellow/Red Hue Steer **negative** + Saturation to keep
  hot highlights warm instead of shearing to lemon-white.
- **Fix pale-cyan skies & water**: Cyan/Blue Hue Steer **positive** + Saturation to keep skies
  and speculars rich rather than washing out.
- **Cleaner speculars**: raise Path Desaturation for neutral, filmic highlight rolloff (colored
  clipping → clean white bloom, midtones untouched).
- **Richer highlights**: positive per-band Saturation to hold color deeper into the highlights.

Reference before/after examples for each of these live in `showcase/`.
