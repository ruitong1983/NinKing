extends RefCounted

static func run() -> void:
    var deck = CardData.create_standard_deck()
    deck.shuffle()
    var sample = deck.slice(0, 9)
    var empty = {"chips": 0, "mult": 0, "x_stack": []}
    var arr = AutoArranger.find_best(sample, empty, empty, empty, {})
    if arr == null:
        print("AI NULL")
        return
    print("AI: " + CardData.get_hand_type3_name(arr.head_eval.hand_type) \
        + " " + CardData.get_hand_type3_name(arr.mid_eval.hand_type) \
        + " " + CardData.get_hand_type3_name(arr.tail_eval.hand_type))
    print("legal: " + str(arr.is_legal()))

    var fails = 0
    for i in 100:
        deck.shuffle()
        var s = deck.slice(0, 9)
        var a = AutoArranger.find_best(s, empty, empty, empty, {})
        if a == null:
            fails += 1
        elif not a.is_legal():
            fails += 1
    print(str(100-fails) + "/100 OK")
