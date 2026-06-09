class_name SaveManager
extends RefCounted

## Handles save/load for NinKing.
## Run save = mid-run state (gold, ninjas, star chart levels, etc.)
## Progress save = persistent unlocks (decks, stats) — permanent death model.

const RUN_SAVE_PATH: String = "user://ninking_run_save.json"
const PROGRESS_SAVE_PATH: String = "user://ninking_progress.json"


# ══════════════════════════════════════════
# Run save (mid-game, deleted on death/win)
# ══════════════════════════════════════════

static func save_run(state: Dictionary) -> void:
	_write_json(RUN_SAVE_PATH, state)


static func load_run() -> Dictionary:
	var data: Dictionary = _read_json(RUN_SAVE_PATH)
	# Backward compat: migrate old key names
	if not data.has("barrier_num") and data.has("ante_num"):
		data["barrier_num"] = data["ante_num"]
	if not data.has("seal_idx") and data.has("blind_index"):
		data["seal_idx"] = data["blind_index"]
	return data


static func delete_run() -> void:
	_delete_file(RUN_SAVE_PATH)


static func has_run_save() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


## Build a save dictionary from current game state.
## @param gs: NinKingGameState autoload (typed Node to avoid circular class_name dependency).
static func build_run_data(gs: Node) -> Dictionary:
	return {
		"barrier_num": gs.barrier_num,
		"seal_idx": gs.seal_idx,
		"current_score": gs.current_score,
		"target_score": gs.target_score,
		"plays_remaining": gs.plays_remaining,
		"redraws_remaining": gs.redraws_remaining,
		"gold": gs.gold,
		"current_deck_name": gs.current_deck_name,
		"owned_ninjas": gs.owned_ninjas.duplicate(true),
		"owned_items": gs.owned_items.duplicate(true),
		"star_chart_levels": gs.star_chart_levels.duplicate(),
		"current_seal_lord_name": gs.current_seal_lord_name,
		"current_seal_lord_effects": gs.current_seal_lord_effects.duplicate(),
	}


# ══════════════════════════════════════════
# Progress save (persistent unlocks)
# ══════════════════════════════════════════

const DEFAULT_PROGRESS: Dictionary = {
	"unlocked_decks": ["standard", "night", "sun"],  # 初始解锁 3 种牌组
	"deck_best_barriers": {},                         # {deck_name: best_barrier_reached}
	"total_runs": 0,
	"total_wins": 0,
}

static func load_progress() -> Dictionary:
	var data: Dictionary = _read_json(PROGRESS_SAVE_PATH)
	if data.is_empty():
		data = DEFAULT_PROGRESS.duplicate()
	# Backward compat: migrate old key names
	if not data.has("deck_best_barriers") and data.has("deck_best_antes"):
		data["deck_best_barriers"] = data["deck_best_antes"]
	return data


static func save_progress(data: Dictionary) -> void:
	_write_json(PROGRESS_SAVE_PATH, data)


static func unlock_deck(deck_name: String) -> void:
	var progress: Dictionary = load_progress()
	var decks: Array = progress.get("unlocked_decks", [])
	if not decks.has(deck_name):
		decks.append(deck_name)
		progress["unlocked_decks"] = decks
		save_progress(progress)


static func record_run_result(deck_name: String, barrier_reached: int, won: bool) -> void:
	var progress: Dictionary = load_progress()
	progress["total_runs"] = progress.get("total_runs", 0) + 1
	if won:
		progress["total_wins"] = progress.get("total_wins", 0) + 1

	var bests: Dictionary = progress.get("deck_best_barriers", {})
	if barrier_reached > bests.get(deck_name, 0):
		bests[deck_name] = barrier_reached
		progress["deck_best_barriers"] = bests

	save_progress(progress)


# ══════════════════════════════════════════
# Internal
# ══════════════════════════════════════════

static func _write_json(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open file for writing: %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_str: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_str)
	if error != OK:
		push_error("SaveManager: Failed to parse: %s" % path)
		return {}
	return json.data


static func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
