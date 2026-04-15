# BB Matchbox Shaders

A collection of custom Matchbox shaders for Autodesk Flame.

---

## What is a Matchbox Shader?

Matchbox is Autodesk Flame's framework for custom GLSL fragment shaders — small GPU programs that run per-pixel on a frame. Each shader is a pair of files: a `.glsl` file containing the image processing logic and an `.xml` file defining the Flame UI (sliders, colour pots, canvas handles, and multi-page layouts). Matchbox shaders are installed to Flame's matchbox directory and appear in the effect library for use in Batch, the Timeline, and Action.

---

## Shaders

### BB_PerspectiveLines
A perspective guide line overlay for layout and composition work. Draws a fan of lines converging at a computed vanishing point derived from two user-defined outer lines. Supports two independent VP line sets for two-point perspective, a horizon line, crosshatch grid mode, dashed lines, and per-VP opacity falloff. When the vanishing point falls off-screen, an arrowhead at the frame edge indicates its direction. Includes a matte output mode for use as a luma matte source downstream.

### BB_BokehGenerator
A procedural bokeh generator that creates cinematic lens bokeh entirely from scratch — no input image required. Features polygon aperture shape control (circle through any n-sided polygon), chromatic aberration, diffraction spikes, near/far depth layering with parallax drift, per-bokeh flicker and fade, and a final lens blur pass. Two-pass shader architecture.

### BB_SocialSafeZones
A social media safe zone overlay for vertical and square delivery formats. Draws platform-specific safe zone boundaries, showing which parts of the frame will be covered by navigation bars, engagement buttons, and caption areas. Supports Instagram Reels, Meta Feed, Meta Stories, TikTok, YouTube Shorts, and YouTube DemandGen, each with accurate margins sourced from official platform guidelines. Includes per-platform UI cutout regions (TikTok/Instagram engagement button stacks, YouTube DemandGen corner overlays), adjustable corner rounding, border and fill colour controls, and a built-in scale/offset adjustment for repositioning the source image without disturbing the safe zone geometry.

### BB_Seascape
A procedural animated ocean — no input image required. Raymarches a multi-octave wave surface with physically-based lighting, fresnel reflection, and sky colour. Camera position and angle are fully manual (X, Height, Z, Pitch, Yaw, Roll), so the scene can be locked off or animated by keyframing sliders in Flame. Wave shape, choppiness, speed, frequency, and colour are all exposed as controls. Ported from "Seascape" by Alexander Alekseev aka TDM (CC BY-NC-SA 3.0).

### BB_Clouds
A procedural animated sky and cloud layer — no input image required. Casts a perspective ray to a horizontal cloud plane, giving natural depth as the camera tilts toward the horizon. Four independently seeded cloud layers are distributed across a controllable vertical span, so clouds appear to have real height when viewed at low angles. Cloud shape, coverage, softness, speed, and colour are all exposed as controls. Two-pass shader: pass 1 generates the clouds, pass 2 applies an optional circular defocus blur.

### BB_ColorDensity
A film-style colour density tool modelled on Beer-Lambert law. Isolates each of the six colour vectors (RGB + CMY) and applies independent density and saturation compensation, producing deep, rich colour shifts similar to film emulation workflows. Supports Rec.709, Scene-Linear, ACEScg, and ACEScct colour spaces.

---

## Tools

### make_proxy
Converts a PNG to an Autodesk `.p` proxy icon — the binary format Flame reads for matchbox shader thumbnails in the node browser. Each shader needs a 268×194 PNG (width must be divisible by 4) alongside its `.glsl` and `.xml` files, named to match the shader (e.g. `ShaderName.glsl.png` → `ShaderName.glsl.p`).

```
python3 make_proxy/make_proxy.py ShaderName.glsl.png
```

Accepts multiple files or a glob. Output is written alongside the input. Requires Pillow (`pip install pillow`).

---

## Installation

Copy the shader folder to Flame's matchbox directory:
```
/opt/Autodesk/shared/matchbox/shaders/
```
Each shader folder must be kept intact — the `.glsl` and `.xml` files need to be in the same directory.
