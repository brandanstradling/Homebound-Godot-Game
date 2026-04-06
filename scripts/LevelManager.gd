extends Node

@onready var ground_layer = $"../Grid/Ground"
@onready var wall_layer = $"../Grid/Walls"
@onready var level_label = $"../UI/TopBar/LevelLabel"
@onready var turn_label = $"../UI/TopBar/TurnLabel"
@onready var pause_menu = $"../UI/PauseMenu"
@onready var settings_menu = $"../UI/SettingsMenu"
@onready var win_screen = $"../UI/WinScreen"
@onready var sfx_player = $"../AudioStreamPlayer"

@export var current_level: int = 0
@export var sfx_select: AudioStream

var selected_animal: Animal = null
var turn: int = 1

func _ready():
	GridManager.initialize(ground_layer, wall_layer)

	for animal in $"../Animals".get_children():
		animal.animal_selected.connect(select_animal)
		animal.reached_den.connect(_on_animal_reached_den)
		animal.snap_to_grid()

	level_label.text = "Level " + str(current_level)
	update_turn_label()
	pause_menu.hide()
	win_screen.hide()

func select_animal(animal: Animal):
	if selected_animal != null:
		selected_animal.set_selected(false)
	selected_animal = animal
	selected_animal.set_selected(true)
	sfx_player.stream = sfx_select
	sfx_player.play()

func _on_animal_reached_den(animal: Animal):
	# Deselect if this was the selected animal
	if selected_animal == animal:
		selected_animal.set_selected(false)
		selected_animal = null

	for a in $"../Animals".get_children():
		if not a.is_at_den:
			return
	show_win_screen()

func show_win_screen():
	GameProgress.complete_level(current_level)
	get_tree().paused = true
	win_screen.show()

func update_turn_label():
	turn_label.text = "Turn: " + str(turn)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

	if event.is_action_pressed("ui_accept") and selected_animal != null:
		selected_animal.activate()
		turn += 1
		update_turn_label()

	if event.is_action_pressed("rotate") and selected_animal != null:
		selected_animal.rotate_facing()

func toggle_pause():
	if pause_menu.visible:
		pause_menu.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true

func restart_level():
	get_tree().paused = false
	get_tree().reload_current_scene()

func go_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func toggle_settings():
	if settings_menu.visible:
		settings_menu.hide()
		pause_menu.show()
	else:
		pause_menu.hide()
		settings_menu.show()

# ---- Signals ----
func _on_restart_button_pressed():
	restart_level()

func _on_pause_button_pressed():
	toggle_pause()

func _on_resume_button_pressed():
	toggle_pause()

func _on_settings_button_pressed():
	toggle_settings()

func _on_menu_button_pressed():
	go_to_main_menu()

func _on_back_button_pressed():
	toggle_settings()

func _on_next_level_button_pressed():
	var next_level = current_level + 1
	get_tree().paused = false
	if next_level <= GameProgress.TOTAL_LEVELS and next_level > 0:
		get_tree().change_scene_to_file("res://scenes/levels/Level_%d.tscn" % next_level)
	else:
		# No more levels — go back to level select
		get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_master_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
