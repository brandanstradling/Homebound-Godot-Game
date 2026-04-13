class_name Boar
extends Animal

# ---- Exports ----
@export var charge_speed: float = 8.0

# ---- Lifecycle ----

func _ready():
	super()
	play_animation("idle")

# ---- Ability: Charge ----
# Boar charges in the facing direction until hitting a wall or breakable tile.
# Breaks the first breakable tile it runs into.

func activate():
	if is_moving:
		return

	var next_pos = grid_pos + facing
	var broke_pos = null  # Tracks if a breakable was hit

	# Advance until blocked; stop at and record any breakable
	while GridManager.is_walkable(next_pos) or GridManager.is_breakable(next_pos):
		if GridManager.is_breakable(next_pos):
			broke_pos = next_pos
			break
		next_pos += facing
	var target_pos = next_pos - facing

	# No movement possible
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
		if broke_pos != null:
			flash_and_break(broke_pos)
		GridManager.update_plates()
		check_den()
	)

# ---- Break Effect ----
# Spawns a temporary sprite copy of the broken tile, fades it out, then removes it.

func flash_and_break(pos: Vector2i):
	var world_pos = GridManager.grid_to_world(pos)
	var tile_data = GridManager.breakable_layer
	var source_id = tile_data.get_cell_source_id(pos)
	var atlas_coords = tile_data.get_cell_atlas_coords(pos)
	var source = tile_data.tile_set.get_source(source_id) as TileSetAtlasSource

	var flash = Sprite2D.new()
	flash.texture = source.texture
	flash.region_enabled = true
	flash.region_rect = source.get_tile_texture_region(atlas_coords, 0)
	# Offset upward to align with wall-height tiles
	flash.global_position = world_pos + Vector2(0, -8)
	flash.z_index = GridManager.breakable_layer.z_index
	get_parent().add_child(flash)

	GridManager.break_tile(pos)
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(flash.queue_free)
