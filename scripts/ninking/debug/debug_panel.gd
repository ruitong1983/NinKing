extends Control
## DebugPanel 折叠/展开控制 — 向上折起、向下展开。
## 默认展开。点击顶端按钮收起为窄条，再次点击展开。

const HEADER_HEIGHT := 44.0

var _collapsed: bool = false
var _content_children: Array[Node] = []

@onready var _toggle_btn: Button = $"ScrollContainer/DebugVBox/ToggleBtn"
@onready var _debug_vbox: VBoxContainer = $"ScrollContainer/DebugVBox"


func _ready() -> void:
	_toggle_btn.pressed.connect(_on_toggle)
	for child in _debug_vbox.get_children():
		if child != _toggle_btn:
			_content_children.append(child)


func _on_toggle() -> void:
	_collapsed = not _collapsed
	_toggle_btn.text = "▼ DEBUG" if _collapsed else "▲"

	for child in _content_children:
		child.visible = not _collapsed

	var parent_h: float = float(get_viewport_rect().size.y)
	var target_bottom: float = -(parent_h - HEADER_HEIGHT) if _collapsed else 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "offset_bottom", target_bottom, 0.25)
