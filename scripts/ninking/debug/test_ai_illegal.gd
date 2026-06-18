extends RefCounted

## 专门测试：能否复现"中行同花顺+尾行散牌"的违规排列

static func run() -> void:
    var deck = CardData.create_standard_deck()
    var empty = {"chips": 0, "mult": 0, "x_stack": []}
    var levels = _default_levels()
    var found_violations = 0
    var total = 100

    print("=== 搜索违规排列 (%d 次随机) ===" % total)
    for run in range(total):
        deck.shuffle()
        var sample = deck.slice(0, 9)

        var arr = AutoArranger.find_best(sample, empty, empty, empty, levels)
        if arr == null:
            continue

        # 检查是否有 mid=同花顺, tail=散牌 的情况
        if arr.mid_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3 \
            and arr.tail_eval.hand_type == CardData.HandType3.HIGH_CARD_3:
            found_violations += 1
            print("【发现严重违规】Run %d: mid=同花顺(%d) tail=散牌(%d)" % [run, arr.mid_eval.strength, arr.tail_eval.strength])
            print("  CardData 中行: %s" % _card_names(arr.mid))
            print("  CardData 尾行: %s" % _card_names(arr.tail))
            print("  is_legal=%s" % str(arr.is_legal()))

        # 也检查是否有 mid 或 tail 违规
        if not arr.is_legal():
            print("【约束违规】Run %d: h=%d(%s) m=%d(%s) t=%d(%s)" % [
                run,
                arr.head_eval.strength, CardData.get_hand_type3_name(arr.head_eval.hand_type),
                arr.mid_eval.strength, CardData.get_hand_type3_name(arr.mid_eval.hand_type),
                arr.tail_eval.strength, CardData.get_hand_type3_name(arr.tail_eval.hand_type),
            ])

    print("=== 结果 ===")
    print("违规排列(中同花顺+尾散牌): %d" % found_violations)
    print("总约束违规: 见上方详细")

static func _card_names(cards: Array) -> String:
    var names = []
    for c in cards:
        names.append(c.get_display_name())
    return " ".join(names)

static func _default_levels() -> Dictionary:
    var d = {}
    for ht in [0, 1, 2, 3, 4, 5]:
        d[ht] = 0
    return d
