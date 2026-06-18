extends RefCounted

## Test script to check AI arranger behavior.

static func run() -> void:
    var deck = CardData.create_standard_deck()
    deck.shuffle()
    var sample = deck.slice(0, 9)
    print("=== 原始手牌 ===")
    var names = []
    for c in sample:
        names.append(c.get_display_name())
    print(" -> ".join(names))

    var empty = {"chips": 0, "mult": 0, "x_stack": []}
    var arr = AutoArranger.find_best(sample, empty, empty, empty, {})

    if arr == null:
        print("❌ AI 未找到合法排列!")
        return

    print("=== AI 排列结果 ===")
    print("影(头): %s 强度=%d" % [CardData.get_hand_type3_name(arr.head_eval.hand_type), arr.head_eval.strength])
    print("瞬(中): %s 强度=%d" % [CardData.get_hand_type3_name(arr.mid_eval.hand_type), arr.mid_eval.strength])
    print("滅(尾): %s 强度=%d" % [CardData.get_hand_type3_name(arr.tail_eval.hand_type), arr.tail_eval.strength])

    var ok = arr.head_eval.strength <= arr.mid_eval.strength and arr.mid_eval.strength <= arr.tail_eval.strength
    print("递增约束: " + ("✅" if ok else "❌"))

    # Repeat multiple times to check consistency
    var fail_count = 0
    var total = 20
    for i in range(total):
        deck.shuffle()
        var test_sample = deck.slice(0, 9)
        var result = AutoArranger.find_best(test_sample, empty, empty, empty, {})
        if result == null:
            fail_count += 1
            print("  Run %d: NO ARRANGEMENT ❌" % i)
        else:
            var str_ok = result.head_eval.strength <= result.mid_eval.strength and result.mid_eval.strength <= result.tail_eval.strength
            if not str_ok:
                fail_count += 1
                print("  Run %d: CONSTRAINT VIOLATED ❌ (head=%d mid=%d tail=%d)" % [i, result.head_eval.strength, result.mid_eval.strength, result.tail_eval.strength])
    print("=== 统计: %d/%d runs OK ===" % [(total - fail_count), total])
