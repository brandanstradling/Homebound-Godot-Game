extends Control

@onready var settings_menu = $SettingsMenu

func _ready():
	MusicManager.play(MusicManager.music_main_menu)
	settings_menu.hide()

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_settings_button_pressed():
	settings_menu.show()

func _on_back_button_pressed():
	settings_menu.hide()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_master_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
