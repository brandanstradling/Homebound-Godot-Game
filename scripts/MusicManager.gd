extends Node

# ---- Node References ----
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sting_player: AudioStreamPlayer = $StingPlayer

# ---- Exports ----
@export var music_main_menu: AudioStream
@export var music_level_select: AudioStream
@export var music_level: AudioStream
@export var music_win: AudioStream

# ---- Playback ----

# Plays a looping music track. Skips if already playing the same track.
func play(stream: AudioStream):
	if player.stream == stream and player.playing:
		return
	player.stream = stream
	player.bus = "Music"
	player.play()

# Plays a one-shot sting (win jingle, etc.) on a separate player.
func play_sting(stream: AudioStream):
	if stream == null:
		return
	sting_player.stream = stream
	sting_player.play()

func stop():
	player.stop()
