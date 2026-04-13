extends Node

# ---- Signals ----
signal gate_opened
signal gate_closed

# ---- Tile Layers ----
var ground_layer: TileMapLayer
var wall_layer: TileMapLayer
var breakable_layer: TileMapLayer
var plate_layer: TileMapLayer
var gate_layer: TileMapLayer

var _plate_gate_pairs: Array = []
var _gate_cells: Dictionary = {}
var _gate_tweens: Dictionary = {}

# ---- Initialization ----

func initialize(ground, walls, breakables, plates, gates, plate_pos: Array, gate_pos: Array):
	ground_layer = ground
	wall_layer = walls
	breakable_layer = breakables
	plate_layer = plates
	gate_layer = gates

	# Group plates by their matching gate — same gate pos = any plate opens it
	_plate_gate_pairs.clear()
	var gate_map: Dictionary = {}
	for i in range(min(plate_pos.size(), gate_pos.size())):
		var gp = gate_pos[i]
		if gp not in gate_map:
			gate_map[gp] = {
				"plates": [],
				"gate":   gp,
				"open":   false
			}
		gate_map[gp]["plates"].append(plate_pos[i])
	for pair in gate_map.values():
		_plate_gate_pairs.append(pair)

	call_deferred("_cache_gate_cells")

func _cache_gate_cells():
	_gate_cells.clear()

	for cell in gate_layer.get_used_cells():
		var solo = TileMapLayer.new()
		solo.tile_set                = gate_layer.tile_set
		solo.z_index                 = gate_layer.z_index
		solo.z_as_relative           = gate_layer.z_as_relative
		solo.y_sort_enabled          = gate_layer.y_sort_enabled
		solo.y_sort_origin           = gate_layer.y_sort_origin
		solo.rendering_quadrant_size = gate_layer.rendering_quadrant_size
		solo.position                = gate_layer.position
		solo.scale                   = gate_layer.scale
		gate_layer.get_parent().add_child(solo)
		solo.set_cell(
			cell,
			gate_layer.get_cell_source_id(cell),
			gate_layer.get_cell_atlas_coords(cell),
			gate_layer.get_cell_alternative_tile(cell)
		)

		_gate_cells[cell] = {
			"source": gate_layer.get_cell_source_id(cell),
			"atlas":  gate_layer.get_cell_atlas_coords(cell),
			"alt":    gate_layer.get_cell_alternative_tile(cell),
			"layer":  solo
		}

	gate_layer.hide()

# ---- Walkability ----

func is_walkable(pos: Vector2i) -> bool:
	if not is_ground(pos):
		return false
	if is_wall(pos):
		return false
	if is_gate(pos):
		return false
	if get_animal_at(pos) != null:
		return false
	return true

# ---- Tile Queries ----

func is_ground(pos: Vector2i) -> bool:
	return ground_layer.get_cell_source_id(pos) != -1

func is_wall(pos: Vector2i) -> bool:
	return wall_layer.get_cell_source_id(pos) != -1

func is_breakable(pos: Vector2i) -> bool:
	return breakable_layer.get_cell_source_id(pos) != -1

func is_gate(pos: Vector2i) -> bool:
	return gate_layer.get_cell_source_id(pos) != -1

func is_plate(pos: Vector2i) -> bool:
	return plate_layer.get_cell_source_id(pos) != -1

# ---- Tile Mutations ----

func break_tile(pos: Vector2i):
	breakable_layer.erase_cell(pos)

# ---- Pressure Plate Logic ----

func update_plates():
	var animals_node = _get_animals_node()
	if animals_node == null:
		return

	for pair in _plate_gate_pairs:
		var any_occupied = false
		for plate_pos in pair["plates"]:
			for animal in animals_node.get_children():
				if animal is Animal and animal.grid_pos == plate_pos:
					any_occupied = true
					break
			if any_occupied:
				break

		if any_occupied and not pair["open"]:
			pair["open"] = true
			_open_gate(pair["gate"])
			gate_opened.emit()
		elif not any_occupied and pair["open"]:
			pair["open"] = false
			_close_gate(pair["gate"])
			gate_closed.emit()

func _open_gate(gate_pos: Vector2i):
	if gate_pos not in _gate_cells:
		return
	var data = _gate_cells[gate_pos]
	_kill_tween(gate_pos)

	var tween = data["layer"].create_tween()
	tween.tween_property(data["layer"], "modulate", Color(1, 1, 1, 0), 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		gate_layer.erase_cell(gate_pos)
	)
	_gate_tweens[gate_pos] = tween

func _close_gate(gate_pos: Vector2i):
	if gate_pos not in _gate_cells:
		return
	var data = _gate_cells[gate_pos]
	_kill_tween(gate_pos)

	gate_layer.set_cell(gate_pos, data["source"], data["atlas"], data["alt"])
	data["layer"].modulate = Color(1, 1, 1, 0)
	var tween = data["layer"].create_tween()
	tween.tween_property(data["layer"], "modulate", Color.WHITE, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_gate_tweens[gate_pos] = tween

func _kill_tween(gate_pos: Vector2i):
	if gate_pos in _gate_tweens and _gate_tweens[gate_pos]:
		_gate_tweens[gate_pos].kill()
		_gate_tweens.erase(gate_pos)

# ---- Animal Lookup ----

func get_animal_at(pos: Vector2i) -> Animal:
	var animals_node = _get_animals_node()
	if animals_node == null:
		return null
	for child in animals_node.get_children():
		if child is Animal and child.grid_pos == pos:
			return child
	return null

# ---- Coordinate Conversion ----

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return ground_layer.local_to_map(ground_layer.to_local(world_pos))

func grid_to_world(pos: Vector2i) -> Vector2:
	return ground_layer.to_global(ground_layer.map_to_local(pos))

# ---- Helpers ----

func _get_animals_node() -> Node:
	var level = get_tree().get_first_node_in_group("level")
	if level == null:
		return null
	return level.get_node_or_null("Animals")
