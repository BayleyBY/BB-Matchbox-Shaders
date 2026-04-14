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

### BB_ColorDensity
A film-style colour density tool modelled on Beer-Lambert law. Isolates each of the six colour vectors (RGB + CMY) and applies independent density and saturation compensation, producing deep, rich colour shifts similar to film emulation workflows. Supports Rec.709, Scene-Linear, ACEScg, and ACEScct colour spaces.

---

## Installation

Copy the shader folder to Flame's matchbox directory:
```
/opt/Autodesk/shared/matchbox/shaders/
```
Each shader folder must be kept intact — the `.glsl` and `.xml` files need to be in the same directory.
