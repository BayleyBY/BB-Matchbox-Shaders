# SocialSafeZones v1.0

A Matchbox shader for Autodesk Flame that draws a safe zone overlay for social media delivery formats. Shows which areas of your frame will be covered by platform UI — navigation bars, engagement buttons, captions — so you can keep important content in the clear zone.

## Files

| File | Purpose |
|---|---|
| `SocialSafeZones.xml` | Matchbox node definition — UI layout, uniforms, pages |
| `SocialSafeZones.1.glsl` | GLSL fragment shader |

## Installation

Copy both files into your Flame Matchbox directory:

```
/opt/Autodesk/presets/<version>/matchbox/shaders/
```

The node will appear in Flame's Matchbox node list as **SocialSafeZones**.

## Usage

Set your Flame timeline resolution to match the delivery format before applying the node (e.g. 1080×1920 for 9:16 content). Select the appropriate **Delivery** option and the overlay will show you exactly what the platform will obscure.

---

## UI Reference

### Setup Page

#### Destination

| Control | Description |
|---|---|
| **Delivery** | The target platform and format. Drives all safe zone margin data. Defaults to TikTok (9:16). |

#### Overlays

| Control | Description |
|---|---|
| **Show Border** | Draws a colored outline along the safe zone boundary. |
| **Show Cutouts** | Toggles all platform UI cutout regions — engagement buttons (Instagram Reels, TikTok) and corner overlay areas (YouTube DemandGen). |
| **Overlay Opacity** | Opacity of the colored fill applied to unsafe areas. `0` = transparent, `1` = fully opaque. |
| **Border Width** | Width of the safe zone border line in pixels. |
| **Corner Radius** | Rounds all corners of the safe zone in pixels, including cutout corners. Default is 20px. Set to `0` for sharp corners. |

#### Adjustments

| Control | Description |
|---|---|
| **Scale** | Scales the background image from the center of the frame. `>1` zooms in, `<1` zooms out. Does not affect the safe zone overlay. |
| **Offset X** | Pans the background image horizontally. Positive moves right. |
| **Offset Y** | Pans the background image vertically. Positive moves up. |

### Colours Page

| Control | Description |
|---|---|
| **Overlay Colour** | Fill colour applied to unsafe areas. Default is semi-transparent red. |
| **Border Colour** | Colour of the safe zone border line. |

---

## Delivery Options

| Delivery | Ratio | Margins (T/B/L/R) | Source |
|---|---|---|---|
| Instagram Reels (9:16) | 9:16 | 14% / 35% / 6% / 6% | Meta official |
| Meta Feed (1:1) | 1:1 | 12.5% / 12.5% / 2.5% / 2.5% | Meta official |
| Meta Feed (4:5) | 4:5 | 10% / 10% / 2.5% / 2.5% | Meta official |
| Meta Stories (9:16) | 9:16 | 14% / 20% / 6% / 6% | Meta official |
| TikTok (9:16) | 9:16 | 13% / 21% / 5.6% / 5.6% | TikTok official |
| YouTube DemandGen (16:9) | 16:9 | 3.5% / 35.8% / 2% / 8.4% | Google official |
| YouTube Shorts (9:16) | 9:16 | 15% / 35% / 4.4% / 17.8% | Google official |

### Cutout Regions

Certain formats include cutout regions where platform UI overlays the video. Toggle visibility with **Show Cutouts**.

**L-shaped engagement cutouts** (right side — like/comment/share buttons):

| Delivery | Cutout Right | Cutout Top |
|---|---|---|
| Instagram Reels (9:16) | 21% from right | 60% from bottom |
| TikTok (9:16) | 14.8% from right | 44.8% from bottom |

**Corner cutouts** (top-left and top-right overlay areas):

| Delivery | Top-Left (W×H) | Top-Right (W×H) |
|---|---|---|
| YouTube DemandGen (16:9) | 496×183 px | 475×133 px |

---

## Technical Notes

- All margins are stored as normalized UV fractions (0–1) of the frame width/height. Pixel values are converted against a 1920×1080 base.
- The border is drawn by sampling `pixelInSafe` at four neighbouring pixel offsets, so it renders at exactly `Border Width` pixels regardless of resolution.
- Corner rounding is computed in pixel space (not UV space) so the arc radius stays consistent across output resolutions. All corners — including inner concave and outer convex cutout corners — use the same radius value.
- The Adjustments controls remap the texture sample UV and have no effect on the safe zone geometry, which is always fixed to the output frame.
- Flame controls output resolution — the shader cannot change it. Set your sequence or node output resolution to match the delivery format before using this node.
