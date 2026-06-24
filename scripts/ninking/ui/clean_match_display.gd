class_name CleanMatchDisplay
extends RefCounted

## Clean mode match detail display — per-wave match group rows in HandTypePanel.
##
## Lifecycle:
##   setup(hand_type_panel)     -> during game_manager init (or clean chain handler setup)
##   reset_for_new_swap()       -> when a new swap begins chain resolution
##   append_wave(wave_data)     -> called mid-chain per wave (auto-spaces between waves)
##
## Row format:  "手役名    chip x mult = score"
## Wave separator: 8px vertical space between waves.
## ScrollContainer auto-scrolls to bottom (deferred to next frame after layout).

const MATCH_MULTS: Dictionary = {
	2: 3,  # STRAIGHT
	3: 4,  # FLUSH
	4: 5,  # STRAIGHT_FLUSH
	5: 8,  # THREE_OF_KIND
}

## Hand type row colors (fixed -- no star chart levels in clean mode).
const HAND_TYPE_COLORS: Dictionary = {
	2: "#7A7A7A",  # 顺子 -- 中灰
	3: "#3A6FD8",  # 同花 -- 深蓝
	4: "#D4A843",  # 同花顺 -- 暗金
	5: "#F24D4D",  # 豹子 -- 烈红
}

const FORMULA_COLOR: String = "#3D2B1A"  # 深褐
const FONT_SIZE: int = 18
const ROW_HEIGHT: int = 26
const WAVE_SPACER_HEIGHT: int = 8

var _vbox: VBoxContainer
var _scroll: ScrollContainer


# Setup

func setup(hand_type_panel: Panel) -> void:
	if not is_instance_valid(hand_type_panel):
		push_error("CleanMatchDisplay.setup: invalid HandTypePanel")
		return

	# Create or find ScrollContainer
	_scroll = hand_type_panel.get_node_or_null("CleanMatchScroll")
	if _scroll == null:
		_scroll = ScrollContainer.new()
		_scroll.name = "CleanMatchScroll"
		_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_scroll.anchor_left = 0.0
		_scroll.anchor_right = 1.0
		_scroll.anchor_top = 0.0
		_scroll.anchor_bottom = 1.0
		_scroll.offset_left = 24
		_scroll.offset_top = 10
		_scroll.offset_right = -24
		_scroll.offset_bottom = -10
		hand_type_panel.add_child(_scroll)

	# Create or find VBox inside scroll
	_vbox = _scroll.get_node_or_null("MatchVBox")
	if _vbox == null:
		_vbox = VBoxContainer.new()
		_vbox.name = "MatchVBox"
		_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scroll.add_child(_vbox)


# Public API

## Clear all rows in preparation for a new swap's chain.
func reset_for_new_swap() -> void:
	if not is_instance_valid(_vbox):
		return
	for child in _vbox.get_children():
		child.queue_free()


## Append one wave's match groups to the display.
## Adds 8px spacing before rows if not the first wave.
## Auto-scrolls to bottom (deferred to next frame after layout).
func append_wave(wave_data: Dictionary) -> void:
	if not is_instance_valid(_vbox):
		return
	var matches: Array = wave_data.get("matches", [])
	if matches.is_empty():
		return

	# Add wave spacer after the first wave
	if _vbox.get_child_count() > 0:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, WAVE_SPACER_HEIGHT)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vbox.add_child(spacer)

	# Build and add one row per match group
	for m: Dictionary in matches:
		var row: RichTextLabel = _build_match_row(m)
		if row != null:
			_vbox.add_child(row)

	# Auto-scroll to bottom (call_deferred so layout is computed first)
	if is_instance_valid(_scroll):
		_scroll.call_deferred("set", "scroll_vertical", 99999)


# Row building

## Build a single RichTextLabel row for one match group.
## Formula:  chip_sum x hand_type_mult = score
## Reverses chip_sum from score / mult (score is always chips x mult).
func _build_match_row(match_data: Dictionary) -> RichTextLabel:
	var hand_type: int = match_data.get("hand_type", 0)
	var score: int = match_data.get("score", 0)
	if hand_type < 2 or hand_type > 5 or score <= 0:
		return null

	var type_name: String = CardData.get_hand_type3_name(hand_type as CardData.HandType3)
	var mult: int = MATCH_MULTS.get(hand_type, 1)
	var chips: int = score / mult  # Inverse: score = chips x mult

	var type_color: String = HAND_TYPE_COLORS.get(hand_type, "#7A7A7A")

	var rtl := RichTextLabel.new()
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.fit_content = true
	rtl.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	rtl.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	rtl.bbcode_enabled = true
	rtl.text = "[color=%s]%s[/color]    [color=%s]%d x %d = %d[/color]" % [
		type_color, type_name,
		FORMULA_COLOR, chips, mult, score
	]
	return rtl
