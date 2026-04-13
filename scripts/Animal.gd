class_name Animal
extends Node2D

# ---- Node References ----
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var den_marker: AnimatedSprite2D = $DenMarker
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

# ---- Exports ----
@export var facing: Vector2i = Vector2i(0, -1)
@export var start_position: Vector2i
@export var den_position: Vector2i
@export var sfx_move: AudioStream
@export var sfx_arrive: AudioStream
@export var sfx_click_low: AudioStream

# ---- Signals ----
signal animal_selected(animal)
signal reached_den(animal)

# ---- State ----
var grid_pos: Vector2i
var is_selected: bool = false
var is_moving: bool = false
var is_at_den: bool = false

# ---- Direction Lookups ----
const FACING_TO_DIR = {
	Vector2i(1, 0):  "SE",
	Vector2i(0, 1):  "SW",
	Vector2i(-1, 0): "NW",
	Vector2i(0, -1): "NE"
}
const ROTATE_ORDER = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)
]

# ---- Lifecycle ----

func _ready():
	grid_pos = start_position
	sprite.material.set_shader_parameter("outline_active", false)
	den_marker.visible = false
	den_marker.global_position = GridManager.grid_to_world(den_position)

func snap_to_grid():
	grid_pos = start_position
	global_position = GridManager.grid_to_world(grid_pos)

# ---- Movement ----

# Instantly moves to a grid position and checks all consequences.
func move_to(new_pos: Vector2i):
	grid_pos = new_pos
	global_position = GridManager.grid_to_world(grid_pos)
	GridManager.update_plates()
	check_den()

# Overridden by each animal subclass to define their unique ability.
func activate():
	pass

# ---- Den Logic ----

func check_den():
	if grid_pos == den_position:
		is_at_den = true
		on_reached_den()

func on_reached_den():
	modulate = Color(0.5, 1.0, 0.5)
	set_process_input(false)
	reached_den.emit(self)

# ---- Input ----

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if is_at_den:
			# Play a denied click sound if already at den
			play_sfx(sfx_click_low)
		else:
			animal_selected.emit(self)

# ---- Selection ----

func set_selected(selected: bool):
	is_selected = selected
	sprite.material.set_shader_parameter("outline_active", selected)
	den_marker.visible = selected

# ---- Facing / Rotation ----

func rotate_facing():
	if is_moving:
		return
	var idx = (ROTATE_ORDER.find(facing) + 1) % ROTATE_ORDER.size()
	facing = ROTATE_ORDER[idx]
	play_animation("idle")

func get_direction_name() -> String:
	return FACING_TO_DIR.get(facing, "NE")

# ---- Animation ----

# Plays a directional animation. Preserves current frame if only direction changed.
func play_animation(state: String):
	var new_anim = get_direction_name() + "_" + state
	if sprite.animation.ends_with("_" + state):
		var current_frame = sprite.frame
		sprite.play(new_anim)
		sprite.frame = current_frame
	else:
		sprite.play(new_anim)

# ---- Audio ----

func play_sfx(stream: AudioStream):
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()
