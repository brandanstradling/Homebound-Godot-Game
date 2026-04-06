extends Node

const TOTAL_LEVELS: int = 12
const UNLOCK_BUFFER: int = 2  # how many levels ahead are unlocked

var completed_levels: Array[int] = []
var unlocked_levels: Array[int] = []

func _ready():
	# Level 1 always unlocked at start
	recalculate_unlocked()

func complete_level(level_num: int):
	if level_num not in completed_levels and level_num > 0:
		completed_levels.append(level_num)
	recalculate_unlocked()

func recalculate_unlocked():
	unlocked_levels.clear()
	# Always unlock from level 1 up to furthest completed + buffer
	var furthest = completed_levels.max() if not completed_levels.is_empty() else 0
	var unlock_up_to = min(furthest + UNLOCK_BUFFER + 1, TOTAL_LEVELS)
	for i in range(1, unlock_up_to + 1):
		unlocked_levels.append(i)
	# Level 1 always unlocked
	if 1 not in unlocked_levels:
		unlocked_levels.append(1)

func is_unlocked(level_num: int) -> bool:
	return level_num in unlocked_levels

func is_completed(level_num: int) -> bool:
	return level_num in completed_levels
