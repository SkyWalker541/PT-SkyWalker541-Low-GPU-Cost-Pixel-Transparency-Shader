/*
    PT SkyWalker541  v1.0.9
    by SkyWalker541  |  Written for NextUI
    File: PT_SkyWalker541.glsl

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

    A standalone shader — no additional passes required.

    ========================
    QUICK START
    ========================
    1. Set PT_SYSTEM to match your target system (1=GB, 2=GBC, 3=GBA)
    2. Set Screen scaling to Native (avoids shadow artifacts at scaled resolutions)
    3. Per-system recommended settings:

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
    KNOWN LIMITATIONS (NextUI)
    ========================
    - OrigTexture is not yet supported in NextUI. White detection runs against
      the post-processed texture rather than the raw game frame. Per-system
      thresholds are pre-compensated to account for this.

    ========================
    CHANGELOG
    ========================
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
           edge-based darkening — no extra texture samples

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
// Pre-compensated for post-processing (no raw OrigTexture available in NextUI).
//   0 = Manual  — tune PT_SENSITIVITY yourself
//   1 = GB      — original Game Boy, no backlight, aggressive transparency
//   2 = GBC     — Game Boy Color, no backlight, moderate transparency
//   3 = GBA     — Game Boy Advance, backlit, conservative transparency
#pragma parameter PT_SYSTEM "== PT SkyWalker541 v1.0.9 == System (0=Manual, 1=GB, 2=GBC, 3=GBA)" 1.0 0.0 3.0 1.0

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
// No extra texture samples — cost is minimal.
//   0 = OFF
//   1 = Subtle   — closest to original GB/GBC hardware appearance
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
#pragma parameter PT_VIGNETTE "== Vignette strength (0=OFF)" 0.12 0.0 1.0 0.01

// ========================
// DROP SHADOWS
// ========================
// Casts a soft shadow behind solid pixels, visible through transparent areas.
// Adds depth and improves readability on sprites and text.
// Shadow blur uses a 4-tap diamond pattern — lightweight and GPU-friendly.
// Set opacity to 0 to effectively disable shadows.
#pragma parameter PT_SHADOW_OFFSET_X "== Shadow X offset" 1.5 -30.0 30.0 0.5
#pragma parameter PT_SHADOW_OFFSET_Y "     ↳ Shadow Y offset" 1.5 -30.0 30.0 0.5
#pragma parameter PT_SHADOW_OPACITY  "     ↳ Shadow opacity (0=OFF)" 0.5 0.0 1.0 0.01
#pragma parameter PT_SHADOW_BLUR     "     ↳ Shadow blur amount" 1.0 0.0 5.0 0.1

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
COMPAT_VARYING   vec2 texel;
COMPAT_VARYING   float shadow_scale_factor;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int  FrameDirection;
uniform COMPAT_PRECISION int  FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 OrigInputSize;

// OrigTextureSize not yet supported in NextUI — aliased to TextureSize.
// When support lands: uncomment uniform and remove define.
// uniform COMPAT_PRECISION vec2 OrigTextureSize;
#define OrigTextureSize TextureSize

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy     = TexCoord.xy;
    texel       = 1.0 / TextureSize;

    // Shadow scale factor compensates offset for output resolution
    // relative to a 640x480 reference baseline.
    float scale_x = OutputSize.x / 640.0;
    float scale_y = OutputSize.y / 480.0;
    shadow_scale_factor = sqrt(scale_x * scale_y);
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
uniform COMPAT_PRECISION vec2 OrigInputSize;

// OrigTexture not yet supported in NextUI — aliased to Texture.
// When support lands: uncomment OrigTextureSize + OrigTexture and remove defines.
// uniform COMPAT_PRECISION vec2 OrigTextureSize;
// uniform sampler2D OrigTexture;
#define OrigTextureSize TextureSize
uniform sampler2D Texture;
#define OrigTexture Texture
#define Source      Texture

COMPAT_VARYING vec4  TEX0;
COMPAT_VARYING vec2  texel;
COMPAT_VARYING float shadow_scale_factor;

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
uniform COMPAT_PRECISION float PT_SHADOW_BLUR;
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
#define PT_SHADOW_OFFSET_X    1.5
#define PT_SHADOW_OFFSET_Y    1.5
#define PT_SHADOW_OPACITY     0.5
#define PT_SHADOW_BLUR        1.0
#define PT_CHROMA             0.20
#define PT_VIGNETTE           0.12
#endif

// Perceptual luma weights — ITU-R BT.709
#define LUMA_R 0.2126
#define LUMA_G 0.7152
#define LUMA_B 0.0722

// -----------------------------------------------------------------------------
// Resolve system preset into a working detection threshold.
//
// Thresholds are pre-compensated for post-processing detection (no OrigTexture).
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
    // Must be bright enough AND have balanced channels (low range = near-white)
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
// Bicubic-interpolated value noise across two octaves.
// Hash uses integer arithmetic only — no trig, fast on PowerVR-class GPUs.
// -----------------------------------------------------------------------------
float noiseHash(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    // Smoothstep for C1 continuity
    f = f * f * (3.0 - 2.0 * f);
    // Arithmetic hash — multiply/fract only, no sin()
    vec2 h = vec2(127.1, 311.7);
    float a = fract(dot(i,             h) * 0.0243902);
    float b = fract(dot(i + vec2(1,0), h) * 0.0243902);
    float c = fract(dot(i + vec2(0,1), h) * 0.0243902);
    float d = fract(dot(i + vec2(1,1), h) * 0.0243902);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 proceduralBackground(vec2 uv)
{
    vec2  p      = uv * 256.0;
    // Two octaves: base grain + fine detail layer
    float grain  = noiseHash(p) * 0.5 + noiseHash(p * 2.0) * 0.25;
    float offset = (grain - 0.375) * 0.065;
    return vec3(0.478 + offset);
}

// -----------------------------------------------------------------------------
// Hue-preserving transparency blend.
//
// Standard mix() blends RGB uniformly, which desaturates colored/pastel pixels
// toward the grey background. Instead we blend only the luminance channel and
// scale chroma to match — hue and saturation are preserved through the blend.
// -----------------------------------------------------------------------------
vec3 huePreservingBlend(vec3 src, vec3 bg, float alpha)
{
    float srcLuma    = perceptualBrightness(src);
    float bgLuma     = perceptualBrightness(bg);
    float blendLuma  = mix(srcLuma, bgLuma, alpha);
    // Avoid divide-by-zero on black pixels
    float ratio      = (srcLuma > 0.001) ? (blendLuma / srcLuma) : 1.0;
    return clamp(src * ratio, 0.0, 1.0);
}

// -----------------------------------------------------------------------------
// Pixel border effect.
//
// Computes how far the current fragment sits from the center of its logical
// pixel in texture space. Pixels near their edges are darkened to simulate
// the thin physical gap between LCD dots on original hardware.
// Each mode increases both the sharpness of the border and its darkness.
// -----------------------------------------------------------------------------
float pixelBorderFactor(vec2 coord)
{
    if (PT_PIXEL_BORDER < 0.5) return 1.0;

    // Position within the current logical pixel (0.0 = center, 1.0 = edge)
    vec2 pixelPos = fract(coord * InputSize);
    vec2 centered = abs(pixelPos - 0.5) * 2.0;
    float edge    = max(centered.x, centered.y);

    // Each mode: sharpness controls where darkening starts,
    // strength controls how dark the border gets at maximum
    float sharpness, strength;
    if (PT_PIXEL_BORDER < 1.5) {
        sharpness = 0.70; strength = 0.40; // Subtle
    } else if (PT_PIXEL_BORDER < 2.5) {
        sharpness = 0.60; strength = 0.65; // Moderate — wider band, darker
    } else {
        sharpness = 0.50; strength = 0.85; // Strong — widest band, darkest
    }

    float border = smoothstep(sharpness, 1.0, edge);
    return 1.0 - border * strength;
}

// -----------------------------------------------------------------------------
// Chromatic shift.
//
// Simulates the slight R/B channel misalignment characteristic of original
// GB/GBC/GBA LCD panels. Achieved by scaling the R and B channels by a tiny
// amount in opposite directions around the screen centre — no texture samples,
// pure math on the existing pixel colour.
// -----------------------------------------------------------------------------
vec3 applyChromaShift(vec3 color, vec2 coord)
{
    if (PT_CHROMA < 0.001) return color;
    // Distance from screen centre, used to scale the shift
    vec2 offset = (coord - 0.5) * PT_CHROMA * 0.02;
    // R channel shifted slightly outward, B channel slightly inward
    float r = mix(color.r, color.r * (1.0 + offset.x), 0.5);
    float b = mix(color.b, color.b * (1.0 - offset.x), 0.5);
    return clamp(vec3(r, color.g, b), 0.0, 1.0);
}

// -----------------------------------------------------------------------------
// Vignette.
//
// Original handheld screens were physically darker toward the corners due
// to the screen bezel, reflective backing, and uneven passive LCD response.
// Computed as a smooth radial falloff from screen centre — pure math,
// no texture samples.
// -----------------------------------------------------------------------------
vec3 applyVignette(vec3 color, vec2 coord)
{
    if (PT_VIGNETTE < 0.001) return color;
    // Remap coord to -1..1 range, compute distance from centre
    vec2 uv       = coord * 2.0 - 1.0;
    float dist    = dot(uv, uv);
    // Smooth falloff — stronger at corners, gentle toward centre
    float vignette = 1.0 - dist * PT_VIGNETTE;
    return color * clamp(vignette, 0.0, 1.0);
}

// =============================================================================
// MAIN
// =============================================================================
void main()
{
    vec4 lcd   = COMPAT_TEXTURE(Source, TEX0.xy);
    vec3 pixel = lcd.rgb;

    // Color harshness filter — set PT_DARK_FILTER_LEVEL to 0 to bypass
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
        // Additive tint: shifts the backing texture toward the target color
        vec3 tinted = clamp(vec3(
            tint.r + mix(-1.0, 1.0, bg.r),
            tint.g + mix(-1.0, 1.0, bg.g),
            tint.b + mix(-1.0, 1.0, bg.b)
        ), 0.0, 1.0);
        bg = mix(bg, tinted, PT_PALETTE_INTENSITY);
    }

    // ------------------------------------------------------------------
    // Drop shadows — only cast through pixels that will be transparent
    // Set PT_SHADOW_OPACITY to 0 to effectively disable
    // ------------------------------------------------------------------
    float willBeTransparent = 0.0;
    if (PT_PIXEL_MODE < 0.5) {
        willBeTransparent = isWhite;
    } else if (PT_PIXEL_MODE < 1.5) {
        willBeTransparent = step(threshold * 0.9, getBrightness(pixel));
    } else {
        willBeTransparent = 1.0;
    }

    if (willBeTransparent > 0.5) {
        vec2 shadowOffset = vec2(-PT_SHADOW_OFFSET_X, -PT_SHADOW_OFFSET_Y)
                          * shadow_scale_factor
                          * OrigInputSize / (OutputSize * OrigTextureSize);

        vec2 shadowPos    = TEX0.xy + shadowOffset;
        vec3 shadowSample = COMPAT_TEXTURE(OrigTexture, shadowPos).rgb;
        float shadowWhite = isWhitePixel(shadowSample, threshold);

        if (shadowWhite < 0.5) {
            // Weighted 4-tap cross blur with exponential falloff.
            // Center sample carries more weight than the four outer taps,
            // so the shadow is strongest at source and fades outward naturally.
            // Exponential falloff (squared) makes the fade drop quickly,
            // matching the passive LCD shadow behaviour of original hardware.
            float blurDist = PT_SHADOW_BLUR
                           * shadow_scale_factor
                           * OrigInputSize.x / (OutputSize.x * OrigTextureSize.x);
            vec2 bp = shadowPos;

            // Center tap weighted at 0.5, four outer taps at 0.125 each (total = 1.0)
            float center  = 1.0 - getBrightness(shadowSample);
            float left    = 1.0 - getBrightness(COMPAT_TEXTURE(OrigTexture, bp + vec2(-blurDist,  0.0     )).rgb);
            float right   = 1.0 - getBrightness(COMPAT_TEXTURE(OrigTexture, bp + vec2( blurDist,  0.0     )).rgb);
            float up      = 1.0 - getBrightness(COMPAT_TEXTURE(OrigTexture, bp + vec2( 0.0,      -blurDist)).rgb);
            float down    = 1.0 - getBrightness(COMPAT_TEXTURE(OrigTexture, bp + vec2( 0.0,       blurDist)).rgb);

            float weighted = center * 0.5 + (left + right + up + down) * 0.125;

            // Exponential falloff — shadow drops off quickly, reads as natural fade
            float shadowStrength = (weighted * weighted) * PT_SHADOW_OPACITY;

            bg = mix(bg, bg * 0.2, shadowStrength);
        }
    }

    // ------------------------------------------------------------------
    // Transparency blend
    // ------------------------------------------------------------------
    vec3 result = pixel;

    if (PT_PIXEL_MODE < 0.5) {
        // Mode 0: White only — transparent pixels are white/near-white only
        if (isWhite > 0.5) {
            float intensity = getBrightness(pixel);
            float alpha     = clamp((intensity / 3.0) + PT_BASE_ALPHA, 0.0, 1.0);
            alpha           = max(alpha, PT_WHITE_TRANSPARENCY);
            result          = huePreservingBlend(pixel, bg, alpha);
        }

    } else if (PT_PIXEL_MODE < 1.5) {
        // Mode 1: Bright — transparency scales proportionally with pixel brightness.
        // The 2.4 constant scales the 0-1 brightness range to a useful alpha range
        // after the PT_BASE_ALPHA offset. Increase to make bright pixels more
        // transparent; decrease for a subtler effect.
        float intensity = getBrightness(pixel);
        float alpha     = clamp(PT_BASE_ALPHA * intensity * 2.4, 0.0, 1.0);
        if (isWhite > 0.5) alpha = max(alpha, PT_WHITE_TRANSPARENCY);
        result = huePreservingBlend(pixel, bg, alpha);

    } else {
        // Mode 2: All pixels — everything blends toward background
        float intensity = getBrightness(pixel);
        float alpha     = clamp((intensity / 3.0) + PT_BASE_ALPHA, 0.0, 1.0);
        if (isWhite > 0.5) alpha = max(alpha, PT_WHITE_TRANSPARENCY);
        result = huePreservingBlend(pixel, bg, alpha);
    }

    // Apply pixel border — darkens pixel edges to simulate LCD dot gaps
    result *= pixelBorderFactor(TEX0.xy);

    // Apply subpixel chromatic shift — subtle R/B channel separation
    result = applyChromaShift(result, TEX0.xy);

    // Apply vignette — darken toward screen edges as on original hardware
    result = applyVignette(result, TEX0.xy);

    FragColor = vec4(result, lcd.a);
}
#endif
