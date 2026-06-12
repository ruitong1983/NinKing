extends Control
## Debug 忍者選択弹窗 — 弹出 Grid 列表显示全部忍者，多选 0-5 个。
## 选中后 emit ninjas_selected(selected: Array[Dictionary])。

signal ninjas_selected(selected_ninjas: Array[Dictionary])
signal cancelled()

const COLS: int = 5
const MAX_SELECT: int = 5

var _all_ninjas: Array[Dictionary] = []
var _selected: Array[Dictionary] = []
var _toggle_btns: Array[Button] = []

@onready var _grid: GridContainer = %NinjaGrid
@onready var _confirm_btn: Button = %ConfirmBtn
@onready var _cancel_btn: Button = %CancelBtn
@onready var _title_label: Label = %SelectorTitle


func _ready() -> void:
	_confirm_btn.pressed.connect(_on_confirm)
	_cancel_btn.pressed.connect(_on_cancel)


func open(ninja_pool: Array[Dictionary], pre_selected: Array[Dictionary]) -> void:
	_all_ninjas = ninja_pool
	_selected = pre_selected.duplicate()
	_build_grid()
	visible = true


func hide_selector() -> void:
	visible = false


func _build_grid() -> void:
	# Clear existing
	for child: Node in _grid.get_children():
		child.queue_free()
	_toggle_btns.clear()

	_grid.columns = COLS
	_title_label.text = "选择忍者 (%d/%d)" % [mini(_selected.size(), MAX_SELECT), MAX_SELECT]

	for ninja: Dictionary in _all_ninjas:
		var nid: String = ninja.get("id", "")
		var name_str: String = ninja.get("name", "?")
		var rarity: String = ninja.get("rarity", "common")
		var desc: String = ninja.get("desc", "")

		var btn := Button.new()
		btn.text = name_str
		btn.tooltip_text = "[%s] %s" % [rarity, desc]
		btn.custom_minimum_size = Vector2(140, 36)
		btn.size = Vector2(140, 36)
		btn.toggle_mode = true
		btn.add_theme_font_size_override("font_size", 14)

		# Color by rarity
		match rarity:
			"rare":
				btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
			"uncommon":
				btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
			_:
				btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

		# Restore pre-selected state
		var already_selected: bool = false
		for sel: Dictionary in _selected:
			if sel.get("id", "") == nid:
				already_selected = true
				break
		btn.button_pressed = already_selected

		btn.toggled.connect(_on_toggle.bind(nid, btn))
		_grid.add_child(btn)
		_toggle_btns.append(btn)


func _on_toggle(toggled_on: bool, nid: String, btn: Button) -> void:
	if toggled_on:
		# Find ninja by id
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


func _on_confirm() -> void:
	ninjas_selected.emit(_selected)
	visible = false


func _on_cancel() -> void:
	cancelled.emit()
	visible = false
