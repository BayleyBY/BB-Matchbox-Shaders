# BB_Clouds v1.0

Autodesk Flame Matchbox shader. Procedural animated sky and cloud layer with a perspective camera — no input required (pure generator).
Files: `BB_Clouds.1.glsl`, `BB_Clouds.2.glsl` + `BB_Clouds.xml`

---

## Why use this?

Generate a fully art-directable animated sky and cloud layer with no plates, drone footage, or stock — ideal for sky replacements, set extensions, and backgrounds. Because it's procedural with a real perspective camera, you can dial the exact cloud shape, coverage, speed, and horizon tilt a shot needs and keyframe it to match your move.

---

## What It Does

Two-pass procedural sky. Pass 1 casts a perspective ray to a horizontal cloud plane — four independently seeded cloud layers are distributed across a controllable vertical span, so clouds gain real apparent height when the camera tilts toward the horizon. Pass 2 applies an optional circular defocus blur. Cloud shape, coverage, softness, speed, and colour are all exposed as controls.
