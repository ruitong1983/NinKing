extends Panel
class_name NinjaSlotNode
## Single ninja slot in the NinjaBar.
## Supports hover scale, click-to-zoom-in (detail popup), and drag-to-reorder.

signal clicked(ninja_data: Dictionary)  # Emitted on left-click → triggers zoom-in detail popup
signal drag_started(index: int)         # Emitted when drag begins
signal reorder_requested(from_index: int, to_index: int)  # Emitted when a slot is dropped here

var _ninja_data: Dictionary = {}
var _index: int = -1
var _is_dragging: bool = false
var _is_drag_target: bool = false  # True when this slot is being hovered as a drop target

@onready var card_art: TextureRect = $CardArt
@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func setup(ninja_name: String, icon_path: String = "", ninja_id: String = "") -> void:
	label.text = ninja_name

	var has_card_art: bool = false
	if ninja_id != "":
		var card_path: String = AssetRegistry.get_ninja_card_path(ninja_id)
		if ResourceLoader.exists(card_path):
			card_art.texture = load(card_path)
			has_card_art = true

	# Hide category icon when full card art is present
	icon_rect.visible = not has_card_art and icon_path != "" and ResourceLoader.exists(icon_path)
	if icon_rect.visible:
		icon_rect.texture = load(icon_path)


# ════════════════════════════════════════════════════════════════
#  Hover feedback
# ════════════════════════════════════════════════════════════════

func _on_mouse_entered() -> void:
	if _is_drag_target:
		return  # Highlight managed by drag system
	if not _is_dragging:
		GlobalTweens.card_hover(self, Vector2(1.15, 1.15), -6.0)


func _on_mouse_exited() -> void:
	if _is_drag_target:
		_reset_drag_target_highlight()
	if not _is_dragging:
		GlobalTweens.card_unhover(self, Vector2.ONE, 0.0)


# ════════════════════════════════════════════════════════════════
#  Click → detail popup (Balatro zoom-in)
# ════════════════════════════════════════════════════════════════

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _is_dragging:
			clicked.emit(_ninja_data)


# ════════════════════════════════════════════════════════════════
#  Drag-to-reorder (Godot built-in drag & drop)
# ════════════════════════════════════════════════════════════════

func get_drag_data(_at_position: Vector2) -> Variant:
	## Start dragging this slot. Returns ninja data + index for the drop target.
	if _ninja_data.is_empty():
		return null

	_is_dragging = true
	modulate = Color(1, 1, 1, 0.5)  # Dim source slot
	drag_started.emit(_index)

	# Build a custom drag preview (card art floating under mouse)
	var preview: TextureRect = TextureRect.new()
	preview.texture = card_art.texture if card_art.texture != null else icon_rect.texture
	preview.size = Vector2(130, 170)
	preview.modulate = Color(1, 1, 1, 0.7)
	preview.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"ninja_data": _ninja_data,
		"from_index": _index,
	}


func can_drop_data(_position: Vector2, data: Variant) -> bool:
	## Accept drops from other ninja slots only.
	if data is Dictionary and data.has("from_index"):
		var from_idx: int = data["from_index"]
		var valid: bool = from_idx != _index and from_idx >= 0
		# Show drop target highlight
		if valid and not _is_drag_target:
			_is_drag_target = true
			_show_drop_target_highlight()
		elif not valid and _is_drag_target:
			_reset_drag_target_highlight()
		return valid
	return false


func drop_data(_position: Vector2, data: Variant) -> void:
	## Complete the reorder.
	_is_drag_target = false
	_reset_drag_target_highlight()
	var from_idx: int = data["from_index"]
	if from_idx != _index:
		reorder_requested.emit(from_idx, _index)


# ── Drag visual helpers ──

func _show_drop_target_highlight() -> void:
	## Glow border or slight scale bump to indicate potential drop.
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)


func _reset_drag_target_highlight() -> void:
	_is_drag_target = false
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)


func notify_drag_ended() -> void:
	## Called by NinjaBarNode when drag completes or cancels.
	_is_dragging = false
	modulate = Color.WHITE
	scale = Vector2.ONE
	_is_drag_target = false
