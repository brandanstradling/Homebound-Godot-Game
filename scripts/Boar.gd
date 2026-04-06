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
	var broke_pos = null  # null = no breakable hit

	while GridManager.is_walkable(next_pos) or GridManager.is_breakable(next_pos):
		if GridManager.is_breakable(next_pos):
			broke_pos = next_pos
			break
		next_pos += facing
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
		if broke_pos != null:
			flash_and_break(broke_pos)
		check_den()
	)

func flash_and_break(pos: Vector2i):
	# Grab the tile's texture and place a temporary sprite at that position
	var world_pos = GridManager.grid_to_world(pos)
	var tile_data = GridManager.breakable_layer
	var source_id = tile_data.get_cell_source_id(pos)
	var atlas_coords = tile_data.get_cell_atlas_coords(pos)
	var source = tile_data.tile_set.get_source(source_id) as TileSetAtlasSource

	var flash = Sprite2D.new()
	flash.texture = source.texture
	flash.region_enabled = true
	flash.region_rect = source.get_tile_texture_region(atlas_coords, 0)
	flash.global_position = world_pos + Vector2(0, -8)
	flash.z_index = GridManager.breakable_layer.z_index
	get_parent().add_child(flash)

	# Erase the tile immediately, flash the sprite then remove it
	GridManager.break_tile(pos)
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(flash.queue_free)
