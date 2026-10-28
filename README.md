# BitKiln

Pixel art plugin for Godot 4.6+: modify, bake and create pixel sprites inside the editor.
Effects stack non-destructively on a source image and bake to plain PNGs, so exported games
don't need the plugin, and the original art is never touched.

- **Recipes** instead of edited copies: a source image, a stack of ops and the files to write.
  Change the source in Aseprite and the recipe bakes again by itself.
- **Pixel-art ops**: outlines (including selective outlines), drop and long shadows, glows in
  crisp rings, blurs snapped to a few alpha levels, palette swaps that make one variant per
  palette, quantizing with dithering, color reduction, gradient maps, and masks to limit any op
  to part of the sprite.
- **Scalers and rotation** that add no new colors: Scale2x / Scale3x / Scale4x (EPX), MMPX, and
  RotSprite rotation, including 8- or 16-direction sets.
- **Lighting**: normal maps for 2D lights (snapped to a few directions so light falls in clean
  bands, ready-made `CanvasTexture`s) and automatic banded, hue-shifted shading.
- **Sprite sheets**: frame-grid guessing, repacking, and `SpriteFrames` for AnimatedSprite2D.
- **Generators** for making art from nothing: pixel-perfect shapes, animated FX sheets
  (sparkles, impacts, smoke, slashes, orbs, shockwaves), seeded random sprites, tileable noise
  textures and hue-shifted palette ramps.
- **Tiles**: a 47-tile blob set built from five hand-drawn tiles, written as a `TileSet` with the
  terrain already set up.
- **Bake Material**: freeze any CanvasItem shader (Pocket's `sprite_fx`, your own) into the PNG.
- **Editor tools**: a dock with a live preview (side by side, lit by a light that follows the
  mouse), bake status for every recipe, pixel-art import checks, and a Lospec palette importer.

![The BitKiln dock](docs/images/dock.png)

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Recipes](#recipes)
  - [Frames](#frames)
  - [Outputs](#outputs)
- [Ops](#ops)
  - [Masks](#masks)
  - [Palettes and variants](#palettes-and-variants)
  - [Scalers](#scalers)
  - [Rotation](#rotation)
  - [Normal maps](#normal-maps)
  - [Shading](#shading)
  - [Glow and blur](#glow-and-blur)
  - [Sprite sheets](#sprite-sheets)
  - [Baking a material](#baking-a-material)
- [Generators](#generators)
  - [Shapes](#shapes)
  - [FX sheets](#fx-sheets)
  - [Random sprites](#random-sprites)
  - [Noise and ramps](#noise-and-ramps)
- [Autotiles](#autotiles)
- [Editor tools](#editor-tools)
  - [Baking and auto bake](#baking-and-auto-bake)
  - [Import checks](#import-checks)
- [Using recipes from code](#using-recipes-from-code)
  - [Writing your own op](#writing-your-own-op)
- [Class reference](#class-reference)
- [Limitations](#limitations)

## Installation

1. Clone this repository into your project's `addons` folder as `bitkiln`:
   ```bash
   git clone https://github.com/Reshiramoo/BitKiln.git addons/bitkiln
   ```
   (or add it as a submodule: `git submodule add https://github.com/Reshiramoo/BitKiln.git addons/bitkiln`).
   The folder must be named `bitkiln`.
2. **Project → Project Settings → Plugins** → enable **BitKiln**. A **BitKiln** tab appears in
   the bottom panel.

## Quick start

1. Right-click a sprite in the FileSystem dock → **New BitKiln Recipe**. This saves
   `hero_kiln.tres` next to `hero.png` and opens it in the Inspector and the BitKiln dock.
2. In the Inspector, add ops to **Ops**: for example a **BitKilnPad** (room for the outline), then
   a **BitKilnOutline**. The dock's preview follows every change.
3. Click **Bake** in the dock. The recipe writes `hero_baked.png` next to the source.
4. Use `hero_baked.png` in your game like any other texture. When you change `hero.png`, the
   recipe bakes again by itself.

To make art from nothing, right-click a folder → **New BitKiln Canvas** instead: a recipe without
a source, starting from a blank canvas for [generators](#generators) to draw on.

## Recipes

A [BitKilnRecipe](docs/classes/BitKilnRecipe.md) is a resource with:

| Property | Meaning |
|---|---|
| `source` | The image to start from. BitKiln reads its file directly, so import settings (compression, mipmaps) don't change the pixels. Leave it empty to start from a blank canvas. |
| `frames` | Columns and rows of frames, for sprite sheets (see [Frames](#frames)). |
| `canvas_size` | Without a source: the size of one blank frame. |
| `ops` | [BitKilnOp](docs/classes/BitKilnOp.md)s, applied top to bottom. Each has an **Enabled** switch, to compare with and without it. |
| `outputs` | [BitKilnOutput](docs/classes/BitKilnOutput.md)s: the files to write when baked. |
| `auto_bake` | Bake again whenever the source, or a palette an op uses, is reimported. |

Recipes are ordinary `.tres` files: keep them next to the art, commit them, duplicate them as
starting points for similar sprites. A recipe's source can be another recipe's output, to chain them.

### Frames

Set `frames` to the sheet's grid (8×1 for an eight-frame strip), or click **Guess Frame Grid**
next to it in the Inspector: BitKiln picks the most frames whose edges cut no sprite. New
recipes start with that guess. Every op then works on each
frame as if it were its own image: outlines, shadows and normal maps stop at frame edges instead
of reaching into the next frame, scalers scale frames one by one, and padding or trimming
changes every frame by the same amount so the grid stays regular.

### Outputs

| Kind | Writes |
|---|---|
| **Color** | The result, as a PNG. |
| **Normal** | The normal map from a [BitKilnNormalMap](docs/classes/BitKilnNormalMap.md), as a PNG. |
| **Canvas Texture** | A `CanvasTexture` `.tres` pairing the recipe's Color and Normal outputs, with the nearest filter: drop it on a Sprite2D and it reacts to 2D lights. Needs a Color and a Normal output in the same recipe. |
| **Palette** | Every color of the result, darkest first, as a one-row PNG: a palette for Palette Swap, Quantize or Pocket's shaders. |
| **Sprite Frames** | A `SpriteFrames` `.tres` for an AnimatedSprite2D, cut from the Color output: one animation, or one per row (named, with fps and looping), leaving out empty cells. See [Sprite sheets](#sprite-sheets). |
| **Tile Set** | A `TileSet` `.tres` with the Color output as an atlas, one tile per non-empty frame; after an Autotile op, with a terrain set up for painting. See [Autotiles](#autotiles). |

An output's `path` can use `{dir}` (the source's folder), `{name}` (the source's file name
without extension), `{recipe}` (the recipe's file name) and `{variant}` (an underscore and the
variant's name, or nothing). Without a source, `{dir}` and `{name}` come from the recipe itself,
minus a `_kiln` suffix (`spark_kiln.tres` bakes `spark_baked.png`). The default is
`{dir}/{name}_baked{variant}.png`. A recipe never
overwrites its own source, and files whose bytes didn't change aren't rewritten (so they don't
reimport for nothing).

## Ops

| Op | What it does |
|---|---|
| **Shape** | |
| [BitKilnPad](docs/classes/BitKilnPad.md) | Adds transparent space around every frame, so outlines, shadows and glows have room. |
| [BitKilnTrim](docs/classes/BitKilnTrim.md) | Cuts away empty space, by the same amount on every frame, keeping a margin if you like. |
| [BitKilnExtrude](docs/classes/BitKilnExtrude.md) | Grows frames with copies of their edge pixels, against bleeding in atlases and tile sets. |
| [BitKilnTransform](docs/classes/BitKilnTransform.md) | Flips and quarter turns, per frame. |
| [BitKilnRotate](docs/classes/BitKilnRotate.md) | RotSprite rotation by any angle, or a set of directions (see [Rotation](#rotation)). |
| [BitKilnScale](docs/classes/BitKilnScale.md) | Scales up with a pixel-art scaler (see [Scalers](#scalers)). |
| [BitKilnRepack](docs/classes/BitKilnRepack.md) | Rearranges or picks frames (see [Sprite sheets](#sprite-sheets)). |
| **Edges and light** | |
| [BitKilnOutline](docs/classes/BitKilnOutline.md) | Outer or inner outline, 1–8 px, round / square / diamond (the same shapes as Pocket's `sprite_fx` shader). **Selective** coloring ("sel-out") colors each outline pixel with a darker version of the sprite color next to it. |
| [BitKilnShadow](docs/classes/BitKilnShadow.md) | Hard drop shadow behind the sprite; with a length above 1, a long shadow. |
| [BitKilnGlow](docs/classes/BitKilnGlow.md) | A halo in crisp rings around the sprite or its bright pixels (see [Glow and blur](#glow-and-blur)). |
| [BitKilnBlur](docs/classes/BitKilnBlur.md) | Box, gaussian or motion blur with the soft edges snapped to a few alpha levels. |
| [BitKilnNormalMap](docs/classes/BitKilnNormalMap.md) | Makes a normal map layer (see [Normal maps](#normal-maps)). |
| [BitKilnShade](docs/classes/BitKilnShade.md) | Banded, hue-shifted shading and rim light from the normals (see [Shading](#shading)). |
| **Color** | |
| [BitKilnPaletteSwap](docs/classes/BitKilnPaletteSwap.md) | Replaces colors, with one variant per palette (see [Palettes and variants](#palettes-and-variants)). |
| [BitKilnQuantize](docs/classes/BitKilnQuantize.md) | Snaps every color to the nearest palette color, with optional Bayer dithering (2×2, 4×4, 8×8), and makes alpha fully on or off. |
| [BitKilnReduce](docs/classes/BitKilnReduce.md) | Reduces the image to at most N colors picked from itself (median cut). Add a Palette output to save them. |
| [BitKilnAdjust](docs/classes/BitKilnAdjust.md) | Hue, saturation, brightness, contrast and tint. |
| [BitKilnGradientMap](docs/classes/BitKilnGradientMap.md) | Recolors by brightness through a Gradient: greyscale art into any color scheme. |
| [BitKilnMaterial](docs/classes/BitKilnMaterial.md) | Renders the image through a CanvasItem material (see [Baking a material](#baking-a-material)). |
| **Generators** | |
| [BitKilnShape](docs/classes/BitKilnShape.md) | Pixel-perfect ellipses, rectangles, polygons, stars and lines (see [Shapes](#shapes)). |
| [BitKilnFxSheet](docs/classes/BitKilnFxSheet.md) | Animated effects across the frames (see [FX sheets](#fx-sheets)). |
| [BitKilnRandomSprite](docs/classes/BitKilnRandomSprite.md) | A different random mirrored sprite per frame (see [Random sprites](#random-sprites)). |
| [BitKilnNoise](docs/classes/BitKilnNoise.md) | Tileable noise banded through a gradient (see [Noise and ramps](#noise-and-ramps)). |
| [BitKilnRamp](docs/classes/BitKilnRamp.md) | Hue-shifted color ramps for building palettes. |
| **Tiles** | |
| [BitKilnAutotile](docs/classes/BitKilnAutotile.md) | The 47-tile blob set from five tiles (see [Autotiles](#autotiles)). |

Order matters: an outline after a palette swap follows the new colors; an outline before a scaler
gets scaled with the sprite, one after it stays 1 px thin; shade before outlining, or the outline
gets shaded too.

### Masks

Every op has a **Mask** group, to limit it to part of the sprite: outside the mask, the image
keeps the pixels it had before the op. A mask is an image drawn over the source, either one
frame's size (used for every frame) or the whole sheet's. White pixels are inside, black or
transparent ones outside. Masks follow padding, trimming and scaling done by earlier ops, so you
always draw them over the original art.

With **Mask By Color**, only pixels of exactly **Mask Color** are inside. One region map with a
color per part (red for the hair, blue for the cape) then serves several ops: an Adjust on the hair
only, a Palette Swap on the cape only. **Mask Invert** works outside the mask instead. Ops that
change the image's size can't be masked.

### Palettes and variants

Palette Swap reads palettes in two forms:

- **Two rows**, as used by Pocket's `sprite_fx` palette swap: row 0 holds the colors to find, row 1
  their replacements.
- **One row** of replacements for the colors in the op's `base_palette`, in the same order. Lospec
  palettes work this way: BitKiln imports `.hex`, `.gpl` (GIMP, Aseprite) and `.pal` (JASC) files
  as one-row textures, so you can drop them straight into the project.

With more than one palette (or `keep_original` on), every palette makes its own **variant**, named
after the palette's file: `slime.png` with `red.hex` and `blue.hex` bakes `slime_baked_red.png` and
`slime_baked_blue.png`. Ops after the swap run on every variant, and the dock's variant menu
shows each one.

Bake palette swaps for variants that never change at runtime (shiny forms, enemy tiers, team
colors): they cost nothing in the game, leave the sprite's material free, and work on any node.
Keep Pocket's live palette swap for colors chosen or animated at runtime (character
customization, palette cycling).

### Scalers

| Algorithm | Look |
|---|---|
| **Nearest** | Every pixel becomes a crisp block of `factor`×`factor`. |
| **Scale2x / Scale3x** | EPX / AdvMAME: rounds off diagonal staircases, the smoothed look of emulators and of some DS-era sprite upscales. |
| **Scale4x** | Scale2x twice. |
| **MMPX** | 2×, style-preserving (McGuire and Gagiu, 2021): builds on Scale2x with rules for lines, slopes and single-pixel details, so results look closer to hand-drawn. |
| **MMPX 4x** | MMPX twice. |

None of them add colors, so the result stays in your palette. A normal map layer is scaled
nearest alongside the colors.

### Rotation

[BitKilnRotate](docs/classes/BitKilnRotate.md) rotates with RotSprite: each frame is scaled to 8×
with Scale2x (three times), then sampled at the rotated positions. Lines stay clean and no new
colors appear, where ordinary rotation smears or breaks pixel art. Angles are clockwise; exact
quarter turns use the original pixels.

Set **Directions** to make a set facing evenly around the circle from **Angle**: 8 for top-down
characters, 16 for vehicles. With the **Variants** layout each direction bakes to its own file
(`ship_baked_r045.png`); with **Rows** they stack as rows of one sheet, ready for a Sprite Frames
output with one animation per row. **Expand** grows frames to fit the rotated corners, the same
size for every angle. Normal maps rotate with the colors.

### Normal maps

[BitKilnNormalMap](docs/classes/BitKilnNormalMap.md) builds a height map, then turns its slopes into normals:

- **Bevel**: the height rises from the sprite's edge toward its middle over `bevel_radius` pixels,
  as if inflated. `bevel_profile` reshapes it (empty = rounded).
- **Detail**: bright colors stand out by `detail_depth` pixels (dark ones with `invert_detail`).
- **Snapping**: `snap_directions` (8 by default) and `snap_steepness` limit the normals to a few
  directions and steepnesses. Lights then fall on the sprite in clean bands, the way a pixel artist
  shades, instead of smooth gradients. 0 directions turns it off.

Normals follow Godot's convention (green = up); `flip_green` gives DirectX's. Switch the dock's
layer menu to **Lit** to see the sprite shaded by a light that follows the mouse.

### Shading

[BitKilnShade](docs/classes/BitKilnShade.md) shades flat colors the way pixel artists do: a few
lighter bands on the side facing **Light Direction** and darker ones away from it, spread over the
light the sprite actually gets so every band shows. Hues shift toward yellow in the light and
toward blue in the shadow (**Hue Shift**, **Saturation Shift**), instead of only getting lighter
or darker. With a **Palette**, every shade snaps to its nearest color.

The shape comes from a [BitKilnNormalMap](docs/classes/BitKilnNormalMap.md) before it (whose
snapping decides how the bands fall), or from a smooth rounded one made just for shading. The
**Rim Light** group adds a thin edge of light on the edges facing **Rim Direction**.

### Glow and blur

[BitKilnGlow](docs/classes/BitKilnGlow.md) draws a halo that fades over **Radius** pixels in a few
crisp **Rings**, around the whole sprite or only its bright pixels (eyes, gems, flames). It can use
one color or the glowing pixels' own colors, stay behind the sprite or add light over it.

[BitKilnBlur](docs/classes/BitKilnBlur.md) blurs with a box, a gaussian or a motion smear, then
snaps the soft edges to **Alpha Steps** levels of transparency. Both can dither between levels
with an ordered pattern. Follow either with a Quantize to bring the colors into your palette.

### Sprite sheets

- **Frames**: set the grid, or click **Guess Frame Grid** (see [Frames](#frames)).
- [BitKilnRepack](docs/classes/BitKilnRepack.md) rearranges frames into a new number of
  **Columns** (0 = one row), keeps a range (**First**, **Count**) and can **Skip Empty** frames:
  a 4×4 sheet into a strip, a strip into rows of 8, frames 5–8 as their own animation.
- A **Sprite Frames** output writes a `SpriteFrames` resource cut from the Color output. With
  **Per Row**, each row of frames becomes an animation, named by **Animation Names** (or
  `row_0`, `row_1`…). Rebaking rebuilds the same file, so scenes using it keep working.

### Baking a material

[BitKilnMaterial](docs/classes/BitKilnMaterial.md) renders the image through a CanvasItem material
and keeps the result: tune an effect live with a shader (Pocket's `sprite_fx`, a palette shader,
your own), then freeze it into the PNG so the game doesn't run the shader. **Parameters** overrides
shader parameters for this bake only (`{"flash_amount": 1.0}`), and the `sheet_frames` uniform used
by Pocket's shaders is set to the frame grid. The material itself is never changed.

It needs a renderer, so it works in the editor and in games but skips itself (with a warning) in
`--headless` runs. Effects that change over time are caught at an arbitrary moment, and effects
that draw outside the sprite need a Pad before it.

## Generators

Generators are ops that draw. On a recipe without a source ("New BitKiln Canvas" on a folder),
they make art from a blank canvas of `canvas_size` per frame; on a recipe with a source, they draw
over it. Like every op, they work frame by frame, so a frame grid gives animations or sets, and
every other op (outlines, shading, palettes, scalers) can follow them.

### Shapes

[BitKilnShape](docs/classes/BitKilnShape.md) draws an ellipse or circle, rectangle, regular
polygon, star or line, filled and/or outlined, placed around the frame's center with an
**Offset**. A pixel is inside when its center is, which gives the symmetric, hand-drawn-looking
circles of pixel art. Stack several for icons, particles and UI pieces. In the **Animation** group,
**Grow**, **Move** and **Spin** change the shape a little on each frame, and **Frame** limits it
to one frame.

### FX sheets

[BitKilnFxSheet](docs/classes/BitKilnFxSheet.md) draws an animated effect across the frames:
**Sparkle** (looping twinkles), **Impact** (a flash, then spikes bursting out), **Smoke** (puffs
drifting toward **Direction**), **Slash** (a sweeping crescent), **Orb** (a looping pulse with a
halo) and **Ring** (a shockwave). Set the recipe's frames to the frame count (8×1), and add a
Sprite Frames output to play it.

Each pixel gets a heat from the hot core to the fading edge, colored by **Colors** (a Gradient) in
**Color Steps** hard bands, so a sheet uses only a few colors. With a Constant gradient whose
points sit at 0, 1/n, 2/n… for n steps, every band is exactly one of its colors. **Count**,
**Scale**, **Seed** and a **Timing** curve shape the effect.

### Random sprites

[BitKilnRandomSprite](docs/classes/BitKilnRandomSprite.md) makes a different random sprite in every
frame: **Creature** (round bodies with limbs, and eyes), **Ship** or **Item**. Each is a random half
following a density map, mirrored (**Horizontal**, **Vertical** or **Both**), kept in one piece,
shaded from top to bottom and outlined. Colors come from ramps of a **Palette**, or from a random
hue per sprite. Frame n uses seed + n, so an 8×8 grid gives 64 sprites, and the same seed always
gives the same set: keep the ones you like, or bake a fresh set for procedural enemies and loot.

### Noise and ramps

[BitKilnNoise](docs/classes/BitKilnNoise.md) fills every frame with noise from a `FastNoiseLite`
(seamless by default, so frames tile), banded through a Gradient: grass, dirt, water and stone
textures, clouds (with a gradient that turns transparent), terrain maps. Each frame samples its
own part of the noise, for variations.

[BitKilnRamp](docs/classes/BitKilnRamp.md) draws a color ramp per base color, one per row: darker
shades shifting toward blue and lighter ones toward yellow, the way pixel artists build ramps by
hand. With a Palette output, it designs palettes for Shade, Quantize and Random Sprite.

## Autotiles

[BitKilnAutotile](docs/classes/BitKilnAutotile.md) turns five hand-drawn tiles into the full
47-tile "blob" set, so a terrain paints with every edge and corner right. The source is five tiles
in a row (frames 5×1), each drawn in one style all around:

| Tile | Draw it as |
|---|---|
| 1. **Island** | A tile with nothing around it: outer corners on all four sides. |
| 2. **Column** | Connected above and below: its left and right edges show. |
| 3. **Row** | Connected left and right: its top and bottom edges show. |
| 4. **Cross** | Connected on all four sides but not diagonally: inner corners. |
| 5. **Fill** | The middle of the terrain. |

Every output tile is put together from quarters of these (so tiles need an even size) and laid
out in **Columns** (8 by default). Add a **Tile Set** output: it writes a `TileSet` with a
Match Corners and Sides terrain (named and colored in the output), every tile's peering bits set,
ready for the TileMap terrain tools. Rebaking rebuilds the same file, so TileMaps using it keep
working. Keep the frame size after Autotile (no Pad or Extrude) when using the Tile Set output.

## Editor tools

The **BitKiln** dock (bottom panel):

| Area | What it does |
|---|---|
| **Recipe list** | Every recipe in the project, with its status: up to date, changed since the last bake, or failed. Filter by name; double-click to inspect. **Bake All Stale** bakes every recipe that isn't up to date. |
| **Preview** | The selected recipe's result, at whole-number zoom on a checkerboard. Menus pick the variant, the layer (**Color**, **Normal**, **Lit**), the view (**Result**, **Source**, **Side by Side**) and how many ops to apply ("Up to 2: Outline"), to see the stack step by step. Scroll to zoom, drag to pan; the grid button shows frame edges. Size, frame size, color count, warnings and time per run appear underneath. |
| **Side panel** | **Bake**, the recipe's status, import checks and the bake log. |

Inspecting a recipe shows it in the dock. Recipes are edited in the Inspector; the preview follows
edits, undo and redo.

FileSystem dock: right-click images → **New BitKiln Recipe** (one per image); a folder → **New
BitKiln Canvas** (a recipe without a source, for generators); recipes → **Bake**.

### Baking and auto bake

Baking writes the outputs, imports them and builds Canvas Texture, Sprite Frames and Tile Set
outputs. Recipes with
`auto_bake` bake again when their source or a texture an op uses (a palette) is reimported, which
happens whenever you save the file in another program. Chains of recipes bake in turn; each recipe
bakes at most once per change, so a loop can't run forever.

BitKiln remembers what each recipe was last baked from, in the project's editor settings folder
(`.godot/editor`), and marks recipes whose source, ops or outputs changed since.

To bake without opening the editor, for example in a build script:

```bash
godot --headless --import    # on a fresh checkout: imports assets and registers BitKiln's classes
godot --headless --script res://addons/bitkiln/tools/bake_all.gd
```

It exits with code 1 if a recipe fails. Canvas Texture, Sprite Frames and Tile Set outputs need the
editor to import their PNGs first, and Bake Material needs a renderer, so this script skips them.

### Import checks

The side panel warns about settings that spoil pixel art, with a **Fix** button for each:

- the project's default texture filter isn't **Nearest** (blurry when scaled);
- the source or an output is compressed lossily or for the GPU (colors shift);
- the source or an output has mipmaps (blurry when drawn smaller).

## Using recipes from code

[BitKilnBaker.run()](docs/classes/BitKilnBaker.md#method-run) only computes, so recipes work at
runtime too, for example to recolor a sprite when the player picks a palette. It returns one
[BitKilnContext](docs/classes/BitKilnContext.md) per variant:

```gdscript
var recipe := preload("res://characters/hero_kiln.tres")
var contexts := BitKilnBaker.run(recipe)
$Sprite2D.texture = contexts[0].color.to_texture()
```

An exported game only has the imported texture, not the source PNG, so BitKiln reads the
texture's image instead; import the source **Lossless** for exact colors.
[BitKilnBaker.bake()](docs/classes/BitKilnBaker.md#method-bake) writes files, which only makes
sense in the editor or a headless script.

### Writing your own op

Extend [BitKilnOp](docs/classes/BitKilnOp.md) and override `_apply()`. Pixels live in
[BitKilnBuffer](docs/classes/BitKilnBuffer.md)s as packed ints; copy `pixels` to a local
variable, change it, and assign it back:

```gdscript
@tool
class_name InvertOp
extends BitKilnOp
## Inverts every color, keeping alpha.

func _apply(context: BitKilnContext) -> void:
	var p := context.color.pixels
	for i in p.size():
		var c := p[i]
		if c != 0:
			p[i] = BitKilnBuffer.pack(255 - BitKilnBuffer.red(c), 255 - BitKilnBuffer.green(c),
				255 - BitKilnBuffer.blue(c), BitKilnBuffer.alpha(c))
	context.color.pixels = p
```

Use `context.frame_size` to keep neighbour lookups inside a frame, `context.remap_frames()` or
`context.scale_nearest()` to change the size of every layer at once, and `context.warn()` for
messages that show in the dock. An op that makes variants overrides `_process()` instead and
returns a context per variant (see [BitKilnPaletteSwap](docs/classes/BitKilnPaletteSwap.md)).

## Class reference

| Class | Role |
|---|---|
| [BitKilnRecipe](docs/classes/BitKilnRecipe.md) | Source, ops and outputs. |
| [BitKilnOutput](docs/classes/BitKilnOutput.md) | A file a recipe writes. |
| [BitKilnOp](docs/classes/BitKilnOp.md) | Base class of ops. |
| [BitKilnPad](docs/classes/BitKilnPad.md), [BitKilnTrim](docs/classes/BitKilnTrim.md), [BitKilnExtrude](docs/classes/BitKilnExtrude.md), [BitKilnTransform](docs/classes/BitKilnTransform.md), [BitKilnRotate](docs/classes/BitKilnRotate.md), [BitKilnScale](docs/classes/BitKilnScale.md), [BitKilnRepack](docs/classes/BitKilnRepack.md) | Shape ops. |
| [BitKilnOutline](docs/classes/BitKilnOutline.md), [BitKilnShadow](docs/classes/BitKilnShadow.md), [BitKilnGlow](docs/classes/BitKilnGlow.md), [BitKilnBlur](docs/classes/BitKilnBlur.md), [BitKilnNormalMap](docs/classes/BitKilnNormalMap.md), [BitKilnShade](docs/classes/BitKilnShade.md) | Edge and light ops. |
| [BitKilnPaletteSwap](docs/classes/BitKilnPaletteSwap.md), [BitKilnQuantize](docs/classes/BitKilnQuantize.md), [BitKilnReduce](docs/classes/BitKilnReduce.md), [BitKilnAdjust](docs/classes/BitKilnAdjust.md), [BitKilnGradientMap](docs/classes/BitKilnGradientMap.md), [BitKilnMaterial](docs/classes/BitKilnMaterial.md) | Color ops. |
| [BitKilnShape](docs/classes/BitKilnShape.md), [BitKilnFxSheet](docs/classes/BitKilnFxSheet.md), [BitKilnRandomSprite](docs/classes/BitKilnRandomSprite.md), [BitKilnNoise](docs/classes/BitKilnNoise.md), [BitKilnRamp](docs/classes/BitKilnRamp.md) | Generators. |
| [BitKilnAutotile](docs/classes/BitKilnAutotile.md) | The autotile expander. |
| [BitKilnBaker](docs/classes/BitKilnBaker.md), [BitKilnBaker.Result](docs/classes/BitKilnBaker.Result.md) | Runs recipes and writes their outputs. |
| [BitKilnContext](docs/classes/BitKilnContext.md) | The layers and frame grid ops work on. |
| [BitKilnBuffer](docs/classes/BitKilnBuffer.md) | RGBA8 pixels as packed ints. |
| [BitKilnPalette](docs/classes/BitKilnPalette.md) | Reads palettes from textures; color distance. |
| [BitKilnFilter](docs/classes/BitKilnFilter.md) | Soft operations for ops: blurs, alpha steps, distances. |
| [BitKilnSheet](docs/classes/BitKilnSheet.md) | Sprite sheet helpers: frame grid guessing, sprite bounds. |
| [BitKilnRaster](docs/classes/BitKilnRaster.md) | Pixel-perfect shape masks for generators. |

## Limitations

- **Speed.** Ops run in GDScript on the CPU. Sprites and sheets of a few hundred pixels preview
  instantly; very large sheets with 4× scalers or RotSprite (which works at 8×) take noticeably
  longer. Turn ops off while tuning the others.
- **Whole-number scaling only**, and the scalers are 2×-based (plus Scale3x).
- **Masks** only work on ops that keep the image's size, and after Transform, Rotate or Repack
  they're stretched over the new frame instead of following the art exactly.
- **Bake Material** needs a renderer, and has only been tested with the Compatibility (OpenGL)
  renderer so far.
- **Members starting with `_`** are internal and may change between versions.
