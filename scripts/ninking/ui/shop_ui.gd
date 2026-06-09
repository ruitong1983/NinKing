extends Control
## 萬屋 UI — buy ninjas and items between seals.

const ABILITY_CARD_SCENE: String = "res://scenes/ninking/shop_ability_card.tscn"
const ITEM_CARD_SCENE: String = "res://scenes/ninking/shop_item_card.tscn"
const REROLL_COST: int = 5

@onready var gold_label: Label = %GoldLabel
@onready var reroll_button: Button = %RerollBtn
@onready var reroll_label: Label = %RerollLabel
@onready var ability_row: HBoxContainer = %AbilityRow
@onready var item_row: HBoxContainer = %ItemRow
@onready var continue_button: Button = %ContinueBtn
@onready var next_level_hint: Label = %NextLevelHint
@onready var ninja_slot_label: Label = %NinjaSlotLabel
@onready var panel: Panel = %ShopPanel

var shop: ShopManager = null
var ability_card_scene: PackedScene = null
var item_card_scene: PackedScene = null
var ability_cards: Array = []
var item_cards: Array = []


func _ready() -> void:
	ability_card_scene = load(ABILITY_CARD_SCENE)
	item_card_scene = load(ITEM_CARD_SCENE)

	shop = ShopManager.new()
	_refresh_shop()

	_update_gold_display()
	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)

	_play_entrance()


func _refresh_shop() -> void:
	shop.generate_stock()
	_render_abilities()
	_render_items()
	_update_reroll_state()


func _render_abilities() -> void:
	_clear_ability_row()
	for data: Dictionary in shop.get_ninjas_for_display():
		var card := ability_card_scene.instantiate()
		card.setup(data)
		card.purchase_requested.connect(_on_ability_purchase)
		ability_row.add_child(card)
		ability_cards.append(card)


func _render_items() -> void:
	_clear_item_row()
	var all_items: Array[Dictionary] = []
	all_items.append_array(shop.get_fujutsu_for_display())
	all_items.append_array(shop.get_star_charts_for_display())
	all_items.append_array(shop.get_kinjutsu_for_display())
	for data: Dictionary in all_items:
		var card := item_card_scene.instantiate()
		card.setup(data)
		card.purchase_requested.connect(_on_item_purchase)
		item_row.add_child(card)
		item_cards.append(card)


func _clear_ability_row() -> void:
	for card in ability_cards:
		card.queue_free()
	ability_cards.clear()


func _clear_item_row() -> void:
	for card in item_cards:
		card.queue_free()
	item_cards.clear()


func _update_gold_display() -> void:
	gold_label.text = str(NinKingGameState.gold)
	_update_ninja_slot_label()


func _update_reroll_state() -> void:
	if NinKingGameState.gold < REROLL_COST:
		reroll_button.disabled = true
		reroll_label.modulate = Color(0.4, 0.4, 0.4, 1)
	else:
		reroll_button.disabled = false
		reroll_label.modulate = Color(1, 1, 1, 1)

	var barrier: int = NinKingGameState.barrier_num
	var seal_idx: int = NinKingGameState.seal_idx
	if barrier <= BarrierConfig.get_total_barriers():
		var next_seal: Dictionary = BarrierConfig.get_seal(barrier, seal_idx)
		if not next_seal.is_empty():
			var seal_names: Array = ["修羅ノ封印", "明王ノ封印", "夜叉ノ封印"]
			var seal_str: String = seal_names[seal_idx] if seal_idx < 3 else "封印%d" % (seal_idx + 1)
			next_level_hint.text = "結界%d · %s · 封印 %d" % [barrier, seal_str, next_seal["target"]]


func _update_ninja_slot_label() -> void:
	ninja_slot_label.text = "忍者 %d/%d" % [NinKingGameState.owned_ninjas.size(), NinKingGameState.max_ninja_slots]
	var full: bool = NinKingGameState.owned_ninjas.size() >= NinKingGameState.max_ninja_slots
	ninja_slot_label.modulate = Color(1.0, 0.35, 0.35, 1) if full else Color(0.7, 0.85, 1.0, 1)


func _on_ability_purchase(ability: Dictionary) -> void:
	if NinKingGameState.owned_ninjas.size() >= NinKingGameState.max_ninja_slots:
		ToastManager.show("忍者牌槽位已满 (%d/%d)!" % [NinKingGameState.max_ninja_slots, NinKingGameState.max_ninja_slots], 2.0)
		return

	if ShopManager.buy_ninja(NinKingGameState, ability):
		_update_gold_display()
		_update_reroll_state()
		for card in ability_cards:
			if card.ability_data == ability:
				card.set_purchased()
				break
		ToastManager.show("获得: %s!" % ability.get("name", "???"), 1.5)
	else:
		ToastManager.show("金币不足!", 1.5)


func _on_item_purchase(item: Dictionary) -> void:
	if ShopManager.buy_item(NinKingGameState, item):
		_update_gold_display()
		_update_reroll_state()
		for card in item_cards:
			if card.item_data == item:
				card.set_purchased()
				break
		ToastManager.show("获得: %s!" % item.get("name", "???"), 1.5)
	else:
		ToastManager.show("金币不足!", 1.5)


func _on_reroll_pressed() -> void:
	if NinKingGameState.gold < REROLL_COST:
		return
	NinKingGameState.gold -= REROLL_COST
	NinKingGameState.gold_changed.emit(NinKingGameState.gold)
	_update_gold_display()
	await get_tree().create_timer(0.3).timeout
	_refresh_shop()
	_update_gold_display()


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	await get_tree().create_timer(0.35).timeout
	SealController.continue_from_shop(NinKingGameState)
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_main.tscn")


func _play_entrance() -> void:
	panel.position.y += 200
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "position:y", panel.position.y - 200, 0.5)

	for i: int in range(ability_cards.size() + item_cards.size()):
		var card: Control
		if i < ability_cards.size():
			card = ability_cards[i]
		else:
			card = item_cards[i - ability_cards.size()]
		card.scale = Vector2.ZERO
		var ct: Tween = create_tween()
		ct.tween_interval(0.4 + i * 0.07)
		ct.tween_property(card, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
