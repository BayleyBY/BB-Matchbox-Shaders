# BB_DayForNight v1.0

Autodesk Flame Matchbox shader. Physically-based **day-for-night** using the Purkinje
mesopic vision model.
Files: `BB_DayForNight.glsl` + `BB_DayForNight.xml`

---

## Why use this?

Turn daytime footage into believable night in a single node. Its physically-based rod-vision response — reds go dark, blues brighten, detail softens — looks like real night vision rather than the flat 'crush the blacks and tint blue' that instantly reads as fake, so the day-for-night holds up on screen.

---

## What It Does

Turns daytime footage into convincing night by modelling how human vision actually behaves in
low light, instead of the usual "crush the blacks and tint everything blue" fake.

As a scene darkens, vision shifts from **cone-dominated (photopic)** to **rod-dominated
(scotopic)**. Rods are colour-blind, peak toward blue-green (~507 nm) and are nearly insensitive
to red. So real night vision:

- **makes reds go dark** and blues relatively brighter — the **Purkinje shift**,
- **desaturates** toward a tinted monochrome,
- **darkens**, and
- **loses acuity** (softens) and **gains noise**.

This shader recomputes luminance with a rod-weighted response and blends the whole look in as
**Night** rises. At **Night = 0** it's a mathematical identity.

---

## How It Works

1. Luminance is computed two ways: photopic (cone, daylight) and scotopic (rod, blue-shifted).
2. **Night** blends luminance from photopic toward scotopic (**Purkinje Shift** scales this) —
   this is what drives reds dark and blues bright.
3. Colour is desaturated toward a **Night Tint** monochrome (moonlight), the level pulled down
   by **Exposure**, all proportional to Night.
4. Optional **Detail Softness** (acuity loss) and **Grain** (scotopic noise) complete the look.

The maths always runs in Rec.709-primaries linear light: Rec.709 is sRGB-decoded, log spaces
(ACEScct, ARRI LogC4) are decoded to linear, and wide-gamut primaries (AP1, AWG4) are
matrix-converted in and restored losslessly on the way out.

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Amount | Rec.709 / Scene-Linear / ACEScg / ACEScct / ARRI LogC4 — sets decode and primaries for the luminance model |
| Night | Amount | Master day→night amount (0 = day / identity, 1 = full night) |
| Purkinje Shift | Amount | How strongly reds darken / blues brighten toward rod vision |
| Saturation | Amount | Residual colour at full night (0 = monochrome) |
| Exposure | Amount | Output level at full night (day-for-night is darker) |
| Detail Softness | Look | Acuity loss — softens detail as night increases |
| Grain | Look | Animated scotopic noise |
| Night Tint | Look | Colour of the night monochrome (moonlight cast) |

---

## Notes

- The Purkinje shift is the distinctive part: a bright **red** object (car, roses, lips) goes
  genuinely **dark** at night the way it does to the eye — something a blue tint alone never does.
- `showcase/Showcase_1_DayToNight.png` shows the day → dusk → night progression.
- Grain animates via `adsk_time`; leave it at 0 for a clean still.
