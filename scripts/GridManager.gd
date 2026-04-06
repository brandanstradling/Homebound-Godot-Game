extends Node

var ground_layer: TileMapLayer
var wall_layer: TileMapLayer
var breakable_layer: TileMapLayer

func initialize(ground: TileMapLayer, walls: TileMapLayer, breakables: TileMapLayer):
	ground_layer = ground
	wall_layer = walls
	breakable_layer = breakables

func is_breakable(pos: Vector2i) -> bool:
	return breakable_layer.get_cell_source_id(pos) != -1

func break_tile(pos: Vector2i):
	breakable_layer.erase_cell(pos)

func is_walkable(pos: Vector2i) -> bool:
	if not is_ground(pos):
		return false
	if is_wall(pos):
		return false
	if get_animal_at(pos) != null:
		return false
	return true

func get_animal_at(pos: Vector2i) -> Animal:
	var level = get_tree().get_first_node_in_group("level")
	if level == null:
		return null
	var animals_node = level.get_node_or_null("Animals")
	if animals_node == null:
		return null
	for child in animals_node.get_children():   # ← searches Animals/*
		if child is Animal and child.grid_pos == pos:
			return child
	return null

func is_ground(grid_pos: Vector2i) -> bool:
	return ground_layer.get_cell_source_id(grid_pos) != -1

func is_wall(grid_pos: Vector2i) -> bool:
	return wall_layer.get_cell_source_id(grid_pos) != -1

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return ground_layer.local_to_map(ground_layer.to_local(world_pos))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return ground_layer.to_global(ground_layer.map_to_local(grid_pos))
