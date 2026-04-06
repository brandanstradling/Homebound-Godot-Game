class_name Badger
extends Animal

func _ready():
	super()
	play_animation("idle")

func activate():
	if is_moving:
		return

	var tile_1 = grid_pos + facing
	var target_pos = grid_pos + (facing * 2)

	if not GridManager.is_walkable(target_pos):
		return

	if not GridManager.is_walkable(tile_1) and not GridManager.is_wall(tile_1):
		return

	var through_wall = GridManager.is_wall(tile_1)

	grid_pos = target_pos
	is_moving = true

	var target_world = GridManager.grid_to_world(target_pos)

	if through_wall:
		play_animation("burrow")
		sprite.animation_finished.connect(func():
			# Burrow done — start moving and play tunnel simultaneously
			play_animation("tunnel")
			z_index = 0
			var tween = create_tween()
			tween.tween_property(self, "global_position", target_world, 0.5)
			tween.tween_callback(func():
				# Movement done — play unburrow then go idle
				z_index = 1
				play_animation("unburrow")
				sprite.animation_finished.connect(func():
					is_moving = false
					play_animation("idle")
					check_den()
				, CONNECT_ONE_SHOT)
			)
		, CONNECT_ONE_SHOT)
	else:
		play_animation("walk")
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_world, 0.35)
		tween.tween_callback(func():
			is_moving = false
			play_animation("idle")
			check_den()
		)
