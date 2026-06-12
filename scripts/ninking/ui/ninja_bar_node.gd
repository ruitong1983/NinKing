extends Node
## Manages the ninja bar — slot lifecycle, animations, drag-to-reorder, detail popup.
##
## Phase 2: Diff-based refresh with stagger pop-in / fade-out / spacing compression.
## Phase 3: Drag-to-reorder, Balatro-style zoom-in detail popup (delegated to CardDetailPopup).
##
## Lives as a plain Node child of the %NinjaBar HBoxContainer, invisible to layout.

var _container: HBoxContainer  # %NinjaBar (parent node)
var _current_ninjas: Array[Dictionary] = []
var _detail_popup: CardDetailPopup = null

const NINJA_SLOT_SCENE: PackedScene = preload("res://scenes/ninking/ninja_slot.tscn")
const SB = preload("res://scripts/config/sound_bank.gd")
const SLOT_WIDTH: float = 130.0
const SPACING_MIN: int = 8
const SPACING_MAX: int = 24


func _ready() -> void:
	_container = get_parent() as HBoxContainer
	assert(_container != null, "NinjaBarNode must be a child of the %NinjaBar HBoxContainer")


func _unhandled_input(event: InputEvent) -> void:
	## ESC dismisses the detail popup (popup handles its own — just guard and pass through).
	if _detail_popup != null:
		return  # Let CardDetailPopup handle ESC
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


# ════════════════════════════════════════════════════════════════
#  Phase 2 — diff-based refresh()
# ════════════════════════════════════════════════════════════════

func refresh(owned_ninjas: Array, _max_slots: int) -> void:
	## Diff-based update: animate out removed ninjas, animate in new ones,
	## keep existing cards in place. Updates spacing automatically.
	if _detail_popup != null:
		_detail_popup.dismiss()
		_detail_popup = null

	var new_ids: Dictionary = {}
	for i: int in range(owned_ninjas.size()):
		new_ids[owned_ninjas[i]["id"]] = true

	# Phase 1: find + animate out removed slots
	var slots_to_remove: Array[NinjaSlotNode] = []
	for child: Node in _container.get_children():
		if child == self or not (child is NinjaSlotNode):
			continue
		var slot: NinjaSlotNode = child as NinjaSlotNode
		var sid: String = slot._ninja_data.get("id", "")
		if sid != "" and not new_ids.has(sid):
			slots_to_remove.append(slot)

	for slot: NinjaSlotNode in slots_to_remove:
		_animate_out(slot)

	# Phase 2: clear remaining old slots
	for child: Node in _container.get_children():
		if child == self or not (child is NinjaSlotNode):
			continue
		var slot: NinjaSlotNode = child as NinjaSlotNode
		var sid: String = slot._ninja_data.get("id", "")
		if sid == "" or not new_ids.has(sid):
			child.queue_free()

	# Phase 3: create new slots with stagger pop-in
	_current_ninjas = owned_ninjas.duplicate(true)
	for i: int in range(owned_ninjas.size()):
		_make_slot(owned_ninjas[i], i)

	_apply_stagger_pop_in()
	_apply_spacing(owned_ninjas.size())


func _animate_out(slot: NinjaSlotNode) -> void:
	## Fade out + shrink, then queue_free.
	if not is_instance_valid(slot):
		return
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(slot, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(slot, "scale", Vector2(0.5, 0.5), 0.2)
	tween.chain()
	tween.tween_callback(func():
		GlobalTweens.play_sfx(SB.SEAL_FAIL)
	)
	tween.tween_callback(slot.queue_free)


func _make_slot(ninja_data: Dictionary, index: int = -1) -> NinjaSlotNode:
	## Instantiate a ninja slot Panel, wire it up, add to container.
	var slot: NinjaSlotNode = NINJA_SLOT_SCENE.instantiate()
	_container.add_child(slot)
	var icon_path: String = AssetRegistry.get_icon_path(
		ninja_data["id"],
		ninja_data.get("effect", {})
	)
	slot.setup(ninja_data["name"], icon_path, ninja_data["id"])

	slot._ninja_data = ninja_data
	slot._index = index if index >= 0 else _container.get_child_count() - 1

	# Start invisible for stagger pop-in
	slot.scale = Vector2(0.1, 0.1)
	slot.modulate = Color(1, 1, 1, 0)

	# Wire signals
	slot.clicked.connect(_on_slot_clicked)
	slot.reorder_requested.connect(_on_reorder_requested)

	return slot


func _apply_stagger_pop_in() -> void:
	## Stagger pop-in for all NinjaSlotNode children.
	var slots: Array[NinjaSlotNode] = []
	for child: Node in _container.get_children():
		if child != self and child is NinjaSlotNode:
			slots.append(child)

	for i: int in range(slots.size()):
		var slot: NinjaSlotNode = slots[i]
		var tween: Tween = create_tween()
		tween.tween_interval(i * 0.08)
		tween.tween_callback(func():
			if is_instance_valid(slot):
				GlobalTweens.pop_in(slot, 0.25)
		)

	# SFX on first card's pop-in
	if slots.size() > 0:
		var _first_slot: NinjaSlotNode = slots[0]
		var sfx_tween: Tween = create_tween()
		sfx_tween.tween_interval(0.05)
		sfx_tween.tween_callback(func():
			GlobalTweens.play_sfx(SB.DEAL)
		)


func _apply_spacing(card_count: int) -> void:
	## Calculate and set separation based on available width.
	if card_count <= 1:
		_container.add_theme_constant_override("separation", 0)
		return

	var container_w: float = _container.size.x
	var total_cards_w: float = card_count * SLOT_WIDTH
	var gaps: float = card_count - 1
	var sep: float = (container_w - total_cards_w) / gaps
	sep = clamp(sep, SPACING_MIN, SPACING_MAX)
	_container.add_theme_constant_override("separation", int(sep))


# ════════════════════════════════════════════════════════════════
#  Phase 3 — drag-to-reorder
# ════════════════════════════════════════════════════════════════

func move_ninja(from_index: int, to_index: int) -> void:
	## Move a ninja from one position to another in the owned list.
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
	var gs = NinKingGameState
	if from_index < 0 or from_index >= gs.owned_ninjas.size():
		return
	if to_index < 0 or to_index >= gs.owned_ninjas.size():
		return
	if from_index == to_index:
		return

	for child: Node in _container.get_children():
		if child is NinjaSlotNode:
			child.notify_drag_ended()

	move_ninja(from_index, to_index)
	# SFX
	GlobalTweens.play_sfx(SB.SWAP)


# ════════════════════════════════════════════════════════════════
#  Phase 3 — Balatro-style zoom-in detail popup
# ════════════════════════════════════════════════════════════════

func _on_slot_clicked(ninja_data: Dictionary) -> void:
	## Show CardDetailPopup with ninja card info.
	if _detail_popup != null:
		return

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	# Load card art (full illustration, fallback to icon)
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
	})
	_detail_popup.tree_exited.connect(func():
		_detail_popup = null
	)


# ════════════════════════════════════════════════════════════════
#  Stubs for atomic add/remove
# ════════════════════════════════════════════════════════════════

func add_ninja(_ninja_data: Dictionary, _index: int = -1) -> void:
	## TODO: stagger pop-in at target index.
	pass


func remove_ninja(_index: int) -> void:
	## TODO: fade-out + shrink + shift remaining.
	pass
