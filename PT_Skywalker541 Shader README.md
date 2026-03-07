# PT SkyWalker541 v1.2.0
**by SkyWalker541 | Written for NextUI**

---

## What is this?

On original Game Boy, Game Boy Color, and Game Boy Advance hardware, pixels that were fully off didn't show as white. Because those screens had no backlight driving those areas, the physical backing material of the screen showed through instead — a subtle grey-green translucency rather than solid white. Game developers of that era designed around this, using "white" areas as intentional transparent zones for backgrounds, windows, and UI overlays.

On modern displays and emulators, those same pixels render as bright white, which was never the intended look. **PT SkyWalker541** restores the original appearance by detecting bright and white pixels and blending them toward a procedurally generated backing texture — putting the transparency back where it belongs.

Both shaders are standalone. No other shaders are required.

---

## Which shader should I use?

| File | Use when |
|---|---|
| `PT_SkyWalker541_Aspect.glsl` | Aspect ratio scaling or any non-integer scale mode |
| `PT_SkyWalker541_Integer.glsl` | Native / integer scaling only |

The difference is in how the pixel border effect works. The Aspect variant uses a sine-wave method that produces a smooth, even grid at any scale. The Integer variant uses a distance-from-center method that produces a sharper, cleaner grid but only looks correct at exact integer scale multiples.

If you are unsure, use the **Aspect** variant — it works correctly at any scale mode including native.

---

## Installation

1. Place both `.glsl` files and both `.cfg` files in your NextUI shaders folder
2. Load the appropriate `.cfg` from the in-game shader menu based on your scale mode
3. Open shader settings and set **PT_SYSTEM** to match your target system
4. Apply the recommended core settings for your system (see below)

---

## Recommended Core Settings

Before adjusting any shader parameters, configure your emulator core settings to match your target system. These settings work alongside the shader for the best result.

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

All parameters are the same between both shader variants. They are accessible from the in-game shader settings menu. You can also change the default values that load when the shader is first applied — see **Editing Default Values** at the bottom of this section.

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

**Always set this first** before adjusting anything else.

---

### Detection Sensitivity — `PT_SENSITIVITY`
**Default: 0.85 | Range: 0.10 – 1.00 | Only active when PT_SYSTEM = 0 (Manual)**

Controls how aggressively the shader detects white pixels when in Manual mode. Has no effect when using a system preset.

- **Higher values** (closer to 1.0) — only very obvious, clearly white pixels go transparent
- **Lower values** (closer to 0.10) — more pixels are treated as white and go transparent

---

### Transparency Mode — `PT_PIXEL_MODE`
**Default: 0 (White only)**

| Value | Mode | Description |
|---|---|---|
| 0 | White only | Only white and near-white pixels go transparent — most authentic |
| 1 | Bright | Brighter pixels become proportionally more transparent |
| 2 | All | Every pixel blends toward the backing texture |

**Mode 0 is recommended** for the most accurate look.

---

### Base Transparency — `PT_BASE_ALPHA`
**Default: 0.20 | Range: 0.00 – 1.00**

Controls how transparent detected pixels become.

- **Lower values** — pixels become only slightly see-through
- **Higher values** — pixels become more transparent, letting more of the backing texture show through

---

### White Pixel Transparency Boost — `PT_WHITE_TRANSPARENCY`
**Default: 0.50 | Range: 0.00 – 1.00**

Sets a minimum transparency level specifically for pixels detected as white. Ensures clearly white pixels are always at least this transparent.

- **Lower values** — white pixels blend in closer to other transparent pixels
- **Higher values** — white pixels go more transparent than other bright pixels

---

### Brightness Mode — `PT_BRIGHTNESS_MODE`
**Default: 1 (Perceptual)**

| Value | Mode | Best for |
|---|---|---|
| 0 | Simple | Equal average of R, G, B channels — good for GB/GBC |
| 1 | Perceptual | Human vision weighted — good for GBA and colour content |

---

### Background Tint — `PT_PALETTE`
**Default: 1 (Pocket)**

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

---

### Color Harshness Filter — `PT_DARK_FILTER_LEVEL`
**Default: 10 | Range: 0 – 100**

Softens overly vivid or harsh dark colours. Useful for GBC games with very aggressive colour palettes.

- **0** — filter disabled
- **Higher values** — progressively softer, darker colours are toned down more

> Set your core's Dark Filter Level to 0 and use this parameter instead.

---

### Pixel Border — `PT_PIXEL_BORDER`
**Default: 1 (Subtle)**

Simulates the thin physical gap between individual LCD dots on original hardware. The Aspect and Integer variants use different methods to draw the border, each optimised for their respective scale modes.

> **Integer variant tip:** At native/integer scaling the pixel grid is particularly sharp and satisfying. Consider increasing to mode 2 or 3 for a more visible grid effect.

| Value | Style | Description |
|---|---|---|
| 0 | OFF | No pixel border effect |
| 1 | Subtle | Closest to original hardware appearance |
| 2 | Moderate | More visible borders |
| 3 | Strong | Clearly defined pixel grid |

---

### Shadow X Offset — `PT_SHADOW_OFFSET_X`
**Default: 1.0 | Range: -30.0 – 30.0**

Controls how far the drop shadow shifts horizontally. Drop shadows appear behind solid pixels and are visible through transparent areas, adding depth to sprites and text. Default of 1.0 is the smallest visible diagonal shift — closest to a period-authentic look.

---

### Shadow Y Offset — `PT_SHADOW_OFFSET_Y`
**Default: 1.0 | Range: -30.0 – 30.0**

Controls how far the drop shadow shifts vertically.

---

### Shadow Opacity — `PT_SHADOW_OPACITY`
**Default: 0.30 | Range: 0.00 – 1.00**

- **0** — shadow disabled
- **Higher values** — darker, more prominent shadow

---

### Chromatic Shift — `PT_CHROMA`
**Default: 0.20 | Range: 0.00 – 1.00**

Simulates the slight colour channel misalignment of original GB/GBC/GBA LCD panels. Most visible on bright colours near screen edges.

- **0** — disabled
- **Higher values** — more pronounced colour separation

---

### Vignette — `PT_VIGNETTE`
**Default: 0.08 | Range: 0.00 – 1.00**

Darkens the screen toward the edges and corners, simulating the uneven light distribution of original handheld screens. Default of 0.08 sits below the threshold of conscious perception — you feel it more than see it.

- **0** — disabled
- **Higher values** — more pronounced darkening toward corners

---

## Editing Default Values

To change a default value, open either `.glsl` file in any text editor and find the block near the top that looks like this:

```glsl
#define PT_SYSTEM             1.0
#define PT_SENSITIVITY        0.85
#define PT_PIXEL_MODE         0.0
#define PT_BASE_ALPHA         0.20
#define PT_WHITE_TRANSPARENCY 0.50
#define PT_BRIGHTNESS_MODE    1.0
#define PT_PALETTE            1.0
#define PT_PALETTE_INTENSITY  1.0
#define PT_DARK_FILTER_LEVEL  10.0
#define PT_PIXEL_BORDER       1.0
#define PT_SHADOW_OFFSET_X    1.0
#define PT_SHADOW_OFFSET_Y    1.0
#define PT_SHADOW_OPACITY     0.30
#define PT_CHROMA             0.20
#define PT_VIGNETTE           0.08
```

Change the number on the right side of any line to set a new default. These values load when the shader first applies and can still be overridden from the in-game settings menu at any time.

---

## Compatibility

Both shaders work on any device and any resolution. Shadow offsets and pixel borders are calculated using proven coordinate methods that work correctly on NextUI regardless of device or display resolution.

**Note:** White detection runs against the post-processed texture rather than the raw game frame. Per-system thresholds are pre-compensated to account for this. When NextUI adds support for OrigTexture as a separate pass, the shaders will be updated to take advantage of it for improved detection accuracy.

---

## Changelog

| Version | Notes |
|---|---|
| v1.2.0 | Updated defaults to period-authentic values — shadow offset 1.5→1.0, shadow opacity 0.50→0.30, vignette 0.12→0.08. Verified on 1024x768, applicable at any resolution |
| v1.1.6 | Removed shadow blur entirely — PT_SHADOW_BLUR parameter removed. Shadow is now a single texture tap. At GB/GBC/GBA pixel scales, blur is imperceptible at any typical display resolution |
| v1.1.5 | Replaced 4-tap cross shadow blur with 2-tap diagonal blur — halves texture fetch cost on transparent pixels with no meaningful change to shadow appearance |
| v1.1.4 | Fixed Aspect pixel border — wfactor multipliers were inverted, producing near-invisible borders. Subtle/Moderate/Strong now produce 17%/41%/76% darkening, matching Integer in visual impact |
| v1.1.3 | Fixed shadow performance — blur tap re-snapping removed, replaced with direct texel-step offsets. Eliminates the slowdown introduced in v1.1.1 |
| v1.1.2 | Fixed Aspect pixel border — fract() applied before sine argument to prevent mediump precision loss on PowerVR. Fixed shadows in both shaders — removed white-pixel gate that blocked shadows inside large white fills like textboxes |
| v1.1.1 | Fixed drop shadows — all shadow and blur taps now snap to texel centre, matching the main sample. Fixed Aspect pixel border — sine-wave wfactor values corrected so all three modes produce a clearly visible grid |
| v1.1.0 | Split into Aspect and Integer variants. Pixel border and shadow methods rewritten using proven NextUI coordinate approach — works correctly at any resolution and scale mode |
| v1.0.9 | Fixed PT_PIXEL_BORDER modes 2 and 3. PT_VIGNETTE default lowered to 0.12 |
| v1.0.8 | Replaced sin()-based noise hash — significant speedup on PowerVR GPUs |
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
