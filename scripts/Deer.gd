class_name Deer
extends Animal

# ---- Exports ----
@export var jump_distance: int = 3

# ---- Lifecycle ----

func _ready():
	super()
	play_animation("idle")

# ---- Ability: Leap ----
# Deer leaps a fixed number of tiles in the facing direction, ignoring tiles in between.
# The landing tile must be walkable.

func activate():
	if is_moving:
		return

	var target_pos = grid_pos + (facing * jump_distance)

	# Only block if a breakable is in the path — gaps are fine to leap over
	for i in range(1, jump_distance):  # stops before landing tile
		var check = grid_pos + (facing * i)
		if GridManager.is_breakable(check):
			play_sfx(sfx_click_low)
			return
		if GridManager.get_animal_at(check) != null:
			play_sfx(sfx_click_low)
			return

	if not GridManager.is_walkable(target_pos):
		play_sfx(sfx_click_low)
		return

	grid_pos = target_pos
	is_moving = true

	var target_world = GridManager.grid_to_world(target_pos)
	play_animation("jump")

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_world, 0.7)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		is_moving = false
		play_animation("idle")
		GridManager.update_plates()
		check_den()
	)
