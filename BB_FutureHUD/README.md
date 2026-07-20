# BB_FutureHUD

An animated sci-fi HUD overlay for Autodesk Flame. No input image required — the shader generates all elements procedurally. Single-pass GLSL with 15 independently enable/disable-able elements across 15 pages of controls.

Ported and extended from "Future HUD" on Shadertoy.

---

## Pages Overview

| Page | Name | Contents |
|------|------|----------|
| 0 | Rings Master | Master enable, camera angle, global ring controls |
| 1 | Rings A | Rings 1–4 (individual enable, colour, speed, opacity) |
| 2 | Rings B | Rings 5–8 (individual enable, colour, speed, opacity) |
| 3 | Stopwatch | Rolling number readout with orbital ring |
| 4 | Blocks | Two scrolling block ticker strips (Blocks 1 & 2) |
| 5 | Arrows | Two scrolling arrow ticker strips (Arrows 1 & 2) |
| 6 | Waveforms | Two waveform bar graphs |
| 7 | Circles | Two sets of decorative circles |
| 8 | Diamond | Rotating diamond frame with animated cutouts |
| 9 | Static | Antenna static icon with cascade replication |
| 10 | Side Panel | Bilateral side bracket decorations with cascade |
| 11 | Dot Grid | Background scrolling dot grid |
| 12 | Cross Grid | Background scrolling cross grid |
| 13 | Box Grid | Background rotating box grid |
| 14 | Global Time | Master animation speed and time offset |

---

## Elements

### Rings Master (Page 0)
Eight concentric raymarched rings rendered with a 3D camera. The master enable gates all rings at once. Individual ring enables are on Pages 1 and 2 — all eight rings are enabled by default; the master is off by default.

Camera controls: Rotate X (tilt), Rotate Y (orbit), Rotate Z (rock amplitude), orbit speed, and overall ring scale.

### Rings A / Rings B (Pages 1–2)
Each of the eight rings has its own column with: Enable, Colour, Speed, and Opacity. Rings 1–4 are on page 1, rings 5–8 on page 2.

### Stopwatch (Page 3)
A rolling number display styled as a stopwatch or data readout, surrounded by a decorative orbital ring. Controls: Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Blocks (Page 4)
Two independently positioned strips of scrolling rectangular blocks — a ticker tape of small bright squares. Width and Height controls reveal more cells as they grow (not scale). Each strip has: Enable, Speed, Time Offset, Width, Height, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

Blocks 1 defaults to the left side of frame; Blocks 2 to the right.

### Arrows (Page 5)
Two strips of scrolling chevron/arrow shapes, tiling in both X and Y. Same control set as Blocks: Enable, Speed, Time Offset, Width, Height, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Waveforms (Page 6)
Two waveform bar graphs with a voice-activity-style bounce cadence — bars animate as independent sine-driven oscillators to suggest live audio or data. Controls per graph: Enable, Speed, Time Offset, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Circles (Page 7)
Two sets of decorative circles:
- **Circles 1** — arc/wedge style, 3 instances positioned randomly around the frame
- **Circles 2** — multi-ring complex style, 2 instances

Each set: Enable, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Diamond (Page 8)
A rotated square frame with animated cutout segments, giving the appearance of a spinning diamond or rotating reticule. Controls: Enable, Speed, Time Offset, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Static (Page 9)
An antenna or broadcast-static icon with cascade replication. The Number control duplicates the element; each successive copy is stepped by the Pos X/Y and Rotate Z increments and scaled by the Scale multiplier. Mirror adds a horizontally flipped copy of the full cascade. Controls: Enable, Number, Mirror, Speed, Time Offset, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Side Panel (Page 10)
Bilateral bracket decorations — a 3-element group mirrored left and right, cascadable. Each copy in the cascade is a full mirrored left+right pair stepped by Pos X/Y and Rotate Z. Controls: Enable, Number, Speed, Time Offset, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Dot Grid (Page 11)
A dense background field of tiny square dots that scrolls continuously. Rotation also rotates the scroll direction (90° = horizontal scroll). Controls: Enable, Speed, Time Offset, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Cross Grid (Page 12)
A background grid of small cross/plus shapes. Like Dot Grid, Rotate Z rotates both the grid and its scroll direction. Controls: Enable, Speed, Time Offset, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Box Grid (Page 13)
A background grid of square frames — each cell independently rotates clockwise or counter-clockwise. Columns and Rows set exactly how many cells are visible; Scale sets individual cell size. Rotate Z rotates the whole grid and its scroll direction. Controls: Enable, Speed, Time Offset, Columns, Rows, Gap, Scale, Pos X/Y, Rotate Z, Colour, Glow, Opacity.

### Global Time (Page 14)
- **Time Scale** — master animation speed multiplier across all elements (1.0 = reference speed at 25 fps)
- **Time Offset** — global animation start offset in seconds; keyframe this to sync the HUD to a specific point in an animation

---

## Defaults

All elements are **disabled by default** (Enable = off). Turn on only the elements you need. Exception: the eight individual rings are each enabled by default — only the Rings Master enable is off, so enabling the master immediately shows all eight rings.

---

## Notes

- No input image required. The node can be used freestanding in Batch or dropped directly onto a clip.
- All Colour controls use Flame's native colour picker.
- Glow controls use an exponential falloff (0 = no glow, 10 = max spread).
- Width/Height on Blocks and Arrows reveal more cells as they grow — they are clip boundaries, not scale multipliers.
- Columns/Rows on Box Grid set the exact cell count — changing them reveals more or fewer boxes without stretching the cells.
- Cascade elements (Static, Side Panel) replicate up to 20 copies with progressive position, rotation, and scale offsets.
