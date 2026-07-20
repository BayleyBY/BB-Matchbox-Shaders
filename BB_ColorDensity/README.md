# BB_ColorDensity - Flame Matchbox Shader

## Overview
Film-style color density adjustment shader for Autodesk Flame. Reduces luminance while boosting saturation to create deep, rich colors similar to PowerGrade Film Emulation methods in DaVinci Resolve / Baselight.

## Files
- `BB_ColorDensity.glsl` - GLSL shader code
- `BB_ColorDensity.xml` - Flame UI definition
- `BB_ColorDensity.png` - 126x92 icon for Flame

## Installation
Copy all three files to your Flame Matchbox shader directory:
- Linux: `/opt/Autodesk/shared/matchbox/shaders/`
- Mac: `/opt/Autodesk/shared/matchbox/shaders/` or user-specific path

---

## Controls

### Color Space Selector
| Value | Color Space | Description |
|-------|-------------|-------------|
| 0 | Rec.709 | Gamma-encoded, uses soft clamp 0-1 |
| 1 | Scene-Linear | Rec.709 primaries, linear light, HDR safe |
| 2 | ACEScg | AP1 primaries, linear light, HDR safe |
| 3 | ACEScct | AP1 primaries, log encoding, HDR safe |

### Global Controls (Page 1: Primary RGB)
- **Global Density** (-5.0 to 5.0): Overall density applied to all colors
- **Global Intensity** (0.0 to 2.0): Overall saturation compensation multiplier
- **Preserve Luminance** (on/off): Restores original luminance after density is applied — keeps color enrichment without darkening

### Per-Color Controls (Page 1: RGB, Page 2: CMY)
Each color vector (Red, Green, Blue, Cyan, Magenta, Yellow) has:
- **Density** (-5.0 to 5.0): Add/remove density for that color
- **Intensity** (0.0 to 2.0): Saturation compensation amount

---

## How It Works

### 1. Color Vector Isolation
Primary colors (RGB):
```
red_weight    = R - (G + B) / 2
green_weight  = G - (R + B) / 2
blue_weight   = B - (R + G) / 2
```

Secondary colors (CMY):
```
cyan_weight    = min(G, B) - R
magenta_weight = min(R, B) - G
yellow_weight  = min(R, G) - B
```

### 2. Density Application (Film Model)
Uses Beer-Lambert law for film-like exponential response:
```
luminance_multiplier = exp(-density × 0.5)
new_luminance = old_luminance × luminance_multiplier
```

### 3. Saturation Compensation
Boosts saturation as density increases to prevent muddy colors:
```
saturation_boost = 1.0 + (density × intensity × 0.5)
result = new_luminance + (saturation_vector × saturation_boost)
```

### 4. Color Space Handling
- **Rec.709/ACEScct**: Operations applied directly (already perceptual)
- **Scene-Linear/ACEScg**: Converts to γ2.4 perceptual space, applies density, converts back
- **Luminance coefficients**: Rec.709 (0.2126, 0.7152, 0.0722) or ACEScg/ACEScct AP1 (0.2722, 0.6741, 0.0537)

---

## Typical Film Look Settings
- Add density to complementary colors (e.g., cyan for teal shadows, yellow for warm highlights)
- Keep intensity at 1.0-1.5 for natural saturation retention
- Small values (0.1-0.3) for subtle shifts; larger values (0.5+) for stylized looks

---

## Matchbox Format Notes

### XML Popup/Dropdown Syntax
Use `ValueType="Popup"` (not `Widget="Popup"`):
```xml
<Uniform Type="int" ValueType="Popup" DisplayName="Color Space" Name="colorSpace">
   <PopupEntry Title="Rec.709" Value="0">
   </PopupEntry>
   <PopupEntry Title="Scene-Linear" Value="1">
   </PopupEntry>
</Uniform>
```

### Required Flame Uniforms
```glsl
uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
```

### Output
```glsl
gl_FragColor = vec4(result, texColor.a);
```

### Limitations
- Uniforms are bound to a single Page — the same control cannot appear on multiple pages

---

## Future Improvements to Consider
- Add more log formats (LogC, S-Log3, V-Log)
- Add Rec.2020 and DCI-P3 support
- Add lift/gamma/gain per color vector
- Add HSL-based alternate mode
- Add print density emulation curves

---

## Created
February 2026
