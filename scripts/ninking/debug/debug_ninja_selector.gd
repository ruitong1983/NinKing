extends Control
## Debug 忍者選択弹窗 — 弹出 Grid 列表显示全部忍者，多选 0-5 个。
## 左键选择/取消忍者，右键弹出 CardDetailPopup 查看卡牌详情。
## 排序模式：类型（默认）、稀有度、全部。

signal ninjas_selected(selected_ninjas: Array[Dictionary])
signal cancelled()

enum SortMode { CATEGORY, RARITY, NONE }

const TARGET_COLS: int = 11
const GRID_H_SEP: int = 6
const MAX_SELECT: int = 5
var _card_width: float = 100.0

const CATEGORY_NAMES: Dictionary = {
	"universal": "通用加成",
	"group_target": "组别定向",
	"rule_change": "规则变更",
	"xi_enhance": "喜之强化",
	"scaling": "成长修炼",
	"economy": "经济",
	"tools": "忍具",
	"legendary": "传说",
	"redraw": "手替激励",
	"cross_link": "跨组联动",
	"face_card": "点数/人牌",
}

const CATEGORY_ORDER: Array[String] = [
	"universal", "group_target", "rule_change", "xi_enhance",
	"scaling", "economy", "tools", "redraw", "cross_link", "face_card", "legendary",
]

const RARITY_ORDER: Array[String] = ["common", "uncommon", "rare", "legendary"]

const RARITY_NAMES: Dictionary = {
	"common": "普通",
	"uncommon": "高级",
	"rare": "稀有",
	"legendary": "传说",
}

var _all_ninjas: Array[Dictionary] = []
var _selected: Array[Dictionary] = []
var _toggle_btns: Array[Button] = []
var _current_sort: SortMode = SortMode.CATEGORY

@onready var _grid: GridContainer = %NinjaGrid
@onready var _confirm_btn: Button = %ConfirmBtn
@onready var _cancel_btn: Button = %CancelBtn
@onready var _title_label: Label = %SelectorTitle
@onready var _category_btn: Button = %CategoryBtn
@onready var _rarity_btn: Button = %RarityBtn
@onready var _all_btn: Button = %AllBtn


func _ready() -> void:
	_confirm_btn.pressed.connect(_on_confirm)
	_cancel_btn.pressed.connect(_on_cancel)
	_category_btn.toggled.connect(_on_sort_toggled.bind(SortMode.CATEGORY))
	_rarity_btn.toggled.connect(_on_sort_toggled.bind(SortMode.RARITY))
	_all_btn.toggled.connect(_on_sort_toggled.bind(SortMode.NONE))


func open(ninja_pool: Array[Dictionary], pre_selected: Array[Dictionary]) -> void:
	_all_ninjas = ninja_pool
	_selected = pre_selected.duplicate()
	_current_sort = SortMode.CATEGORY
	_sync_sort_buttons()
	visible = true
	_build_grid.call_deferred()


func hide_selector() -> void:
	visible = false


func _get_sorted_ninjas() -> Array[Dictionary]:
	match _current_sort:
		SortMode.CATEGORY:
			var result: Array[Dictionary] = []
			for cat: String in CATEGORY_ORDER:
				for ninja: Dictionary in _all_ninjas:
					if ninja.get("category", "") == cat:
						result.append(ninja)
			for ninja: Dictionary in _all_ninjas:
				if not CATEGORY_ORDER.has(ninja.get("category", "")):
					result.append(ninja)
			return result
		SortMode.RARITY:
			var result: Array[Dictionary] = []
			for rar: String in RARITY_ORDER:
				for ninja: Dictionary in _all_ninjas:
					if ninja.get("rarity", "") == rar:
						result.append(ninja)
			return result
		_:
			return _all_ninjas


func _on_sort_toggled(toggled_on: bool, mode: SortMode) -> void:
	if not toggled_on:
		if _current_sort == mode:
			_active_sort_button().set_pressed_no_signal(true)
		return

	_current_sort = mode
	_sync_sort_buttons()
	_update_sort_button_styles()
	_build_grid()


func _active_sort_button() -> Button:
	match _current_sort:
		SortMode.CATEGORY:
			return _category_btn
		SortMode.RARITY:
			return _rarity_btn
		_:
			return _all_btn


func _sync_sort_buttons() -> void:
	_category_btn.set_pressed_no_signal(_current_sort == SortMode.CATEGORY)
	_rarity_btn.set_pressed_no_signal(_current_sort == SortMode.RARITY)
	_all_btn.set_pressed_no_signal(_current_sort == SortMode.NONE)


func _update_sort_button_styles() -> void:
	for btn: Button in [_category_btn, _rarity_btn, _all_btn]:
		if btn.button_pressed:
			btn.add_theme_color_override("font_color", Color(0.94, 0.75, 0.25, 1.0))
		else:
			btn.remove_theme_color_override("font_color")


func _calc_columns() -> int:
	return TARGET_COLS


func _grid_group_key(ninja: Dictionary) -> String:
	match _current_sort:
		SortMode.CATEGORY:
			return ninja.get("category", "")
		SortMode.RARITY:
			return ninja.get("rarity", "common")
		_:
			return ""


func _build_grid() -> void:
	for child: Node in _grid.get_children():
		child.queue_free()
	_toggle_btns.clear()

	_grid.columns = _calc_columns()
	_title_label.text = "选择忍者 (%d/%d)" % [mini(_selected.size(), MAX_SELECT), MAX_SELECT]

	var sorted: Array[Dictionary] = _get_sorted_ninjas()
	var last_group: String = ""
	var cells_filled: int = 0

	for ninja: Dictionary in sorted:
		var group_key: String = _grid_group_key(ninja)

		# Group switch → pad previous row + add header label at column 0 of fresh row
		if group_key != last_group:
			if last_group != "":
				cells_filled = _pad_grid_row(cells_filled)
			cells_filled = _add_group_header(group_key, cells_filled)
			last_group = group_key

		# Continuation row within same group → spacer at col 0 aligns with first row
		if last_group != "" and cells_filled % _grid.columns == 0:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(_card_width, 36)
			_grid.add_child(spacer)
			cells_filled += 1

		var nid: String = ninja.get("id", "")
		var name_str: String = ninja.get("name", "?")
		var rarity: String = ninja.get("rarity", "common")
		var desc: String = ninja.get("desc", "")

		var btn := Button.new()
		btn.text = name_str
		btn.custom_minimum_size = Vector2(_card_width, 36)
		btn.size = Vector2(_card_width, 36)
		btn.toggle_mode = true
		btn.add_theme_font_size_override("font_size", 14)

		match rarity:
			"rare":
				btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
			"legendary":
				btn.add_theme_color_override("font_color", Color(0.85, 0.45, 0.9))
			"uncommon":
				btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
			_:
				btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

		var already_selected: bool = false
		for sel: Dictionary in _selected:
			if sel.get("id", "") == nid:
				already_selected = true
				break
		btn.button_pressed = already_selected

		btn.toggled.connect(_on_toggle.bind(nid, btn))
		btn.gui_input.connect(_on_ninja_gui_input.bind(nid, name_str, rarity, desc))
		_grid.add_child(btn)
		_toggle_btns.append(btn)
		cells_filled += 1


func _pad_grid_row(cells: int) -> int:
	var rem: int = cells % _grid.columns
	if rem == 0:
		return cells
	var nc: int = cells
	for _i: int in range(_grid.columns - rem):
		var filler := Control.new()
		filler.custom_minimum_size = Vector2(_card_width, 36)
		_grid.add_child(filler)
		nc += 1
	return nc


func _add_group_header(key: String, cells: int) -> int:
	var text: String = ""
	match _current_sort:
		SortMode.CATEGORY:
			text = CATEGORY_NAMES.get(key, key)
		SortMode.RARITY:
			text = RARITY_NAMES.get(key, key)

	if text.is_empty():
		return cells

	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(_card_width, 36)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.94, 0.75, 0.25, 1.0))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_grid.add_child(label)
	return cells + 1


func _on_toggle(toggled_on: bool, nid: String, btn: Button) -> void:
	if toggled_on:
		for ninja: Dictionary in _all_ninjas:
			if ninja.get("id", "") == nid:
				if _selected.size() >= MAX_SELECT:
					btn.button_pressed = false
					return
				_selected.append(ninja)
				break
	else:
		for i: int in range(_selected.size()):
			if _selected[i].get("id", "") == nid:
				_selected.remove_at(i)
				break

	_title_label.text = "选择忍者 (%d/%d)" % [mini(_selected.size(), MAX_SELECT), MAX_SELECT]


func _on_ninja_gui_input(event: InputEvent, nid: String, name_str: String, rarity: String, desc: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		return

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	var tex: Texture2D = null
	var card_path: String = AssetRegistry.get_ninja_card_path(nid)
	if ResourceLoader.exists(card_path):
		tex = load(card_path)

	CardDetailPopup.open({
		viewport = viewport,
		texture = tex,
		name = name_str,
		desc = desc,
		rarity = rarity,
	})


func _on_confirm() -> void:
	ninjas_selected.emit(_selected)
	visible = false


func _on_cancel() -> void:
	cancelled.emit()
	visible = false
