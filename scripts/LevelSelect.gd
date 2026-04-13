extends Control

# ---- Node References ----
@onready var grid = $LevelPanel/LevelContainer/GridContainer
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

# ---- Exports ----
@export var sfx_click_high: AudioStream

# ---- Constants ----
const LEVEL_BUTTON = preload("res://scenes/menus/LevelButton.tscn")

const TEST_LEVELS = [
	"res://scenes/levels/testing/BoarTest.tscn",
	"res://scenes/levels/testing/BadgerTest.tscn",
	"res://scenes/levels/testing/DeerTest.tscn",
	"res://scenes/levels/testing/WolfTest.tscn"
]

# ---- Lifecycle ----

func _ready():
	MusicManager.play(MusicManager.music_level_select)
	_populate_main_levels()

# ---- Level Population ----

func _populate_main_levels():
	for i in range(1, GameProgress.TOTAL_LEVELS + 1):
		var btn = LEVEL_BUTTON.instantiate()
		btn.get_node("Checkmark").visible = GameProgress.is_completed(i)
		btn.text = " " + str(i) + " "
		if GameProgress.is_unlocked(i):
			var level_index = i
			btn.pressed.connect(func():
				sfx_player.stream = sfx_click_high
				sfx_player.play()
				get_tree().change_scene_to_file("res://scenes/levels/Level_%d.tscn" % level_index)
			)
		else:
			btn.disabled = true
		grid.add_child(btn)

# ---- Navigation ----

func _on_back_button_pressed():
	sfx_player.stream = sfx_click_high
	sfx_player.play()
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
