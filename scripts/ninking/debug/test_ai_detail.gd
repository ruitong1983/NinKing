extends RefCounted

static func run() -> void:
    var total_tests = 100
    var constraint_fails = 0
    var score_diff_big = 0
    var high_score_diff = 0.0

    print("=== AI Arranger 详细测试 (%d runs) ===" % total_tests)

    var deck = CardData.create_standard_deck()
    var empty = {"chips": 0, "mult": 0, "x_stack": []}
    var star_levels = _default_levels()

    for i in range(total_tests):
        deck.shuffle()
        var sample = deck.slice(0, 9)
        var arr = AutoArranger.find_best(sample, empty, empty, empty, star_levels)

        if arr == null:
            print("Run %d: NO ARRANGEMENT FOUND!" % i)
            constraint_fails += 1
            continue

        # Check constraint
        if not arr.is_legal():
            print("Run %d: CONSTRAINT VIOLATED! h=%d m=%d t=%d" % [i, arr.head_eval.strength, arr.mid_eval.strength, arr.tail_eval.strength])
            constraint_fails += 1
            continue

        # Compare AI score vs real score
        var fast = AutoArranger._fast_score(arr.head_eval, arr.mid_eval, arr.tail_eval, arr.head, arr.mid, arr.tail, empty, empty, empty, star_levels, {})

        var real = ScoreCalculator.calculate(arr.head, arr.mid, arr.tail, arr.head_eval, arr.mid_eval, arr.tail_eval)
        var real_total = float(real.total_score)

        var diff = abs(fast - real_total)
        if diff > 100.0:
            score_diff_big += 1
            if diff > high_score_diff:
                high_score_diff = diff
            if diff > 500.0:
                print("Run %d: BIG SCORE DIFF fast=%.1f real=%d (%.0f%%) h=%s m=%s t=%s" % [i, fast, real.total_score, diff/real_total*100.0, CardData.get_hand_type3_name(arr.head_eval.hand_type), CardData.get_hand_type3_name(arr.mid_eval.hand_type), CardData.get_hand_type3_name(arr.tail_eval.hand_type)])

    print("=== 结果 ===")
    print("约束违规: %d/%d" % [constraint_fails, total_tests])
    print("AI分差>100: %d/%d (最大差=%.1f)" % [score_diff_big, total_tests, high_score_diff])

static func _default_levels() -> Dictionary:
    var d = {}
    for ht in [CardData.HandType3.HIGH_CARD_3, CardData.HandType3.ONE_PAIR_3, CardData.HandType3.STRAIGHT_3, CardData.HandType3.FLUSH_3, CardData.HandType3.STRAIGHT_FLUSH_3, CardData.HandType3.THREE_OF_KIND_3]:
        d[ht] = 0
    return d
