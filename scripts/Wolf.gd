class_name Wolf
extends Animal

@export var charge_speed: float = 8.0

func _ready():
	super()
	play_animation("idle")

func activate():
	if is_moving:
		return

	# Move up to 3 tiles, stop early if blocked
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
	var distance = (target_world - global_position).length()
	var duration = distance / (charge_speed * 16.0)

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
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var neighbors = []

	for dir in directions:
		var check_pos = grid_pos + dir
		var animal = get_animal_at(check_pos)
		if animal != null:
			neighbors.append({"animal": animal, "dir": dir})

	if neighbors.is_empty():
		return

	play_animation("howl")

	# Wait until the push frame, then shove — adjust the delay to match your frame timing
	# e.g. if howl runs at 8fps and you want frame 3: 3/8 = 0.375s
	await get_tree().create_timer(0.75).timeout

	for entry in neighbors:
		var animal = entry["animal"]
		var push_dir = entry["dir"]
		var push_target = animal.grid_pos + push_dir
		animal.facing = push_dir
		animal.play_animation("idle")
		if GridManager.is_walkable(push_target):
			animal.grid_pos = push_target
			var push_world = GridManager.grid_to_world(push_target)
			var tween = create_tween()
			tween.tween_property(animal, "global_position", push_world, 0.2)
			tween.tween_callback(func(): animal.check_den())

func get_animal_at(pos: Vector2i) -> Animal:
	for animal in get_parent().get_children():
		if animal is Animal and animal != self and animal.grid_pos == pos:
			return animal
	return null
