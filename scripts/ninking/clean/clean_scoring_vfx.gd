class_name CleanScoringVFX
extends Node

## Clean mode scoring visual effects orchestrator.
##
## Created by CleanChainHandler. Receives UIManager reference via setup().
## Lifecycle: per-wave floaters (birth bezier flight convergence) ->
##            swap-finalized trigger (score jump + ninja flash + combo).
##
## Style: 符術光輝 (base) + 忍風墨染 (high score / high chain).

const SB = preload("res://scripts/config/sound_bank.gd")

const CARD_W: float = 125.0
const CARD_H: float = 175.0
const ROWS: int = 3
const COLS: int = 3
const ROW_0_Y_MIN: float = 34.0

const TYPE_COLORS: Dictionary = {
	2: Color(0.48, 0.48, 0.48),
	3: Color(0.23, 0.44, 0.85),
	4: Color(0.83, 0.66, 0.26),
	5: Color(0.95, 0.30, 0.30),
}

const SCORE_LOW: int = 50
const SCORE_MID: int = 200

var _ui: UIManager
var _grid_global: Vector2
var _grid_size: Vector2


func setup(ui_ref: UIManager) -> void:
	_ui = ui_ref
	if is_instance_valid(_ui.card_grid):
		_grid_global = _ui.card_grid.global_position
		_grid_size = _ui.card_grid.size


func on_wave_scored(wave_data: Dictionary) -> void:
	var matches: Array = wave_data.get("matches", [])
	var chain_level: int = wave_data.get("chain_level", 1)
	for m: Dictionary in matches:
		_spawn_floater(m, chain_level)


func on_swap_finalized(swap_result: Dictionary, old_score: int) -> void:
	var total: int = swap_result.get("swap_score", 0)
	if total <= 0:
		return
	var new_score: int = old_score + total
	var wave_scores: Array = swap_result.get("wave_scores", [])
	var chain_level: int = wave_scores.size()
	if chain_level >= 2:
		_show_combo_badge(chain_level)
	if is_instance_valid(_ui):
		_ui.play_clean_score_jump(old_score, new_score, chain_level)
	if is_instance_valid(_ui.score_panel):
		var panel_center: Vector2 = _ui.score_panel.global_position \
			+ _ui.score_panel.size * 0.5
		GlobalTweens.burst_particles(panel_center, "confetti")
	var contribs: Array = swap_result.get("ninja_contribs", [])
	for nc: Dictionary in contribs:
		_flash_ninja(nc)


func on_ninja_triggered(ninja_contrib: Dictionary) -> void:
	_flash_ninja(ninja_contrib)


func _spawn_floater(match_data: Dictionary, chain_level: int) -> void:
	var hand_type: int = match_data.get("hand_type", 0)
	var score: int = match_data.get("score", 0)
	var score_raw: int = score
	var score_with_chain: int = score_raw * chain_level
	var positions: Array = match_data.get("positions", [])
	if positions.is_empty():
		return
	var is_high: bool = score_raw >= SCORE_MID or hand_type == 5
	var center: Vector2 = _compute_positions_center(positions)

	var label := Label.new()
	label.text = "+%d" % score_with_chain
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if score_raw >= SCORE_MID or is_high:
		label.add_theme_font_size_override("font_size", 34)
		label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.15, 1.0))
	else:
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("font_outline_size", 4)
	label.custom_minimum_size = Vector2(120, 40)
	label.size = Vector2(120, 40)
	label.position = center - label.size * 0.5
	add_child(label)

	label.scale = Vector2(1.3, 1.3)
	label.modulate.a = 0.0
	var tw_birth: Tween = create_tween().set_parallel(true)
	tw_birth.tween_property(label, "scale", Vector2.ONE, 0.10)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_birth.tween_property(label, "modulate:a", 1.0, 0.06)
	await tw_birth.finished
	if not is_instance_valid(label):
		return

	GlobalTweens.burst_particles(center, "sparkle")
	if is_high:
		GlobalTweens.particles.burst_custom(
			center, 8, 0.3, Color(0.1, 0.08, 0.05, 0.5),
			null, 180.0, 30, 80
		)

	var target: Vector2
	if is_instance_valid(_ui) and is_instance_valid(_ui.score_label):
		target = _ui.score_label.global_position + _ui.score_label.size * 0.5
	else:
		target = center + Vector2(-200, -150)

	var start: Vector2 = label.position
	var ctrl_offset: Vector2 = Vector2(randf_range(-30, 30), -20.0)
	if not is_high:
		ctrl_offset.y = randf_range(-40, -15)

	var flight_duration: float = 1.0
	var tw_flight: Tween = create_tween()
	tw_flight.tween_method(func(t: float) -> void:
		if not is_instance_valid(label):
			return
		var p0: Vector2 = start
		var p2: Vector2 = target - label.size * 0.5
		var p1: Vector2 = Vector2(
			(p0.x + p2.x) * 0.5 + ctrl_offset.x,
			(p0.y + p2.y) * 0.5 + ctrl_offset.y
		)
		var bt: float = 1.0 - t
		label.position = bt * bt * p0 + 2.0 * bt * t * p1 + t * t * p2
	, 0.0, 1.0, flight_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	_create_trail_at(label, 0.2, flight_duration)
	_create_trail_at(label, 0.5, flight_duration)

	await tw_flight.finished
	if not is_instance_valid(label):
		return
	var tw_end: Tween = create_tween().set_parallel(true)
	tw_end.tween_property(label, "scale", Vector2(0.3, 0.3), 0.15)\
		.set_ease(Tween.EASE_IN)
	tw_end.tween_property(label, "modulate:a", 0.0, 0.12)
	await tw_end.finished
	if is_instance_valid(label):
		label.queue_free()


func _create_trail_at(label: Label, progress: float, flight_dur: float) -> void:
	var tw_trail: Tween = create_tween()
	tw_trail.tween_callback(func() -> void:
		if not is_instance_valid(label):
			return
		GlobalTweens.burst_particles(
			label.global_position + label.size * 0.5,
			"sparkle"
		)
	).set_delay(0.05 + flight_dur * progress)


func _show_combo_badge(chain_level: int) -> void:
	if not is_inside_tree():
		return
	var badge := Label.new()
	badge.text = "COMBO x%d" % chain_level
	badge.add_theme_font_size_override("font_size", 24)
	badge.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0, 1.0))
	badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	badge.add_theme_constant_override("font_outline_size", 3)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.size = Vector2(160, 36)
	badge.position = get_viewport().get_visible_rect().size * Vector2(0.5, 0.18) \
		- badge.size * 0.5
	add_child(badge)
	badge.modulate = Color(1, 1, 1, 0)
	var tw: Tween = create_tween()
	tw.tween_property(badge, "modulate", Color.WHITE, 0.15)
	tw.tween_interval(0.6)
	tw.tween_property(badge, "modulate:a", 0.0, 0.3)
	if chain_level >= 4:
		var badge_center: Vector2 = badge.global_position + badge.size * 0.5
		GlobalTweens.particles.burst_custom(
			badge_center, 6, 0.4, Color(1.0, 0.5, 0.0, 0.6),
			null, 360.0, 20, 50
		)
	await tw.finished
	if is_instance_valid(badge):
		badge.queue_free()


func _flash_ninja(nc: Dictionary) -> void:
	if not is_instance_valid(_ui):
		return
	var ninja_id: String = nc.get("id", "")
	if ninja_id.is_empty():
		return
	var parts: PackedStringArray = []
	var chips: int = nc.get("chips", 0)
	var mult: int = nc.get("mult", 0)
	var xv: int = nc.get("x_mult", 1)
	if chips > 0:
		parts.append("+%d" % chips)
	if mult > 0:
		parts.append("+%d" % mult)
	if xv > 1:
		parts.append("x%d" % xv)
	var display_text: String = " ".join(parts)
	_find_and_flash_ninja_card(ninja_id, display_text)


func _find_and_flash_ninja_card(ninja_id: String, display_text: String) -> void:
	if not is_instance_valid(_ui):
		return
	var bar: Control = _ui.ninja_bar_wrapper
	if not is_instance_valid(bar):
		return
	for child in bar.get_children():
		if child is Card and child.has_method("play_ninja_flash"):
			var child_data: Variant = null
			if "card_data" in child:
				child_data = child.card_data
			var cd_id: String = child_data.get("id", "") if child_data is Dictionary else ""
			var cd_name: String = child_data.get("name", "") if child_data is Dictionary else ""
			if cd_id == ninja_id or cd_name == ninja_id:
				child.play_ninja_flash()
				if not display_text.is_empty():
					_show_ninja_floater(child, display_text)
				return
	for child in bar.get_children():
		if child is Card and child.has_method("play_ninja_flash"):
			child.play_ninja_flash()


func _show_ninja_floater(card_node: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("font_outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(100, 24)
	label.position = card_node.global_position + Vector2(
		card_node.size.x * 0.5 - 50, -30
	)
	add_child(label)
	label.scale = Vector2(0.8, 0.8)
	label.modulate.a = 0.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(label, "scale", Vector2.ONE, 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 1.0, 0.06)
	tw.tween_property(label, "position:y", label.position.y - 25, 0.6)\
		.set_delay(0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.35)
	await tw.finished
	if is_instance_valid(label):
		label.queue_free()


func _compute_positions_center(positions: Array) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for p in positions:
		if typeof(p) == TYPE_INT:
			sum += _cell_center(p)
			count += 1
	if count == 0:
		return Vector2.ZERO
	return sum / count


func _cell_center(idx: int) -> Vector2:
	var row: int = int(float(idx) / 3.0)
	var col: int = idx % COLS
	var container_w: float = _grid_size.x if _grid_size.x > 0 else 600.0
	var container_h: float = _grid_size.y if _grid_size.y > 0 else 600.0
	var h_excess: float = maxf(container_w - COLS * CARD_W, 0.0)
	var h_margin: float = h_excess / float(COLS + 1)
	var spacing: float = CARD_W + h_margin
	var v_excess: float = maxf(container_h - ROWS * CARD_H, 0.0)
	var v_margin: float = v_excess / float(ROWS + 1)
	var row_h: float = CARD_H + v_margin
	var row_0_y: float = maxf(ROW_0_Y_MIN, v_margin)
	var x: float = _grid_global.x + container_w * 0.5 + (col - 1) * spacing + CARD_W * 0.5
	var y: float = _grid_global.y + row_0_y + row * row_h + CARD_H * 0.5
	return Vector2(x, y)
