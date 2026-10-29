@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnMotion
extends Resource
## One effect of a [BitKilnAnimate]: how the sprite moves, deforms or changes color over
## the animation. Pick the [member effect], then set its [member amount]; the Inspector
## shows only the settings that effect uses.
##
## Time runs from 0 (first frame) to 1 (end of the animation). [member start] and
## [member end] limit the effect to part of it. [member curve], when set, shapes the
## effect over that window: for effects that swing back and forth (squash, shake, wobble,
## skew, wave, jump) it scales the swings; for the others it is the effect's value itself.

enum Effect {
	SQUASH, ## Squash and stretch: wider and flatter, then taller and thinner, [member cycles] times. [member amount] 0.2 = 20%.
	JUMP, ## Hops up [member amount] pixels and lands, [member cycles] times.
	SHAKE, ## Jitters up to [member amount] pixels in random directions, fading out.
	WOBBLE, ## Rocks side to side up to [member amount] degrees around [member pivot], settling down.
	SKEW, ## Leans like jelly, top swaying [member amount] times its height relative to the base, settling down.
	SPIN, ## Turns [member amount] full turns clockwise around [member pivot].
	WAVE, ## Rows (or columns) ripple sideways up to [member amount] pixels, [member cycles] waves tall.
	MOVE, ## Slides by [member direction] × [member amount] pixels.
	SCALE, ## Grows by [member amount] (0.5 = half again as big) around [member pivot].
	FLASH, ## Turns [member color] while active (hit flash). [member amount] 1 = solid color.
	TINT, ## Mixes in [member color] by [member amount] while active.
	FADE, ## Fades out by [member amount] (1 = gone), in whole pixels with dithering.
	BLINK, ## Disappears and reappears [member cycles] times while active.
	DISSOLVE, ## Crumbles away pixel by pixel; [member color] lights the crumbling edge.
	AFTERIMAGE, ## Ghost copies of earlier frames trail behind, [member amount] = their opacity.
}

## Effects that swing back and forth: the curve scales their swings.
const SWINGING: Array[Effect] = [Effect.SQUASH, Effect.JUMP, Effect.SHAKE, Effect.WOBBLE, Effect.SKEW, Effect.WAVE]
## Effects that keep their last value after [member end] (the others stop).
const HOLDING: Array[Effect] = [Effect.SPIN, Effect.MOVE, Effect.SCALE, Effect.FADE, Effect.DISSOLVE]

## What the effect does.
@export var effect := Effect.SQUASH:
	set(value):
		effect = value
		notify_property_list_changed()
## Skipped while off.
@export var enabled := true
## How strong the effect is; its meaning depends on the effect (see [enum Effect]).
@export var amount := 0.2
## Shapes the effect over its window (see the class description). Empty = the effect's
## natural shape.
@export var curve: Curve
## When the effect starts, 0–1 of the animation.
@export_range(0.0, 1.0, 0.01) var start := 0.0
## When the effect ends, 0–1 of the animation.
@export_range(0.0, 1.0, 0.01) var end := 1.0
## Swings, hops, blinks or waves during the window.
@export_range(0.0, 16.0, 0.25, "or_greater") var cycles := 1.0
## For flash, tint, dissolve edges and afterimages (alpha 0 = keep the sprite's colors).
@export var color := Color.WHITE
## For Move: which way; for Shake: the axes it shakes along; for Wave: (1, 0) ripples rows
## sideways, (0, 1) ripples columns up and down.
@export var direction := Vector2(1.0, 0.0)
## The point that stays put when squashing, scaling, wobbling, skewing or spinning, relative
## to the sprite's bounds: (0.5, 1) is the bottom middle, (0.5, 0.5) the center.
@export var pivot := Vector2(0.5, 1.0)
## For Afterimage: how many ghosts.
@export_range(1, 8, 1) var ghosts := 3
## For Afterimage: frames between ghosts.
@export_range(1, 8, 1) var ghost_spacing := 1
## Changes the randomness of Shake and Dissolve.
@export var seed := 0


func _validate_property(property: Dictionary) -> void:
	var uses := {
		"cycles": [Effect.SQUASH, Effect.JUMP, Effect.WOBBLE, Effect.SKEW, Effect.WAVE, Effect.BLINK],
		"color": [Effect.FLASH, Effect.TINT, Effect.DISSOLVE, Effect.AFTERIMAGE],
		"direction": [Effect.MOVE, Effect.SHAKE, Effect.WAVE],
		"pivot": [Effect.SQUASH, Effect.WOBBLE, Effect.SKEW, Effect.SPIN, Effect.SCALE],
		"ghosts": [Effect.AFTERIMAGE],
		"ghost_spacing": [Effect.AFTERIMAGE],
		"seed": [Effect.SHAKE, Effect.DISSOLVE],
	}
	if uses.has(property.name) and not effect in uses[property.name]:
		property.usage = PROPERTY_USAGE_STORAGE


## How far into its window the effect is at animation time [param t] (0–1), or -1 when
## it's inactive then.
func local_time(t: float) -> float:
	var length := maxf(end - start, 0.0001)
	var u := (t - start) / length
	if u < 0.0 or u > 1.0:
		if effect in HOLDING:
			return clampf(u, 0.0, 1.0)
		return -1.0
	return u


## The effect's strength at window time [param u]: the curve's value, or the natural shape.
func envelope(u: float) -> float:
	if curve != null:
		return curve.sample_baked(u)
	match effect:
		Effect.SHAKE, Effect.WOBBLE, Effect.SKEW:
			return 1.0 - u # settle down
		Effect.SPIN, Effect.MOVE, Effect.SCALE, Effect.FADE, Effect.DISSOLVE:
			return u # progress
	return 1.0


## A motion with [param motion_effect] and [param motion_amount], the rest left at their defaults.
static func create(motion_effect: Effect, motion_amount: float) -> BitKilnMotion:
	var motion := BitKilnMotion.new()
	motion.effect = motion_effect
	motion.amount = motion_amount
	return motion
