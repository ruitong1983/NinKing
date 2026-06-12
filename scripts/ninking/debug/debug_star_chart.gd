extends RefCounted
## Debug 场景星图等级控制 UI。
## 提取自 debug_controller.gd（原 465 行 → ~400 行）。
## 自包含：持有 container + levels 引用，通过 increment() / rebuild() 管理。

var container: VBoxContainer
var _levels: Dictionary

const STAR_CHART_TYPES: Array[CardData.HandType3] = [
	CardData.HandType3.HIGH_CARD_3,
	CardData.HandType3.ONE_PAIR_3,
	CardData.HandType3.STRAIGHT_3,
	CardData.HandType3.FLUSH_3,
	CardData.HandType3.STRAIGHT_FLUSH_3,
	CardData.HandType3.THREE_OF_KIND_3,
]


func setup(vbox: VBoxContainer, levels: Dictionary) -> void:
	container = vbox
	_levels = levels
	# rebuild() 由 debug_controller._reset_ui() 触发，避免 _ready() 时 double-build


func rebuild() -> void:
	if not is_instance_valid(container):
		return
	for child: Node in container.get_children():
		child.queue_free()

	for ht: CardData.HandType3 in STAR_CHART_TYPES:
		var name_str: String = CardData.get_hand_type3_name(ht)
		var lvl: int = _levels.get(ht, 0)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = "%s  Lv.%d" % [name_str, lvl]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 14)
		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(30, 30)
		var captured_ht: int = ht
		plus_btn.pressed.connect(_on_plus.bind(captured_ht))

		row.add_child(label)
		row.add_child(plus_btn)
		container.add_child(row)


func _on_plus(ht_int: int) -> void:
	var ht: CardData.HandType3 = ht_int as CardData.HandType3
	var current: int = _levels.get(ht, 0)
	_levels[ht] = current + 1
	rebuild()
