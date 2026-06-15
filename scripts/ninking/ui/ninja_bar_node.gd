class_name NinjaBarNode
extends Node
## Manages the ninja bar — slot lifecycle, animations, detail popup.
##
## Phase 2: Diff-based refresh with stagger pop-in / fade-out / spacing compression.
## Phase 3: Drag-to-reorder delegated to card-framework (NinjaBarContainer).
## Phase 4: Balatro-style zoom-in detail popup.
##
## Lives as a plain Node child of the %NinjaBar Control, invisible to layout.

var _container: NinjaBarContainer
var _current_ninjas: Array[Dictionary] = []
var _detail_popup: CardDetailPopup = null

const SB = preload("res://scripts/config/sound_bank.gd")


const NINJA_CARD_SCENE = preload("res://scenes/ninking/ninja_card.tscn")


func set_container(container: NinjaBarContainer) -> void:
	_container = container
	_container.reorder_requested.connect(_on_reorder_requested)


func _unhandled_input(event: InputEvent) -> void:
	## ESC dismisses the detail popup.
	if _detail_popup != null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


# ════════════════════════════════════════════════════════════════
#  Diff-based refresh()
# ════════════════════════════════════════════════════════════════

func refresh(owned_ninjas: Array, _max_slots: int, use_dissolve: bool = false) -> void:
	## Diff-based update: animate out removed ninjas, animate in new ones,
	## keep existing cards in place. Container handles spacing automatically.
	## use_dissolve: use ceremonial dissolve_out instead of quick fade+shrink.
	if _detail_popup != null:
		_detail_popup.dismiss()
		_detail_popup = null

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
	## Animate card out — quick fade+shrink (default) or ceremonial dissolve.
	if not is_instance_valid(card):
		return
	_container.remove_card(card)

	if use_dissolve:
		card.dissolve_out()
	else:
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
	card.detail_requested.connect(_on_detail_requested)
	_container.add_card(card, index)
	# Card is now positioned via _update_target_positions; update slot indices
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
	## Cards are already in the correct visual positions; just persist to GameState.
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
#  Detail popup
# ════════════════════════════════════════════════════════════════

func _on_detail_requested(ninja_data: Dictionary) -> void:
	## Show CardDetailPopup with ninja card info.
	if _detail_popup != null:
		return

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	var tex: Texture2D = null
	var card_path: String = AssetRegistry.get_ninja_card_path(ninja_data.get("id", ""))
	if ResourceLoader.exists(card_path):
		tex = load(card_path)
	if tex == null:
		var icon_path: String = AssetRegistry.get_icon_path(
			ninja_data.get("id", ""),
			ninja_data.get("effect", {})
		)
		if ResourceLoader.exists(icon_path):
			tex = load(icon_path)

	_detail_popup = CardDetailPopup.open({
		viewport = viewport,
		texture = tex,
		name = ninja_data.get("name", "???"),
		desc = ninja_data.get("desc", ""),
		rarity = ninja_data.get("rarity", "common"),
		extra_desc = "",
		effect = ninja_data.get("effect", {}),
	})
	_detail_popup.tree_exited.connect(func():
		_detail_popup = null
	)


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
