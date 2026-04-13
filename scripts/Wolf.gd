class_name Wolf
extends Animal

# ---- Exports ----
@export var charge_speed: float = 8.0

# ---- Lifecycle ----

func _ready():
	super()
	play_animation("idle")

# ---- Ability: Charge + Howl ----
# Wolf charges up to 3 tiles in the facing direction, then howls to push adjacent animals.

func activate():
	if is_moving:
		return

	var next_pos = grid_pos + facing
	var steps = 0
	while steps < 3 and GridManager.is_walkable(next_pos):
		next_pos += facing
		steps += 1
	var target_pos = next_pos - facing

	if target_pos == grid_pos:
		play_sfx(sfx_click_low)
		return

	grid_pos = target_pos
	is_moving = true

	var target_world = GridManager.grid_to_world(target_pos)
	var duration = (target_world - global_position).length() / (charge_speed * 16.0)

	play_animation("run")
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_world, duration)
	tween.tween_callback(func():
		is_moving = false
		play_animation("idle")
		howl()
	)

# ---- Howl ----
# Pushes all directly adjacent animals one tile away. Waits for animation before pushing.

func howl():
	var neighbors = []
	for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var animal = GridManager.get_animal_at(grid_pos + dir)
		if animal != null and animal != self and not animal.is_at_den:
			neighbors.append({"animal": animal, "dir": dir})

	if neighbors.is_empty():
		check_den()
		return

	play_animation("howl")
	# Delay push to sync with the howl animation peak
	await get_tree().create_timer(0.75).timeout

	for entry in neighbors:
		var animal = entry["animal"]
		var push_target = animal.grid_pos + entry["dir"]
		animal.facing = entry["dir"]
		animal.play_animation("idle")
		if GridManager.is_walkable(push_target):
			animal.grid_pos = push_target
			var tween = create_tween()
			tween.tween_property(animal, "global_position", GridManager.grid_to_world(push_target), 0.2)
			tween.tween_callback(func():
				GridManager.update_plates()
				animal.check_den()
			)

	check_den()
