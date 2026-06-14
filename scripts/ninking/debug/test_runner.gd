## NinKing test_runner.gd — P0 交叉验证
## 读取 test_payload.json, 调用 ScoreCalculator.calculate(),
## 输出 actual.json 供 diff.py 对比。
##
## 用法 (Godot editor script):
##   TestRunner.run("res://docs/ninking/testing/test_payload.json",
##                 "res://docs/ninking/testing/actual.json")

class_name TestRunner
extends RefCounted

const SUIT_MAP := {
	"♣": CardData.Suit.CLUBS,
	"♦": CardData.Suit.DIAMONDS,
	"♥": CardData.Suit.HEARTS,
	"♠": CardData.Suit.SPADES,
}

const RANK_MAP := {
	"2": CardData.Rank.TWO, "3": CardData.Rank.THREE, "4": CardData.Rank.FOUR,
	"5": CardData.Rank.FIVE, "6": CardData.Rank.SIX, "7": CardData.Rank.SEVEN,
	"8": CardData.Rank.EIGHT, "9": CardData.Rank.NINE, "10": CardData.Rank.TEN,
	"J": CardData.Rank.JACK, "Q": CardData.Rank.QUEEN, "K": CardData.Rank.KING,
	"A": CardData.Rank.ACE,
}


static func parse_card(s: String) -> CardData.PlayingCard:
	var suit_char: String = s[0]  # ♠♥♦♣
	var rank_str: String = s.substr(1)  # 2-10, J, Q, K, A
	return CardData.PlayingCard.new(SUIT_MAP[suit_char], RANK_MAP[rank_str])


static func parse_cards(strings: Array) -> Array[CardData.PlayingCard]:
	var result: Array[CardData.PlayingCard] = []
	for s: String in strings:
		result.append(parse_card(s))
	return result


static func eval_column(col_cards: Array[CardData.PlayingCard]) -> HandEvaluator3.EvalResult:
	return HandEvaluator3.evaluate(col_cards)


static func build_ninja_effects(effect_list: Array) -> Array[Dictionary]:
	## Convert payload ninja_effects to the format ScoreCalculator expects.
	const GROUP_MAP := {"h": "head", "m": "mid", "t": "tail"}
	var result: Array[Dictionary] = []
	for eff in effect_list:
		var d: Dictionary = {}
		var group: String = eff.get("group", "all")
		if group != "all":
			d["condition"] = {"group": GROUP_MAP.get(group, group)}
		d["add_chips"] = eff.get("chips", 0)
		d["add_mult"] = eff.get("mult", 0)
		var x_list: Array = eff.get("x_mult", [])
		if x_list.size() > 0:
			d["x_stack"] = x_list  # pass all multipliers
		result.append(d)
	return result


static func build_expected_entry(case_id: String, head_cards: Array, mid_cards: Array, tail_cards: Array,
		ninja_effects: Array, xi_bonus: int, xi_override: Dictionary) -> Dictionary:
	## Run ScoreCalculator.calculate() and serialize the result.

	var he := HandEvaluator3.evaluate(head_cards)
	var me := HandEvaluator3.evaluate(mid_cards)
	var te := HandEvaluator3.evaluate(tail_cards)

	# Build column evaluations
	var col_evals: Array = [
		eval_column([head_cards[0], mid_cards[0], tail_cards[0]]),
		eval_column([head_cards[1], mid_cards[1], tail_cards[1]]),
		eval_column([head_cards[2], mid_cards[2], tail_cards[2]]),
	]

	# Detect xi
	var xi_result: XiDetector.XiResult = XiDetector.detect(head_cards, mid_cards, tail_cards, he, me, te)

	# Build ninja dicts
	var effects: Array[Dictionary] = build_ninja_effects(ninja_effects)
	var ninjas: Array[Dictionary] = []
	for eff in effects:
		ninjas.append({"effect": eff})

	var result: ScoreCalculator.ScoreResult = ScoreCalculator.calculate(
		head_cards, mid_cards, tail_cards,
		he, me, te,
		col_evals,
		ninjas,
		{},  # star_chart_levels
		xi_result,
		{},  # seal_lord_effects
		0,   # gold
		xi_bonus,
		xi_override
	)

	# Serialize to expected.json format
	var xi_list: Array[String] = []
	if xi_result:
		for xi_name: String in xi_result.triggered:
			xi_list.append(xi_name)

	var global_xi_x_prod: int = 1
	for x: int in result.global_xi_x_stack:
		global_xi_x_prod *= x

	return {
		"id": case_id,
		"hand_types": {
			"head": int(he.hand_type),
			"mid": int(me.hand_type),
			"tail": int(te.hand_type),
		},
		"col_types": [
			int(col_evals[0].hand_type),
			int(col_evals[1].hand_type),
			int(col_evals[2].hand_type),
		],
		"xi_list": xi_list,
		"head": {
			"card_chips": result.head_card_chips,
			"hand_chips": result.head_hand_chips,
			"ench_chips": result.head_ench_chips,
			"ninja_chips": result.head_ninja_chips,
			"chips_total": result.head_chips,
			"hand_mult": result.head_hand_mult,
			"ench_mult": result.head_ench_mult,
			"ninja_mult": result.head_ninja_mult,
			"mult_total": result.head_mult,
			"ninja_x_stack": result.head_ninja_x_stack,
			"score": result.head_score,
		},
		"mid": {
			"card_chips": result.mid_card_chips,
			"hand_chips": result.mid_hand_chips,
			"ench_chips": result.mid_ench_chips,
			"ninja_chips": result.mid_ninja_chips,
			"chips_total": result.mid_chips,
			"hand_mult": result.mid_hand_mult,
			"ench_mult": result.mid_ench_mult,
			"ninja_mult": result.mid_ninja_mult,
			"mult_total": result.mid_mult,
			"ninja_x_stack": result.mid_ninja_x_stack,
			"score": result.mid_score,
		},
		"tail": {
			"card_chips": result.tail_card_chips,
			"hand_chips": result.tail_hand_chips,
			"ench_chips": result.tail_ench_chips,
			"ninja_chips": result.tail_ninja_chips,
			"chips_total": result.tail_chips,
			"hand_mult": result.tail_hand_mult,
			"ench_mult": result.tail_ench_mult,
			"ninja_mult": result.tail_ninja_mult,
			"mult_total": result.tail_mult,
			"ninja_x_stack": result.tail_ninja_x_stack,
			"score": result.tail_score,
		},
		"col_scores": result.col_scores,
		"col_total": result.col_total,
		"total_raw": result.head_score + result.mid_score + result.tail_score + result.col_total,
		"global_xi_x_prod": global_xi_x_prod,
		"final_score": result.total_score,
	}


static func run(payload_path: String, output_path: String) -> void:
	print("[test_runner] Loading payload: ", payload_path)

	var file := FileAccess.open(payload_path, FileAccess.READ)
	if file == null:
		printerr("[test_runner] Cannot open: ", payload_path)
		return
	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		printerr("[test_runner] JSON parse error: ", json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	var cases: Array = data.get("cases", [])
	print("[test_runner] Loaded ", cases.size(), " test cases")

	var results: Array[Dictionary] = []
	for case_data in cases:
		var case_id: String = case_data["id"]
		var cards: Dictionary = case_data["cards"]
		var head_cards := parse_cards(cards["head"])
		var mid_cards := parse_cards(cards["mid"])
		var tail_cards := parse_cards(cards["tail"])
		var ninja_effects: Array = case_data.get("ninja_effects", [])
		var xi_bonus: int = case_data.get("xi_bonus", 0)
		var xi_override: Dictionary = case_data.get("xi_override", {})

		var entry := build_expected_entry(case_id, head_cards, mid_cards, tail_cards,
			ninja_effects, xi_bonus, xi_override)
		results.append(entry)

	# Write output
	var out_file := FileAccess.open(output_path, FileAccess.WRITE)
	if out_file == null:
		printerr("[test_runner] Cannot write: ", output_path)
		return

	var out_dict := {"cases": results}
	out_file.store_string(JSON.stringify(out_dict, "  "))
	out_file.close()

	print("[test_runner] Wrote ", results.size(), " results to ", output_path)
