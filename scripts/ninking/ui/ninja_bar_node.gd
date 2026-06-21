class_name NinjaBarNode
extends Node
## Manages the ninja bar — slot lifecycle, animations, hover tooltip, sell button.
##
## Phase 2: Diff-based refresh with stagger pop-in / fade-out / spacing compression.
## Phase 3: Drag-to-reorder delegated to card-framework (NinjaBarContainer).
## Phase 5: Hover tooltip (0.3s delay) + right-click sell button.

var _container: NinjaBarContainer
var _current_ninjas: Array[Dictionary] = []

# Single-instance tooltip and sell button (shown/hidden, repositioned as needed)
var _tooltip: NinjaDetailTooltip = null
var _sell_button: NinjaSellButton = null

# Hover state
var _hover_timer: SceneTreeTimer = null
var _hovered_card: NinjaInventoryCard = null

# Sell button state
var _sell_target_card: NinjaInventoryCard = null

const SB = preload("res://scripts/config/sound_bank.gd")
const NINJA_CARD_SCENE = preload("res://scenes/ninking/ninja_card.tscn")
const TOOLTIP_SCENE = preload("res://scenes/ninking/ninja_detail_tooltip.tscn")
const SELL_BUTTON_SCENE = preload("res://scenes/ninking/ninja_sell_button.tscn")

const HOVER_DELAY: float = 0.3


func _ready() -> void:
	_tooltip = TOOLTIP_SCENE.instantiate() as NinjaDetailTooltip
	add_child(_tooltip)

	_sell_button = SELL_BUTTON_SCENE.instantiate() as NinjaSellButton
	_sell_button.sell_confirmed.connect(_on_sell_confirmed)
	add_child(_sell_button)


func set_container(container: NinjaBarContainer) -> void:
	_container = container
	_container.reorder_requested.connect(_on_reorder_requested)


func get_held_cards() -> Array:
	## Returns the currently held NinjaInventoryCard instances.
	if _container == null:
		return []
	return _container._held_cards.duplicate()


func _unhandled_input(event: InputEvent) -> void:
	## Dismiss sell button on left-click in blank area.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _sell_button != null and _sell_button.visible:
			_dismiss_sell_button()


# ════════════════════════════════════════════════════════════════
#  Diff-based refresh()
# ════════════════════════════════════════════════════════════════

func refresh(owned_ninjas: Array, _max_slots: int, use_dissolve: bool = false) -> void:
	## Diff-based update: animate out removed ninjas, animate in new ones,
	## keep existing cards in place. Container handles spacing automatically.
	## use_dissolve: when true, instant removal (no animation).
	_dismiss_sell_button()
	_dismiss_tooltip()

	_current_ninjas = owned_ninjas.duplicate(true)

	var new_ids: Dictionary = {}
	for i: int in range(owned_ninjas.size()):
		new_ids[owned_ninjas[i]["id"]] = true

	# Phase 1: animate out removed cards
	var cards_to_remove: Array[NinjaInventoryCard] = []
	for card: NinjaInventoryCard in _container._held_cards:
		var cid: String = card.ninja_data.get("id", "")
		if cid != "" and not new_ids.has(cid):
			cards_to_remove.append(card)

	for card: NinjaInventoryCard in cards_to_remove:
		_animate_out(card, use_dissolve)

	# Phase 2: collect surviving card ids
	var existing_ids: Dictionary = {}
	for card: NinjaInventoryCard in _container._held_cards:
		var cid: String = card.ninja_data.get("id", "")
		if cid != "":
			existing_ids[cid] = true

	# Phase 3: create cards for new ninjas
	for i: int in range(owned_ninjas.size()):
		if not existing_ids.has(owned_ninjas[i]["id"]):
			_make_slot(owned_ninjas[i], i)

	# Phase 4: update slot_index on surviving cards to match new order
	_sync_slot_indices()

	_apply_stagger_pop_in()


func _animate_out(card: NinjaInventoryCard, use_dissolve: bool = false) -> void:
	## Remove card — instant (use_dissolve) or quick fade+shrink.
	if not is_instance_valid(card):
		return

	if use_dissolve:
		_container.remove_card(card)
		card.queue_free()
	else:
		_container.remove_card(card)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_property(card, "scale", Vector2(0.5, 0.5), 0.2)
		tween.chain()
		tween.tween_callback(func():
			GlobalTweens.play_sfx(SB.SEAL_FAIL)
		)
		tween.tween_callback(card.queue_free)


func _make_slot(ninja_data: Dictionary, index: int = -1) -> NinjaInventoryCard:
	## Create a NinjaInventoryCard and add it to the container.
	var card := NINJA_CARD_SCENE.instantiate() as NinjaInventoryCard
	if index < 0:
		index = _container.get_card_count()
	card.setup(ninja_data["name"], ninja_data)
	card.slot_index = index
	card.scale = Vector2(0.1, 0.1)
	card.pivot_offset = card.card_size / 2.0
	card.modulate = Color(1, 1, 1, 0)
	card.hover_started.connect(_on_hover_started.bind(card))
	card.hover_ended.connect(_on_hover_ended)
	card.sell_requested.connect(_on_sell_requested.bind(card))
	_container.add_card(card, index)
	_sync_slot_indices()
	return card


func _sync_slot_indices() -> void:
	for i: int in range(_container._held_cards.size()):
		var card := _container._held_cards[i] as NinjaInventoryCard
		if card:
			card.slot_index = i


func _apply_stagger_pop_in() -> void:
	## Stagger pop-in (scale + fade) — only for cards not yet fully visible.
	var new_cards: Array[NinjaInventoryCard] = []
	for card: NinjaInventoryCard in _container._held_cards:
		if card.modulate.a < 1.0:
			new_cards.append(card)

	for i: int in range(new_cards.size()):
		var card: NinjaInventoryCard = new_cards[i]
		var tween: Tween = create_tween()
		tween.tween_interval(i * 0.08)
		var c: NinjaInventoryCard = card  # capture
		tween.tween_callback(func():
			if is_instance_valid(c):
				GlobalTweens.pop_in(c, 0.25)
				var ft := c.create_tween()
				ft.tween_property(c, "modulate", Color.WHITE, 0.25)
		)

	if new_cards.size() > 0:
		var sfx_tween: Tween = create_tween()
		sfx_tween.tween_interval(0.05)
		sfx_tween.tween_callback(func():
			GlobalTweens.play_sfx(SB.DEAL)
		)


# ════════════════════════════════════════════════════════════════
#  Hover tooltip
# ════════════════════════════════════════════════════════════════

func _on_hover_started(card: NinjaInventoryCard) -> void:
	## Start 0.3s hover delay before showing tooltip.
	_hovered_card = card
	_hover_timer = get_tree().create_timer(HOVER_DELAY)
	_hover_timer.timeout.connect(_show_tooltip)


func _on_hover_ended() -> void:
	## Cancel pending tooltip and dismiss if visible.
	_hovered_card = null
	_dismiss_tooltip()


func _show_tooltip() -> void:
	## Show tooltip below the hovered card (timer completed, card still hovered).
	if _hovered_card == null or not is_instance_valid(_hovered_card):
		return
	if _tooltip == null:
		return
	_tooltip.show_for(_hovered_card)


func _dismiss_tooltip() -> void:
	## Cancel hover timer and hide tooltip.
	if _hover_timer != null:
		_hover_timer = null
	if _tooltip != null:
		_tooltip.dismiss()


# ════════════════════════════════════════════════════════════════
#  Sell button
# ════════════════════════════════════════════════════════════════

func _on_sell_requested(card: NinjaInventoryCard) -> void:
	## Right-click on card: toggle sell button.
	if _sell_target_card == card and _sell_button != null and _sell_button.visible:
		_dismiss_sell_button()
		return

	# Dismiss old sell button and show new one
	GlobalTweens.play_sfx(SB.UI_CLICK)
	GlobalTweens.scale_pop(card, 1.15, 0.15)
	_sell_target_card = card
	var price: int = max(1, ceili(card.ninja_data.get("cost", 0) * 0.5))
	if _sell_button != null:
		_sell_button.show_for(card, price)


func _on_sell_confirmed(ninja_data: Dictionary) -> void:
	## Sell button pressed: refund gold, remove ninja, refresh.
	if ninja_data.is_empty():
		return
	var gs = NinKingGameState
	var ninja_id: String = ninja_data.get("id", "")
	var sell_index: int = -1
	for i: int in range(gs.owned_ninjas.size()):
		if gs.owned_ninjas[i].get("id", "") == ninja_id:
			sell_index = i
			break
	if sell_index < 0:
		return

	var ninja: Dictionary = gs.owned_ninjas[sell_index]
	var sell_price: int = max(1, ceili(ninja.get("cost", 0) * 0.5))
	gs.gold += sell_price
	gs.owned_ninjas.remove_at(sell_index)
	_dismiss_sell_button()
	refresh(gs.owned_ninjas, gs.max_ninja_slots, true)
	gs.gold_changed.emit(gs.gold)


func _dismiss_sell_button() -> void:
	## Hide sell button and clear target.
	_sell_target_card = null
	if _sell_button != null:
		_sell_button.dismiss()


# ════════════════════════════════════════════════════════════════
#  Reorder (delegated from NinjaBarContainer)
# ════════════════════════════════════════════════════════════════

func move_ninja(from_index: int, to_index: int) -> void:
	## Move a ninja in GameState and refresh visual order.
	var gs = NinKingGameState
	if from_index < 0 or from_index >= gs.owned_ninjas.size():
		return
	if to_index < 0 or to_index >= gs.owned_ninjas.size():
		return
	if from_index == to_index:
		return

	var ninja: Dictionary = gs.owned_ninjas[from_index]
	gs.owned_ninjas.remove_at(from_index)
	gs.owned_ninjas.insert(to_index, ninja)

	refresh(gs.owned_ninjas, gs.max_ninja_slots)
	gs.gold_changed.emit(gs.gold)


func _on_reorder_requested(from_index: int, to_index: int) -> void:
	## Called by NinjaBarContainer.move_cards() after a drag-reorder.
	var gs = NinKingGameState
	if from_index < 0 or from_index >= gs.owned_ninjas.size():
		return
	if to_index < 0 or to_index >= gs.owned_ninjas.size():
		return
	if from_index == to_index:
		return

	var ninja: Dictionary = gs.owned_ninjas[from_index]
	gs.owned_ninjas.remove_at(from_index)
	gs.owned_ninjas.insert(to_index, ninja)

	_current_ninjas = gs.owned_ninjas.duplicate(true)
	_sync_slot_indices()
	GlobalTweens.play_sfx(SB.SWAP)
	gs.gold_changed.emit(gs.gold)


# ════════════════════════════════════════════════════════════════
#  Pulse animation — collective card scale pop (2 rounds)
# ════════════════════════════════════════════════════════════════

func pulse_cards() -> void:
	var cards: Array = get_held_cards()
	for round: int in range(2):
		for card: NinjaInventoryCard in cards:
			if is_instance_valid(card):
				GlobalTweens.scale_pop(card, 1.08, 0.15)
		if round == 0:
			await get_tree().create_timer(0.15).timeout


# ════════════════════════════════════════════════════════════════
#  Stubs for atomic add/remove
# ════════════════════════════════════════════════════════════════

func add_ninja(_ninja_data: Dictionary, _index: int = -1) -> void:
	pass


## Remove ninja at index with dissolve effect, updating GameState.
func remove_ninja(index: int) -> void:
	var gs = NinKingGameState
	if index < 0 or index >= gs.owned_ninjas.size():
		return
	gs.owned_ninjas.remove_at(index)
	refresh(gs.owned_ninjas, gs.max_ninja_slots, true)
	gs.gold_changed.emit(gs.gold)
