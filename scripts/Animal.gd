class_name Animal
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var den_marker: AnimatedSprite2D = $DenMarker
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

@export var facing: Vector2i = Vector2i(0, -1)
@export var start_position: Vector2i
@export var den_position: Vector2i
@export var sfx_move: AudioStream
@export var sfx_arrive: AudioStream

signal animal_selected(animal)
signal reached_den(animal)

var grid_pos: Vector2i
var is_selected: bool = false
var is_moving: bool = false
var is_at_den: bool = false

func _ready():
	grid_pos = start_position
	sprite.material.set_shader_parameter("outline_active", false)
	den_marker.visible = false
	den_marker.global_position = GridManager.grid_to_world(den_position)

func snap_to_grid():
	grid_pos = start_position
	global_position = GridManager.grid_to_world(grid_pos)

func move_to(new_pos: Vector2i):
	grid_pos = new_pos
	global_position = GridManager.grid_to_world(grid_pos)
	check_den()

func activate():
	pass

func check_den():
	if grid_pos == den_position:
		is_at_den = true
		on_reached_den()

func on_reached_den():
	modulate = Color(0.5, 1.0, 0.5)
	set_process_input(false)
	reached_den.emit(self)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if not is_at_den:
			animal_selected.emit(self)

func set_selected(selected: bool):
	is_selected = selected
	sprite.material.set_shader_parameter("outline_active", selected)
	den_marker.visible = selected

func rotate_facing():
	if is_moving:
		return

	if facing == Vector2i(1, 0):
		facing = Vector2i(0, 1)
	elif facing == Vector2i(0, 1):
		facing = Vector2i(-1, 0)
	elif facing == Vector2i(-1, 0):
		facing = Vector2i(0, -1)
	else:
		facing = Vector2i(1, 0)
	play_animation("idle")

func get_direction_name() -> String:
	if facing == Vector2i(1, 0):
		return "SE"
	elif facing == Vector2i(0, 1):
		return "SW"
	elif facing == Vector2i(-1, 0):
		return "NW"
	else:
		return "NE"

func play_animation(state: String):
	var new_anim = get_direction_name() + "_" + state
	if sprite.animation.ends_with("_" + state):
		var current_frame = sprite.frame
		sprite.play(new_anim)
		sprite.frame = current_frame
	else:
		sprite.play(new_anim)

func play_sfx(stream: AudioStream):
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()
