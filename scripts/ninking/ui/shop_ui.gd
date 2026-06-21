class_name ShopPanel
extends Control
## Shop UI panel — ink-wash (水墨) bottom-stage layout.
##
## Paper-textured 740px panel, calligraphy title/buttons,
## 4 ability cards (grid) + 2 item cards (2-column centered grid).
##
## Usage:
##   var panel = preload("res://scenes/ninking/shop_panel.tscn").instantiate()
##   panel.init(shop_mgr, gold, barrier_colors)
##   panel.purchase_requested.connect(...)
##   shop_overlay.add_child(panel)

const SLOT_SCENE: String = "res://scenes/ninking/shop_slot.tscn"

# ═══ Ink-wash palette (independent of BarrierTheme) ═══
const COLOR_PAPER      := Color(0.961, 0.941, 0.910)  # 和纸白 #F5F0E8
const COLOR_PAPER_DARK := Color(0.910, 0.878, 0.835)  # 纸色暗 #E8E0D0
const COLOR_SUMI       := Color(0.169, 0.118, 0.063)  # 焦墨 #2B1E10
const COLOR_PALE_INK   := Color(0.420, 0.420, 0.412)  # 淡墨 #6B6B6B
const COLOR_CINNABAR   := Color(0.722, 0.227, 0.165)  # 朱砂 #B83A2A
const COLOR_BLUE_ZAN   := Color(0.180, 0.361, 0.541)  # 蓝锖 #2E5C8A
const COLOR_GOLD_MUD   := Color(0.769, 0.639, 0.353)  # 金泥 #C4A35A

# ═══ Signals (for game_manager to wire) ═══
signal purchase_requested(ability_data: Dictionary)
signal item_purchase_requested(item_data: Dictionary)
signal reroll_requested()
signal continue_requested()

# ═══ @onready references ═══
@onready var stage_bg: ColorRect = $StageBg
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

	_apply_ink_wash_theme()
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
		top_border = get_node_or_null("TopBorder"),
		stage_bg = stage_bg,
		title_bar = $TitleBar,
		panel = self,
		all_cards = all_cards,
		whoosh_sfx = whoosh_sfx,
		impact_sfx = impact_sfx,
	})

	_entrance_active = false


# ══════════════════════════════════════════
# Theme — ink-wash (水墨) styling
# ══════════════════════════════════════════

func _apply_ink_wash_theme() -> void:
	# ── Stage: washi paper ──
	stage_bg.color = COLOR_PAPER
	# Remove edge-fade shader (paper doesn't fade to ink)
	GlobalShaders.clear_edge_fade(stage_bg)

	# ── TitleBar: darkened paper background + sumi ink text ──
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = COLOR_PAPER_DARK
	%TitleBar.add_theme_stylebox_override("normal", title_style)
	%TitleBar.add_theme_color_override("font_color", COLOR_SUMI)
	%TitleBar.add_theme_font_size_override("font_size", 40)

	# ── Separator: pale ink ──
	$Separator.color = Color(COLOR_PALE_INK, 0.4)

	# ── Shop title: sumi ink ──
	shop_title.add_theme_color_override("font_color", COLOR_SUMI)
	shop_title.add_theme_font_size_override("font_size", 36)

	# ── Gold label: sumi ink ──
	gold_label.add_theme_color_override("font_color", COLOR_SUMI)

	# ── Buttons: seal (印章) style ──
	_apply_seal_button_style(continue_button, COLOR_GOLD_MUD, "continue")
	_apply_seal_button_style(reroll_button, COLOR_BLUE_ZAN, "reroll")


func _apply_seal_button_style(btn: Button, seal_color: Color, _label: String) -> void:
	## Seal (印章) button: solid mineral-pigment bg + ink border + white calligraphy text.
	var bg := seal_color

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = COLOR_SUMI
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 12
	normal.content_margin_top = 6
	normal.content_margin_right = 12
	normal.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var hovered := normal.duplicate() as StyleBoxFlat
	hovered.bg_color = Color(bg).lightened(0.10)
	hovered.border_width_left = 3
	hovered.border_width_right = 3
	hovered.border_width_top = 3
	hovered.border_width_bottom = 3
	btn.add_theme_stylebox_override("hover", hovered)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(bg).darkened(0.15)
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 4
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.85))


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
		slot.apply_ink_wash_theme()
		slot.purchase_requested.connect(_on_ability_purchase)
		ability_cards.append(slot)


func _render_items() -> void:
	_clear_item_column()
	for data: Dictionary in shop_manager.get_star_charts_for_display():
		var slot: ShopSlot = slot_scene.instantiate()
		item_column.add_child(slot)
		slot.setup(data)
		slot.apply_ink_wash_theme()
		slot.purchase_requested.connect(_on_item_purchase)
		item_cards.append(slot)


func _clear_ability_grid() -> void:
	for card in ability_cards:
		if is_instance_valid(card):
			if card.get_parent() == ability_grid:
				ability_grid.remove_child(card)
			card.queue_free()
	ability_cards.clear()


func _clear_item_column() -> void:
	for card in item_cards:
		if is_instance_valid(card):
			if card.get_parent() == item_column:
				item_column.remove_child(card)
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
	for card in ability_cards:
		if is_instance_valid(card) and card.get_card_id() == item_id:
			card.set_purchased()
			return
	for card in item_cards:
		if is_instance_valid(card) and card.get_card_id() == item_id:
			card.set_purchased()
			return
