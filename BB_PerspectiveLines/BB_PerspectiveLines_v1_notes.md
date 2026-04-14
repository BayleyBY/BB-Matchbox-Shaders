# BB_PerspectiveLines v1.0 — Development Notes

Autodesk Flame 2026 Matchbox shader. Perspective vanishing point line overlay.
Files: `BB_PerspectiveLines.glsl` + `BB_PerspectiveLines.xml`

---

## What It Does

Draws perspective guide lines over a source image. Two independent VP line sets support two-point perspective. A horizon line and VP widget (ring + crosshair, or off-screen arrow) round out the toolkit.

---

## Feature List

| Feature | Control location |
|---|---|
| VP line fan (Lines A+B with intermediates) | First VP / Second VP pages |
| Vanishing point computed from line geometry | Automatic |
| VP widget: ring + crosshair when VP is on-screen | Options col, "Vanishing Point" |
| VP indicator: filled arrowhead when VP is off-screen | Same toggle as widget |
| Canvas drag handles for all 4 control points per VP set | Line A/B cols (icons hidden when Lines = Disable) |
| Solid or dashed lines with dash/gap length control | Options col + Line Options col |
| Crosshatch mode (cross lines between outer lines) | Options col, "Crosshatch" |
| Opacity falloff toward VP | Line Options col, "VP Falloff" |
| Second VP line set (green default) | Second VP page |
| Horizon line with Y position, rotation, colour, width, opacity | Horizon Line page |
| Matte output (grayscale luma matte) | Horizon Line page, Output col |

---

## UI Structure

### Page 0 — First VP
| Col | Name | Contents |
|---|---|---|
| 0 | Options | Lines, Vanishing Point, VP Size, Crosshatch, Line Style |
| 1 | Line A | Start + End drag handles (hidden when Lines = Disable) |
| 2 | Line B | Start + End drag handles (hidden when Lines = Disable) |
| 3 | Style | Line Colour, Width, Opacity |
| 4 | Line Options | Fan Lines, Cross Lines, Dash Length, Gap Length, VP Falloff |

### Page 1 — Second VP
Identical structure to First VP. Line C/D instead of A/B. Green default colour.

### Page 2 — Horizon Line
| Col | Name | Contents |
|---|---|---|
| 0 | Position | Horizon Line enable, Y Position, Rotation |
| 1 | Style | Width, Opacity, Colour |
| 2 | Output | Matte Output |

---

## GLSL Architecture

**Coordinate system:** `gl_FragCoord.xy` = pixel space, origin bottom-left.
Normalised uniforms (0–1) are converted to pixel space immediately: `vec2 a0 = la_start * res`.

**VP computation:** 2D cross product intersection of the two outer lines extended.
```glsl
float vpT = cross2d(b0 - a0, db) / cross2d(da, db);
vec2  vp  = a0 + vpT * da;
```
`vpValid` guards division by zero (parallel lines). `vpInFrame` gates the widget.

**Line drawing:** `distToSeg()` gives perpendicular pixel distance to each segment.
Each fan line is `mix(a0, b0, t)` → `mix(a1, b1, t)` for t ∈ [0,1].

**Dashing:** Along-segment projection via `dot(px - segStart, seg) / len`, then `mod()`.

**Crosshatch:** Cross lines connect `mix(a0, a1, u)` → `mix(b0, b1, u)` for evenly spaced u values in (0, 1). Reuses same dash and width settings.

**Falloff:** Distance from pixel to VP normalised by frame diagonal, smoothstepped over 35% range, mixed by `line_falloff` strength (0=off, 1=full).
```glsl
float vpDist  = length(px - vp) / length(res);
float contrib = mix(1.0, smoothstep(0.0, 0.35, vpDist), line_falloff);
mask = max(mask, contrib);
```

**Off-screen arrow:** When VP is valid but outside frame, ray from frame centre toward VP finds the boundary intersection, then a filled triangle is tested per-pixel using cross product sign consistency.
```glsl
float tx = (res.x * 0.5) / abs(dir.x);   // works because centre = res/2
float ty = (res.y * 0.5) / abs(dir.y);
vec2  ep = ctr + min(tx, ty) * dir;       // edge intersection point
```
Arrow size: 28px deep × 40px wide (base to base).

**Mask accumulation:** `float mask = 0.0` accumulates via `max()` so overlapping lines take the brightest value. VP widget pixels set `mask = 1.0` directly (not subject to falloff).

**Composite:**
```glsl
outColor = mix(bg.rgb,   line_color,  mask  * line_opacity);
outColor = mix(outColor, line_color2, mask2 * line_opacity2);
outColor = mix(outColor, horiz_color, horizMask * horiz_opacity);
```

**Matte output:** When enabled, outputs `vec4(vec3(drawMatte), 1.0)` — grayscale luma matte, alpha held at 1.0. Alpha channel cannot carry the matte because Flame composites shader output alpha over source alpha (`drawMatte + (1 - drawMatte) × source_alpha`), which collapses to 1.0 when source is opaque. Use as a **luma matte source** downstream instead.

---

## XML Patterns (Flame Matchbox)

**Colour pot:**
```xml
<Uniform Inc="0.01" Row="0" Col="3" Page="0" DisplayName="Line Colour"
         ValueType="Colour" Type="vec3" Name="line_color">
   <SubUniform ResDependent="None" Max="1000000.0" Min="-1000000.0" Default="1.0"/>
   <SubUniform ResDependent="None" Max="1000000.0" Min="-1000000.0" Default="0.0"/>
   <SubUniform ResDependent="None" Max="1000000.0" Min="-1000000.0" Default="0.0"/>
</Uniform>
```

**Canvas drag handle (position icon):**
```xml
<Uniform UIConditionType="Hide" UIConditionValue="1" UIConditionSource="lines1_enable"
         IconDefaultState="True" IconType="Axis" ValueType="Position"
         Inc="0.001" Row="0" Col="1" Page="0"
         DisplayName="Line A Start" Type="vec2" Name="la_start">
   <SubUniform Default="0.4" Min="-1.0" Max="2.0" ResDependent="None"/>
   <SubUniform Default="0.35" Min="-1.0" Max="2.0" ResDependent="None"/>
</Uniform>
```

**Popup (Enable/Disable):**
```xml
<Uniform Max="1" Min="0" Default="1" Inc="1" Row="0" Col="0" Page="0"
         Type="int" ChannelName="lines1_enable" DisplayName="Lines"
         Name="lines1_enable" ValueType="Popup">
   <PopupEntry Title="Disable" Value="0"/>
   <PopupEntry Title="Enable"  Value="1"/>
</Uniform>
```

**Conditional visibility:** `UIConditionType="Hide"` + `UIConditionValue="1"` + `UIConditionSource="uniformName"` → widget is **hidden** when source ≠ value, **shown** when source = value. Use `UIConditionValue="1"` to show when enabled, hide when disabled.

---

## Known Issues / Future Ideas

- **Matte alpha channel** doesn't work as expected in Flame — Flame composites output alpha over source alpha. Workaround: use Matte Output as a luma matte (read RGB, not alpha).
- **Conditional hiding** of "Cross Lines" count when Crosshatch = Disable not implemented.
- **Conditional hiding** of Dash Length / Gap Length when Line Style = Solid not implemented.
- **Three-point perspective** (third VP set) not implemented.
- **Per-line colour** (each fan line independently coloured) not implemented.
- **Animated VP path** (VP moves over time using `adsk_time`) not implemented.
