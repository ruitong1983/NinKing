class_name CardDetailPopup
extends Control
## Unified Balatro-style zoom-in card detail popup.
##
## Shows a large framed card with rarity border + cropped art,
## rarity-based flash shader material (foil/holo/polychrome),
## and staggered entrance / dismiss animations.
##
## Scene structure defined in card_detail_popup.tscn.
## Card visual is built via CardVisualComposer.build_card_face_with_flash().
##
## Entrance animation varies by rarity:
##   Common/Uncommon → compact (~0.35s)
##   Rare           → medium (~0.45s), punch_in + flash pulse
##   Legendary       → full (~0.55s), punch_in + screen_shake + particles + flash pulse
##
## Usage:
##   var popup = CardDetailPopup.open({
##       viewport = get_viewport(),
##       texture = card_texture,
##       name = "风魔小太郎",
##       desc = "效果描述/触发条件",
##       rarity = "rare",
##       extra_desc = "Lv.3",
##       effect = {"add_chips": 15, "add_mult": 2},
##   })

const CARD_SIZE: Vector2 = Vector2(320, 448)
const SB = preload("res://scripts/config/sound_bank.gd")

# Balatro-style effect colors
const COLOR_CHIPS_BLUE: Color = Color("#1E6BFF")
const COLOR_MULT_RED: Color = Color("#E53935")

var _is_dismissing: bool = false

# Cached node refs (set in _build, not @onready)
var _overlay: ColorRect
var _name_label: Label
var _effect_container: Control
var _effect_rows: Array[Control] = []
var _desc_label: Label
var _extra_label: Label = null

# Card panel + flash material (for dismiss cleanup)
var _card_panel: Panel
var _flash_mat: ShaderMaterial


static func open(config: Dictionary) -> CardDetailPopup:
	var popup: CardDetailPopup = preload("res://scenes/ninking/card_detail_popup.tscn").instantiate()
	popup._build(config)
	return popup


func _build(config: Dictionary) -> void:
	# Cache scene node refs (available immediately after instantiate)
	_overlay = %DetailOverlay
	_name_label = %NameLabel
	_effect_container = %EffectContainer
	_desc_label = %DescLabel
	_effect_rows.clear()
	_extra_label = null

	var viewport: Viewport = config.get("viewport")
	if viewport == null:
		push_error("CardDetailPopup: viewport is required")
		queue_free()
		return

	var tex: Texture2D = config.get("texture")
	var card_name: String = config.get("name", "???")
	var desc: String = config.get("desc", "")
	var rarity: String = config.get("rarity", "common")
	var extra_desc: String = config.get("extra_desc", "")
	var effect: Dictionary = config.get("effect", {})

	var viewport_size: Vector2 = viewport.get_visible_rect().size

	# Setup self
	size = viewport_size
	z_index = 1200
	name = "CardDetailPopup"
	viewport.get_tree().current_scene.add_child(self)

	# ── Position overlay ──
	_overlay.size = viewport_size
	_overlay.gui_input.connect(_on_overlay_clicked)
	_overlay.modulate.a = 0.0  # hidden until entrance

	# ── Card face via CardVisualComposer.build_card_face_with_flash ──
	var card_pos: Vector2 = viewport_size / 2 - CARD_SIZE / 2
	card_pos.y -= 60  # Shift up for text below

	var result: Dictionary = CardVisualComposer.build_card_face_with_flash(
			self, CARD_SIZE, tex, rarity)
	_card_panel = result["panel"]
	_card_panel.name = "DetailCardPanel"
	_card_panel.position = card_pos
	_flash_mat = result["flash_mat"]

	# ── Parse effect → Balatro-style rows ──
	var effect_rows: Array[Dictionary] = _parse_effect_rows(effect)

	# ── Name label (32px, rarity-colored if non-common) ──
	_name_label.text = card_name
	_name_label.add_theme_font_size_override("font_size", 32)
	if rarity != "common" and AssetRegistry.RARITY_NAME_COLORS.has(rarity):
		_name_label.add_theme_color_override("font_color", AssetRegistry.RARITY_NAME_COLORS[rarity])
	_name_label.position = Vector2(
		viewport_size.x / 2 - 200,
		card_pos.y + CARD_SIZE.y + 12
	)
	_name_label.size = Vector2(400, 40)
	_name_label.modulate.a = 0.0  # hidden until entrance

	# ── Effect rows (Balatro-style: chips blue / mult red / xmult red) ──
	var after_effect_y: float = _name_label.position.y + 46
	if not effect_rows.is_empty():
		var row_y: float = after_effect_y
		for row: Dictionary in effect_rows:
			_build_effect_row(row, viewport_size.x, row_y)
			row_y += 36  # 32px row height + 4px gap
		after_effect_y = row_y + 4
		# Hide effect rows until entrance
		for er: Control in _effect_rows:
			er.modulate.a = 0.0

	# ── Description (only show if: no effect rows, OR effect has condition text) ──
	if desc != "":
		var has_condition: bool = (not effect_rows.is_empty()
				and effect.has("condition"))
		var show_desc: bool = effect_rows.is_empty() or has_condition

		if show_desc:
			_desc_label.text = desc
			if effect_rows.is_empty():
				_desc_label.add_theme_font_size_override("font_size", 22)
			else:
				_desc_label.add_theme_font_size_override("font_size", 18)
			_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			_desc_label.position = Vector2(
				viewport_size.x / 2 - 200,
				after_effect_y
			)
			_desc_label.size = Vector2(400, 26)
			_desc_label.modulate.a = 0.0  # hidden until entrance

			if extra_desc != "":
				_extra_label = Label.new()
				_extra_label.text = extra_desc
				_extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				_extra_label.add_theme_font_size_override("font_size", 18)
				_extra_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				_extra_label.position = Vector2(
					viewport_size.x / 2 - 200,
					_desc_label.position.y + 28
				)
				_extra_label.size = Vector2(400, 26)
				_extra_label.modulate.a = 0.0  # hidden until entrance
				add_child(_extra_label)

	elif extra_desc != "":
		# No desc but extra_desc exists (e.g. item level info)
		_extra_label = Label.new()
		_extra_label.text = extra_desc
		_extra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_extra_label.add_theme_font_size_override("font_size", 22)
		_extra_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		_extra_label.position = Vector2(
			viewport_size.x / 2 - 200,
			after_effect_y
		)
		_extra_label.size = Vector2(400, 30)
		_extra_label.modulate.a = 0.0  # hidden until entrance
		add_child(_extra_label)

	# ── SFX ──
	GlobalTweens.play_sfx(SB.SELECT)

	# ── Entrance animation ──
	_animate_entrance(rarity)


# ══════════════════════════════════════════
# Entrance animation
# ══════════════════════════════════════════

func _animate_entrance(rarity: String) -> void:
	## Staggered entrance sequence based on rarity.

	# ── Step 0: Overlay fade ──
	GlobalTweens.fade_in(_overlay, 0.08)

	# ── Step 1: Card entrance + flash pulse ──
	match rarity:
		"legendary":
			GlobalTweens.punch_in(_card_panel, 0.35, 1.3)
			GlobalTweens.screen_shake(0.12, 0.06)
			if _flash_mat:
				GlobalTweens.shader_pulse(_card_panel, _flash_mat, "intensity", 0.1, 0.38, 0.8)
				# Delayed particle burst
				var pt_tw := get_tree().create_tween()
				pt_tw.tween_interval(0.25)
				pt_tw.tween_callback(func():
					GlobalTweens.burst_particles(
						_card_panel.global_position + _card_panel.size * 0.5, "sparkle")
				)
		"rare":
			GlobalTweens.punch_in(_card_panel, 0.3, 1.25)
			if _flash_mat:
				GlobalTweens.shader_pulse(_card_panel, _flash_mat, "intensity", 0.2, 0.55, 0.6)
		_:
			# common / uncommon: compact pop-in
			GlobalTweens.pop_in(_card_panel, 0.25)
			if _flash_mat and rarity == "uncommon":
				GlobalTweens.shader_pulse(_card_panel, _flash_mat, "intensity", 0.18, 0.42, 1.2)

	# ── Step 2: Text stagger ──
	var name_delay: float = 0.22 if rarity == "legendary" else 0.18 if rarity == "rare" else 0.15
	var stagger_gap: float = 0.08 if rarity == "legendary" else 0.06

	# Name label: fade_in + slight slide down
	var name_tw := get_tree().create_tween()
	name_tw.tween_interval(name_delay)
	name_tw.set_parallel(true)
	name_tw.tween_property(_name_label, "modulate:a", 1.0, 0.12)
	name_tw.tween_property(_name_label, "position:y", _name_label.position.y - 6, 0.12)

	# Effect rows: stagger slide up + fade
	if not _effect_rows.is_empty():
		var row_delay: float = name_delay + 0.08
		for i: int in _effect_rows.size():
			var er: Control = _effect_rows[i]
			var orig_y: float = er.position.y
			er.position.y += 10  # start offset down
			var row_tw := get_tree().create_tween()
			row_tw.tween_interval(row_delay + i * stagger_gap)
			row_tw.set_parallel(true)
			row_tw.tween_property(er, "modulate:a", 1.0, 0.15)
			row_tw.tween_property(er, "position:y", orig_y, 0.15)

	# Description (if visible)
	var desc_delay: float = name_delay + 0.12
	if _desc_label.modulate.a < 1.0 and _desc_label.text != "":
		var orig_y: float = _desc_label.position.y
		_desc_label.position.y += 8
		var desc_tw := get_tree().create_tween()
		desc_tw.tween_interval(desc_delay)
		desc_tw.set_parallel(true)
		desc_tw.tween_property(_desc_label, "modulate:a", 1.0, 0.1)
		desc_tw.tween_property(_desc_label, "position:y", orig_y, 0.1)

	# Extra label (if visible)
	if _extra_label and _extra_label.modulate.a < 1.0:
		var orig_y: float = _extra_label.position.y
		_extra_label.position.y += 8
		var ext_tw := get_tree().create_tween()
		ext_tw.tween_interval(desc_delay)
		ext_tw.set_parallel(true)
		ext_tw.tween_property(_extra_label, "modulate:a", 1.0, 0.1)
		ext_tw.tween_property(_extra_label, "position:y", orig_y, 0.1)


# ══════════════════════════════════════════
# Dismiss
# ══════════════════════════════════════════

func _stop_flash() -> void:
	## Smoothly fade flash intensity to 0 before dismiss.
	if not _flash_mat or not is_instance_valid(_flash_mat):
		return
	var tw: Tween = get_tree().create_tween()
	tw.set_parallel(false)
	tw.tween_property(_flash_mat, "shader_parameter/intensity", 0.0, 0.06)


func dismiss() -> void:
	if _is_dismissing:
		return
	_is_dismissing = true

	# Stop flash pulse
	_stop_flash()

	# Card scale down + fade out (parallel)
	if is_instance_valid(_card_panel):
		var card_tw := _card_panel.create_tween().set_parallel(true)
		card_tw.tween_property(_card_panel, "scale", Vector2(0.9, 0.9), 0.1)
		card_tw.tween_property(_card_panel, "modulate:a", 0.0, 0.1)

	# Overlay fade out (slight delay so card begins shrinking first)
	if is_instance_valid(_overlay):
		var ov_tw := _overlay.create_tween()
		ov_tw.tween_interval(0.06)
		ov_tw.tween_property(_overlay, "modulate:a", 0.0, 0.08)

	# Queue free after brief delay
	var free_tw := get_tree().create_tween()
	free_tw.tween_interval(0.14)
	free_tw.tween_callback(queue_free)


# ══════════════════════════════════════════
# Effect rows
# ══════════════════════════════════════════

## Parse effect dict into Balatro-style rows.
## Skips zero values (add_chips/add_mult = 0 is scaling cards with
## runtime growth) and x_mult  1 (no meaningful multiplier).
static func _parse_effect_rows(effect: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var chips: int = effect.get("add_chips", 0)
	var mult: int = effect.get("add_mult", 0)
	var xmult: float = effect.get("x_mult", 0.0)

	if chips > 0:
		rows.append({"type": "chips", "value": chips, "unit": "筹码"})
	if mult > 0:
		rows.append({"type": "mult", "value": mult, "unit": "倍率"})
	if xmult > 1.0:
		rows.append({"type": "xmult", "value": xmult})
	return rows


## Build one Balatro-style effect row (colored number + gray unit on one line).
## Chips: +30 筹码 (blue bold #1E6BFF, gray unit)
## Mult:  +10 倍率 (red bold #E53935, gray unit)
## xMult: ×N         (red bold #E53935)
func _build_effect_row(row: Dictionary, screen_w: float, y: float) -> void:
	var rtl: RichTextLabel = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.scroll_active = false
	rtl.size = Vector2(300, 32)
	rtl.position = Vector2(screen_w / 2 - 150, y)
	rtl.add_theme_font_size_override("normal_font_size", 24)
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF

	match row.type:
		"chips":
			rtl.text = ("[center][color=#1E6BFF][b]+%d[/b][/color]"
					+ " [color=#B3B3B3]%s[/color][/center]") % [row.value, row.unit]
		"mult":
			rtl.text = ("[center][color=#E53935][b]+%d[/b][/color]"
					+ " [color=#B3B3B3]%s[/color][/center]") % [row.value, row.unit]
		"xmult":
			rtl.text = "[center][color=#E53935][b]×%s[/b][/color][/center]" % row.value

	_effect_container.add_child(rtl)
	_effect_rows.append(rtl)


# ══════════════════════════════════════════
# Input handling
# ══════════════════════════════════════════

func _on_overlay_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		dismiss()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed \
			and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
