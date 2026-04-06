class_name Boar
extends Animal

@export var charge_speed: float = 8.0

func _ready():
	super()
	play_animation("idle")

func activate():
	if is_moving:
		return

	var next_pos = grid_pos + facing
	while GridManager.is_walkable(next_pos):
		next_pos += facing
	var target_pos = next_pos - facing

	if target_pos == grid_pos:
		return  # already against a wall, nothing to do

	grid_pos = target_pos
	is_moving = true

	var target_world = GridManager.grid_to_world(target_pos)
	var distance = (target_world - global_position).length()
	var duration = distance / (charge_speed * 16.0)

	play_animation("run")

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_world, duration)
	tween.tween_callback(func():
		is_moving = false
		play_animation("idle")
		check_den()
	)
