/*
    PT SkyWalker541 Aspect  v1.2.0
    by SkyWalker541  |  Written for NextUI
    File: PT_SkyWalker541_Aspect.glsl

    On original Game Boy, GBC, and GBA hardware, screen pixels that were fully
    off did not display as white — the display had no backlight driving those
    areas, so they appeared as the physical backing material showing through:
    a grey-green translucency rather than solid white. Game developers of that
    era designed around this, using "white" areas as intentional transparent
    regions for backgrounds, windows, and UI overlays.

    On modern displays and emulators, those same pixels render as bright white,
    which was never the intended look and can be visually jarring. PT SkyWalker541
    restores the original appearance by detecting bright/white pixels and blending
    them toward a procedurally generated backing texture — putting the transparency
    back where it belongs.

    Use this variant for ASPECT RATIO / NON-INTEGER scaling.
    Use PT_SkyWalker541_Integer.glsl for NATIVE / INTEGER scaling.

    A standalone shader — no additional passes required.

    ========================
    QUICK START
    ========================
    1. Set PT_SYSTEM to match your target system (1=GB, 2=GBC, 3=GBA)
    2. Per-system recommended settings:

         GB  (PT_SYSTEM = 1)
              Screen effect:          None
              Color correction:       Disabled
              Frontlight position:    Central
              Dark filter level:      0  (PT_DARK_FILTER_LEVEL handles this instead)
              Interframe blending:    Disabled
              GB Colorization:        Disabled recommended — any colorization palette
                                      can shift what registers as white. If you use
                                      colorization (Auto, GBC, SGB, Internal, or Custom),
                                      switch to Manual mode and lower PT_SENSITIVITY
                                      until backgrounds go transparent as expected.

         GBC (PT_SYSTEM = 2)
              Screen effect:          None
              Color correction:       GBC Only
              Frontlight position:    Central
              Dark filter level:      0  (PT_DARK_FILTER_LEVEL handles this instead)
              Interframe blending:    Disabled

         GBA (PT_SYSTEM = 3)
              Screen effect:          None
              Color correction:       Enabled
              Interframe blending:    Enabled

    ========================
    KNOWN LIMITATIONS
    ========================
    - White detection runs against the post-processed texture rather than
      the raw game frame. Per-system thresholds are pre-compensated to
      account for this and produce accurate results.
    - When NextUI adds support for OrigTexture as a separate pass, the
      shader will be updated to take advantage of it for improved
      detection accuracy.

    ========================
    CHANGELOG
    ========================
    v1.2.0 - SkyWalker541
         - Updated defaults to period-authentic values based on original hardware
           research and device testing (verified on 1024x768, applicable at any
           resolution):
             PT_SHADOW_OFFSET_X  1.5 → 1.0  (smallest visible diagonal shift)
             PT_SHADOW_OFFSET_Y  1.5 → 1.0
             PT_SHADOW_OPACITY   0.50 → 0.30 (subtle depth, not visually dominant)
             PT_VIGNETTE         0.12 → 0.08 (below conscious perception threshold)

    v1.1.6 - SkyWalker541
         - Removed shadow blur entirely. PT_SHADOW_BLUR parameter removed.
           Shadow is now a single texture tap — lowest possible cost while
           retaining the shadow effect. At GB/GBC/GBA pixel scales, blur is
           imperceptible at any typical display resolution.

    v1.1.5 - SkyWalker541
         - Replaced 4-tap cross shadow blur with 2-tap diagonal blur — two opposite
           corner samples cover both X and Y softening, halving texture fetch cost
           with no meaningful change to shadow appearance at GBC pixel scales

    v1.1.4 - SkyWalker541
         - Fixed pixel border visibility in Aspect — wfactor multipliers were
           inverted, producing the complement of the intended GRID_WIDTH values.
           Subtle/Moderate/Strong now produce 17%/41%/76% border darkening,
           matching the Integer variant in visual impact.

    v1.1.3 - SkyWalker541
         - Fixed shadow performance — removed floor()/TextureSize re-snapping from
           the 4 blur taps. Blur taps step by exactly one texel from the already-snapped
           shadow position, so re-snapping was redundant and expensive on PowerVR.
           Replaced with direct InvTextureSize offset — same result, much lower cost.

    v1.1.2 - SkyWalker541
         - Fixed pixel border — wrapped imgPixelCoord with fract() before computing
           sine angle, keeping arguments in 0..1 range. Large raw values (~1005 rad)
           caused precision loss on mediump (PowerVR), producing a flat/broken grid
         - Fixed drop shadows — removed redundant isWhitePixel gate on shadow sample.
           The gate prevented shadows from drawing when transparent areas are adjacent
           to other white pixels (textboxes, large UI fills). The underlying math
           already handles white-behind-white correctly: brightness ~ 1.0 produces
           shadowStrength ~ 0, so bg is unchanged. No gate needed.

    v1.1.1 - SkyWalker541
         - Fixed drop shadows — shadow and blur taps now snap to texel centre
           matching the main pixel sample, ensuring reliable lookups on PowerVR
         - Fixed pixel border — corrected sine-wave wfactor values so all three
           modes produce a clearly visible grid (were too subtle to see on device)

    v1.1.0 - SkyWalker541
         - Split into Aspect and Integer variants
         - Aspect: pixel border uses sine-wave method (proven for any scale)
         - Integer: pixel border uses distFromCenter method (clean at integer scale)
         - Shadow formula rewritten using TextureSize/InputSize/OutputSize only —
           drops OrigInputSize which was unreliable on NextUI

    v1.0.9 - SkyWalker541
         - Fixed PT_PIXEL_BORDER modes 2 and 3 — each mode now correctly
           increases both border width and darkness independently
         - PT_VIGNETTE default lowered from 0.25 to 0.12 for a more
           subtle, authentic corner darkening out of the box

    v1.0.8 - SkyWalker541
         - Replaced sin()-based noise hash with arithmetic multiply/fract hash
           Eliminates 8 sin() calls per pixel — significant speedup on PowerVR

    v1.0.7 - SkyWalker541
         - Chromatic shift rewritten as pure math on existing pixel data —
           zero texture samples, fixes pink tint and eliminates slowdown

    v1.0.6 - SkyWalker541
         - Replaced subpixel fringing (2 texture taps) with chromatic shift
           (pure UV math, zero extra texture samples) — eliminates slowdown
         - PT_FRINGE renamed to PT_CHROMA

    v1.0.5 - SkyWalker541
         - Added PT_FRINGE: subpixel colour fringing simulating lateral bleed
           between adjacent LCD pixels on original hardware (2 extra taps)
         - Added PT_VIGNETTE: radial screen edge darkening simulating physical
           screen bezel and passive LCD response falloff (pure math, no taps)

    v1.0.4 - SkyWalker541
         - Shadow blur upgraded to weighted 4-tap with exponential falloff
           Center tap weighted at 0.5, outer taps at 0.125 each for natural fade
           Squared falloff matches passive LCD shadow behaviour of original hardware

    v1.0.3 - SkyWalker541
         - Removed all ON/OFF toggle parameters — all features always active
         - PT_DARK_FILTER_LEVEL now goes to 0 to disable (no separate toggle)
         - PT_SHADOW_OPACITY now goes to 0 to disable shadows (no separate toggle)
         - PT_WHITE_BOOST removed — white transparency boost always applied
         - PT_ENABLE removed — shader is always active
         - PT_BRIGHTNESS_GRID removed — was non-functional (reserved for future)
         - Default system preset changed to GB (1)

    v1.0.2 - SkyWalker541
         - Added PT_PIXEL_BORDER parameter (0=OFF, 1=Subtle, 2=Moderate, 3=Strong)
           Simulates the physical gap between LCD dots on original hardware using
           sine-wave grid darkening — no extra texture samples

    v1.0.1 - SkyWalker541
         - Replaced adaptive 4-tap neighborhood white detection with lightweight
           dual-channel ratio method — zero extra texture samples, lower GPU load
         - Removed sensitivity parameter from system preset resolution

    v1.0.0 - SkyWalker541
         - Full independent rewrite
         - System presets (GB / GBC / GBA) with pre-tuned, pre-compensated thresholds
         - Adaptive neighborhood-based white detection replaces fixed global threshold
         - PT_SENSITIVITY replaces raw threshold value for more intuitive user control
         - Hue-preserving transparency blend — colored and pastel backgrounds no
           longer wash out to grey during the blend
         - Drop shadows restricted to transparent pixels only
         - 4-tap diamond shadow blur optimized for low sample count
         - Procedural backing texture rewritten with smooth bicubic-interpolated noise
         - All parameters and constants documented inline
*/

// ========================
// SYSTEM PRESET
// ========================
// Set this first. Configures detection thresholds for your target system.
// Thresholds are pre-compensated for post-processing (NextUI).
//   0 = Manual  — tune PT_SENSITIVITY yourself
//   1 = GB      — original Game Boy, no backlight, aggressive transparency
//   2 = GBC     — Game Boy Color, no backlight, moderate transparency
//   3 = GBA     — Game Boy Advance, backlit, conservative transparency
#pragma parameter PT_SYSTEM "== PT SkyWalker541 Aspect v1.2.0 == System (0=Manual, 1=GB, 2=GBC, 3=GBA)" 1.0 0.0 3.0 1.0

// ========================
// SENSITIVITY (Manual mode only)
// ========================
// Only active when PT_SYSTEM = 0.
// Higher = only very obvious whites detected. Lower = more aggressive detection.
#pragma parameter PT_SENSITIVITY "== Detection sensitivity (Manual mode only)" 0.85 0.10 1.0 0.01

// ========================
// TRANSPARENCY
// ========================
// Mode selects which pixels become transparent:
//   0 = White only  — only white/near-white pixels (recommended, most authentic)
//   1 = Bright      — brighter pixels become proportionally more transparent
//   2 = All         — all pixels blend toward background
#pragma parameter PT_PIXEL_MODE  "== Transparency mode == (0=White, 1=Bright, 2=All)" 0.0 0.0 2.0 1.0
#pragma parameter PT_BASE_ALPHA  "     ↳ Base transparency amount" 0.20 0.0 1.0 0.01
// White transparency boost — raises the transparency floor for detected white pixels
#pragma parameter PT_WHITE_TRANSPARENCY "     ↳ White pixel transparency boost" 0.50 0.0 1.0 0.01

// ========================
// BRIGHTNESS MODE
// ========================
// 0 = Simple      — equal RGB average, good for GB/GBC
// 1 = Perceptual  — ITU-R BT.709 weighted luma, good for GBA and color content
#pragma parameter PT_BRIGHTNESS_MODE "== Brightness mode == (0=Simple, 1=Perceptual)" 1.0 0.0 1.0 1.0

// ========================
// BACKGROUND TINT
// ========================
// Tints the procedural backing texture to approximate different screen materials.
//   0 = OFF    — neutral grey grain
//   1 = Pocket — warm green-grey (approximates original GB screen backing)
//   2 = Grey   — neutral grey
//   3 = White  — clean white backing
#pragma parameter PT_PALETTE           "== Background tint == (0=OFF, 1=Pocket, 2=Grey, 3=White)" 1.0 0.0 3.0 1.0
#pragma parameter PT_PALETTE_INTENSITY "     ↳ Tint intensity" 1.0 0.0 2.0 0.05

// ========================
// COLOR HARSHNESS FILTER
// ========================
// Softens overly vivid dark colors. Set to 0 to disable.
// Useful for GBC games with aggressive palettes.
#pragma parameter PT_DARK_FILTER_LEVEL "== Color harshness filter amount (0=OFF)" 10.0 0.0 100.0 1.0

// ========================
// PIXEL BORDER
// ========================
// Simulates the thin physical gap between LCD dots on original hardware.
// Uses a sine-wave method that works correctly at any scale mode.
// For a more visible pixel grid, increase to mode 2 or 3.
//   0 = OFF
//   1 = Subtle   — closest to original hardware appearance (default)
//   2 = Moderate — more visible, suits personal preference
//   3 = Strong   — clearly defined pixel borders
#pragma parameter PT_PIXEL_BORDER "== Pixel border == (0=OFF, 1=Subtle, 2=Moderate, 3=Strong)" 1.0 0.0 3.0 1.0

// ========================
// CHROMATIC SHIFT
// ========================
// Simulates the slight colour separation characteristic of original GB/GBC/GBA
// LCD panels, where R and B channels were not perfectly spatially aligned.
// Achieved by offsetting R and B channels in opposite horizontal directions
// using UV math only — zero extra texture samples, no GPU cost.
// Set to 0 to disable.
#pragma parameter PT_CHROMA "== Chromatic shift amount (0=OFF)" 0.20 0.0 1.0 0.01

// ========================
// VIGNETTE
// ========================
// Darkens the screen toward the edges, simulating the uneven light
// distribution and physical screen bezel of original handheld hardware.
// Pure math — no extra texture samples. Set to 0 to disable.
#pragma parameter PT_VIGNETTE "== Vignette strength (0=OFF)" 0.08 0.0 1.0 0.01

// ========================
// DROP SHADOWS
// ========================
// Casts a shadow behind solid pixels, visible through transparent areas.
// Adds subtle depth at sprite and text edges.
// Single texture tap — no blur. At GB/GBC/GBA pixel scales, shadow edge
// softening is imperceptible at any typical display resolution. Default
// offset of 1.0/1.0 is the smallest visible diagonal shift — closest to
// a period-authentic look without the shadow dominating.
// Set opacity to 0 to disable shadows entirely.
#pragma parameter PT_SHADOW_OFFSET_X "== Shadow X offset" 1.0 -30.0 30.0 0.5
#pragma parameter PT_SHADOW_OFFSET_Y "     ↳ Shadow Y offset" 1.0 -30.0 30.0 0.5
#pragma parameter PT_SHADOW_OPACITY  "     ↳ Shadow opacity (0=OFF)" 0.30 0.0 1.0 0.01

// =============================================================================
// VERTEX SHADER
// =============================================================================
#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING    out
#define COMPAT_ATTRIBUTE  in
#define COMPAT_TEXTURE    texture
#else
#define COMPAT_VARYING    varying
#define COMPAT_ATTRIBUTE  attribute
#define COMPAT_TEXTURE    texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING   vec4 TEX0;
COMPAT_VARYING   vec2 InvTextureSize;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int  FrameDirection;
uniform COMPAT_PRECISION int  FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position    = MVPMatrix * VertexCoord;
    TEX0.xy        = TexCoord.xy;
    InvTextureSize = 1.0 / TextureSize;
}

// =============================================================================
// FRAGMENT SHADER
// =============================================================================
#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING  in
#define COMPAT_TEXTURE  texture
out vec4 FragColor;
#else
#define COMPAT_VARYING  varying
#define FragColor       gl_FragColor
#define COMPAT_TEXTURE  texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int  FrameDirection;
uniform COMPAT_PRECISION int  FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// OrigTexture aliased to Texture — will be updated when NextUI adds OrigTexture support.
uniform sampler2D Texture;
#define Source Texture

COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 InvTextureSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float PT_SYSTEM;
uniform COMPAT_PRECISION float PT_SENSITIVITY;
uniform COMPAT_PRECISION float PT_PIXEL_MODE;
uniform COMPAT_PRECISION float PT_BASE_ALPHA;
uniform COMPAT_PRECISION float PT_WHITE_TRANSPARENCY;
uniform COMPAT_PRECISION float PT_BRIGHTNESS_MODE;
uniform COMPAT_PRECISION float PT_PALETTE;
uniform COMPAT_PRECISION float PT_PALETTE_INTENSITY;
uniform COMPAT_PRECISION float PT_DARK_FILTER_LEVEL;
uniform COMPAT_PRECISION float PT_PIXEL_BORDER;
uniform COMPAT_PRECISION float PT_SHADOW_OFFSET_X;
uniform COMPAT_PRECISION float PT_SHADOW_OFFSET_Y;
uniform COMPAT_PRECISION float PT_SHADOW_OPACITY;
uniform COMPAT_PRECISION float PT_CHROMA;
uniform COMPAT_PRECISION float PT_VIGNETTE;
#else
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
#endif

// Perceptual luma weights — ITU-R BT.709
#define LUMA_R 0.2126
#define LUMA_G 0.7152
#define LUMA_B 0.0722

// Sine-wave pixel border constant
#define PI 3.141592654
#define BORDER_WIDTH_FACTOR_MAX 31.0

// -----------------------------------------------------------------------------
// Resolve system preset into a working detection threshold.
//
// Thresholds are pre-compensated for post-processing detection.
// Color correction darkens the image before this pass runs,
// so values are tuned lower than a clean frame would require.
//
//   GB:     0.58 — no backlight, aggressive
//   GBC:    0.65 — no backlight, moderate
//   GBA:    0.42 — backlit, conservative
//   Manual: uses PT_SENSITIVITY directly
// -----------------------------------------------------------------------------
float resolveThreshold()
{
    if (PT_SYSTEM < 0.5)  return PT_SENSITIVITY; // Manual
    if (PT_SYSTEM < 1.5)  return 0.58;           // GB
    if (PT_SYSTEM < 2.5)  return 0.65;           // GBC
    return 0.42;                                  // GBA
}

// -----------------------------------------------------------------------------
// Brightness functions
// -----------------------------------------------------------------------------
float perceptualBrightness(vec3 c)
{
    return LUMA_R * c.r + LUMA_G * c.g + LUMA_B * c.b;
}

float simpleBrightness(vec3 c)
{
    return (c.r + c.g + c.b) / 3.0;
}

float getBrightness(vec3 c)
{
    return (PT_BRIGHTNESS_MODE < 0.5) ? simpleBrightness(c) : perceptualBrightness(c);
}

// -----------------------------------------------------------------------------
// White pixel detection — dual-channel ratio method.
//
// A genuine white pixel is both bright AND has low variation across R, G, B
// channels. This naturally rejects pixels that are only bright due to
// color correction processing, which tends to produce uneven channel values.
// Zero extra texture samples — runs entirely on the current pixel.
// -----------------------------------------------------------------------------
float isWhitePixel(vec3 pixel, float threshold)
{
    float brightness   = perceptualBrightness(pixel);
    float maxChannel   = max(max(pixel.r, pixel.g), pixel.b);
    float minChannel   = min(min(pixel.r, pixel.g), pixel.b);
    float channelRange = maxChannel - minChannel;
    return (brightness > threshold && channelRange < 0.15) ? 1.0 : 0.0;
}

// -----------------------------------------------------------------------------
// Color harshness filter.
// Reduces perceived harshness of vivid dark colors by scaling toward black
// proportional to luma. Bright pixels are largely unaffected.
// -----------------------------------------------------------------------------
vec3 applyDarkFilter(vec3 c, float level)
{
    float strength = level * 0.01;
    float luma     = perceptualBrightness(c);
    float factor   = max(1.0 - strength * luma, 0.0);
    return c * factor;
}

// -----------------------------------------------------------------------------
// Procedural backing texture.
//
// Generates a subtle grain to approximate the physical backing material visible
// through unlit pixels on an original GB/GBC/GBA screen.
// Hash uses integer arithmetic only — no trig, fast on PowerVR-class GPUs.
// -----------------------------------------------------------------------------
float noiseHash(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    vec2 h = vec2(127.1, 311.7);
    float a = fract(dot(i,             h) * 0.0243902);
    float b = fract(dot(i + vec2(1,0), h) * 0.0243902);
    float c = fract(dot(i + vec2(0,1), h) * 0.0243902);
    float d = fract(dot(i + vec2(1,1), h) * 0.0243902);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 proceduralBackground(vec2 uv)
{
    vec2  p     = uv * 256.0;
    float grain = noiseHash(p) * 0.5 + noiseHash(p * 2.0) * 0.25;
    float offset = (grain - 0.375) * 0.065;
    return vec3(0.478 + offset);
}

// -----------------------------------------------------------------------------
// Hue-preserving transparency blend.
// -----------------------------------------------------------------------------
vec3 huePreservingBlend(vec3 src, vec3 bg, float alpha)
{
    float srcLuma   = perceptualBrightness(src);
    float bgLuma    = perceptualBrightness(bg);
    float blendLuma = mix(srcLuma, bgLuma, alpha);
    float ratio     = (srcLuma > 0.001) ? (blendLuma / srcLuma) : 1.0;
    return clamp(src * ratio, 0.0, 1.0);
}

// -----------------------------------------------------------------------------
// Pixel border — sine-wave method.
//
// Uses a sine-wave grid pattern that works correctly at any scale mode,
// including aspect ratio and non-integer scaling. Based on the lcd3x method.
// The 0.25 offset ensures grid lines fall between pixels rather than on them.
// -----------------------------------------------------------------------------
float pixelBorderFactor(vec2 coord)
{
    if (PT_PIXEL_BORDER < 0.5) return 1.0;

    // Pixel coordinate in texture space — proven approach for NextUI.
    // fract() wraps to 0..1 per texel before multiplying by 2*PI,
    // keeping sin() arguments small and precise on mediump hardware.
    vec2 imgPixelCoord = fract(coord * TextureSize);

    vec2 angle = 2.0 * PI * (imgPixelCoord - 0.25);

    // Width factor controls how wide the bright center of each pixel is
    // vs how much is border. Higher = narrower border.
    float wfactor, strength;
    if (PT_PIXEL_BORDER < 1.5) {
        wfactor  = 1.0 + (BORDER_WIDTH_FACTOR_MAX - (0.80 * BORDER_WIDTH_FACTOR_MAX));
        strength = 0.40; // Subtle   — equivalent to GRID_WIDTH 0.80
    } else if (PT_PIXEL_BORDER < 2.5) {
        wfactor  = 1.0 + (BORDER_WIDTH_FACTOR_MAX - (0.90 * BORDER_WIDTH_FACTOR_MAX));
        strength = 0.65; // Moderate — equivalent to GRID_WIDTH 0.90
    } else {
        wfactor  = 1.0 + (BORDER_WIDTH_FACTOR_MAX - (0.97 * BORDER_WIDTH_FACTOR_MAX));
        strength = 0.85; // Strong   — equivalent to GRID_WIDTH 0.97
    }

    float yfactor   = (wfactor + sin(angle.y)) / (wfactor + 1.0);
    float xfactor   = (wfactor + sin(angle.x)) / (wfactor + 1.0);
    float lineWeight = 1.0 - (yfactor * xfactor);

    return 1.0 - lineWeight * strength;
}

// -----------------------------------------------------------------------------
// Chromatic shift.
// -----------------------------------------------------------------------------
vec3 applyChromaShift(vec3 color, vec2 coord)
{
    if (PT_CHROMA < 0.001) return color;
    vec2 offset = (coord - 0.5) * PT_CHROMA * 0.02;
    float r = mix(color.r, color.r * (1.0 + offset.x), 0.5);
    float b = mix(color.b, color.b * (1.0 - offset.x), 0.5);
    return clamp(vec3(r, color.g, b), 0.0, 1.0);
}

// -----------------------------------------------------------------------------
// Vignette.
// -----------------------------------------------------------------------------
vec3 applyVignette(vec3 color, vec2 coord)
{
    if (PT_VIGNETTE < 0.001) return color;
    vec2 uv        = coord * 2.0 - 1.0;
    float dist     = dot(uv, uv);
    float vignette = 1.0 - dist * PT_VIGNETTE;
    return color * clamp(vignette, 0.0, 1.0);
}

// =============================================================================
// MAIN
// =============================================================================
void main()
{
    // Sample current pixel — snap to texel center to avoid filtering artifacts
    vec2 imgPixelCoord  = TEX0.xy * TextureSize;
    vec2 imgCenterCoord = floor(imgPixelCoord) + vec2(0.5);
    vec4 lcd   = COMPAT_TEXTURE(Source, imgCenterCoord * InvTextureSize);
    vec3 pixel = lcd.rgb;

    // Color harshness filter
    if (PT_DARK_FILTER_LEVEL > 0.5) {
        pixel   = applyDarkFilter(pixel, PT_DARK_FILTER_LEVEL);
        lcd.rgb = pixel;
    }

    // Resolve per-system detection threshold
    float threshold = resolveThreshold();
    float isWhite   = isWhitePixel(pixel, threshold);

    // ------------------------------------------------------------------
    // Build procedural backing texture with optional palette tint
    // ------------------------------------------------------------------
    vec3 bg = proceduralBackground(TEX0.xy);

    if (PT_PALETTE > 0.5) {
        vec3 tint;
        if (PT_PALETTE < 1.5) {
            tint = vec3(0.651, 0.675, 0.518); // Pocket: warm green-grey
        } else if (PT_PALETTE < 2.5) {
            tint = vec3(0.737, 0.737, 0.737); // Grey
        } else {
            tint = vec3(1.0,   1.0,   1.0  ); // White
        }
        vec3 tinted = clamp(vec3(
            tint.r + mix(-1.0, 1.0, bg.r),
            tint.g + mix(-1.0, 1.0, bg.g),
            tint.b + mix(-1.0, 1.0, bg.b)
        ), 0.0, 1.0);
        bg = mix(bg, tinted, PT_PALETTE_INTENSITY);
    }

    // ------------------------------------------------------------------
    // Drop shadows — only cast through pixels that will be transparent.
    // Shadow offset uses InvTextureSize — proven on NextUI.
    // ------------------------------------------------------------------
    float willBeTransparent = 0.0;
    if (PT_PIXEL_MODE < 0.5) {
        willBeTransparent = isWhite;
    } else if (PT_PIXEL_MODE < 1.5) {
        willBeTransparent = step(threshold * 0.9, getBrightness(pixel));
    } else {
        willBeTransparent = 1.0;
    }

    if (willBeTransparent > 0.5 && PT_SHADOW_OPACITY > 0.001) {
        // Single tap shadow — one sample at the offset position.
        // No blur: at GB/GBC/GBA pixel scales, shadow edge softening is
        // imperceptible at any typical display resolution — verified on
        // 1024x768. Single tap matches the cost floor of the reference shaders.
        // No white gate — if behind-pixel is white, shadowStrength ~ 0 and
        // bg is unchanged. The math self-regulates.
        vec2 shadowPos       = TEX0.xy + vec2(-PT_SHADOW_OFFSET_X, -PT_SHADOW_OFFSET_Y) * InvTextureSize;
        float shadowDark     = 1.0 - getBrightness(COMPAT_TEXTURE(Source, shadowPos).rgb);
        float shadowStrength = (shadowDark * shadowDark) * PT_SHADOW_OPACITY;

        bg = mix(bg, bg * 0.2, shadowStrength);
    }

    // ------------------------------------------------------------------
    // Transparency blend
    // ------------------------------------------------------------------
    vec3 result = pixel;

    if (PT_PIXEL_MODE < 0.5) {
        if (isWhite > 0.5) {
            float intensity = getBrightness(pixel);
            float alpha     = clamp((intensity / 3.0) + PT_BASE_ALPHA, 0.0, 1.0);
            alpha           = max(alpha, PT_WHITE_TRANSPARENCY);
            result          = huePreservingBlend(pixel, bg, alpha);
        }
    } else if (PT_PIXEL_MODE < 1.5) {
        float intensity = getBrightness(pixel);
        float alpha     = clamp(PT_BASE_ALPHA * intensity * 2.4, 0.0, 1.0);
        if (isWhite > 0.5) alpha = max(alpha, PT_WHITE_TRANSPARENCY);
        result = huePreservingBlend(pixel, bg, alpha);
    } else {
        float intensity = getBrightness(pixel);
        float alpha     = clamp((intensity / 3.0) + PT_BASE_ALPHA, 0.0, 1.0);
        if (isWhite > 0.5) alpha = max(alpha, PT_WHITE_TRANSPARENCY);
        result = huePreservingBlend(pixel, bg, alpha);
    }

    result  = result * pixelBorderFactor(TEX0.xy);
    result  = applyChromaShift(result, TEX0.xy);
    result  = applyVignette(result, TEX0.xy);

    FragColor = vec4(result, lcd.a);
}
#endif
