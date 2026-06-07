class_name SaveManager
extends RefCounted

## Handles save/load of run state.

const SAVE_PATH: String = "user://poking_save.json"


static func save(state: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing")
		return
	file.store_string(JSON.stringify(state, "\t"))


static func load() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json_str: String = file.get_as_text()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_str)
	if error != OK:
		push_error("SaveManager: Failed to parse save file")
		return {}
	return json.data


static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
