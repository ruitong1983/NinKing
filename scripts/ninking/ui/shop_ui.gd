class_name ShopPanel
extends Control
## 萬屋 UI 面板组件 — 左右分栏 (Phase D)
##
## 左 60%: 2x2 忍者牌网格  右 40%: 道具卡竖排 2 张
## 通过 init(data) 传入数据，通过信号上报用户操作。
##
## Usage:
##   var panel = preload("res://scenes/ninking/shop_panel.tscn").instantiate()
##   panel.init(shop_mgr, gold, barrier_colors)
##   panel.purchase_requested.connect(...)
##   shop_overlay.add_child(panel)

const ABILITY_CARD_SCENE: String = "res://scenes/ninking/shop_ability_card.tscn"
const ITEM_CARD_SCENE: String = "res://scenes/ninking/shop_item_card.tscn"
const COLOR_INK: Color = Color(0.102, 0.102, 0.102)

# ═══ Signals (for game_manager to wire) ═══
signal purchase_requested(ability_data: Dictionary)
signal item_purchase_requested(item_data: Dictionary)
signal enchant_purchase_requested(item_data: Dictionary)
signal reroll_requested()
signal continue_requested()

# ═══ @onready references ═══
@onready var overlay: ColorRect = $Overlay
@onready var gold_label: Label = %GoldLabel
@onready var reroll_button: Button = %RerollBtn
@onready var shop_title: Label = %ShopSubtitle
@onready var ability_grid: GridContainer = %AbilityGrid
@onready var item_column: VBoxContainer = %ItemColumn
@onready var continue_button: Button = %ContinueBtn

# ═══ State ═══
var ability_card_scene: PackedScene = null
var item_card_scene: PackedScene = null
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

	ability_card_scene = load(ABILITY_CARD_SCENE)
	item_card_scene = load(ITEM_CARD_SCENE)

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
# Entrance animation
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

	await NinKingTween.play_shop_entrance({
		overlay = overlay,
		panel = self,
		all_cards = all_cards,
		whoosh_sfx = whoosh_sfx,
		impact_sfx = impact_sfx,
	})

	_entrance_active = false


# ══════════════════════════════════════════
# Theme
# ══════════════════════════════════════════

func _apply_barrier_theme() -> void:
	var c: Dictionary = barrier_colors
	var darker: Color = Color(c.bg).darkened(0.08)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = c.panel
	panel_style.border_color = COLOR_INK
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_bottom = 12
	panel_style.shadow_size = 6
	panel_style.shadow_color = Color(0, 0, 0, 0.15)
	self.add_theme_stylebox_override("panel", panel_style)

	%TitleBar.color = darker
	%BottomBar.color = darker

	shop_title.add_theme_color_override("font_color", c.accent)
	shop_title.add_theme_font_size_override("font_size", 56)

	BarrierTheme.apply_impact_button_style(continue_button, c.accent)
	BarrierTheme.apply_impact_button_style(reroll_button, c.accent)

	_update_reroll_button_text()


func _update_reroll_button_text() -> void:
	reroll_button.text = "入替 $%d" % _reroll_cost


# ══════════════════════════════════════════
# Shop rendering
# ══════════════════════════════════════════

func _refresh_shop() -> void:
	_render_abilities()
	_render_items()


func _render_abilities() -> void:
	_clear_ability_grid()
	for data: Dictionary in shop_manager.get_ninjas_for_display():
		var card := ability_card_scene.instantiate()
		ability_grid.add_child(card)
		card.setup(data)
		card.apply_barrier_theme(barrier_colors)
		card.purchase_requested.connect(_on_ability_purchase)
		ability_cards.append(card)


func _render_items() -> void:
	_clear_item_column()
	var all_items: Array[Dictionary] = []
	all_items.append_array(shop_manager.get_fujutsu_for_display())
	all_items.append_array(shop_manager.get_star_charts_for_display())
	all_items.append_array(shop_manager.get_kinjutsu_for_display())
	for data: Dictionary in all_items:
		var card := item_card_scene.instantiate()
		item_column.add_child(card)
		card.setup(data)
		card.apply_barrier_theme(barrier_colors)
		card.purchase_requested.connect(_on_item_purchase)
		item_cards.append(card)


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
	if _current_gold < _reroll_cost:
		reroll_button.disabled = true
	else:
		reroll_button.disabled = false


func update_reroll_cost(cost: int) -> void:
	_reroll_cost = cost
	_update_reroll_button_text()
	_update_reroll_state()


# ══════════════════════════════════════════
# Purchase handlers (emit signals)
# ══════════════════════════════════════════

func _on_ability_purchase(ability: Dictionary) -> void:
	purchase_requested.emit(ability)


func _on_item_purchase(item: Dictionary) -> void:
	var item_id: String = item.get("id", "")
	if item_id.begins_with("enc_"):
		enchant_purchase_requested.emit(item)
		return
	item_purchase_requested.emit(item)


func _on_reroll_pressed() -> void:
	reroll_requested.emit()


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	continue_requested.emit()


# ══════════════════════════════════════════
# Enchant targeting
# ══════════════════════════════════════════

func start_enchant_targeting(hand: Array, on_card_selected: Callable) -> void:
	var selector := EnchantTargetSelector.new()
	add_child(selector)
	selector.open(hand, on_card_selected)


# ══════════════════════════════════════════
# Helpers for parent
# ══════════════════════════════════════════

func get_all_cards() -> Array[Node]:
	var result: Array[Node] = []
	result.append_array(ability_cards)
	result.append_array(item_cards)
	return result


func mark_item_purchased(item_id: String) -> void:
	for card in item_cards:
		if is_instance_valid(card) and card.item_data.get("id", "") == item_id:
			card.set_purchased()
			return
