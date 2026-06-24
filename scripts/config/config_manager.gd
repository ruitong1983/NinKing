extends Node
## ConfigManager — 加载 res://config/game_config.json，校验后暴露只读属性。
## 任一字段缺失/非法 → 退回硬编码默认值 + push_warning。

const CONFIG_PATH: String = "res://config/game_config.json"
const DEFAULT: Dictionary = {
	"starting_gold": 8,
	"plays_per_seal": 3,
	"max_ninja_slots": 5,
	"interest_divisor": 5,
	"interest_cap": 5,
	"shop_ninja_count": 4,
	"shop_item_count": 2,
	"reroll_base_cost": 3,
	"starter_ninja_ids": ["n_001", "n_052", "n_059", "n_105", "n_151"],
		"clean_swaps_per_seal": 5,
}


const REQUIRED_KEYS: Array[String] = [
	"starting_gold", "plays_per_seal", "max_ninja_slots",
	"interest_divisor", "interest_cap", "shop_ninja_count",
	"shop_item_count", "reroll_base_cost", "starter_ninja_ids", "clean_swaps_per_seal",
]

var starting_gold: int
var plays_per_seal: int
var max_ninja_slots: int
var interest_divisor: int
var interest_cap: int
var shop_ninja_count: int
var shop_item_count: int
var reroll_base_cost: int
var starter_ninja_ids: Array[String]
var clean_swaps_per_seal: int
var _config_loaded: bool = false


func _ready() -> void:
	_load_config()


func is_loaded() -> bool:
	return _config_loaded


func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		_apply_default("配置文件不存在: %s" % CONFIG_PATH)
		return

	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		_apply_default("无法打开配置文件: %s" % CONFIG_PATH)
		return

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(text)
	if error != OK:
		_apply_default("JSON 解析失败: %s (行 %d)" % [json.get_error_message(), json.get_error_line()])
		return

	var data = json.get_data()
	if not data is Dictionary:
		_apply_default("JSON 顶层不是对象")
		return

	# Strip _comment keys
	var cleaned: Dictionary = {}
	for key: String in data:
		if not key.begins_with("_"):
			cleaned[key] = data[key]
	data = cleaned

	# Check required keys
	var missing: Array[String] = []
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			missing.append(key)
	if not missing.is_empty():
		_apply_default("缺少字段: %s" % ", ".join(missing))
		return

	# Validate value ranges
	var errors: Array[String] = []
	_validate_gte(errors, data, "starting_gold", 0)
	_validate_gte(errors, data, "plays_per_seal", 1)
	_validate_gte(errors, data, "max_ninja_slots", 1)
	_validate_gt(errors, data, "interest_divisor", 0)
	_validate_gte(errors, data, "interest_cap", 0)
	_validate_gte(errors, data, "shop_ninja_count", 1)
	_validate_gte(errors, data, "shop_item_count", 1)
	_validate_gte(errors, data, "reroll_base_cost", 0)
	_validate_gte(errors, data, "clean_swaps_per_seal", 1)
	if not data["starter_ninja_ids"] is Array or data["starter_ninja_ids"].is_empty():
		errors.append("starter_ninja_ids 非数组或为空")
	else:
		for element in data["starter_ninja_ids"]:
			if not element is String:
				errors.append("starter_ninja_ids 包含非字符串元素")
				break
	if not errors.is_empty():
		_apply_default("值域校验失败: %s" % ", ".join(errors))
		return

	# All good — apply
	_apply_config(data)
	_config_loaded = true


func _apply_default(reason: String) -> void:
	push_warning("ConfigManager: %s — 使用默认配置" % reason)
	_apply_config(DEFAULT)
	_config_loaded = true


func _apply_config(data: Dictionary) -> void:
	starting_gold = int(data["starting_gold"])
	plays_per_seal = int(data["plays_per_seal"])
	max_ninja_slots = int(data["max_ninja_slots"])
	interest_divisor = int(data["interest_divisor"])
	interest_cap = int(data["interest_cap"])
	shop_ninja_count = int(data["shop_ninja_count"])
	shop_item_count = int(data["shop_item_count"])
	reroll_base_cost = int(data["reroll_base_cost"])
	starter_ninja_ids = []
	clean_swaps_per_seal = int(data.get("clean_swaps_per_seal", 5))
	var ids: Array = data["starter_ninja_ids"]
	for id: String in ids:
		starter_ninja_ids.append(id)


func _validate_gte(errors: Array[String], data: Dictionary, key: String, min_val: int) -> void:
	var val = data[key]
	if not (val is int or val is float):
		errors.append("%s 不是数字" % key)
	elif int(val) < min_val:
		errors.append("%s 需 >= %d，当前 %d" % [key, min_val, int(val)])


func _validate_gt(errors: Array[String], data: Dictionary, key: String, min_val: int) -> void:
	var val = data[key]
	if not (val is int or val is float):
		errors.append("%s 不是数字" % key)
	elif int(val) <= min_val:
		errors.append("%s 需 > %d，当前 %d" % [key, min_val, int(val)])
