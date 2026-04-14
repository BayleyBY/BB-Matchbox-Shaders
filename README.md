# BB Matchbox Shaders

A collection of custom Matchbox shaders for Autodesk Flame.

---

## What is a Matchbox Shader?

Matchbox is Autodesk Flame's framework for custom GLSL fragment shaders. A Matchbox shader is a small GPU program that runs per-pixel on a frame, allowing artists to create effects that aren't possible with Flame's built-in tools — or to build highly specific, purpose-built utilities tailored to a particular workflow.

Each Matchbox shader is a pair of files:

- **`.glsl`** — the fragment shader written in GLSL (OpenGL Shading Language). This is where all the image processing logic lives. It runs on the GPU once per pixel, every frame.
- **`.xml`** — the UI definition. This tells Flame what controls to display in the node's parameter panel: sliders, colour pots, popup menus, canvas drag handles, and multi-page layouts.

Matchbox shaders are placed in Flame's designated Matchbox directory and appear inside Flame's effect library. They can be used in Batch, the Timeline, and Action. Inputs are connected as textures (`sampler2D`), and Flame provides built-in uniforms for resolution (`adsk_result_w`, `adsk_result_h`), time (`adsk_time`), and more.

---

## Shaders in This Collection

*Descriptions coming soon.*

---

## Repository Structure

```
/BB_PerspectiveLines    — Perspective vanishing point line overlay
/BB_BokehGenerator      — Bokeh / depth-of-field effect
/BB_ColorDensity        — Colour density grading tool
/examples               — Reference shaders used during development (not BB originals)
```
