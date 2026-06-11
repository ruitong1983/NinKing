extends Panel
## Balatro-style ability (joker) card displayed in the shop.

@onready var art_rect: ColorRect = $ArtArea
@onready var art_icon: ColorRect = $ArtArea/ArtIcon
@onready var art_name_label: Label = $ArtArea/ArtNameLabel
@onready var rarity_badge: Panel = $RarityBadge
@onready var name_label: Label = $NameLabel
@onready var effect_label: Label = $EffectLabel
@onready var condition_label: Label = $ConditionLabel
@onready var price_badge: Panel = $PriceBadge
@onready var price_label: Label = $PriceBadge/PriceLabel
@onready var buy_button: Button = $BuyButton

var ability_data: Dictionary = {}
var is_purchased: bool = false
var _card_style: StyleBoxFlat = null

signal purchase_requested(ability: Dictionary)
signal card_pressed(card: Panel)

const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A 漫画墨色

# ═══ Rarity visual configuration ═══
const RARITY_CONFIG: Dictionary = {
	"common": {
		"border_width": 2,
		"border_color": Color(0.102, 0.102, 0.102),  # COLOR_INK
		"shadow_size": 4,
		"shadow_color": Color(0, 0, 0, 0.12),
		"badge_visible": false,
	},
	"uncommon": {
		"border_width": 2,
		"border_color": null,  # null = follow BarrierTheme accent
		"shadow_size": 6,
		"shadow_color": Color(0, 0, 0, 0.15),
		"badge_visible": false,
	},
	"rare": {
		"border_width": 3,
		"border_color": Color(0.878, 0.251, 0.251),  # #E04040
		"shadow_size": 12,
		"shadow_color": Color(0.878, 0.251, 0.251, 0.2),
		"badge_visible": true,
		"badge_bg": Color(0.878, 0.251, 0.251),
		"badge_border": Color(0.6, 0.1, 0.1),
		"badge_text": "稀有",
	},
	"legendary": {
		"border_width": 3,
		"border_color": Color(1.0, 0.843, 0.0),  # #FFD700
		"shadow_size": 16,
		"shadow_color": Color(1.0, 0.843, 0.0, 0.25),
		"badge_visible": true,
		"badge_bg": Color(1.0, 0.843, 0.0),
		"badge_border": Color(0.8, 0.6, 0.0),
		"badge_text": "伝説",
	},
}


func _cache_nodes() -> void:
	## Ensure @onready vars are initialized — setup() may be called before enter_tree.
	if not name_label:
		art_rect = $ArtArea
		art_icon = $ArtArea/ArtIcon
		art_name_label = $ArtArea/ArtNameLabel
		rarity_badge = $RarityBadge
		name_label = $NameLabel
		effect_label = $EffectLabel
		condition_label = $ConditionLabel
		price_badge = $PriceBadge
		price_label = $PriceBadge/PriceLabel
		buy_button = $BuyButton


func setup(data: Dictionary) -> void:
	_cache_nodes()
	ability_data = data

	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color(0.1, 0.1, 0.18, 0.92)  # 默认暗底，apply_barrier_theme() 覆盖
	_card_style.corner_radius_top_left = 8
	_card_style.corner_radius_top_right = 8
	_card_style.corner_radius_bottom_left = 8
	_card_style.corner_radius_bottom_right = 8

	# ── Rarity-based card frame styling ──
	var r: String = data.get("rarity", "common")
	var rarity_cfg: Dictionary = RARITY_CONFIG.get(r, RARITY_CONFIG["common"])
	_card_style.border_width_left = rarity_cfg.border_width
	_card_style.border_width_right = rarity_cfg.border_width
	_card_style.border_width_top = rarity_cfg.border_width
	_card_style.border_width_bottom = rarity_cfg.border_width
	_card_style.shadow_size = rarity_cfg.shadow_size
	_card_style.shadow_color = rarity_cfg.shadow_color
	if rarity_cfg.border_color != null:
		_card_style.border_color = rarity_cfg.border_color
	else:
		_card_style.border_color = COLOR_INK

	_setup_rarity_badge(r)

	add_theme_stylebox_override("panel", _card_style)

	name_label.text = data.get("name", "???")
	art_name_label.text = data.get("name", "???")
	effect_label.text = data.get("effect_desc", "")

	var cond: String = data.get("condition_desc", "")
	if cond.is_empty():
		condition_label.text = "无条件触发"
	else:
		condition_label.text = cond + "触发"

	price_label.text = str(data.get("cost", 0))

	buy_button.pressed.connect(_on_buy_pressed)
	gui_input.connect(_on_gui_input)


func apply_barrier_theme(colors: Dictionary) -> void:
	## Apply barrier-specific manga colors to the card.
	## colors = {bg, panel, accent, name, particle_color}
	_cache_nodes()
	if not _card_style:
		return

	# Card base = panel color + rarity-aware border
	_card_style.bg_color = colors.panel
	var r: String = ability_data.get("rarity", "common")
	match r:
		"rare", "legendary":
			pass  # Preserve rarity border set in setup()
		"uncommon":
			_card_style.border_color = colors.accent
		_:
			_card_style.border_color = COLOR_INK

	# Art area = panel darkened 15%
	art_rect.color = Color(colors.panel).darkened(0.15)
	# Art name label = accent color at low opacity
	art_name_label.add_theme_color_override("font_color", Color(colors.accent, 0.35))
	art_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	# Name plate = panel darkened 5%
	$NamePlate.color = Color(colors.panel).darkened(0.05)
	# Price badge = panel color + ink border
	var price_style := price_badge.get_theme_stylebox("panel") as StyleBoxFlat
	if not price_style:
		price_style = StyleBoxFlat.new()
	price_style.bg_color = colors.panel
	price_style.border_color = COLOR_INK
	price_style.border_width_left = 2
	price_style.border_width_right = 2
	price_style.border_width_top = 2
	price_style.border_width_bottom = 2
	price_style.corner_radius_top_left = 6
	price_style.corner_radius_top_right = 6
	price_style.corner_radius_bottom_left = 6
	price_style.corner_radius_bottom_right = 6
	price_badge.add_theme_stylebox_override("panel", price_style)

	# Buy button = accent color + ink border (light-impact style)
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = colors.accent
	btn_normal.border_color = COLOR_INK
	btn_normal.border_width_left = 3
	btn_normal.border_width_right = 3
	btn_normal.border_width_top = 3
	btn_normal.border_width_bottom = 3
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_bottom = 8
	buy_button.add_theme_stylebox_override("normal", btn_normal)
	buy_button.add_theme_color_override("font_color", Color.WHITE)

	# Hover: lighter accent + thicker border
	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(colors.accent).lightened(0.1)
	btn_hover.border_width_left = 4
	btn_hover.border_width_right = 4
	btn_hover.border_width_top = 4
	btn_hover.border_width_bottom = 4
	buy_button.add_theme_stylebox_override("hover", btn_hover)

	# Pressed: darker accent + content shift down
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(colors.accent).darkened(0.15)
	btn_pressed.content_margin_top = 10
	btn_pressed.content_margin_bottom = 6
	buy_button.add_theme_stylebox_override("pressed", btn_pressed)

func _setup_rarity_badge(rarity: String) -> void:
	## Configure the RarityBadge based on card rarity tier.
	var cfg: Dictionary = RARITY_CONFIG.get(rarity, RARITY_CONFIG["common"])
	if not cfg.get("badge_visible", false):
		rarity_badge.visible = false
		return

	rarity_badge.visible = true
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = cfg.badge_bg
	badge_style.border_color = cfg.badge_border
	badge_style.border_width_left = 1
	badge_style.border_width_right = 1
	badge_style.border_width_top = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 4
	badge_style.corner_radius_top_right = 4
	badge_style.corner_radius_bottom_left = 4
	badge_style.corner_radius_bottom_right = 4
	rarity_badge.add_theme_stylebox_override("panel", badge_style)

	var label: Label = rarity_badge.get_node_or_null("RarityLabel")
	if label:
		label.text = cfg.get("badge_text", "稀有")
		var text_color: Color = Color(0.95, 0.95, 0.9)
		if rarity == "legendary":
			text_color = Color(0.1, 0.1, 0.1)
		label.add_theme_color_override("font_color", text_color)


func set_purchased() -> void:
	is_purchased = true
	buy_button.disabled = true
	buy_button.text = "入手済"
	modulate = Color(0.5, 0.5, 0.5, 1.0)


func set_unavailable(reason: String) -> void:
	buy_button.disabled = true
	buy_button.text = reason


func _on_buy_pressed() -> void:
	if not is_purchased:
		purchase_requested.emit(ability_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit(self)
