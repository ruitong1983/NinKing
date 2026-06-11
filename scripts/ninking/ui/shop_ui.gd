class_name ShopPanel
extends Control
## 萬屋 UI 面板组件 — 同场景版本 (Phase C)
##
## 通过 init(data) 传入数据，通过信号上报用户操作。
## 不直接读取 NinKingGameState，由 game_manager 编排数据流。
##
## Usage:
##   var panel = preload("res://scenes/ninking/shop_panel.tscn").instantiate()
##   panel.init(shop_mgr, NinKingGameState.gold, barrier_colors, NinKingGameState.owned_ninjas.size(), NinKingGameState.max_ninja_slots)
##   panel.purchase_requested.connect(...)
##   shop_overlay.add_child(panel)

const ABILITY_CARD_SCENE: String = "res://scenes/ninking/shop_ability_card.tscn"
const ITEM_CARD_SCENE: String = "res://scenes/ninking/shop_item_card.tscn"
# B4: Reroll cost is dynamic (递进式 $3 + $1/次), set by parent via update_reroll_cost()
var _reroll_cost: int = 3
const COLOR_INK: Color = Color(0.102, 0.102, 0.102)

# ═══ Signals (for game_manager to wire) ═══
signal purchase_requested(ability_data: Dictionary)
signal item_purchase_requested(item_data: Dictionary)
signal enchant_purchase_requested(item_data: Dictionary)  # B5: 附魔卡需要选目标
signal reroll_requested()
signal continue_requested()

# ═══ @onready references ═══
@onready var overlay: ColorRect = $Overlay
@onready var gold_label: Label = %GoldLabel
@onready var reroll_button: Button = %RerollBtn
@onready var reroll_label: Label = %RerollLabel
@onready var ability_row: HBoxContainer = %AbilityRow
@onready var item_row: HBoxContainer = %ItemRow
@onready var continue_button: Button = %ContinueBtn
@onready var ninja_slot_label: Label = %NinjaSlotLabel
@onready var title_focus_lines: ColorRect = %TitleFocusLines
@onready var shop_subtitle: Label = %ShopSubtitle
@onready var ability_focus_lines: ColorRect = %AbilityFocusLines
@onready var item_focus_lines: ColorRect = %ItemFocusLines
@onready var bottom_focus_lines: ColorRect = %BottomFocusLines

# ═══ State ═══
var ability_card_scene: PackedScene = null
var item_card_scene: PackedScene = null
var ability_cards: Array = []
var item_cards: Array = []
var _owned_ninja_count: int = 0
var _max_ninja_slots: int = 5
var barrier_colors: Dictionary = {}
var _entrance_active: bool = false
var _initialized: bool = false
var _current_gold: int = 0  # B4: 当前金币，用于刷新按钮禁用判断

# ShopManager instance (owned by this panel in the simple approach)
var shop_manager: ShopManager = null


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

func init(shop_mgr: ShopManager, gold: int, colors: Dictionary, owned_ninja_count: int = 0, max_ninja_slots: int = 5) -> void:
	## Initialize the shop panel with data.
	## Called once after instantiation, before add_child.
	if _initialized:
		return
	_initialized = true

	ability_card_scene = load(ABILITY_CARD_SCENE)
	item_card_scene = load(ITEM_CARD_SCENE)

	shop_manager = shop_mgr
	barrier_colors = colors
	_owned_ninja_count = owned_ninja_count
	_max_ninja_slots = max_ninja_slots

	_apply_barrier_theme()
	_refresh_shop()
	_update_gold_display(gold)

	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)


func update_gold(gold: int, owned_ninja_count: int = -1) -> void:
	## Update the gold display (called after purchase/reroll by parent).
	## Also update owned ninja count if provided (>= 0).
	_current_gold = gold
	gold_label.text = str(gold)
	if owned_ninja_count >= 0:
		_owned_ninja_count = owned_ninja_count
	_update_ninja_slot_label()
	_update_reroll_state()


func refresh_stock() -> void:
	## Re-render all stock cards (called after reroll by parent).
	_render_abilities()
	_render_items()


# ══════════════════════════════════════════
# Entrance animation
# ══════════════════════════════════════════

func play_entrance_animation() -> void:
	## Play manga-style shop entrance sequence. Fire-and-forget.
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
		focus_title = title_focus_lines,
		focus_ability = ability_focus_lines,
		focus_item = item_focus_lines,
		focus_bottom = bottom_focus_lines,
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
	shop_subtitle.add_theme_color_override("font_color", c.accent)
	shop_subtitle.add_theme_color_override("font_outline_color", COLOR_INK)
	shop_subtitle.add_theme_constant_override("outline_size", 2)

	title_focus_lines.modulate = Color(c.accent, 0.6)
	ability_focus_lines.modulate = Color(c.accent, 0.4)
	item_focus_lines.modulate = Color(c.accent, 0.4)
	bottom_focus_lines.modulate = Color(c.accent, 0.6)

	$Separator.color = Color(c.accent, 0.25)

	BarrierTheme.apply_impact_button_style(continue_button, c.accent)
	BarrierTheme.apply_impact_button_style(reroll_button, c.accent)

	ninja_slot_label.add_theme_color_override("font_color", c.accent)
	%AbilityLabel.add_theme_color_override("font_color", c.accent)
	%ItemLabel.add_theme_color_override("font_color", c.accent)


# (impact button styling moved to BarrierTheme.apply_impact_button_style)


# ══════════════════════════════════════════
# Shop rendering
# ══════════════════════════════════════════

func _refresh_shop() -> void:
	_render_abilities()
	_render_items()


func _render_abilities() -> void:
	_clear_ability_row()
	for data: Dictionary in shop_manager.get_ninjas_for_display():
		var card := ability_card_scene.instantiate()
		ability_row.add_child(card)
		card.setup(data)
		card.apply_barrier_theme(barrier_colors)
		card.purchase_requested.connect(_on_ability_purchase)
		ability_cards.append(card)


func _render_items() -> void:
	_clear_item_row()
	var all_items: Array[Dictionary] = []
	all_items.append_array(shop_manager.get_fujutsu_for_display())
	all_items.append_array(shop_manager.get_star_charts_for_display())
	all_items.append_array(shop_manager.get_kinjutsu_for_display())
	for data: Dictionary in all_items:
		var card := item_card_scene.instantiate()
		item_row.add_child(card)
		card.setup(data)
		card.apply_barrier_theme(barrier_colors)
		card.purchase_requested.connect(_on_item_purchase)
		item_cards.append(card)


func _clear_ability_row() -> void:
	for card in ability_cards:
		if is_instance_valid(card):
			card.queue_free()
	ability_cards.clear()


func _clear_item_row() -> void:
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
	_update_ninja_slot_label()
	_update_reroll_state()


## B4: 基于 _current_gold 和 _reroll_cost 刷新禁用状态
func _update_reroll_state() -> void:
	if _current_gold < _reroll_cost:
		reroll_button.disabled = true
		reroll_label.modulate = Color(0.4, 0.4, 0.4, 1)
	else:
		reroll_button.disabled = false
		reroll_label.modulate = Color(1, 1, 1, 1)


## B4: 由 UIManager 转发 shop_handler 的动态价格更新
func update_reroll_cost(cost: int) -> void:
	_reroll_cost = cost
	_update_reroll_state()


func _update_ninja_slot_label() -> void:
	## Show actual owned ninjas count against max slots.
	## Uses _owned_ninja_count provided by parent via init() / update_gold(),
	## NOT shop_manager stock (which is cards for sale, not owned).
	ninja_slot_label.text = "忍者 %d/%d" % [_owned_ninja_count, _max_ninja_slots]


# ══════════════════════════════════════════
# Purchase handlers (emit signals)
# ══════════════════════════════════════════

func _on_ability_purchase(ability: Dictionary) -> void:
	purchase_requested.emit(ability)


func _on_item_purchase(item: Dictionary) -> void:
	# B5: 附魔卡需要选目标牌，走独立信号让 handler 处理
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
# B5: Enchant targeting
# ══════════════════════════════════════════

## Open a hand-card target selector overlay.
## Called by ShopHandler after gold deduction.
## `on_card_selected` receives (card_index: int).
func start_enchant_targeting(hand: Array, on_card_selected: Callable) -> void:
	var selector := EnchantTargetSelector.new()
	add_child(selector)
	selector.open(hand, on_card_selected)


# ══════════════════════════════════════════
# Helpers for parent
# ══════════════════════════════════════════

func get_all_cards() -> Array[Node]:
	## Return all ability and item card nodes (for exit animation).
	var result: Array = []
	result.append_array(ability_cards)
	result.append_array(item_cards)
	return result


## B6: Mark a specific item card as purchased by ID (greys out + disables buy button).
func mark_item_purchased(item_id: String) -> void:
	for card in item_cards:
		if is_instance_valid(card) and card.item_data.get("id", "") == item_id:
			card.set_purchased()
			return
