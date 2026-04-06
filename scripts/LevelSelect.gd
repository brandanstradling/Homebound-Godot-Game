extends Control

@onready var grid = $LevelPanel/LevelContainer/GridContainer
@onready var test_grid = $TestPanel/TestContainer/GridContainer

const LEVEL_BUTTON = preload("res://scenes/menus/LevelButton.tscn")

const TEST_LEVELS = [
	"res://scenes/levels/testing/BoarTest.tscn",
	"res://scenes/levels/testing/BadgerTest.tscn",
	"res://scenes/levels/testing/DeerTest.tscn",
	"res://scenes/levels/testing/WolfTest.tscn"
]

func _ready():
	MusicManager.play(MusicManager.music_level_select)

	# Main levels
	for i in range(1, GameProgress.TOTAL_LEVELS + 1):
		var btn = LEVEL_BUTTON.instantiate()
		btn.get_node("Checkmark").visible = GameProgress.is_completed(i)
		btn.text = " " + str(i) + " "
		if GameProgress.is_unlocked(i):
			var level_index = i
			btn.pressed.connect(func():
				get_tree().change_scene_to_file("res://scenes/levels/Level_%d.tscn" % level_index)
			)
		else:
			btn.disabled = true
		grid.add_child(btn)

	# Test levels
	for path in TEST_LEVELS:
		var btn = LEVEL_BUTTON.instantiate()
		btn.get_node("Checkmark").visible = false
		btn.text = path.get_file().get_basename().replace("Test", "")
		var scene_path = path
		btn.pressed.connect(func():
			get_tree().change_scene_to_file(scene_path)
		)
		test_grid.add_child(btn)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
