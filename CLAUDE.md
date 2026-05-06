# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of custom Matchbox shaders for Autodesk Flame. Each shader lives in its own directory and consists of two required files: a `.glsl` fragment shader and an `.xml` UI descriptor. There is no build system — these files are deployed directly to Flame's matchbox directory.

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
uniform float adsk_time;                      // current time in seconds at output FPS
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

Controls are `<Uniform>` elements. Layout is a grid: `Page`, `Col`, `Row` (all zero-indexed). Each page gets a `<Page>` element that names its columns with `<Col>` children.

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

Popup (int with named entries):
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

**Conditional visibility:** Hide a control when another uniform equals a specific value:
```xml
<Uniform UIConditionType="Hide" UIConditionValue="False" UIConditionSource="my_bool" ...>
```
`UIConditionValue="False"` → hidden when `my_bool` is false (shown when true). Swap values to invert.

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

Each shader should have a `ShaderName.glsl.png` (268×194, width divisible by 4) and its companion `ShaderName.glsl.p` binary. Both are tracked in git. To regenerate a `.p` after updating a PNG, run `make_proxy.py` on the new PNG.
