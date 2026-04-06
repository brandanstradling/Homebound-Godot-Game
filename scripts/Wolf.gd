class_name Wolf
extends Animal

@export var charge_speed: float = 8.0

func _ready():
	super()
	play_animation("idle")

func activate():
	if is_moving:
		return

	# Charge up to 3 tiles, stop when blocked
	var next_pos = grid_pos + facing
	var steps = 0
	while steps < 3 and GridManager.is_walkable(next_pos):
		next_pos += facing
		steps += 1
	var target_pos = next_pos - facing

	if target_pos == grid_pos:
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
		check_den()
	)

func howl():
	# Collect adjacent animals before playing animation
	var neighbors = []
	for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var animal = GridManager.get_animal_at(grid_pos + dir)
		if animal != null and animal != self:
			neighbors.append({"animal": animal, "dir": dir})

	if neighbors.is_empty():
		return

	play_animation("howl")
	# Delay push to sync with howl animation peak (adjust to match fps/frame)
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
			tween.tween_callback(func(): animal.check_den())
