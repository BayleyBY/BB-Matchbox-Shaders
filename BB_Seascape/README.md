# BB_Seascape v1.0

Autodesk Flame 2026 Matchbox shader. Procedural animated ocean — no input image required.
Files: `BB_Seascape.glsl` + `BB_Seascape.xml`

Based on "Seascape" by Alexander Alekseev aka TDM (2014).
License: **CC BY-NC-SA 3.0 Unported** — non-commercial use only.
Original: https://www.shadertoy.com/view/Ms2SD1

---

## What It Does

Raymarches a procedural ocean surface with a physically-based lighting model. Generates sky, water, fresnel reflection, specular highlights, and animated waves entirely in GLSL — no source footage needed. Camera position and angle are fully manual, making it easy to lock off a frame or animate a camera move by keyframing sliders in Flame.

---

## Feature List

| Feature | Control location |
|---|---|
| Procedural animated wave surface (multi-octave noise) | Sea page — Shape col |
| Wave height, choppiness, frequency, speed | Sea page — Shape col |
| Deep water base colour | Sea page — Colour col |
| Shallow water / foam colour | Sea page — Colour col |
| Manual camera position (X, Height, Z) | Camera page — Position col |
| Manual camera angle (Pitch, Yaw, Roll in degrees) | Camera page — Angle col |
| Wave animation speed multiplier | Render page — Animation col |
| Wave animation time offset (scrub start point) | Render page — Animation col |
| 3×3 supersampling anti-alias toggle | Render page — Quality col |

---

## UI Structure

### Page 0 — Sea
| Col | Name | Contents |
|---|---|---|
| 0 | Shape | Height, Choppiness, Frequency, Speed |
| 1 | Colour | Sea Base (colour pot), Water Colour (colour pot) |

### Page 1 — Camera
| Col | Name | Contents |
|---|---|---|
| 0 | Position | X, Height, Z |
| 1 | Angle | Pitch, Yaw, Roll (degrees) |

### Page 2 — Render
| Col | Name | Contents |
|---|---|---|
| 0 | Animation | Time Scale, Time Offset |
| 1 | Quality | Anti-Alias (Disable / Enable) |

---

## GLSL Architecture

**Entry point:** Standard Matchbox `void main()` with `gl_FragColor` / `gl_FragCoord`.

**Time:** `adsk_time` is in frames. Converted to seconds with `adsk_time / 25.0`. Adjust `Time Scale` if your project runs at a different frame rate (e.g. set to `0.96` for 24fps).

**Camera:** Fully explicit — no procedural motion. Origin `vec3(cam_x, cam_y, cam_z)` and Euler angles `radians(vec3(cam_pitch, cam_yaw, cam_roll))` passed to `fromEuler()`. To animate a camera fly-through, keyframe the Z slider in Flame's curve editor.

**Wave surface:** Two functions — `map()` (low detail, used for raymarching) and `map_detailed()` (high detail, used for normal estimation). Both iterate octaves of `sea_octave()`, a noise-displaced sinusoidal wave pattern. Octave count is a compile-time constant (`ITER_GEOMETRY = 3`, `ITER_FRAGMENT = 5`).

**Sea time:** Wave animation clock `sea_time = 1.0 + time * sea_speed` computed inside `getPixel()` and passed as a parameter through `map()`, `map_detailed()`, `getNormal()`, and `heightMapTracing()`. Fully decoupled from camera.

**Raymarching:** `heightMapTracing()` bisects along the ray to find the water surface intersection. Up to `NUM_STEPS = 32` iterations, early-exits when `abs(hmid) < EPSILON`.

**Normal estimation:** Finite-difference gradient of `map_detailed()` at a pixel-space epsilon:
```glsl
float EPSILON_NRM = 0.1 / adsk_result_w;  // computed at runtime, not a #define
n.x = map_detailed(p + dx, sea_time) - map_detailed(p, sea_time);
n.z = map_detailed(p + dz, sea_time) - map_detailed(p, sea_time);
n.y = eps;
```

**Lighting:** Diffuse + specular (`getSeaColor`) mixed with sky reflection via fresnel. Sky colour is a simple gradient function of ray Y direction (`getSkyColor`). Final gamma: `pow(color, vec3(0.65))`.

**Anti-alias:** When enabled, samples a 3×3 grid of sub-pixel offsets and averages. Significantly increases render time — use only for finals.

---

## Shadertoy → Flame Conversion Notes

| Original (Shadertoy) | Flame port |
|---|---|
| `mainImage(out vec4 fragColor, in vec2 fragCoord)` | `void main()` + `gl_FragColor` + `gl_FragCoord` |
| `iResolution.xy` | `adsk_result_w`, `adsk_result_h` |
| `iTime` (seconds) | `adsk_time / 25.0` |
| `iMouse.x` (camera offset) | `time_offset` uniform |
| `#define EPSILON_NRM (0.1 / iResolution.x)` | `float EPSILON_NRM` local variable in `getPixel()` |
| `#define SEA_TIME (1.0 + iTime * SEA_SPEED)` | `float sea_time` local in `getPixel()`, passed as parameter |
| `#define AA` compile-time toggle | `aa_enable` int uniform, runtime branch |
| Procedural camera (`sin` oscillation + continuous roll) | Manual `cam_x/y/z` + `cam_pitch/yaw/roll` uniforms |
| Sea shape/colour as `const` values | Exposed as float/vec3 uniforms |

---

## Performance

This shader is computationally heavy — `NUM_STEPS = 32` raymarching iterations per pixel, each calling `map()` which runs 3 noise octaves. Normal estimation calls `map_detailed()` (5 octaves) three times per pixel. Expect slow render times at HD or higher resolutions. Use offline rendering in Flame rather than expecting real-time playback. Enable Anti-Alias only for final renders.

---

## Known Issues / Future Ideas

- **Frame rate assumption:** Time conversion uses `adsk_time / 25.0`. At non-25fps project rates the wave animation speed will be slightly off — compensate with Time Scale.
- **`CommercialUsePermitted="False"`** is set in the XML — Flame will flag this shader accordingly. The underlying CC BY-NC-SA 3.0 license restricts commercial use. Contact the original author for commercial licensing.
- **Light direction** is hardcoded as `normalize(vec3(0.0, 1.0, 0.8))` — could be exposed as a canvas handle or angle sliders.
- **Fog / atmosphere** not implemented — distant waves clip abruptly at the raymarch limit (`tx = 1000.0`).
- **Animated camera path** requires keyframing Z (and other sliders) in Flame — no built-in motion presets.
