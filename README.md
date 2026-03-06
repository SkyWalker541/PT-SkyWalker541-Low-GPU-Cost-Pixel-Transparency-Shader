# PT-SkyWalker541-Low-GPU-Cost-Pixel-Transparency-Shader

**PT SkyWalker541 restores the original appearance by detecting bright/white pixels and blending them toward a procedurally generated backing texture, putting the transparency back where it belongs.**

***Please take a look at the [PT_SkyWalker541 Shader README](https://github.com/SkyWalker541/PT-SkyWalker541-Low-GPU-Cost-Pixel-Transparency-Shader/blob/main/PT_Skywalker541%20Shader%20README.md) for full instructions and customization.***

On original Game Boy, GBC, and GBA hardware, screen pixels that were fully
off did not display as white — the display had no backlight driving those
areas, so they appeared as the physical backing material showing through:
a grey-green translucency rather than solid white. Game developers of that
era designed around this, using "white" areas as intentional transparent
regions for backgrounds, windows, and UI overlays.

On modern displays and emulators, those same pixels render as bright white,
which was never the intended look and can be visually jarring.

I specifically created this shader to use on my TrimUI Brick with NextUI.

**There are a lot of adjustable settings in the glsl file. They are all well documented, with instructions on how to adjust them. If the default settings are not to your liking, feel free to mess around with the settings.**


**Gameboy (Zelda's Adventure)
Without and With Shader - Native**
<img width="1024" height="768" alt="Zelda&#39;s Adventure 2026-03-04-15-09-33" src="https://github.com/user-attachments/assets/8c780734-35f2-4b28-9faf-bd9f78a1bca2" />
<img width="1024" height="768" alt="Zelda&#39;s Adventure 2026-03-04-15-09-45" src="https://github.com/user-attachments/assets/9c639a2e-0742-4c02-80dc-898207300942" />



**Gameboy Color (Opossum Country)
Without and With Shader - Native**
<img width="1024" height="768" alt="Opossum Country 2026-03-04-15-08-03" src="https://github.com/user-attachments/assets/f82228c4-c94c-4e90-8004-9c6ad8588fe5" />
<img width="1024" height="768" alt="Opossum Country 2026-03-04-15-07-55" src="https://github.com/user-attachments/assets/0fb6de7d-3bf5-4937-bd2f-7d243ab3d44e" />



**Gameboy Advance (Goodboy Galaxy) 
Without and With Shader - Native**
<img width="1024" height="768" alt="Goodboy Galaxy 2026-03-04-15-11-54" src="https://github.com/user-attachments/assets/ad4efc5a-2e9c-4e9f-84ff-e38af900569d" />
<img width="1024" height="768" alt="Goodboy Galaxy 2026-03-04-15-11-45" src="https://github.com/user-attachments/assets/47369865-199c-4e03-9577-cb1869c1f9ce" />



