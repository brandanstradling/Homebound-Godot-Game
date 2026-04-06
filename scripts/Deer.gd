class_name Deer
extends Animal

@export var jump_distance: int = 3

func _ready():
	super()
	play_animation("idle")

func activate():
	if is_moving:
		return

	var target_pos = grid_pos + (facing * jump_distance)

	if not GridManager.is_walkable(target_pos):
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
		check_den()
	)
