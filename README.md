# BB Matchbox Shaders

A collection of custom Matchbox shaders for Autodesk Flame.

---

## What is a Matchbox Shader?

Matchbox is Autodesk Flame's framework for custom GLSL fragment shaders — small GPU programs that run per-pixel on a frame. Each shader is a pair of files: a `.glsl` file containing the image processing logic and an `.xml` file defining the Flame UI (sliders, colour pots, canvas handles, and multi-page layouts). Matchbox shaders are installed to Flame's matchbox directory and appear in the effect library for use in Batch, the Timeline, and Action.

---

## Shaders

### BB_BokehGenerator
A procedural bokeh generator that creates cinematic lens bokeh entirely from scratch — no input image required. Features polygon aperture shape control (circle through any n-sided polygon), chromatic aberration, diffraction spikes, near/far depth layering with parallax drift, per-bokeh flicker and fade, and a final lens blur pass. Two-pass shader architecture.

### BB_Clouds
A procedural animated sky and cloud layer — no input image required. Casts a perspective ray to a horizontal cloud plane, giving natural depth as the camera tilts toward the horizon. Four independently seeded cloud layers are distributed across a controllable vertical span, so clouds appear to have real height when viewed at low angles. Cloud shape, coverage, softness, speed, and colour are all exposed as controls. Two-pass shader: pass 1 generates the clouds, pass 2 applies an optional circular defocus blur.

### BB_ColorDensity
A film-style colour density tool modelled on Beer-Lambert law. Isolates each of the six colour vectors (RGB + CMY) and applies independent density and saturation compensation, producing deep, rich colour shifts similar to film emulation workflows. Supports Rec.709, Scene-Linear, ACEScg, and ACEScct colour spaces.

### BB_ColorDiagnostics
A physically-based analysis overlay — the collection's one *diagnostic* tool, where the others correct or create. Per-pixel modes that Flame's scopes can't show spatially: exposure false-colour (black-clip / shadow / 18%-grey / skin / near-clip / clip zones), clipping zebras, out-of-gamut and sub-black/negative flags, a saturation heat map (the gamut- and white-balance-fragile regions), and a luminance view. Adjustable high/low thresholds (push high > 1 and low < 0 for scene-linear / wide-gamut), a dim-context toggle so flags stand out, and Rec.709 / Scene-Linear / ACEScg / ACEScct luma. Mode Off is a pass-through.

### BB_DayForNight
A physically-based day-for-night grade using the Purkinje mesopic vision model. As the Night amount rises, luminance is recomputed with rod (scotopic, blue-shifted ~507nm) weighting instead of cones, so reds go genuinely dark and blues brighten — the Purkinje shift — while the image desaturates toward a tinted moonlight monochrome, darkens, and can lose acuity and gain scotopic grain. Unlike the usual "crush and tint blue" fake, a bright red car or roses go dark the way they do to the eye at night. Rec.709 / Scene-Linear, identity at Night 0.

### BB_FilmCoupler
An emulation of film DIR (Development-Inhibitor-Releasing) coupler chemistry — the inhibitor effects that make film colour "work", which curve/LUT film emulations can't reproduce. Where a dye layer develops, it releases inhibitor that suppresses the other layers and neighbouring areas, giving two signature effects: inter-layer coupling (cross-channel colour separation and saturation, computed in log-density space, leaving neutrals untouched) and adjacency effects (edge acutance and local contrast from the inhibitor diffusing spatially). It models the coupler chemistry itself rather than being another stock LUT, so it pairs with any density/tone or print emulation. Rec.709 / Scene-Linear, identity at zero.

### BB_FutureHUD
An animated sci-fi HUD overlay — no input image required. Inspired by the holographic interfaces of Minority Report, Iron Man, and Pacific Rim. Fifteen independently enable/disable-able elements across 15 pages: eight concentric raymarched rings with individual colour, speed, and opacity; a rolling number stopwatch; two scrolling block ticker strips; two scrolling arrow strips; two waveform bar graphs; two sets of decorative circles; a rotating diamond frame; a cascade-replicating antenna static icon; bilateral side bracket decorations; and three background grid layers (dot grid, cross grid, rotating box grid). Width/Height on Blocks and Arrows reveal more cells as they grow. Box grid Columns/Rows set exact cell counts without stretching. Dot/Cross/Box grids all support Rotate Z which also rotates the scroll direction. Cascade elements replicate up to 20 copies with progressive position, rotation, and scale. Global Time page for master speed and offset. All elements disabled by default (individual rings enabled, master rings off). All colours use Flame's native colour picker. Ported from "Future HUD" (Shadertoy). A `BB_FutureHUD_Showcase` variant (in a subfolder) enables every element at once as an at-a-glance overview of the library.

### BB_MelaninHemoglobin
A skin-pigment separation tool with no equivalent in Flame or Resolve. In optical-density space, skin colour is decomposed onto two physiological pigment axes — melanin (tan/depth) and haemoglobin (blood/ruddiness) — over a shading term, so each can be graded independently: calm a red flush without draining the tan, or deepen a tan without pushing the shot orange. Uses physiologically-motivated fixed pigment vectors (eumelanin ≈ λ⁻³·⁴⁸ rising to blue; oxy-haemoglobin green-peaked), and Melanin/Haemoglobin map outputs visualise the separation directly. Rec.709 / Scene-Linear, identity at default — skin only (qualify with a matte).

### BB_PathToWhite
A highlight hue-path controller for colour grading — a tool with no equivalent in Flame or Resolve. When a saturated colour climbs toward clipping it must desaturate to white, but the hue it travels through on the way is normally uncontrolled: blues shear to cyan, reds to orange/yellow, magentas break up (the Abney / Bezold–Brücke shift, the "notorious six"). This shader exposes that path as an artist control. A highlight mask (Pivot + Rolloff) gates the effect to the highlights only, then per hue vector (R, G, B, C, M, Y) you steer the hue and hold or drop saturation along the path to white. Includes a global path-desaturation for clean filmic highlight rolloff, an adjustable hue-band width (distinct bands through to continuous blend), a highlight-mask output for dialling the pivot, and Rec.709 / Scene-Linear / ACEScg / ACEScct colour-space handling with HDR-aware pivoting.

### BB_PerspectiveLines
A perspective guide line overlay for layout and composition work. Draws a fan of lines converging at a computed vanishing point derived from two user-defined outer lines. Supports two independent VP line sets for two-point perspective, a horizon line, crosshatch grid mode, dashed lines, and per-VP opacity falloff. When the vanishing point falls off-screen, an arrowhead at the frame edge indicates its direction. Includes a matte output mode for use as a luma matte source downstream.

### BB_RetroHUD
A retro sci-fi HUD overlay — no input image required. Inspired by Alien, Aliens, Blade Runner, 2001: A Space Odyssey, and TRON. Thirteen independently enable/disable-able animated elements, each with its own colour, scale, position, rotation, and animation controls: a sweeping radar with blips, a targeting reticle, an oscilloscope, segmented bar meters, a scrolling data terminal, a receding perspective grid, a PCB circuit trace with flowing pulses, corner brackets with a perimeter scanner, a compass heading tape, a trajectory arc, an analog dial gauge, a TRON-style light grid with pulsing nodes, and TRON-style lightcycle trails (per-cycle colours, fading tails). Two-pass: pass 1 draws the elements on black, pass 2 applies an optional CRT/old-TV filter (geometry distortion, scan lines, glow, and VHS artefacts). A `BB_RetroHUD_Showcase` variant (in a subfolder) enables every element at once as an at-a-glance overview of the library.

### BB_Seascape
A procedural animated ocean — no input image required. Raymarches a multi-octave wave surface with physically-based lighting, fresnel reflection, and sky colour. Camera position and angle are fully manual (X, Height, Z, Pitch, Yaw, Roll), so the scene can be locked off or animated by keyframing sliders in Flame. Wave shape, choppiness, speed, frequency, and colour are all exposed as controls. Ported from "Seascape" by Alexander Alekseev aka TDM (CC BY-NC-SA 3.0).

### BB_ShadowDensity
A shadow density and saturation control for colour correction. Isolates the shadow zone using a smooth luminance mask — full strength at black, rolling off to zero at a user-defined pivot — then applies two independent effects: a luminance pull-down (shadow lift/density) and saturation reduction toward neutral grey. Both effects share the same derived mask so lift and desat are always spatially consistent. Midtones and highlights above the pivot are completely unaffected. Supports Rec.709, Scene-Linear, ACEScg, ACEScct, and ARRI LogC4 (AWG4) colour spaces.

### BB_SocialSafeZones
A social media safe zone overlay for vertical and square delivery formats. Draws platform-specific safe zone boundaries, showing which parts of the frame will be covered by navigation bars, engagement buttons, and caption areas. Supports Instagram Reels, Meta Feed, Meta Stories, TikTok, YouTube Shorts, and YouTube DemandGen, each with accurate margins sourced from official platform guidelines. Includes per-platform UI cutout regions (TikTok/Instagram engagement button stacks, YouTube DemandGen corner overlays), adjustable corner rounding, border and fill colour controls, and a built-in scale/offset adjustment for repositioning the source image without disturbing the safe zone geometry.

### BB_SpectralWB
A spectral white balance that reconstructs a plausible reflectance spectrum for every pixel and re-lights it under a target illuminant, instead of the tristimulus (3-channel) tint an ordinary white balance applies. This captures spectral behaviour a matrix cannot: recovering colour under spiky, low-CRI sources (sodium-vapor, fluorescent, cheap LED) and reproducing the metameric colour-collapse those lights cause. Source and Target are chosen from analytic illuminants (blackbody by Kelvin, plus Sodium/LED/Fluorescent); Source = Target is an exact identity. It's the physically-heaviest shader here and a plausible reconstruction rather than ground truth — the specialist companion to BB_WhiteBalance's everyday tristimulus correction.

### BB_ViewingCondition
Re-renders an image so it *looks the same* in a different viewing environment — dark cinema, dim TV, bright phone, HDR — using the **CAM16** colour appearance model, a compensation no NLE exposes. It runs CAM16 forward under the Source viewing condition to capture the appearance (lightness/chroma/hue), then inverse under the Target condition, so the **Hunt** effect (colourfulness rises with luminance), the **Stevens** effect (contrast rises with luminance) and the **surround** effect are reproduced automatically. Full chromatic adaptation keeps neutrals fixed, and Source = Target is an exact identity. Rec.709 / Scene-Linear; use it as an appearance trim alongside your normal output transform.

### BB_WhiteBalance
A physically-based **dual-illuminant white balance** — a tool with no direct equivalent in Flame. Instead of naive per-channel gains, it adapts the image with a Bradford chromatic adaptation transform (CAT) in linear light, driven by Temperature and Tint along the Planckian locus. Its headline feature is dual-illuminant mode: independent white balances for shadows and highlights blended by a luminance mask, so the classic mixed-lighting problem — warm tungsten practicals against a cool daylight window — can be neutralised in a single node, which no single global control can do. Corrects global casts (wrong white-balance settings) that the highlight-only BB_PathToWhite deliberately can't. Supports Rec.709, Scene-Linear, ACEScg, and ACEScct, and is a mathematical identity at its default settings.

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

---

## License

Copyright © Bayley (BB).

Except where noted below, this collection is licensed under the
**[Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/)** license — see [`LICENSE`](LICENSE). You are free to use, modify, and redistribute these shaders, including commercially, provided you give appropriate credit and license any derivatives under the same terms.

**Exception** — `BB_Seascape` is a direct port of "Seascape" by Alexander Alekseev (TDM) and retains its upstream license, **[CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/)** (non-commercial, share-alike). It is **not** covered by the CC BY-SA 4.0 grant above, and its `.xml` `CommercialUsePermitted` flag is `False`.

`BB_Clouds` and `BB_FutureHUD` began from Shadertoy references but were substantially rewritten as original works; they are licensed CC BY-SA 4.0, with attribution to their inspiration retained in the `.glsl` headers. `BB_RetroHUD` is an original work merely *inspired by* films and is likewise CC BY-SA 4.0.
