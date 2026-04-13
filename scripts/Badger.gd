class_name Badger
extends Animal

# ---- Lifecycle ----

func _ready():
	super()
	play_animation("idle")

# ---- Ability: Burrow ----
# Badger moves 2 tiles in the facing direction.
# If the first tile is a wall, Badger burrows through it with a tunnel animation.

func activate():
	if is_moving:
		return

	var tile_1 = grid_pos + facing
	var target_pos = grid_pos + (facing * 2)

	# Destination must be walkable
	if not GridManager.is_walkable(target_pos):
		play_sfx(sfx_click_low)
		return

	# Middle tile must be either walkable or a wall (not a gate, animal, etc.)
	if not GridManager.is_walkable(tile_1) and not GridManager.is_wall(tile_1):
		play_sfx(sfx_click_low)
		return

	var through_wall = GridManager.is_wall(tile_1)

	grid_pos = target_pos
	is_moving = true

	var target_world = GridManager.grid_to_world(target_pos)

	if through_wall:
		# Play burrow-in, travel underground, then emerge
		play_animation("burrow")
		sprite.animation_finished.connect(func():
			play_animation("tunnel")
			z_index = 0  # Go below other tiles while underground
			var tween = create_tween()
			tween.tween_property(self, "global_position", target_world, 0.5)
			tween.tween_callback(func():
				z_index = 1
				play_animation("unburrow")
				sprite.animation_finished.connect(func():
					is_moving = false
					play_animation("idle")
					GridManager.update_plates()
					check_den()
				, CONNECT_ONE_SHOT)
			)
		, CONNECT_ONE_SHOT)
	else:
		# Normal 2-tile walk
		play_animation("walk")
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_world, 0.35)
		tween.tween_callback(func():
			is_moving = false
			play_animation("idle")
			GridManager.update_plates()
			check_den()
		)
