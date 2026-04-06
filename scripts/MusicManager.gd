extends Node

@onready var player: AudioStreamPlayer = $AudioStreamPlayer

@export var music_main_menu: AudioStream
@export var music_level_select: AudioStream
@export var music_level: AudioStream
@export var music_win: AudioStream

func play(stream: AudioStream):
	if player.stream == stream and player.playing:
		return
	player.stream = stream
	player.bus = "Music"
	player.play()

func stop():
	player.stop()
