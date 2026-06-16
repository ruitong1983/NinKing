class_name NinjaReplaceOverlay
extends CanvasLayer
## Full-screen modal overlay for replacing a ninja when slots are full (B14).
##
## Balatro-style: left shows the new card (large preview), right shows 5 owned cards
## as clickable choices. Emits replacement_chosen(result) on confirm or cancel.
##
## Lifecycle: created by ui_manager.show_replace_overlay(), auto-freed after signal.

signal replacement_chosen(result: Dictionary)  # { action: "CONFIRM", index: int } | { action: "CANCEL" }

const NINJA_CARD_SCENE: PackedScene = preload("res://scenes/ninking/ninja_card.tscn")
const SB = preload("res://scripts/config/sound_bank.gd")


func setup(new_ninja: Dictionary, old_ninjas: Array[Dictionary]) -> void:
	## Build the overlay UI programmatically.
	# Leave existing canvas items visible underneath — this overlay sits on top.
	layer = 128

	# ── Full-screen dark BG (click = cancel) ──
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.72)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_bg_clicked)
	add_child(bg)

	# ── Center container (pass-through, so clicks reach bg outside the panel) ──
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(900, 480)
	center.add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	main_vbox.add_theme_constant_override("separation", 16)
	panel.add_child(main_vbox)

	# ── Title ──
	var title := Label.new()
	title.text = "選擇要替換的忍者"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	main_vbox.add_child(title)

	# ── Content row: left (new card) | arrow | right (old cards) ──
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 32)
	content_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# ── Left: new card preview ──
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_hbox.add_child(left_col)

	var new_card := NINJA_CARD_SCENE.instantiate() as NinjaInventoryCard
	new_card.card_size = Vector2(160, 224)
	new_card.custom_minimum_size = Vector2(160, 224)
	new_card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # not clickable
	new_card.setup_shop(new_ninja)
	var card_path: String = AssetRegistry.get_ninja_card_path(new_ninja.get("id", ""))
	if ResourceLoader.exists(card_path):
		new_card.set_content_texture(load(card_path))
	left_col.add_child(new_card)

	var cost_label := Label.new()
	cost_label.text = "花費 $%d" % new_ninja.get("cost", 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 20)
	left_col.add_child(cost_label)

	# ── Arrow ──
	var arrow := Label.new()
	arrow.text = "↓ 替換 ↓"
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 22)
	content_hbox.add_child(arrow)

	# ── Right: old cards row ──
	var old_row := HBoxContainer.new()
	old_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	old_row.add_theme_constant_override("separation", 8)
	content_hbox.add_child(old_row)

	for i: int in range(old_ninjas.size()):
		var nd: Dictionary = old_ninjas[i]
		var refund: int = max(1, ceili(nd.get("cost", 0) * 0.5))

		var slot_vbox := VBoxContainer.new()
		slot_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_vbox.add_theme_constant_override("separation", 4)
		old_row.add_child(slot_vbox)

		# ── Old card (bar-mode for full visual, then override _shop_mode for click) ──
		var card := NINJA_CARD_SCENE.instantiate() as NinjaInventoryCard
		card.card_size = Vector2(120, 168)
		card.custom_minimum_size = Vector2(120, 168)
		card.setup(nd.get("name", "???"), nd)
		card._shop_mode = true  # emit card_clicked instead of drag
		card.card_clicked.connect(_on_old_card_clicked.bind(i))
		slot_vbox.add_child(card)

		# ── Refund label ──
		var rl := Label.new()
		rl.text = "退還 $%d" % refund
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.add_theme_font_size_override("font_size", 13)
		slot_vbox.add_child(rl)

	# ── Bottom: cancel button ──
	var btn_row := HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.pressed.connect(_on_cancel)
	btn_row.add_child(cancel_btn)


func _on_old_card_clicked(_data: Dictionary, index: int) -> void:
	## An owned card was clicked — choose it for replacement.
	GlobalTweens.play_sfx(SB.SELECT)
	replacement_chosen.emit({ "action": "CONFIRM", "index": index })


func _on_cancel() -> void:
	GlobalTweens.play_sfx(SB.UI_ERROR)
	replacement_chosen.emit({ "action": "CANCEL" })


func _on_bg_clicked(event: InputEvent) -> void:
	## Click on the dark background = cancel.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_cancel()
