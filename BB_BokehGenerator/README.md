# BB_BokehGenerator

**Author:** Bayley (BB)
**Created:** 2026-03-15
**Type:** Matchbox Shader (Multipass)
**Flame Version:** 2017+

---

## Overview

Procedural bokeh generator for Autodesk Flame. Generates cinematic lens bokeh entirely from scratch — no input image required, though a background can be connected for compositing. Features shape control, optical lens character, depth layering, distribution, and time-driven animation.

---

## Files

| File | Purpose |
|------|---------|
| `BB_BokehGenerator.glsl` | Root stub — load this in Flame |
| `BB_BokehGenerator.1.glsl` | Pass 1 — bokeh rendering |
| `BB_BokehGenerator.2.glsl` | Pass 2 — lens blur |
| `BB_BokehGenerator.xml` | UI controls and defaults |
| `BB_BokehGenerator.md` | This documentation file |

All files must be in the same directory.

---

## Installation

Copy all four files to:
```
/opt/Autodesk/presets/<version>/matchbox/shaders/
```

Load in Flame via the Matchbox browser by selecting `BB_BokehGenerator.glsl`.

---

## Parameters

### Main Page

| Parameter | Default | Description |
|-----------|---------|-------------|
| Bokeh Count | 40 | Total number of bokeh discs. Split 50/50 between near and far depth layers. Max 200. |
| Seed | 0 | Random seed. Change to get a completely different arrangement. |
| Size | 120 | Base size of bokeh discs in pixels. |
| Size Variation | 0.4 | Per-bokeh size randomness. 0=all identical, 1=maximum variation. |
| R / G / B | 1.0 / 0.95 / 0.8 | Base bokeh color (warm white by default). |
| Color Variation | 0.15 | How much hue and saturation varies per bokeh. |
| Brightness | 1.2 | Master brightness multiplier for all bokeh. |
| Brightness Variation | 0.3 | Per-bokeh brightness randomness. |
| Global Opacity | 1.0 | Master opacity for the entire effect. |
| Background Mix | 1.0 | Mix between the background input and the full bokeh render. |
| Blend Mode | Screen | How bokeh composites over the background. Options: Add, Screen, Normal, Multiply, Overlay. |

### Shape Page

| Parameter | Default | Description |
|-----------|---------|-------------|
| Sides (0=round) | 0 | Number of polygon sides. 0=circle, 3=triangle, 5=pentagon, 6=hexagon, etc. Blends smoothly to circle at 0. |
| Rotation | 0 | Base rotation angle in degrees applied to all bokeh. |
| Rotation Variation | 0.5 | Per-bokeh rotation randomness. At 1.0, each bokeh is fully random up to ±180°. |
| Aspect Ratio | 1.0 | Stretches bokeh shape. 1.0=square, >1=wider, <1=taller. |
| Edge Softness | 0.15 | 0=hard aperture edge, 1=very soft glowing falloff. |
| Hollow | 0.0 | 0=filled disc, 1=outline ring only. Partial values blend between the two. |
| Rim Brightness | 0.4 | Extra brightness on the outer edge. Real lens bokeh is brighter at the rim than the fill. |

### Optical Page

| Parameter | Default | Description |
|-----------|---------|-------------|
| Chromatic Aberration | 0.0 | RGB fringing on bokeh edges. Simulates lens chromatic aberration. |
| Diffraction Spikes | 0.0 | Intensity of star-pattern spikes radiating from each bokeh. Common on bladed apertures. |
| Spike Count | 6 | Number of diffraction spikes. Usually matches the number of Sides. |
| Spike Blur | 0.0 | Softness of spike edges. 0=razor sharp, 1=wide feathered glow. |
| Spike Length | 2.0 | Length of spikes as a multiplier of bokeh size. |
| Lens Blur | 0.0 | Final circular blur applied to the entire output in pass 2. Simulates overall defocus. |

### Distribution Page

| Parameter | Default | Description |
|-----------|---------|-------------|
| Density Falloff | 0.3 | Controls spatial distribution. Positive=bokeh pushed toward edges. Negative=pushed toward center. 0=uniform. |
| Distribution X | 0.5 | X coordinate of the distribution center point. Only active when Density Falloff is non-zero. |
| Distribution Y | 0.5 | Y coordinate of the distribution center point. Only active when Density Falloff is non-zero. |
| Near Layer Scale | 1.8 | Size multiplier for the near depth layer. Near bokeh are typically larger and more defocused. |
| Near Opacity | 0.7 | Opacity of the near bokeh layer. |
| Far Opacity | 1.0 | Opacity of the far bokeh layer. |

### Animation Page

| Parameter | Default | Description |
|-----------|---------|-------------|
| Time Offset | 1.0 | Drives all time-based effects. Keyframe this (or connect to frame/time expression) to animate drift, flicker, and fade. |
| Drift X | 0.0 | Horizontal drift speed. Near layer drifts faster than far, creating parallax depth. Each bokeh also has individual speed variation. |
| Drift Y | 0.0 | Vertical drift speed. Same depth parallax as Drift X. |
| Flicker Amount | 0.0 | Per-bokeh brightness flicker driven by sine waves. Each bokeh flickers at its own random frequency and phase. Requires Time Offset to be animated. |
| Fade Amount | 0.0 | Per-bokeh fade in/out driven by sine waves. Requires Time Offset to be animated. |
| Fade Variation | 0.5 | How desynchronized each bokeh's fade cycle is. 0=all fade in sync, 1=each at its own rate. |

---

## Animation Tips

- **Time Offset** is the single driver for all animation. Keyframe it from 0 to any value over time, or connect it to a Flame expression like `frame / 24.0`.
- **Drift** moves bokeh across the frame. Near and far layers move at different speeds automatically — no extra setup needed.
- **Flicker and Fade** are pure sine-wave driven — no keyframing required once Time Offset is animated.

---

## Architecture Notes

- **Two-pass shader.** Pass 1 renders all bokeh. Pass 2 reads the pass 1 result via `adsk_results_pass1` and applies the lens blur kernel.
- **Depth layers.** The bokeh count is split 50/50 into near and far layers. Near layer gets a size multiplier (Near Layer Scale) and faster drift speed.
- **Distribution** uses a radial power-curve remap — all bokeh are kept, positions are redistributed, no bokeh are discarded.
- **Polygon SDF** blends smoothly to a circle as Sides approaches 0.
- **GLSL 120** compatible for macOS Flame.

---

## Known Limitations

- Max 200 bokeh (GLSL loop limit). For more, the shader would need to be restructured.
- Lens Blur in pass 2 is a 48-sample circular kernel — good quality but not a true optical bokeh blur.
- Distribution X/Y have no effect when Density Falloff is 0.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-03-15 | Initial version |
