class_name ShopPanel
extends Control
## Shop UI panel — bottom-stage layout.
##
## Full 1500px manga-panel stage, barrier-colored background (matching left panel),
## 4 ability cards (grid) + 2 item cards (2-column centered grid).
## Color scheme references the left panel: dark barrier-toned bg, cream text, accent details.
##
## Usage:
##   var panel = preload("res://scenes/ninking/shop_panel.tscn").instantiate()
##   panel.init(shop_mgr, gold, barrier_colors)
##   panel.purchase_requested.connect(...)
##   shop_overlay.add_child(panel)

const SLOT_SCENE: String = "res://scenes/ninking/shop_slot.tscn"
const COLOR_INK: Color = Color(0.102, 0.102, 0.102)
const COLOR_CREAM: Color = Color(0.941, 0.929, 0.894)   # Left panel primary text
const COLOR_GOLD: Color = Color(0.941, 0.816, 0.376)     # Left panel gold accent
const COLOR_GRAY_OLIVE: Color = Color(0.478, 0.478, 0.416)  # Left panel secondary

# ═══ Signals (for game_manager to wire) ═══
signal purchase_requested(ability_data: Dictionary)
signal item_purchase_requested(item_data: Dictionary)
signal reroll_requested()
signal continue_requested()

# ═══ @onready references ═══
@onready var stage_bg: ColorRect = $StageBg
@onready var screentone: TextureRect = $StageBg/ScreentoneOverlay
@onready var gold_label: Label = %GoldLabel
@onready var reroll_button: Button = %RerollBtn
@onready var shop_title: Label = %ShopSubtitle
@onready var ability_grid: GridContainer = %AbilityGrid
@onready var item_column: GridContainer = %ItemColumn
@onready var continue_button: Button = %ContinueBtn

# ═══ State ═══
var slot_scene: PackedScene = null
var ability_cards: Array = []
var item_cards: Array = []
var barrier_colors: Dictionary = {}
var _entrance_active: bool = false
var _initialized: bool = false
var _current_gold: int = 0
var _reroll_cost: int = 3

var shop_manager: ShopManager = null


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

func init(shop_mgr: ShopManager, gold: int, colors: Dictionary) -> void:
	if _initialized:
		return
	_initialized = true

	slot_scene = load(SLOT_SCENE)

	shop_manager = shop_mgr
	barrier_colors = colors

	_apply_barrier_theme()
	_refresh_shop()
	_update_gold_display(gold)

	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)


func update_gold(gold: int) -> void:
	_current_gold = gold
	gold_label.text = str(gold)
	_update_reroll_state()


func refresh_stock() -> void:
	_render_abilities()
	_render_items()


# ══════════════════════════════════════════
# Entrance animation — panel opens
# ══════════════════════════════════════════

func play_entrance_animation() -> void:
	if _entrance_active:
		return
	_entrance_active = true

	var all_cards: Array[Control] = []
	all_cards.append_array(ability_cards)
	all_cards.append_array(item_cards)

	var whoosh_sfx = preload("res://scripts/config/sound_bank.gd").SHOP_ENTER
	var impact_sfx = preload("res://scripts/config/sound_bank.gd").BOSS_REVEAL

	await NinKingTween.play_shop_entrance_manga({
		top_border = $TopBorder,
		stage_bg = stage_bg,
		title_bar = $TitleBar,
		panel = self,
		all_cards = all_cards,
		whoosh_sfx = whoosh_sfx,
		impact_sfx = impact_sfx,
	})

	_entrance_active = false


# ══════════════════════════════════════════
# Theme — left-panel-inspired barrier coloring
# ══════════════════════════════════════════

func _apply_barrier_theme() -> void:
	var c: Dictionary = barrier_colors

	# StageBg: barrier panel color (like left panel PanelBg), darkened for depth
	stage_bg.color = Color(c.panel).darkened(0.06)

	# Screentone: very subtle ~5% for texture reference
	screentone.modulate = Color(0, 0, 0, 0.05)

	# Edge-fade: ink-bleed fade on right side (matching left panel style)
	var fade_shader: Shader = preload("res://scripts/ninking/ui/panel_edge_fade.gdshader")
	var fade_mat := ShaderMaterial.new()
	fade_mat.shader = fade_shader
	fade_mat.set_shader_parameter("fade_start", 0.82)
	stage_bg.material = fade_mat

	# TitleBar / BottomBar: deep barrier panel (like left panel sub-panels)
	%TitleBar.color = Color(c.panel).darkened(0.35)
	%BottomBar.color = Color(c.panel).darkened(0.35)

	# Separator: thin accent line
	$Separator.color = Color(c.accent, 0.3)

	# Shop title: accent color (decorative heading, like left panel MatchTitle gold)
	shop_title.add_theme_color_override("font_color", c.accent)
	shop_title.add_theme_font_size_override("font_size", 32)

	# Gold label: warm gold like left panel's GoldLabel
	gold_label.add_theme_color_override("font_color", COLOR_GOLD)

	# Buttons: dark bg + accent border/text (left panel style, not impact style)
	_apply_dark_button_style(continue_button, c.accent, c.panel, "continue")
	_apply_dark_button_style(reroll_button, c.accent, c.panel, "reroll")


func _apply_dark_button_style(btn: Button, accent: Color, panel_color: Color, label: String) -> void:
	## Dark button with accent border + cream text — matching left panel button style.
	var bg_dark: Color = Color(panel_color).darkened(0.50)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_dark
	normal.border_color = accent
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 12
	normal.content_margin_top = 6
	normal.content_margin_right = 12
	normal.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_color_override("font_color", COLOR_CREAM)
	btn.add_theme_font_size_override("font_size", 16)

	var hovered := normal.duplicate() as StyleBoxFlat
	hovered.bg_color = Color(bg_dark).lightened(0.12)
	hovered.border_color = Color(accent).lightened(0.15)
	hovered.border_width_left = 3
	hovered.border_width_right = 3
	hovered.border_width_top = 3
	hovered.border_width_bottom = 3
	btn.add_theme_stylebox_override("hover", hovered)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(bg_dark).darkened(0.15)
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 4
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_pressed_color", Color(COLOR_CREAM).darkened(0.2))


# ══════════════════════════════════════════
# Shop rendering
# ══════════════════════════════════════════

func _refresh_shop() -> void:
	_render_abilities()
	_render_items()


func _render_abilities() -> void:
	_clear_ability_grid()
	for data: Dictionary in shop_manager.get_ninjas_for_display():
		var slot: ShopSlot = slot_scene.instantiate()
		ability_grid.add_child(slot)
		slot.setup(data)
		slot.apply_barrier_theme(barrier_colors)
		slot.purchase_requested.connect(_on_ability_purchase)
		ability_cards.append(slot)


func _render_items() -> void:
	_clear_item_column()
	for data: Dictionary in shop_manager.get_star_charts_for_display():
		var slot: ShopSlot = slot_scene.instantiate()
		item_column.add_child(slot)
		slot.setup(data)
		slot.apply_barrier_theme(barrier_colors)
		slot.purchase_requested.connect(_on_item_purchase)
		item_cards.append(slot)


func _clear_ability_grid() -> void:
	for card in ability_cards:
		if is_instance_valid(card):
			card.queue_free()
	ability_cards.clear()


func _clear_item_column() -> void:
	for card in item_cards:
		if is_instance_valid(card):
			card.queue_free()
	item_cards.clear()


# ══════════════════════════════════════════
# Display helpers
# ══════════════════════════════════════════

func _update_gold_display(gold: int) -> void:
	_current_gold = gold
	gold_label.text = str(gold)
	_update_reroll_state()


func _update_reroll_state() -> void:
	reroll_button.disabled = _current_gold < _reroll_cost


func update_reroll_cost(cost: int) -> void:
	_reroll_cost = cost
	reroll_button.text = "入替 $%d" % _reroll_cost
	_update_reroll_state()


# ══════════════════════════════════════════
# Purchase handlers (emit signals)
# ══════════════════════════════════════════

func _on_ability_purchase(ability: Dictionary) -> void:
	purchase_requested.emit(ability)


func _on_item_purchase(item: Dictionary) -> void:
	item_purchase_requested.emit(item)


func _on_reroll_pressed() -> void:
	reroll_requested.emit()


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	continue_requested.emit()


func get_all_cards() -> Array[Node]:
	var result: Array[Node] = []
	result.append_array(ability_cards)
	result.append_array(item_cards)
	return result


func mark_item_purchased(item_id: String) -> void:
	for card in item_cards:
		if is_instance_valid(card) and card.get_card_id() == item_id:
			card.set_purchased()
			return
