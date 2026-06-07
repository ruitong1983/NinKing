class_name LevelConfig
extends RefCounted

## Defines 8 levels with target scores and gold rewards.

const LEVELS: Array[Dictionary] = [
	{ "level": 1, "target_score": 300,  "gold_reward": 10 },
	{ "level": 2, "target_score": 600,  "gold_reward": 12 },
	{ "level": 3, "target_score": 1000, "gold_reward": 15 },
	{ "level": 4, "target_score": 1500, "gold_reward": 18 },
	{ "level": 5, "target_score": 2200, "gold_reward": 22 },
	{ "level": 6, "target_score": 3200, "gold_reward": 26 },
	{ "level": 7, "target_score": 4500, "gold_reward": 30 },
	{ "level": 8, "target_score": 6000, "gold_reward": 40 },
]


static func get_level(level_num: int) -> Dictionary:
	var idx: int = level_num - 1
	if idx < 0 or idx >= LEVELS.size():
		return {}
	return LEVELS[idx]


static func get_total_levels() -> int:
	return LEVELS.size()
