extends RefCounted

## Compare AI _fast_score vs real ScoreCalculator in detail.
## Identify cases where the AI ranks arrangements wrongly.

static func run() -> void:
    var deck = CardData.create_standard_deck()
    var empty = {"chips": 0, "mult": 0, "x_stack": []}
    var levels = _default_levels()
    var worst_diff = 0
    var worst_real_score = 0
    var wrong_count = 0
    var total = 200

    for run in range(total):
        deck.shuffle()
        var sample = deck.slice(0, 9)

        # Find what AI thinks is best
        var ai_best = AutoArranger.find_best(sample, empty, empty, empty, levels)
        if ai_best == null:
            continue

        var ai_fast = AutoArranger._fast_score(
            ai_best.head_eval, ai_best.mid_eval, ai_best.tail_eval,
            ai_best.head, ai_best.mid, ai_best.tail,
            empty, empty, empty, levels, {})

        var ai_real = ScoreCalculator.calculate(
            ai_best.head, ai_best.mid, ai_best.tail,
            ai_best.head_eval, ai_best.mid_eval, ai_best.tail_eval).total_score

        # Now brute-force ALL arrangements and find the TRUE best
        var best_real = 0
        var best_real_arr = null
        var head_combos = _combinations(sample, 3)
        for hc in head_combos:
            var rem = _array_diff(sample, hc)
            var mid_combos = _combinations(rem, 3)
            for mc in mid_combos:
                var tc = _array_diff(rem, mc)
                var hd = _to_typed(hc)
                var md = _to_typed(mc)
                var td = _to_typed(tc)
                var he = HandEvaluator3.evaluate(hd)
                var me = HandEvaluator3.evaluate(md)
                var te = HandEvaluator3.evaluate(td)

                if not (he.strength <= me.strength and me.strength <= te.strength):
                    continue

                var real = ScoreCalculator.calculate(
                    hd, md, td, he, me, te).total_score

                if real > best_real:
                    best_real = real
                    best_real_arr = [hd, md, td, he, me, te]

        # Did AI pick the TRUE best?
        if ai_real < best_real and best_real_arr != null:
            wrong_count += 1
            var diff = best_real - ai_real
            if diff > worst_diff:
                worst_diff = diff
                worst_real_score = ai_real

            if diff > 200:
                var h_types = "h=" + CardData.get_hand_type3_name(ai_best.head_eval.hand_type)
                h_types += " m=" + CardData.get_hand_type3_name(ai_best.mid_eval.hand_type)
                h_types += " t=" + CardData.get_hand_type3_name(ai_best.tail_eval.hand_type)

                var b_types = " → h=" + CardData.get_hand_type3_name(best_real_arr[3].hand_type)
                b_types += " m=" + CardData.get_hand_type3_name(best_real_arr[4].hand_type)
                b_types += " t=" + CardData.get_hand_type3_name(best_real_arr[5].hand_type)

                print("Run %d: AI选了 %s（得分%d），真正最优 %s（得分%d），差=%d" % [
                    run, h_types, ai_real, b_types, best_real, diff])

    print("=== 汇总 ===")
    print("AI选错: %d/%d" % [wrong_count, total])
    print("最大分差: %d (AI得分%d)" % [worst_diff, worst_real_score])

static func _combinations(items: Array, k: int) -> Array:
    var result = []
    _combine(items, k, 0, [], result)
    return result

static func _combine(items: Array, k: int, start: int, current: Array, result: Array) -> void:
    if current.size() == k:
        result.append(current.duplicate())
        return
    for i in range(start, items.size()):
        current.append(items[i])
        _combine(items, k, i + 1, current, result)
        current.pop_back()

static func _array_diff(all: Array, sub: Array) -> Array:
    var result = []
    for item in all:
        var found = false
        for s in sub:
            if (item as CardData.PlayingCard).is_equal(s as CardData.PlayingCard):
                found = true
                break
        if not found:
            result.append(item)
    return result

static func _to_typed(arr: Array) -> Array:
    var result = []
    for item in arr:
        result.append(item as CardData.PlayingCard)
    return result

static func _default_levels() -> Dictionary:
    var d = {}
    for ht in [0, 1, 2, 3, 4, 5]:
        d[ht] = 0
    return d
