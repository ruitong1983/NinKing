class_name NinjaInventoryCard
extends Card
## Ninja card for the NinjaBar inventory.
##
## Extends card-framework's Card → DraggableObject, reusing the full
## IDLE→HOVERING→HOLDING→MOVING state machine for drag-to-reorder.
## Renders ninja illustration + rarity border + name label.
## Right-click emits detail_requested for the CardDetailPopup.

signal detail_requested(ninja_data: Dictionary)

var ninja_data: Dictionary = {}
var slot_index: int = -1

var _name_label: Label = null
var _rarity_style: StyleBoxFlat = null

const NAME_FONT_SIZE: int = 12
const COLOR_INK: Color = Color(0.102, 0.102, 0.102)


func _init() -> void:
	_ensure_face_nodes()
	card_size = Vector2(125, 175)
	hover_scale = 1.15
	hover_distance = 6


func _ready() -> void:
	super._ready()
	back_face_texture.visible = false
	show_front = true

	_create_name_label()
	gui_input.connect(_on_right_click)


func _ensure_face_nodes() -> void:
	if not has_node("FrontFace"):
		var ff := Control.new()
		ff.name = "FrontFace"
		ff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ff)

		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ff.add_child(tex_rect)

	if not has_node("BackFace"):
		var bf := Control.new()
		bf.name = "BackFace"
		bf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bf)

		var tex_rect := TextureRect.new()
		tex_rect.name = "TextureRect"
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bf.add_child(tex_rect)


func setup(ninja_name: String, data: Dictionary) -> void:
	ninja_data = data
	card_name = ninja_name

	_apply_rarity_border(data.get("rarity", "common"))
	_update_name_label(ninja_name)

	var ninja_id: String = data.get("id", "")
	if ninja_id != "":
		var card_path: String = AssetRegistry.get_ninja_card_path(ninja_id)
		if ResourceLoader.exists(card_path):
			var tex: Texture2D = load(card_path)
			if tex:
				set_faces(tex, null)


func _apply_rarity_border(rarity: String) -> void:
	var width: int = 2
	var border_color: Color = COLOR_INK
	var shadow_size: int = 4
	var shadow_color: Color = Color(0, 0, 0, 0.12)

	match rarity:
		"uncommon":
			border_color = Color(0.831, 0.659, 0.263)
			shadow_size = 6
		"rare":
			width = 3
			border_color = Color(0.878, 0.251, 0.251)
			shadow_size = 10
		"legendary":
			width = 3
			border_color = Color(1.0, 0.843, 0.0)
			shadow_size = 14

	if shadow_size > 4:
		shadow_color = Color(border_color, 0.18 if rarity == "legendary" else 0.25)

	_rarity_style = StyleBoxFlat.new()
	_rarity_style.bg_color = Color(0.1, 0.1, 0.18, 0.92)
	_rarity_style.set_corner_radius_all(6)
	_rarity_style.border_width_left = width
	_rarity_style.border_width_right = width
	_rarity_style.border_width_top = width
	_rarity_style.border_width_bottom = width
	_rarity_style.border_color = border_color
	_rarity_style.shadow_size = shadow_size
	_rarity_style.shadow_color = shadow_color
	add_theme_stylebox_override("panel", _rarity_style)


func _create_name_label() -> void:
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.position = Vector2(0, card_size.y + 2)
	_name_label.size = Vector2(card_size.x, 20)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	add_child(_name_label)


func _update_name_label(text: String) -> void:
	if _name_label:
		_name_label.text = text


func _on_right_click(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
		if current_state != DraggableObject.DraggableState.HOLDING:
			detail_requested.emit(ninja_data)
