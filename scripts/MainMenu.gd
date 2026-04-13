extends Control

# ---- Node References ----
@onready var settings_menu = $SettingsMenu
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

# ---- Exports ----
@export var sfx_click_high: AudioStream

# ---- Lifecycle ----

func _ready():
	MusicManager.play(MusicManager.music_main_menu)
	settings_menu.hide()

# ---- Audio Helper ----

func _click():
	sfx_player.stream = sfx_click_high
	sfx_player.play()

# ---- Navigation ----

func _on_play_button_pressed():
	_click()
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_quit_button_pressed():
	_click()
	get_tree().quit()

# ---- Settings ----

func _on_settings_button_pressed():
	_click()
	settings_menu.show()

func _on_back_button_pressed():
	_click()
	settings_menu.hide()

# ---- Volume Sliders ----

func _set_bus_volume(bus_name: String, value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value))

func _on_master_volume_slider_value_changed(value): _set_bus_volume("Master", value)
func _on_music_volume_slider_value_changed(value):  _set_bus_volume("Music", value)
func _on_sfx_volume_slider_value_changed(value):    _set_bus_volume("SFX", value)
