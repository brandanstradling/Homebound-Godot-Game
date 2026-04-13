extends Node

# ---- Node References ----
@onready var ground_layer     = $"../Grid/Ground"
@onready var wall_layer       = $"../Grid/Walls"
@onready var breakable_layer  = $"../Grid/Breakables"
@onready var plate_layer      = $"../Grid/Plates"
@onready var gate_layer       = $"../Grid/Gates"
@onready var level_label      = $"../UI/TopBar/LevelLabel"
@onready var pause_menu       = $"../UI/PauseMenu"
@onready var settings_menu    = $"../UI/SettingsMenu"
@onready var win_screen       = $"../UI/WinScreen"
@onready var sfx_player       = $"../AudioStreamPlayer"

# ---- Exports ----
@export var current_level: int = 0
@export var sfx_click_high: AudioStream
@export var sfx_click_low: AudioStream
@export var plate_positions: Array[Vector2i] = []
@export var gate_positions:  Array[Vector2i] = []

# ---- Level Names ----
const LEVEL_NAMES: Dictionary = {
	-4: "Wolf Test",
	-3: "Badger Test",
	-2: "Deer Test",
	-1: "Boar Test",
	1:  "Home",
	2:  "Wrong Way",
	3:  "Two Paths",
	4:  "Thin Air",
	5:  "Follow My Lead",
	6:  "Through the Wall",
	7:  "Gatekeeper",
	8:  "The Hard Way",
	9:  "Chain Reaction"
}

# ---- State ----
var selected_animal: Animal = null
var _breakable_tween: Tween

# ---- Lifecycle ----

func _ready():
	GridManager.initialize(ground_layer, wall_layer, breakable_layer, plate_layer, gate_layer, plate_positions, gate_positions)
	GridManager.gate_opened.connect(func(): play_sfx(sfx_click_high))
	GridManager.gate_closed.connect(func(): play_sfx(sfx_click_low))

	for animal in $"../Animals".get_children():
		animal.animal_selected.connect(select_animal)
		animal.reached_den.connect(_on_animal_reached_den)
		animal.snap_to_grid()

	level_label.text = LEVEL_NAMES.get(current_level, "Level " + str(current_level)) + "\n\n"
	pause_menu.hide()
	win_screen.hide()

# ---- Audio ----

func play_sfx(stream: AudioStream):
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()

# ---- Boar Breakable Hint ----

func _start_breakable_hint():
	_stop_breakable_hint()
	_breakable_tween = create_tween().set_loops()
	_breakable_tween.tween_property(breakable_layer, "modulate", Color(1.15, 1.05, 0.85), 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breakable_tween.tween_property(breakable_layer, "modulate", Color(1.0, 1.0, 1.0), 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_breakable_hint():
	if _breakable_tween:
		_breakable_tween.kill()
		_breakable_tween = null
	breakable_layer.modulate = Color.WHITE

# ---- Animal Selection ----

func select_animal(animal: Animal):
	if selected_animal == animal:
		selected_animal.set_selected(false)
		selected_animal = null
		play_sfx(sfx_click_low)
		_stop_breakable_hint()
		return

	if selected_animal != null:
		selected_animal.set_selected(false)
	selected_animal = animal
	selected_animal.set_selected(true)
	play_sfx(sfx_click_high)

	if animal is Boar:
		_start_breakable_hint()
	else:
		_stop_breakable_hint()

# ---- Win Condition ----

func _on_animal_reached_den(animal: Animal):
	if selected_animal == animal:
		selected_animal.set_selected(false)
		selected_animal = null
		_stop_breakable_hint()
	call_deferred("_check_all_at_den")

func _check_all_at_den():
	for a in $"../Animals".get_children():
		if not a.is_at_den:
			return
	show_win_screen()

func show_win_screen():
	GameProgress.complete_level(current_level)
	MusicManager.play_sting(MusicManager.music_win)
	get_tree().paused = true
	win_screen.show()

# ---- Input ----

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	if event.is_action_pressed("ui_accept") and selected_animal != null:
		selected_animal.activate()
	if event.is_action_pressed("rotate") and selected_animal != null:
		selected_animal.rotate_facing()

# ---- Pause / Settings ----

func toggle_pause():
	play_sfx(sfx_click_high)
	if pause_menu.visible:
		pause_menu.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true

func toggle_settings():
	play_sfx(sfx_click_high)
	if settings_menu.visible:
		settings_menu.hide()
		pause_menu.show()
	else:
		pause_menu.hide()
		_sync_volume_sliders()
		settings_menu.show()

func restart_level():
	play_sfx(sfx_click_high)
	get_tree().paused = false
	get_tree().reload_current_scene()

func go_to_main_menu():
	play_sfx(sfx_click_high)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

# ---- Next Level ----

func go_to_next_level():
	play_sfx(sfx_click_high)
	var next_level = current_level + 1
	get_tree().paused = false
	if next_level <= GameProgress.TOTAL_LEVELS and next_level > 1:
		get_tree().change_scene_to_file("res://scenes/levels/Level_%d.tscn" % next_level)
	else:
		get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

# ---- Volume Sliders ----

func _set_bus_volume(bus_name: String, value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value))

func _sync_volume_sliders():
	$"../UI/SettingsMenu/VBoxContainer/MasterContainer/MasterVolumeSlider".value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	$"../UI/SettingsMenu/VBoxContainer/MusicContainer/MusicVolumeSlider".value  = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	$"../UI/SettingsMenu/VBoxContainer/SFXContainer/SFXVolumeSlider".value    = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

# ---- Signal Callbacks ----

func _on_restart_button_pressed():    restart_level()
func _on_pause_button_pressed():      toggle_pause()
func _on_resume_button_pressed():     toggle_pause()
func _on_settings_button_pressed():   toggle_settings()
func _on_back_button_pressed():       toggle_settings()
func _on_menu_button_pressed():       go_to_main_menu()
func _on_next_level_button_pressed(): go_to_next_level()

func _on_master_volume_slider_value_changed(value): _set_bus_volume("Master", value)
func _on_music_volume_slider_value_changed(value):  _set_bus_volume("Music", value)
func _on_sfx_volume_slider_value_changed(value):    _set_bus_volume("SFX", value)
