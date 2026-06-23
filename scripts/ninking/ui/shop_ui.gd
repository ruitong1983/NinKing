class_name ShopPanel
extends Control
## Shop UI panel — Kenney beige (暖纸风) layout.
##
## 1000x650 panel, panel_beige background, panel_brown title bar,
## 4 ninja cards (grid) + 2 item cards (grid),
## buttonLong_brown reroll + buttonLong_beige continue.
##
## Usage:
##   var panel = preload("res://scenes/ninking/shop_panel.tscn").instantiate()
##   panel.init(shop_mgr, gold)
##   panel.purchase_requested.connect(...)
##   shop_overlay.add_child(panel)

const SLOT_SCENE: String = "res://scenes/ninking/shop_slot.tscn"

# ═══ Signals ═══
signal purchase_requested(ability_data: Dictionary)
signal item_purchase_requested(item_data: Dictionary)
signal reroll_requested()
signal continue_requested()

# ═══ @onready references ═══
@onready var stage_bg: NinePatchRect = $StageBg
@onready var gold_label: Label = %GoldLabel
@onready var reroll_button: Button = %RerollBtn
@onready var ability_grid: GridContainer = %AbilityGrid
@onready var item_grid: GridContainer = %ItemGrid
@onready var continue_button: Button = %ContinueBtn

# ═══ State ═══
var slot_scene: PackedScene = null
var ability_cards: Array = []
var item_cards: Array = []
var _entrance_active: bool = false
var _initialized: bool = false
var _current_gold: int = 0
var _reroll_cost: int = 3

## Currently raised card slot (null if none).
var _active_slot: ShopSlot = null

var shop_manager: ShopManager = null


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

func init(shop_mgr: ShopManager, gold: int) -> void:
	if _initialized:
		return
	_initialized = true

	slot_scene = load(SLOT_SCENE)
	shop_manager = shop_mgr

	ButtonStyles.apply_kenney_long(reroll_button, "brown")
	ButtonStyles.apply_kenney_long(continue_button, "beige")
	# 商店按钮统一入场动效（轻度：脉冲 + hover + 点击）
	ButtonStyles.attach_entrance_animation(reroll_button, {"mild": true})
	ButtonStyles.attach_entrance_animation(continue_button, {"mild": true})
	_refresh_shop()
	_update_gold_display(gold)

	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)

	# Blank-area click detection: background elements must be IGNORE
	# so unhandled clicks reach ShopPanel.gui_input
	stage_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TitleBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gui_input.connect(_on_shop_panel_gui_input)


func update_gold(gold: int) -> void:
	_current_gold = gold
	gold_label.text = str(gold)
	_update_reroll_state()


func refresh_stock() -> void:
	_render_abilities()
	_render_items()
	ability_grid.queue_sort()
	item_grid.queue_sort()


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

	var whoosh_sfx: AudioStream = preload("res://scripts/config/sound_bank.gd").SHOP_ENTER
	var impact_sfx: AudioStream = preload("res://scripts/config/sound_bank.gd").BOSS_REVEAL

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
# Shop rendering
# ══════════════════════════════════════════

func _refresh_shop() -> void:
	_render_abilities()
	_render_items()


func _is_ninja_bar_full() -> bool:
	return NinKingGameState.owned_ninjas.size() >= NinKingGameState.max_ninja_slots


func _render_abilities() -> void:
	_clear_ability_grid()
	var bar_full: bool = _is_ninja_bar_full()
	for data: Dictionary in shop_manager.get_ninjas_for_display():
		var slot: ShopSlot = slot_scene.instantiate()
		ability_grid.add_child(slot)
		slot.setup(data, bar_full)
		slot.purchase_requested.connect(_on_ability_purchase)
		slot.card_raised.connect(_on_card_raised)
		ability_cards.append(slot)


func _render_items() -> void:
	_clear_item_grid()
	for data: Dictionary in shop_manager.get_star_charts_for_display():
		var slot: ShopSlot = slot_scene.instantiate()
		item_grid.add_child(slot)
		slot.setup(data, false)
		slot.purchase_requested.connect(_on_item_purchase)
		slot.card_raised.connect(_on_card_raised)
		item_cards.append(slot)


func _clear_ability_grid() -> void:
	_reset_active_slot()
	for card in ability_cards:
		if is_instance_valid(card):
			if card.get_parent() == ability_grid:
				ability_grid.remove_child(card)
			card.queue_free()
	ability_cards.clear()


func _clear_item_grid() -> void:
	_reset_active_slot()
	for card in item_cards:
		if is_instance_valid(card):
			if card.get_parent() == item_grid:
				item_grid.remove_child(card)
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
	reroll_button.text = "入替 ¥%d" % _reroll_cost
	_update_reroll_state()


# ══════════════════════════════════════════
# Purchase handlers
# ══════════════════════════════════════════

func _on_ability_purchase(ability: Dictionary) -> void:
	# Reset active slot after purchase
	_reset_active_slot()
	purchase_requested.emit(ability)


func _on_item_purchase(item: Dictionary) -> void:
	_reset_active_slot()
	item_purchase_requested.emit(item)


# ══════════════════════════════════════════
# Card raise / reset (shop click-to-reveal)
# ══════════════════════════════════════════

func _on_card_raised(slot: ShopSlot) -> void:
	## A card slot has been raised. If another slot was active, snap-reset it first.
	if _active_slot != null and is_instance_valid(_active_slot) and _active_slot != slot:
		_active_slot.reset_immediate()
	_active_slot = slot


func _on_shop_panel_gui_input(event: InputEvent) -> void:
	## Blank-area click -> reset raised card.
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_reset_active_slot()


func _reset_active_slot() -> void:
	if _active_slot != null and is_instance_valid(_active_slot):
		_active_slot.reset_immediate()
	_active_slot = null


func _on_reroll_pressed() -> void:
	_reset_active_slot()
	reroll_requested.emit()


func _on_continue_pressed() -> void:
	_reset_active_slot()
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
