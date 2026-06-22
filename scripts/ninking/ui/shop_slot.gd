class_name ShopSlot
extends VBoxContainer
## Shop card container — Kenney beige (暖纸风) card + button layout.
##
## VBoxContainer: NinjaInventoryCard (125×175) + BuyBtn (125×40), separation=6.
## Supports dynamic button state: ¥N / 満員 / disabled.

# ═══ Signals ═══
signal purchase_requested(data: Dictionary)

# ═══ @onready references ═══
@onready var ninja_card: NinjaInventoryCard = $NinjaCard
@onready var buy_button: Button = $BuyBtn

# ═══ State ═══
var _data: Dictionary = {}
var _is_item: bool = false
var _is_ninja_bar_full: bool = false
var _is_purchased: bool = false


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

func setup(data: Dictionary, is_ninja_bar_full: bool = false) -> void:
	_data = data
	_is_item = data.has("hand_type") or data.get("type") == "item"
	_is_ninja_bar_full = is_ninja_bar_full

	ninja_card.setup_shop(data)
	_load_illustration(data)

	_apply_card_style()
	_apply_purchase_button_style()
	_update_button_state()

	if buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.disconnect(_on_buy_pressed)
	buy_button.pressed.connect(_on_buy_pressed)

	if ninja_card.card_clicked.is_connected(_on_buy_pressed):
		ninja_card.card_clicked.disconnect(_on_buy_pressed)
	ninja_card.card_clicked.connect(_on_buy_pressed)

	_is_purchased = false
	visible = true


func set_purchased() -> void:
	_is_purchased = true
	visible = false


func get_card_id() -> String:
	return _data.get("id", "")


# ══════════════════════════════════════════
# Card style
# ══════════════════════════════════════════

func _apply_card_style() -> void:
	if ninja_card.has_method("apply_barrier_theme"):
		ninja_card.apply_barrier_theme({"panel": Color(0.961, 0.941, 0.910), "accent": Color(0.169, 0.118, 0.063)})

	if not _is_item:
		var r: String = _data.get("rarity", "common")
		ninja_card.set_frame(r)


# ══════════════════════════════════════════
# Purchase button — buttonSquare_brown / grey disabled
# ══════════════════════════════════════════

func _apply_purchase_button_style() -> void:
	var tex_n: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_brown.png")
	var tex_p: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_brown_pressed.png")
	var tex_grey: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_grey.png")

	var s_n := StyleBoxTexture.new()
	s_n.texture = tex_n
	const PM: int = 8
	s_n.set("patch_margin_left", PM); s_n.set("patch_margin_top", PM); s_n.set("patch_margin_right", PM); s_n.set("patch_margin_bottom", PM)
	buy_button.add_theme_stylebox_override("normal", s_n)

	var s_h := StyleBoxTexture.new()
	s_h.texture = tex_n; s_h.modulate_color = Color(1.05, 1.03, 1.0)
	s_h.set("patch_margin_left", PM); s_h.set("patch_margin_top", PM); s_h.set("patch_margin_right", PM); s_h.set("patch_margin_bottom", PM)
	buy_button.add_theme_stylebox_override("hover", s_h)

	var s_p := StyleBoxTexture.new()
	s_p.texture = tex_p
	s_p.set("patch_margin_left", PM); s_p.set("patch_margin_top", PM); s_p.set("patch_margin_right", PM); s_p.set("patch_margin_bottom", PM)
	buy_button.add_theme_stylebox_override("pressed", s_p)

	var s_d := StyleBoxTexture.new()
	s_d.texture = tex_grey
	s_d.set("patch_margin_left", PM); s_d.set("patch_margin_top", PM); s_d.set("patch_margin_right", PM); s_d.set("patch_margin_bottom", PM)
	buy_button.add_theme_stylebox_override("disabled", s_d)

	buy_button.add_theme_color_override("font_color", Color.WHITE)
	buy_button.add_theme_color_override("font_pressed_color", Color(0.95, 0.95, 0.98))
	buy_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	buy_button.add_theme_font_size_override("font_size", 14)


func _update_button_state() -> void:
	var cost: int = _data.get("cost", 0)
	if not _is_item and _is_ninja_bar_full:
		buy_button.text = "満員"
		buy_button.disabled = true
	else:
		buy_button.text = "¥%d" % cost
		buy_button.disabled = false


# ══════════════════════════════════════════
# Illustration loading
# ══════════════════════════════════════════

func _load_illustration(data: Dictionary) -> void:
	var path: String = ""
	var id: String = data.get("id", "")

	if _is_item:
		path = AssetRegistry.get_star_chart_card_path(id)
	else:
		path = AssetRegistry.get_ninja_card_path(id)

	if path.is_empty() or not ResourceLoader.exists(path):
		return

	var tex: Texture2D = _load_texture_safe(path)
	if tex:
		ninja_card.set_content_texture(tex)
		ninja_card.set_detail_data(
			data.get("name", "???"),
			data.get("desc", ""),
			tex,
			data.get("effect", {})
		)


static func _load_texture_safe(path: String) -> Texture2D:
	return load(path) as Texture2D


# ══════════════════════════════════════════
# Purchase
# ══════════════════════════════════════════

func _on_buy_pressed() -> void:
	if not _is_purchased:
		purchase_requested.emit(_data)
