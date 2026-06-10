extends Control
## 萬屋 UI — buy ninjas and items between seals.
## Manga hot-blooded style with impact-frame title bars and focus lines.

const ABILITY_CARD_SCENE: String = "res://scenes/ninking/shop_ability_card.tscn"
const ITEM_CARD_SCENE: String = "res://scenes/ninking/shop_item_card.tscn"
const REROLL_COST: int = 5
const COLOR_INK: Color = Color(0.102, 0.102, 0.102)  # #1A1A1A 漫画墨色

@onready var gold_label: Label = %GoldLabel
@onready var reroll_button: Button = %RerollBtn
@onready var reroll_label: Label = %RerollLabel
@onready var ability_row: HBoxContainer = %AbilityRow
@onready var item_row: HBoxContainer = %ItemRow
@onready var continue_button: Button = %ContinueBtn
@onready var next_level_hint: Label = %NextLevelHint
@onready var ninja_slot_label: Label = %NinjaSlotLabel
@onready var panel: Panel = %ShopPanel
@onready var title_focus_lines: TextureRect = %TitleFocusLines
@onready var shop_subtitle: Label = %ShopSubtitle
@onready var ability_focus_lines: TextureRect = %AbilityFocusLines
@onready var item_focus_lines: TextureRect = %ItemFocusLines
@onready var bottom_focus_lines: TextureRect = %BottomFocusLines

var shop: ShopManager = null
var ability_card_scene: PackedScene = null
var item_card_scene: PackedScene = null
var ability_cards: Array = []
var item_cards: Array = []
var barrier_colors: Dictionary = {}
var _entrance_active: bool = false


func _ready() -> void:
	ability_card_scene = load(ABILITY_CARD_SCENE)
	item_card_scene = load(ITEM_CARD_SCENE)

	shop = ShopManager.new()
	barrier_colors = BarrierTheme.get_colors(NinKingGameState.barrier_num)
	_apply_barrier_theme()
	_refresh_shop()

	_update_gold_display()
	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)

	_play_entrance()


func _apply_barrier_theme() -> void:
	## Apply barrier-specific manga colors to the shop chrome.
	var c: Dictionary = barrier_colors
	var darker: Color = Color(c.bg).darkened(0.08)

	# Panel frame
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
	panel.add_theme_stylebox_override("panel", panel_style)

	# Title bar / bottom bar
	$ShopPanel/TitleBar.color = darker
	$ShopPanel/BottomBar.color = darker

	# Title text
	$ShopPanel/ShopTitle.add_theme_color_override("font_color", c.accent)

	# Subtitle stamp
	shop_subtitle.add_theme_color_override("font_color", c.accent)
	shop_subtitle.add_theme_color_override("font_outline_color", COLOR_INK)
	shop_subtitle.add_theme_constant_override("outline_size", 2)

	# Focus lines (white PNG → modulate to accent)
	title_focus_lines.modulate = Color(c.accent, 0.6)
	ability_focus_lines.modulate = Color(c.accent, 0.4)
	item_focus_lines.modulate = Color(c.accent, 0.4)
	bottom_focus_lines.modulate = Color(c.accent, 0.6)

	# Separator
	$ShopPanel/Separator.color = Color(c.accent, 0.25)

	# Impact buttons — override bg_color to current accent
	_apply_impact_button_style(continue_button, c.accent)
	_apply_impact_button_style(reroll_button, c.accent)

	# Ninja slot label
	ninja_slot_label.add_theme_color_override("font_color", c.accent)

	# Section labels
	$ShopPanel/AbilityLabel.add_theme_color_override("font_color", c.accent)
	$ShopPanel/ItemLabel.add_theme_color_override("font_color", c.accent)


func _apply_impact_button_style(btn: Button, accent: Color) -> void:
	## Create impact-button styleboxes for a button with the given accent color.
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = accent
	s_normal.border_color = COLOR_INK
	s_normal.border_width_left = 3
	s_normal.border_width_right = 3
	s_normal.border_width_top = 3
	s_normal.border_width_bottom = 3
	s_normal.corner_radius_top_left = 8
	s_normal.corner_radius_top_right = 8
	s_normal.corner_radius_bottom_left = 8
	s_normal.corner_radius_bottom_right = 8
	s_normal.content_margin_left = 20
	s_normal.content_margin_top = 10
	s_normal.content_margin_right = 20
	s_normal.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var s_hover := s_normal.duplicate() as StyleBoxFlat
	s_hover.bg_color = Color(accent).lightened(0.1)
	s_hover.border_width_left = 4
	s_hover.border_width_right = 4
	s_hover.border_width_top = 4
	s_hover.border_width_bottom = 4
	btn.add_theme_stylebox_override("hover", s_hover)

	var s_pressed := s_normal.duplicate() as StyleBoxFlat
	s_pressed.bg_color = Color(accent).darkened(0.15)
	s_pressed.content_margin_top = 12
	s_pressed.content_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", s_pressed)

	var s_disabled := s_normal.duplicate() as StyleBoxFlat
	s_disabled.bg_color = Color(0.8, 0.8, 0.8, 1)
	s_disabled.border_color = Color(0.6, 0.6, 0.6, 1)
	s_disabled.border_width_left = 2
	s_disabled.border_width_right = 2
	s_disabled.border_width_top = 2
	s_disabled.border_width_bottom = 2
	btn.add_theme_stylebox_override("disabled", s_disabled)


func _refresh_shop() -> void:
	shop.generate_stock()
	_render_abilities()
	_render_items()
	_update_reroll_state()


func _render_abilities() -> void:
	_clear_ability_row()
	for data: Dictionary in shop.get_ninjas_for_display():
		var card := ability_card_scene.instantiate()
		ability_row.add_child(card)  # must add to tree first — @onready fires on enter_tree
		card.setup(data)
		card.apply_barrier_theme(barrier_colors)
		card.purchase_requested.connect(_on_ability_purchase)
		ability_cards.append(card)


func _render_items() -> void:
	_clear_item_row()
	var all_items: Array[Dictionary] = []
	all_items.append_array(shop.get_fujutsu_for_display())
	all_items.append_array(shop.get_star_charts_for_display())
	all_items.append_array(shop.get_kinjutsu_for_display())
	for data: Dictionary in all_items:
		var card := item_card_scene.instantiate()
		item_row.add_child(card)  # must add to tree first — @onready fires on enter_tree
		card.setup(data)
		card.apply_barrier_theme(barrier_colors)
		card.purchase_requested.connect(_on_item_purchase)
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
				# Purchase micro-impact
				GlobalTweens.scale_pop(card.buy_button, 1.05, 0.15)
				GlobalTweens.shake_node(card, 3.0, 0.06)
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
				GlobalTweens.scale_pop(card.buy_button, 1.05, 0.15)
				GlobalTweens.shake_node(card, 3.0, 0.06)
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
	## Play manga-style shop entrance sequence. Fire-and-forget.
	if _entrance_active:
		return
	_entrance_active = true

	var all_cards: Array[Control] = []
	all_cards.append_array(ability_cards)
	all_cards.append_array(item_cards)

	# Sound: load directly until SoundBank C16 is done
	var whoosh_sfx: AudioStream = load("res://assets/audio/sound/game/shop_enter.ogg")
	var impact_sfx: AudioStream = load("res://assets/audio/sound/game/boss_reveal.ogg")

	await NinKingTween.play_shop_entrance({
		overlay = $Overlay,
		panel = panel,
		all_cards = all_cards,
		focus_title = title_focus_lines,
		focus_ability = ability_focus_lines,
		focus_item = item_focus_lines,
		focus_bottom = bottom_focus_lines,
		whoosh_sfx = whoosh_sfx,
		impact_sfx = impact_sfx,
	})

	_entrance_active = false
