# PT SkyWalker541 v1.0.9
**by SkyWalker541 | Written for NextUI**

---

## What is this?

On original Game Boy, Game Boy Color, and Game Boy Advance hardware, pixels that were fully off didn't show as white. Because those screens had no backlight driving those areas, the physical backing material of the screen showed through instead — a subtle grey-green translucency rather than solid white. Game developers of that era designed around this, using "white" areas as intentional transparent zones for backgrounds, windows, and UI overlays.

On modern displays and emulators, those same pixels render as bright white, which was never the intended look. **PT SkyWalker541** restores the original appearance by detecting bright and white pixels and blending them toward a procedurally generated backing texture — putting the transparency back where it belongs.

This is a **standalone shader**. No other shaders are required.

---

## Installation

1. Place `PT_SkyWalker541.glsl` and `PT_SkyWalker541.cfg` in your NextUI shaders folder
2. Load `PT_SkyWalker541.cfg` from the in-game shader menu
3. Open shader settings and set **PT_SYSTEM** to match your target system
4. Apply the recommended core settings for your system (see below)

---

## Recommended Core Settings

Before adjusting any shader parameters, configure your emulator core settings to match your target system. These settings work alongside the shader for the best result.

> **All systems:** Set **Screen Scaling** to **Native** to avoid shadow artifacts at non-native resolutions.

### Game Boy (GB)
| Setting | Recommended Value |
|---|---|
| Screen effect | None |
| Color correction | Disabled |
| Frontlight position | Central |
| Dark filter level | 0 |
| Interframe blending | Disabled |
| GB Colorization | Disabled *(see note below)* |

> **GB Colorization note:** Any colorization palette (Auto, GBC, SGB, Internal, or Custom) can shift what the shader detects as white, causing backgrounds to not go transparent. If you want to use colorization, set **PT_SYSTEM to 0 (Manual)** and lower **PT_SENSITIVITY** gradually until backgrounds go transparent as expected.

> **Dark filter level note:** Set this to 0 in your core settings. The shader has its own **PT_DARK_FILTER_LEVEL** parameter that handles this more accurately. Running both at the same time will double the effect.

### Game Boy Color (GBC)
| Setting | Recommended Value |
|---|---|
| Screen effect | None |
| Color correction | GBC Only |
| Frontlight position | Central |
| Dark filter level | 0 |
| Interframe blending | Disabled |

> **Dark filter level note:** Same as GB above — set to 0 and use **PT_DARK_FILTER_LEVEL** in the shader instead.

### Game Boy Advance (GBA)
| Setting | Recommended Value |
|---|---|
| Screen effect | None |
| Color correction | Enabled |
| Interframe blending | Enabled |

---

## Shader Parameters

All parameters are accessible from the in-game shader settings menu under **Options > Shaders > Optional Shader Settings**. You can also edit the default values directly in `PT_SkyWalker541.glsl` — each parameter has a `#define` near the top of the file that sets its default.

---

### System Preset — `PT_SYSTEM`
**Default: 1 (GB)**

This is the most important setting. It configures how aggressively the shader detects white and transparent pixels, tuned specifically for each system's display characteristics.

| Value | System | Description |
|---|---|---|
| 0 | Manual | Use PT_SENSITIVITY to tune detection yourself |
| 1 | GB | Original Game Boy — no backlight, aggressive detection |
| 2 | GBC | Game Boy Color — no backlight, moderate detection |
| 3 | GBA | Game Boy Advance — backlit screen, conservative detection |

**Always set this first** before adjusting anything else. The right preset will get you most of the way there out of the box.

To change the default, find this line in `PT_SkyWalker541.glsl`:
```
#define PT_SYSTEM  1.0
```
Change `1.0` to `2.0` for GBC or `3.0` for GBA.

---

### Detection Sensitivity — `PT_SENSITIVITY`
**Default: 0.85 | Range: 0.10 – 1.00 | Only active when PT_SYSTEM = 0 (Manual)**

Controls how aggressively the shader detects white pixels when in Manual mode. Has no effect when using a system preset (GB, GBC, or GBA).

- **Higher values** (closer to 1.0) — only very obvious, clearly white pixels go transparent
- **Lower values** (closer to 0.10) — more pixels are treated as white and go transparent

Use this if the system presets aren't working well for your specific game, particularly if you are using GB colorization.

---

### Transparency Mode — `PT_PIXEL_MODE`
**Default: 0 (White only)**

Selects which pixels become transparent.

| Value | Mode | Description |
|---|---|---|
| 0 | White only | Only white and near-white pixels go transparent — most authentic |
| 1 | Bright | Brighter pixels become proportionally more transparent |
| 2 | All | Every pixel blends toward the backing texture |

**Mode 0 is recommended** for the most accurate look. Modes 1 and 2 are more stylistic choices.

---

### Base Transparency — `PT_BASE_ALPHA`
**Default: 0.20 | Range: 0.00 – 1.00**

Controls how transparent detected pixels become. Think of this as the base strength of the effect.

- **Lower values** — pixels become only slightly see-through
- **Higher values** — pixels become more transparent, letting more of the backing texture show through

Works together with **PT_WHITE_TRANSPARENCY** for detected white pixels.

---

### White Pixel Transparency Boost — `PT_WHITE_TRANSPARENCY`
**Default: 0.50 | Range: 0.00 – 1.00**

Sets a minimum transparency level specifically for pixels detected as white. Ensures that clearly white pixels are always at least this transparent, even if the base calculation would give a lower value.

- **Lower values** — white pixels blend in closer to other transparent pixels
- **Higher values** — white pixels go more transparent than other bright pixels

---

### Brightness Mode — `PT_BRIGHTNESS_MODE`
**Default: 1 (Perceptual)**

Controls how the shader measures pixel brightness when deciding how transparent a pixel should be.

| Value | Mode | Best for |
|---|---|---|
| 0 | Simple | Equal average of R, G, B channels — good for GB/GBC |
| 1 | Perceptual | Human vision weighted (ITU-R BT.709) — good for GBA and colour content |

Most users won't need to change this. Perceptual mode is the default as it produces more natural results across all systems.

---

### Background Tint — `PT_PALETTE`
**Default: 1 (Pocket)**

Selects the colour of the procedural backing texture that shows through transparent pixels. This simulates different types of screen backing material.

| Value | Tint | Description |
|---|---|---|
| 0 | OFF | Neutral grey grain |
| 1 | Pocket | Warm green-grey — approximates the original Game Boy screen backing |
| 2 | Grey | Neutral grey |
| 3 | White | Clean white backing |

---

### Background Tint Intensity — `PT_PALETTE_INTENSITY`
**Default: 1.00 | Range: 0.00 – 2.00**

Controls how strongly the chosen tint colour is applied to the backing texture.

- **Lower values** — the backing texture stays closer to neutral grey
- **Higher values** — the tint colour becomes more prominent

---

### Color Harshness Filter — `PT_DARK_FILTER_LEVEL`
**Default: 10 | Range: 0 – 100**

Softens overly vivid or harsh dark colours. Useful for GBC games with very aggressive colour palettes that can look unnaturally saturated on modern displays.

- **0** — filter disabled, colours are unchanged
- **Higher values** — progressively softer, darker colours are toned down more

> Set your core's Dark Filter Level to 0 and use this parameter instead — running both will double the effect.

---

### Pixel Border — `PT_PIXEL_BORDER`
**Default: 1 (Subtle)**

Simulates the thin physical gap between individual LCD dots on original hardware, making each pixel visually distinct. This is what gives the image that characteristic "you can see individual pixels" look of original handhelds.

| Value | Style | Description |
|---|---|---|
| 0 | OFF | No pixel border effect |
| 1 | Subtle | Closest to original GB/GBC/GBA hardware appearance |
| 2 | Moderate | More visible borders — personal preference |
| 3 | Strong | Clearly defined pixel grid |

---

### Shadow X Offset — `PT_SHADOW_OFFSET_X`
**Default: 1.5 | Range: -30.0 – 30.0**

Controls how far the drop shadow shifts horizontally. Positive values push the shadow to the left, negative values to the right. Drop shadows appear behind solid pixels and are visible through transparent areas, adding depth to sprites and text.

---

### Shadow Y Offset — `PT_SHADOW_OFFSET_Y`
**Default: 1.5 | Range: -30.0 – 30.0**

Controls how far the drop shadow shifts vertically. Positive values push the shadow upward, negative values downward.

---

### Shadow Opacity — `PT_SHADOW_OPACITY`
**Default: 0.50 | Range: 0.00 – 1.00**

Controls how dark and visible the drop shadow is.

- **0** — shadow disabled
- **Higher values** — darker, more prominent shadow

---

### Shadow Blur — `PT_SHADOW_BLUR`
**Default: 1.0 | Range: 0.0 – 5.0**

Controls how soft and spread out the shadow edges are. The blur uses a weighted pattern that is strongest at the shadow source and fades outward, matching the natural look of original hardware passive LCD shadows.

- **Lower values** — sharper, harder shadow edge
- **Higher values** — softer, more spread out shadow

---

### Chromatic Shift — `PT_CHROMA`
**Default: 0.20 | Range: 0.00 – 1.00**

Simulates the slight colour channel misalignment characteristic of original GB/GBC/GBA LCD panels, where the red and blue channels were not perfectly spatially aligned. Gives the image a subtle organic quality.

- **0** — disabled, perfectly aligned colour channels
- **Higher values** — more pronounced colour separation toward screen edges

This effect is most visible on bright colours near the edges of the screen.

---

### Vignette — `PT_VIGNETTE`
**Default: 0.12 | Range: 0.00 – 1.00**

Darkens the screen toward the edges and corners, simulating the uneven light distribution of original handheld screens and their physical bezels.

- **0** — disabled, uniform brightness across the screen
- **Higher values** — more pronounced darkening toward the corners

---

## Editing Default Values

Every parameter has a default value defined near the top of `PT_SkyWalker541.glsl`. Look for the block that starts with `#else` after the `#ifdef PARAMETER_UNIFORM` section. It looks like this:

```glsl
#define PT_SYSTEM             1.0
#define PT_SENSITIVITY        0.85
#define PT_PIXEL_MODE         0.0
#define PT_BASE_ALPHA         0.20
#define PT_WHITE_TRANSPARENCY 0.50
...
```

Change any value here to set a new default. These values are used when the shader is first loaded, and can still be overridden from the in-game settings menu at any time.

---

## Known Limitations

- **OrigTexture** is not yet supported in NextUI. White detection currently runs against the post-processed image rather than the raw game frame. Per-system thresholds are pre-compensated to account for this. A future update will take advantage of OrigTexture support when it becomes available in NextUI, which will improve detection accuracy significantly.

---

## Changelog

| Version | Notes |
|---|---|
| v1.0.9 | Fixed PT_PIXEL_BORDER modes 2 and 3 — each mode now correctly increases both border width and darkness. PT_VIGNETTE default lowered to 0.12 |
| v1.0.8 | Replaced sin()-based noise hash with arithmetic hash — significant speedup on PowerVR GPUs |
| v1.0.7 | Chromatic shift rewritten as pure math — fixes pink tint, eliminates slowdown |
| v1.0.6 | Replaced subpixel fringing with chromatic shift — eliminates slowdown |
| v1.0.5 | Added chromatic shift and vignette |
| v1.0.4 | Shadow blur upgraded to weighted 4-tap with exponential falloff |
| v1.0.3 | Removed all ON/OFF toggle parameters — all features always active |
| v1.0.2 | Added PT_PIXEL_BORDER — simulates LCD dot gaps |
| v1.0.1 | Replaced adaptive white detection with lightweight dual-channel method |
| v1.0.0 | Initial release — full independent rewrite |

---

*PT SkyWalker541 by SkyWalker541 | Written for NextUI*
