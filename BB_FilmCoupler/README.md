# BB_FilmCoupler v1.0

Autodesk Flame Matchbox shader. Emulates film **DIR-coupler** chemistry — the inhibitor
effects that make film colour "work", which curve/LUT film emulations skip.
Files: `BB_FilmCoupler.glsl` + `BB_FilmCoupler.xml`

---

## Why use this?

Get the cross-channel colour 'life' of real film that LUTs and curves fundamentally can't reproduce — the inter-layer colour separation and edge acutance that come from film's inhibitor chemistry. Drop it into a digital or LUT-based pipeline when a film look feels flat and you want colour that actually behaves like film.

---

## What It Does

Colour negative film has three dye layers, and they don't develop independently. Each layer
carries **DIR (Development-Inhibitor-Releasing) couplers**: where a layer develops, it releases
a chemical inhibitor that **suppresses development in the other layers and in neighbouring
areas**. This is a large part of *why film colour looks like film* — and it's exactly the part a
tone curve or a 3D LUT cannot reproduce, because it's a cross-channel, spatial process, not a
per-pixel remap.

This shader models the two signature DIR effects:

1. **Inter-layer effects** — cross-channel coupling. In log-density space, each layer is pushed
   away from the mean development of the *other two*, which increases colour **separation and
   saturation** in the characteristic film way (and leaves neutrals untouched — couplers only
   act where the layers differ).
2. **Adjacency effects** — the inhibitor **diffuses spatially**, so edges get **acutance** and
   local contrast (film's apparent "sharpness" beyond its raw resolution). Implemented as an
   unsharp of the coupled signal at a controllable diffusion radius.

---

## Controls

| Control | Location | Notes |
| --- | --- | --- |
| Color Space | Inter-Layer | Rec.709 (sRGB) or Scene-Linear — sets the gamma decode for the coupler math |
| Coupling | Inter-Layer | Inter-layer effect strength (colour separation / saturation) |
| Amount | Inter-Layer | Blend the coupled result with the original |
| Acutance | Adjacency | Edge / local-contrast strength from inhibitor diffusion |
| Radius | Adjacency | Diffusion radius in pixels (edge-effect scale) |
| Grain | Adjacency | Animated film grain |

---

## Notes

- **Neutrals are untouched.** The coupling term is zero when R=G=B — couplers act on colour
  differences, not on greys — so this enriches colour without shifting the neutral axis.
- **Not a film stock LUT.** This is specifically the coupler *chemistry* (inter-layer + adjacency).
  Pair it with your own density/tone curve or print emulation for a full film pipeline.
- `showcase/Showcase_1_Couplers.png` isolates the two effects: Original → Inter-Layer →
  + Adjacency.
- Identity when Coupling and Acutance are both 0. Grain animates via `adsk_time`.
