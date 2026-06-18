extends Control
## 计分公式详情面板 — 程序化构建，无 class_name（避免编辑器缓存冲突）。
## 通过 load("res://scripts/ninking/debug/debug_score_detail.gd") 引用。

signal close_requested()

const COL_MULT_MAP: Dictionary = {
	CardData.HandType3.HIGH_CARD_3: 1,
	CardData.HandType3.ONE_PAIR_3: 2,
	CardData.HandType3.STRAIGHT_3: 4,
	CardData.HandType3.FLUSH_3: 8,
	CardData.HandType3.STRAIGHT_FLUSH_3: 16,
	CardData.HandType3.THREE_OF_KIND_3: 32,
}

const GROUP_NAMES: Dictionary = { "head": "影", "mid": "瞬", "tail": "滅" }
const GROUP_ORDER: Array[String] = ["head", "mid", "tail"]

const CLR_NORMAL: String = "#d0d0d0"
const CLR_NINJA: String = "#aa8aff"
const CLR_COL: String = "#6aaa8a"
const CLR_XI: String = "#d4a030"
const CLR_GOLD: String = "#ffd700"
const CLR_GRAY: String = "#8899aa"
const CLR_GREEN: String = "#4caf50"
const CLR_RED: String = "#e55a5a"
const CLR_CHIPS: String = "#5a9af5"
const CLR_MULT: String = "#e55a5a"

var _baseline: ScoreResult
var _ninja_result: ScoreResult
var _head_cards: Array[CardData.PlayingCard] = []
var _mid_cards: Array[CardData.PlayingCard] = []
var _tail_cards: Array[CardData.PlayingCard] = []
var _col_evals: Array = []
var _xi_result = null
var _star_chart_levels: Dictionary = {}
var _ninjas: Array[Dictionary] = []

@onready var _detail_vbox: VBoxContainer = %DetailVBox
@onready var _close_btn: Button = %CloseBtn
@onready var _ninja_summary: Label = %NinjaSummary


func _ready() -> void:
	_close_btn.pressed.connect(_on_close)
	visible = false


func show_detail(
	baseline: ScoreResult,
	ninja_result: ScoreResult,
	head_cards: Array,
	mid_cards: Array,
	tail_cards: Array,
	col_evals: Array,
	xi_result,
	star_chart_levels: Dictionary,
	ninjas: Array[Dictionary]
) -> void:
	_baseline = baseline
	_ninja_result = ninja_result
	_head_cards = head_cards
	_mid_cards = mid_cards
	_tail_cards = tail_cards
	_col_evals = col_evals
	_xi_result = xi_result
	_star_chart_levels = star_chart_levels
	_ninjas = ninjas

	_clear_content()
	_build_card_grid()
	_build_compare_section()
	_build_delta_section()
	_update_ninja_summary()
	visible = true


func hide_detail() -> void:
	visible = false


func has_valid_data() -> bool:
	return _baseline != null and _ninja_result != null


func _on_close() -> void:
	visible = false
	close_requested.emit()


func _clear_content() -> void:
	for child: Node in _detail_vbox.get_children():
		child.queue_free()


# ══════════════════════════════════════════
# 3×3 card grid
# ══════════════════════════════════════════

func _build_card_grid() -> void:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "🃏 牌组 3×3 — 行(组) / 列(牌型)"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.831, 0.659, 0.263))
	wrapper.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)

	# Center the grid horizontally
	var grid_center := CenterContainer.new()
	grid_center.add_child(grid)

	# Header row
	grid.add_child(_cell_label("", CLR_GRAY, 18))
	var col_dir: Array[String] = ["左", "中", "右"]
	for ci: int in range(3):
		var col_type: int = _col_evals[ci].hand_type if _col_evals.size() > ci else CardData.HandType3.HIGH_CARD_3
		var cm: int = COL_MULT_MAP.get(col_type, 1)
		var hdr: String = "%s\n%s" % [col_dir[ci], CardData.get_hand_type3_name(col_type)]
		if cm > 1:
			hdr += "(×%d)" % cm
		grid.add_child(_cell_label(hdr, CLR_COL, 18))

	# Row data
	for gi: int in range(3):
		var gname: String = GROUP_NAMES[GROUP_ORDER[gi]]
		var cards: Array = [_head_cards, _mid_cards, _tail_cards][gi]
		var eval_result = null
		match gi:
			0: eval_result = _get_head_eval()
			1: eval_result = _get_mid_eval()
			2: eval_result = _get_tail_eval()

		var ht_name: String = "?"
		if eval_result != null:
			ht_name = CardData.get_hand_type3_name(eval_result.hand_type)
		var label_text: String = "%s\n%s" % [gname, ht_name]
		var label_color: String = CLR_NORMAL
		grid.add_child(_cell_label(label_text, label_color, 18))

		for ci: int in range(3):
			if ci < cards.size():
				var cd: CardData.PlayingCard = cards[ci]
				grid.add_child(_card_cell(cd))
			else:
				grid.add_child(_cell_label("-", CLR_GRAY, 13))

	wrapper.add_child(grid_center)
	_detail_vbox.add_child(wrapper)


func _get_head_eval():
	return HandEvaluator3.evaluate(_head_cards) if _head_cards.size() == 3 else null


func _get_mid_eval():
	return HandEvaluator3.evaluate(_mid_cards) if _mid_cards.size() == 3 else null


func _get_tail_eval():
	return HandEvaluator3.evaluate(_tail_cards) if _tail_cards.size() == 3 else null


func _cell_label(text: String, color: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(color))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


func _card_cell(cd: CardData.PlayingCard) -> Label:
	var suit_symbols: Dictionary = {
		CardData.Suit.SPADES: "♠", CardData.Suit.HEARTS: "♥",
		CardData.Suit.DIAMONDS: "♦", CardData.Suit.CLUBS: "♣",
	}
	var rank_str: String = CardData.RANK_NAMES.get(cd.rank, "?")
	var suit_str: String = suit_symbols.get(cd.suit, "?")
	var text: String = "%s%s" % [suit_str, rank_str]
	var color: String = CLR_RED if (cd.suit == CardData.Suit.HEARTS or cd.suit == CardData.Suit.DIAMONDS) else CLR_NORMAL

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(color))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(120, 60)
	return lbl


# ══════════════════════════════════════════
# Compare section (baseline || with_ninja)
# ══════════════════════════════════════════

func _build_compare_section() -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var left_col := _build_result_column("🔵 基线 (无忍者)", _baseline, false)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_col)

	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 0)
	hbox.add_child(sep)

	var right_col := _build_result_column(_ninja_column_title(), _ninja_result, true)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_col)

	_detail_vbox.add_child(hbox)


func _ninja_column_title() -> String:
	if _ninjas.is_empty():
		return "🟡 忍者效果 (无)"
	var names: Array[String] = []
	for n: Dictionary in _ninjas:
		names.append(n.get("name", "?"))
	return "🟡 忍者效果 (%s)" % ", ".join(names)


func _build_result_column(title: String, result: ScoreResult, is_ninja: bool) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Title
	var ttl := Label.new()
	ttl.text = title
	ttl.add_theme_font_size_override("font_size", 16)
	ttl.add_theme_color_override("font_color", Color(0.831, 0.659, 0.263))
	vbox.add_child(ttl)

	# Subtitle: 三组原始分
	var raw_label := Label.new()
	raw_label.text = "三组原始分 Σ = %d" % _compute_total_raw(result)
	raw_label.add_theme_font_size_override("font_size", 17)
	raw_label.add_theme_color_override("font_color", Color(CLR_GOLD))
	vbox.add_child(raw_label)

	# Per-group formulas
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.add_theme_font_size_override("normal_font_size", 18)
	rtl.add_theme_constant_override("line_separation", 4)
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.text = _build_all_groups_bbcode(result, is_ninja)
	vbox.add_child(rtl)

	# Final score formula
	var final_rtl := RichTextLabel.new()
	final_rtl.bbcode_enabled = true
	final_rtl.fit_content = true
	final_rtl.scroll_active = false
	final_rtl.add_theme_font_size_override("normal_font_size", 18)
	final_rtl.add_theme_constant_override("line_separation", 4)
	final_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	final_rtl.text = _build_final_score_bbcode(result)
	vbox.add_child(final_rtl)

	return vbox


# ══════════════════════════════════════════
# Per-group BBCode
# ══════════════════════════════════════════

func _build_all_groups_bbcode(result: ScoreResult, is_ninja: bool) -> String:
	var parts: Array[String] = []

	# Row groups
	var group_keys: Array[String] = ["head", "mid", "tail"]
	var group_eval_labels: Array[String] = [
			"影 (%s)" % CardData.get_hand_type3_name(_get_head_eval().hand_type),
			"瞬 (%s)" % CardData.get_hand_type3_name(_get_mid_eval().hand_type),
			"滅 (%s)" % CardData.get_hand_type3_name(_get_tail_eval().hand_type),
		]
	for gi: int in range(3):
		parts.append(_build_group_bbcode(
			group_eval_labels[gi],
			_get_group_card_chips(result, group_keys[gi]),
			_get_group_hand_chips(result, group_keys[gi]),
			_get_group_ench_chips(result, group_keys[gi]),
			_get_group_ninja_chips(result, group_keys[gi]),
			_get_group_hand_mult(result, group_keys[gi]),
			_get_group_ench_mult(result, group_keys[gi]),
			_get_group_ninja_mult(result, group_keys[gi]),
			_get_group_ninja_x_stack(result, group_keys[gi]),
			_get_group_score(result, group_keys[gi]),
			is_ninja
		))

	# Column groups
	if _col_evals.size() == 3 and result.col_scores.size() == 3:
		var col_cards_array: Array[Array] = [
			[_head_cards[0], _mid_cards[0], _tail_cards[0]],
			[_head_cards[1], _mid_cards[1], _tail_cards[1]],
			[_head_cards[2], _mid_cards[2], _tail_cards[2]],
		]
		for ci: int in range(3):
			var col_type: int = _col_evals[ci].hand_type
			if col_type == CardData.HandType3.HIGH_CARD_3:
				continue
			var col_cards: Array = col_cards_array[ci]
			parts.append(_build_column_bbcode(ci, col_cards, col_type, result, is_ninja))

	return "\n".join(parts)


func _build_group_bbcode(
	label: String,
	card_chips: int, hand_chips: int, ench_chips: int, ninja_chips: int,
	hand_mult: int, ench_mult: int, ninja_mult: int,
	x_stack: Array, score: int,
	is_ninja: bool
) -> String:
	var lines: Array[String] = []
	lines.append("[color=%s]━━ %s ━━[/color]" % [CLR_GRAY, label])

	# ① chips + ② mult on same line
	var chips_total: int = card_chips + hand_chips + ench_chips + ninja_chips
	var mult_total: int = hand_mult + ench_mult + ninja_mult

	var row_parts: Array[String] = ["[color=%s]筹码 [/color]" % CLR_GRAY]
	row_parts.append("[color=%s]%d(牌面)[/color]" % [CLR_CHIPS, card_chips])
	row_parts.append("[color=%s]+[/color]" % CLR_GRAY)
	row_parts.append("[color=%s]%d(牌型)[/color]" % [CLR_CHIPS, hand_chips])
	if ench_chips > 0:
		row_parts.append("[color=%s]+[/color]" % CLR_GRAY)
		row_parts.append("[color=%s]%d(附魔)[/color]" % [CLR_CHIPS, ench_chips])
	if is_ninja and ninja_chips > 0:
		row_parts.append("[color=%s]+[/color]" % CLR_GRAY)
		row_parts.append("[color=%s]%d(忍者)[/color]" % [CLR_NINJA, ninja_chips])
	row_parts.append("[color=%s] = [b]%d[/b][/color]" % [CLR_CHIPS, chips_total])
	row_parts.append("    [color=%s]倍率 [/color]" % CLR_GRAY)
	row_parts.append("[color=%s]%d(牌型)[/color]" % [CLR_MULT, hand_mult])
	if ench_mult > 0:
		row_parts.append("[color=%s]+[/color]" % CLR_GRAY)
		row_parts.append("[color=%s]%d(附魔)[/color]" % [CLR_MULT, ench_mult])
	if is_ninja and ninja_mult > 0:
		row_parts.append("[color=%s]+[/color]" % CLR_GRAY)
		row_parts.append("[color=%s]%d(忍者)[/color]" % [CLR_NINJA, ninja_mult])
	row_parts.append("[color=%s] = [b]%d[/b][/color]" % [CLR_MULT, mult_total])
	lines.append("".join(row_parts))

	# ③ score
	var safe_mult: int = max(mult_total, 1)
	var score_parts: Array[String] = ["[color=%s]得分 =[/color]" % CLR_GRAY]
	score_parts.append("[color=%s]%d[/color]" % [CLR_CHIPS, chips_total])
	score_parts.append("[color=%s]×[/color]" % CLR_GRAY)
	score_parts.append("[color=%s]%d[/color]" % [CLR_MULT, safe_mult])
	for xv: int in x_stack:
		if xv > 1:
			score_parts.append("[color=%s]×[/color]" % CLR_GRAY)
			score_parts.append("[color=%s]%d(x_stack)[/color]" % [CLR_NINJA, xv])
	score_parts.append("[color=%s]=[/color]" % CLR_GRAY)
	score_parts.append("[color=%s][b]%d[/b][/color]" % [CLR_GOLD, score])
	lines.append("".join(score_parts))

	return "\n".join(lines)


func _build_column_bbcode(
	col_idx: int, col_cards: Array, col_type: int, result: ScoreResult, is_ninja: bool
) -> String:
	var col_names: Array[String] = ["左列", "中列", "右列"]
	var label: String = "%s — %s" % [col_names[col_idx], CardData.get_hand_type3_name(col_type)]
	var cm: int = COL_MULT_MAP.get(col_type, 1)
	if cm > 1:
		label += " ×%d" % cm

	var card_chips: int = ScoreHelpers.group_card_chips(col_cards, false, true)
	var hand_chips: int = CardData.get_hand_type3_leveled_chips(col_type, _star_chart_levels)
	var ench_chips: int = ScoreHelpers.group_ench_chips(col_cards)
	var hand_mult_val: int = CardData.get_hand_type3_leveled_mult(col_type, _star_chart_levels)
	var ench_mult_val: int = ScoreHelpers.group_ench_mult(col_cards)

	# Collect column ninja effects
	var col_ninja_chips: int = _collect_col_ninja_chips(col_type)
	var col_ninja_mult: int = _collect_col_ninja_mult(col_type)
	var col_ninja_x: Array[int] = _collect_col_ninja_x(col_type)

	var col_score: int = result.col_scores[col_idx] if col_idx < result.col_scores.size() else 0

	return _build_group_bbcode(
		label,
		card_chips, hand_chips, ench_chips, col_ninja_chips,
		hand_mult_val, ench_mult_val, col_ninja_mult,
		col_ninja_x, col_score,
		is_ninja
	)


# ══════════════════════════════════════════
# Column ninja effect collection (replicates ScoreCalculator logic)
# ══════════════════════════════════════════

func _collect_col_ninja_chips(col_type: int) -> int:
	var total: int = 0
	for ninja: Dictionary in _ninjas:
		var eff: Dictionary = ninja.get("effect", {})
		if _col_ninja_applies(eff, col_type):
			total += eff.get("add_chips", 0)
	return total


func _collect_col_ninja_mult(col_type: int) -> int:
	var total: int = 0
	for ninja: Dictionary in _ninjas:
		var eff: Dictionary = ninja.get("effect", {})
		if _col_ninja_applies(eff, col_type):
			total += eff.get("add_mult", 0)
	return total


func _collect_col_ninja_x(col_type: int) -> Array[int]:
	var stack: Array[int] = []
	for ninja: Dictionary in _ninjas:
		var eff: Dictionary = ninja.get("effect", {})
		if not _col_ninja_applies(eff, col_type):
			continue
		var xv: int = eff.get("x_mult", 1)
		if xv > 1:
			stack.append(xv)
		for x: int in eff.get("x_stack", []):
			if x > 1:
				stack.append(x)
	return stack


func _col_ninja_applies(effect: Dictionary, col_type: int) -> bool:
	if effect.get("pyramid_x3", false):
		return false

	var cond: Dictionary = effect.get("condition", {})
	if cond.get("group", "") != "":
		return false
	if cond.has("xi") and not cond.has("hand_type"):
		return false
	if cond.is_empty():
		return true

	var required: int = cond.get("hand_type", -1)
	if required != -1 and int(col_type) != required:
		return false
	var at_most: int = cond.get("at_most_hand_type", -1)
	if at_most != -1 and int(col_type) > at_most:
		return false
	var at_least: int = cond.get("at_least_hand_type", -1)
	if at_least != -1 and int(col_type) < at_least:
		return false
	return true


# ══════════════════════════════════════════
# Final score BBCode
# ══════════════════════════════════════════

func _build_final_score_bbcode(result: ScoreResult) -> String:
	var lines: Array[String] = []
	lines.append("[color=%s]━━ 最终分 ━━[/color]" % CLR_GRAY)

	# ④ Row breakdown: N + N + N = total
	var row_scores: Array[int] = [result.head_score, result.mid_score, result.tail_score]
	var row_parts: Array[String] = []
	var rows_raw: int = 0
	for ri: int in range(3):
		rows_raw += row_scores[ri]
		row_parts.append("[color=%s]%d[/color]" % [CLR_GOLD, row_scores[ri]])
	lines.append("[color=%s]④ 三行分 =[/color] %s [color=%s]= [b]%d[/b][/color]" % [CLR_GRAY, " + ".join(row_parts), CLR_GOLD, rows_raw])

	# ⑤ Column breakdown (additive): N + N + N = total
	if result.col_scores.size() == 3:
		var col_parts: Array[String] = []
		var col_total: int = 0
		for ci: int in range(3):
			var cs: int = result.col_scores[ci]
			if cs > 0:
				col_total += cs
				col_parts.append("[color=%s]%d[/color]" % [CLR_GOLD, cs])
		if not col_parts.is_empty():
			lines.append("[color=%s]⑤ 列分 =[/color] %s [color=%s]= [b]%d[/b][/color]" % [CLR_GRAY, " + ".join(col_parts), CLR_GOLD, col_total])

	# ⑥ Raw total
	var total_raw: int = _compute_total_raw(result)
	lines.append("[color=%s]⑥ 原始总分 = ④ + ⑤[/color] [color=%s]= [b]%d[/b][/color]" % [CLR_GRAY, CLR_GOLD, total_raw])

	# × 喜乘 with xi type names
	if not result.global_xi_x_stack.is_empty():
		var xi_details: Array[Dictionary] = _get_xi_details()
		if not xi_details.is_empty():
			var xi_parts: Array[String] = []
			var xi_prod: int = 1
			for xi: Dictionary in xi_details:
				xi_prod *= xi["x_mult"]
				xi_parts.append("[color=%s]%s(×%d)[/color]" % [CLR_XI, xi["name"], xi["x_mult"]])
			lines.append("[color=%s]× 喜乘 =[/color] %s [color=%s]= ×%d[/color]" % [CLR_GRAY, " × ".join(xi_parts), CLR_XI, xi_prod])

	lines.append("[color=%s]=[/color] [color=%s][b]%d[/b][/color]" % [CLR_GRAY, CLR_GOLD, result.total_score])

	return "\n".join(lines)


# ══════════════════════════════════════════
# Delta section
# ══════════════════════════════════════════

func _build_delta_section() -> void:
	var sep := HSeparator.new()
	_detail_vbox.add_child(sep)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "📊 变化对比"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.831, 0.659, 0.263))
	wrapper.add_child(title)

	var bs: int = _baseline.total_score
	var ns: int = _ninja_result.total_score
	var delta: int = ns - bs
	var pct: float = (float(delta) / float(max(bs, 1))) * 100.0

	var rows_b: int = _compute_rows_raw(_baseline)
	var rows_n: int = _compute_rows_raw(_ninja_result)
	var rows_delta: int = rows_n - rows_b

	var cols_b_raw: int = 0
	var cols_n_raw: int = 0
	if _baseline.col_scores.size() == 3:
		for cs: int in _baseline.col_scores:
			cols_b_raw += cs
	if _ninja_result.col_scores.size() == 3:
		for cs: int in _ninja_result.col_scores:
			cols_n_raw += cs
	var cols_delta: int = cols_n_raw - cols_b_raw

	# Xi prod
	var xi_b: int = _xi_prod(_baseline)
	var xi_n: int = _xi_prod(_ninja_result)

	var lines: Array[String] = [
		"三行: [b]%d[/b] → [b]%d[/b]  %s" % [rows_b, rows_n, _delta_str(rows_delta)],
		"列分: [b]%d[/b] → [b]%d[/b]  %s" % [cols_b_raw, cols_n_raw, _delta_str(cols_delta)],
		"喜乘: ×%d → ×%d  %s" % [xi_b, xi_n, _delta_xi_str(xi_n - xi_b)],
		"最终: [b]%d[/b] → [b]%d[/b]  %s (%+.1f%%)" % [bs, ns, _delta_str(delta), pct],
	]

	for line_str: String in lines:
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.scroll_active = false
		lbl.add_theme_font_size_override("normal_font_size", 17)
		lbl.add_theme_constant_override("line_separation", 4)
		lbl.add_theme_color_override("default_color", Color(CLR_NORMAL))
		lbl.text = line_str
		wrapper.add_child(lbl)

	_detail_vbox.add_child(wrapper)


func _delta_str(d: int) -> String:
	if d > 0:
		return "[color=%s]▲ +%d[/color]" % [CLR_GREEN, d]
	elif d < 0:
		return "[color=%s]▼ %d[/color]" % [CLR_RED, d]
	return "[color=%s]— 0[/color]" % CLR_GRAY


func _delta_xi_str(d: int) -> String:
	if d > 0:
		return "[color=%s]▲ +%d[/color]" % [CLR_GREEN, d]
	elif d < 0:
		return "[color=%s]▼ %d[/color]" % [CLR_RED, d]
	return "[color=%s](不变)[/color]" % CLR_GRAY


func _compute_col_prod() -> int:
	var prod: int = 1
	if _col_evals.size() == 3:
		for ci: int in range(3):
			var ct: int = _col_evals[ci].hand_type
			prod *= COL_MULT_MAP.get(ct, 1)
	return prod


func _xi_prod(result: ScoreResult) -> int:
	var p: int = 1
	for xv: int in result.global_xi_x_stack:
		p *= xv
	return p


func _compute_total_raw(result: ScoreResult) -> int:
	var raw: int = result.head_score + result.mid_score + result.tail_score
	if result.col_scores.size() > 0:
		for cs: int in result.col_scores:
			raw += cs
	return raw


func _compute_rows_raw(result: ScoreResult) -> int:
	return result.head_score + result.mid_score + result.tail_score


## Build named xi detail list by matching triggered names against XI_DEFINITIONS.
## Only includes xi with x_mult > 1 (those that actually contribute to the stack).
func _get_xi_details() -> Array[Dictionary]:
	if _xi_result == null or _xi_result.triggered.is_empty():
		return []
	var details: Array[Dictionary] = []
	for name: String in _xi_result.triggered:
		for def: Dictionary in XiDetector.XI_DEFINITIONS:
			if def["name"] == name:
				var xv: int = def.get("x_mult", 1)
				if xv > 1:
					details.append({"name": name, "x_mult": xv})
				break
	return details


# ══════════════════════════════════════════
# Ninja summary
# ══════════════════════════════════════════

func _update_ninja_summary() -> void:
	if _ninjas.is_empty():
		_ninja_summary.text = ""
		return
	var parts: Array[String] = []
	for n: Dictionary in _ninjas:
		var name_str: String = n.get("name", "?")
		var effect: Dictionary = n.get("effect", {})
		var desc_parts: Array[String] = []
		if effect.get("add_chips", 0) > 0:
			desc_parts.append("c+%d" % effect.add_chips)
		if effect.get("add_mult", 0) > 0:
			desc_parts.append("m+%d" % effect.add_mult)
		if effect.get("x_mult", 1) > 1:
			desc_parts.append("×%d" % effect.x_mult)
		var desc_str: String = ""
		if not desc_parts.is_empty():
			desc_str = " [%s]" % ", ".join(desc_parts)
		parts.append("%s%s" % [name_str, desc_str])
	_ninja_summary.text = "忍者: " + "  ·  ".join(parts)


# ══════════════════════════════════════════
# Group data accessors
# ══════════════════════════════════════════

func _get_group_card_chips(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_card_chips
		"mid": return result.mid_card_chips
		_: return result.tail_card_chips


func _get_group_hand_chips(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_hand_chips
		"mid": return result.mid_hand_chips
		_: return result.tail_hand_chips


func _get_group_ench_chips(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_ench_chips
		"mid": return result.mid_ench_chips
		_: return result.tail_ench_chips


func _get_group_ninja_chips(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_ninja_chips
		"mid": return result.mid_ninja_chips
		_: return result.tail_ninja_chips


func _get_group_hand_mult(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_hand_mult
		"mid": return result.mid_hand_mult
		_: return result.tail_hand_mult


func _get_group_ench_mult(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_ench_mult
		"mid": return result.mid_ench_mult
		_: return result.tail_ench_mult


func _get_group_ninja_mult(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_ninja_mult
		"mid": return result.mid_ninja_mult
		_: return result.tail_ninja_mult


func _get_group_ninja_x_stack(result: ScoreResult, key: String) -> Array:
	match key:
		"head": return result.head_ninja_x_stack
		"mid": return result.mid_ninja_x_stack
		_: return result.tail_ninja_x_stack


func _get_group_score(result: ScoreResult, key: String) -> int:
	match key:
		"head": return result.head_score
		"mid": return result.mid_score
		_: return result.tail_score
