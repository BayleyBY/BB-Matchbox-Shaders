# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of custom Matchbox shaders for Autodesk Flame. Each shader lives in its own directory and consists of two required files: a `.glsl` fragment shader and an `.xml` UI descriptor. There is no build system — these files are deployed directly to Flame's matchbox directory.

The root `README.md` holds the per-shader catalog (what each `BB_*` shader does and its ported source, if any), and most shader folders also carry their own `README.md` with deeper per-shader docs (file roles, control breakdowns) — read both before modifying a shader to understand its intended behaviour. The `examples/` directory contains third-party reference shaders (`crok_*`, `KE_*`) kept for learning Matchbox conventions; it is gitignored and **not** part of this collection — never edit, ship, or treat those as BB shaders.

## Licensing

The collection is **CC BY-SA 4.0** (see `LICENSE`). The one exception is `BB_Seascape`, a direct port that keeps its upstream **CC BY-NC-SA 3.0** (non-commercial) license — never relicense it as CC BY-SA, and its XML `CommercialUsePermitted` must stay `False`. When porting a new shader from third-party work, keep the upstream attribution header in the `.glsl`; if the port stays a derivative under a non-commercial/share-alike license, add it to the README License-section exception and set `CommercialUsePermitted="False"`.

## Tools

### make_proxy — generate thumbnail icons

Converts a 268×194 PNG to Flame's binary `.p` proxy format (width must be divisible by 4):

```
python3 make_proxy/make_proxy.py ShaderName.glsl.png
```

Accepts multiple files or a glob. Output is written alongside the input. Requires `pillow`.

### Installation

Copy a shader folder to:
```
/opt/Autodesk/shared/matchbox/shaders/
```

## Shader architecture

### File naming
- Single-pass: `ShaderName.glsl` + `ShaderName.xml`
- Multi-pass: `ShaderName.1.glsl`, `ShaderName.2.glsl`, ... + one `ShaderName.xml`

### GLSL conventions

Flame provides these built-in uniforms — declare them but never define them:
```glsl
uniform float adsk_result_w, adsk_result_h;  // output dimensions in pixels
uniform float adsk_time;                      // current time in seconds at output FPS (omit if the shader has no animation)
```

UV construction is always pixel-space, not 0–1:
```glsl
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 px  = gl_FragCoord.xy;          // pixel coords, origin bottom-left
vec2 uv  = gl_FragCoord.xy / res;    // normalised 0–1
```

Position uniforms from canvas drag handles arrive as normalised 0–1. Convert to pixel space before geometry math: `vec2 pt = uniform_pos * res`.

Entry point is `void main()` writing to `gl_FragColor`. GLSL version must remain GLSL 1.20 compatible (no `in`/`out` qualifiers, no `texture()` — use `texture2D()`).

### XML UI structure

The root element is `<ShaderNodePreset>`. Key attributes on the opening tag:
- `SoftwareVersion="2026.0.0"` — minimum Flame version
- `LimitInputsToTexture="True"` — prevents non-texture connections
- `CommercialUsePermitted="True"` / `ShaderType="Matchbox"` — standard for BB shaders
- `Description="..."` — tooltip shown in Flame's node browser
- `Version="2"` — UI schema version; always 2

Each pass lives in a `<Shader Clear="0" GridSubdivision="1" OutputBitDepth="Output" Index="N">` block (Index is 1-based).

Controls are `<Uniform>` elements. Layout is a grid: `Page`, `Col`, `Row` (all zero-indexed). Add a `Tooltip="..."` attribute to any uniform to show a tooltip in Flame's UI.

Page tabs and column headers are declared at the end of the XML (after all `<Shader>` blocks):
```xml
<Page Name="My Page" Page="0">
   <Col Name="Controls" Col="0" Page="0"/>
   <Col Name="Appearance" Col="1" Page="0"/>
</Page>
```

**Uniform type patterns:**

Float slider:
```xml
<Uniform ResDependent="None" Max="1.0" Min="0.0" Default="0.5" Inc="0.01"
         Row="0" Col="0" Page="0" DisplayName="Opacity" Type="float" Name="my_float">
</Uniform>
```

Colour pot (vec3 with three SubUniforms for R/G/B defaults):
```xml
<Uniform Inc="0.01" Row="0" Col="1" Page="0" DisplayName="Colour"
         ValueType="Colour" Type="vec3" Name="my_color">
   <SubUniform ResDependent="None" Max="1000000.0" Min="-1000000.0" Default="1.0"/>
   <SubUniform ResDependent="None" Max="1000000.0" Min="-1000000.0" Default="0.5"/>
   <SubUniform ResDependent="None" Max="1000000.0" Min="-1000000.0" Default="0.0"/>
</Uniform>
```

Canvas drag handle (position icon):
```xml
<Uniform IconDefaultState="True" IconType="Axis" ValueType="Position" Inc="0.001"
         Row="0" Col="1" Page="0" DisplayName="Point" Type="vec2" Name="my_pos">
   <SubUniform Default="0.5" Min="-1.0" Max="2.0" ResDependent="None"/>
   <SubUniform Default="0.5" Min="-1.0" Max="2.0" ResDependent="None"/>
</Uniform>
```

Popup (int with named entries — `ChannelName` must equal `Name`):
```xml
<Uniform Max="1" Min="0" Default="0" Inc="1" Row="0" Col="0" Page="0"
         Type="int" ChannelName="my_popup" DisplayName="Mode" Name="my_popup" ValueType="Popup">
   <PopupEntry Title="Option A" Value="0"/>
   <PopupEntry Title="Option B" Value="1"/>
</Uniform>
```

Bool toggle:
```xml
<Uniform Row="0" Col="0" Page="0" Default="False" DisplayName="Enable" Type="bool" Name="my_bool">
</Uniform>
```

**Conditional visibility:** Show a control only when another uniform matches a specific value:
```xml
<Uniform UIConditionType="Hide" UIConditionValue="True" UIConditionSource="my_bool" ...>
```
`UIConditionValue` is the value at which the control is **visible** (hidden otherwise). `"True"` → shown when `my_bool` is true. Use `"False"` to show only when disabled.

**Multi-pass:** Each pass is a separate `<Shader Index="N">` block inside `<ShaderNodePreset>`. Pass 2 reads pass 1's output via:
```xml
<Uniform Mipmaps="False" ... Type="sampler2D" Name="adsk_results_pass1">
</Uniform>
```
No `Index` or `NoInput` on this uniform — the name is the convention Flame uses automatically.

**Texture input (front/source):**
```xml
<Uniform Index="0" NoInput="Error" DisplayName="Front" InputType="Front"
         Mipmaps="False" GL_TEXTURE_WRAP_T="GL_CLAMP_TO_EDGE"
         GL_TEXTURE_WRAP_S="GL_CLAMP_TO_EDGE" GL_TEXTURE_MAG_FILTER="GL_LINEAR"
         GL_TEXTURE_MIN_FILTER="GL_LINEAR" Type="sampler2D" Name="front">
</Uniform>
```
Generator shaders (no input required) omit the texture uniform entirely, or use `NoInput="BlackImage"` for an optional background.

## Proxy icons

Each shader should have a proxy PNG (268×194, width divisible by 4) and its companion `.p` binary, both tracked in git. The PNG name must match the shader file Flame reads the icon from:
- Single-pass: `ShaderName.glsl.png` → `ShaderName.glsl.p`
- Multi-pass: `ShaderName.1.glsl.png` → `ShaderName.1.glsl.p` (first-pass file)

To regenerate a `.p` after updating a PNG, run `make_proxy.py` on the new PNG.

## Showcase images and ignored files

Newer shaders carry a `showcase/` subdirectory of before/after and scene PNGs (referenced from the shader's `README.md` to document look and use cases). These are documentation only — they are not deployed to Flame and are unrelated to the proxy icon. Some also hold synthetic `Before_*.png` test charts (labelled *SYNTHETIC TEST PLATE*) built for before/after demos.

`.gitignore` excludes `.DS_Store`, an `examples/` directory (third-party reference shaders), `BB_FutureHUD/Additional ShaderToy HUDS/`, and `presentation/` (local talk/deck working files, tracked separately — do **not** commit its contents to this repo). The `.glsl.p` proxy binaries are intentionally **not** ignored — they are tracked in git.

## Naming conventions in practice

The conventions above are the intended standard, but existing shaders are not fully consistent — match a shader's *own* existing pattern when editing it rather than assuming the standard:
- `BB_SocialSafeZones` is single-pass yet uses the multi-pass `.1.glsl` naming (its XML has only one `<Shader Index="1">` block) — the `.N` suffix does not guarantee multiple passes.
- `BB_Clouds` is multi-pass yet its icon is `BB_Clouds.glsl.png` (not `.1.glsl.png`). Whichever `.glsl` filename the PNG stem matches is the one Flame reads the icon from.

## Multi-element HUD shaders (BB_RetroHUD, BB_FutureHUD)

These overlay shaders compose many independent animated elements and share conventions worth knowing before editing them:

- **Coordinate space is centred and aspect-correct**, not the 0–1 pixel UV described under GLSL conventions above: `uv = (gl_FragCoord.xy - 0.5*res) / res.y` → `y ∈ [-0.5, 0.5]`, `x ∈ [±aspect/2]`. Element position uniforms live in this space.
- **Each element is a uniform-name prefix** with a consistent control set: `{elem}_enable / _speed / _time_offset / _scale / _pos_x / _pos_y / _rot / _color / _glow / _opacity` (plus element-specific extras), and its own XML page. To add a control to one element, follow that prefix and add a matching `<Uniform>` on the element's page. (Note: a few elements are fixed — e.g. FutureHUD's concentric rings have no pos/scale, only depth/speed/opacity; `ring_depth` is thickness, not distance.)
- **Static line art vs. bright animation are separate channels.** Static geometry is an SDF rendered via `ov_alpha(d, glow)` (crisp core + phosphor halo) and composited with `mix(col, color, alpha*opacity)`. Bright animated highlights — pulses, scanners, pulsing nodes, lightcycle trails — are returned on a separate additive "glow" channel and composited as `col += mix(color, vec3(1.0), ~0.5) * glow * opacity`, so they read brighter than the lines and **overlaps add/brighten instead of cutting out** (the function returns e.g. `vec2(sdf, glow)` or a `vec3` emissive). Prefer additive/screen for overlapping glows.
- Keep it **GLSL 1.20-safe**: no dynamic array indexing (use unrolled `if/else` chains), and `min(max(intUniform, lo), hi)` for clamping int counts.

## Showcase variants

A `BB_<Name>_Showcase/` folder nested **inside the parent shader's folder** demonstrates every element at once (an at-a-glance overview of the library). Conventions:

- GLSL is copied **verbatim** from the parent (GLSL is filename-independent, so byte copies work); only the XML defaults differ — all elements enabled, with `_pos_x/_pos_y/_scale` set to tile them without overlap.
- Elements that can't be boxed (infinite-tiling patterns like Circuit Trace, or fixed centred elements like FutureHUD's rings/grids) are set to low `_opacity` as faint backdrops rather than tiled.
- Reuse the parent's proxy: copy its `.png`/`.p` renamed to the showcase's first-pass GLSL name (e.g. `BB_RetroHUD_Showcase.1.glsl.png`).
- Generate by transforming the parent XML's `Default=` attributes programmatically (each `<Uniform>` is one line keyed by `Name="..."`) rather than by hand — see how the existing showcases were built.
