class_name ShopHandler
extends RefCounted

## Handles shop overlay entry, purchase, reroll, and continue operations.
## Created by game_manager.gd as a delegate for shop-related logic.
## B4: Reroll cost = $3 + $1/次（递进式，每次商店刷新后重置）

const SB = preload("res://scripts/config/sound_bank.gd")

var _ui: UIManager
var _transition_guard: bool = false
var _shop_cache: Dictionary = {}
var _reroll_count: int = 0  # B4: 本趟商店已刷新次数，每次打开新商店时重置


func setup(ui: UIManager) -> void:
	_ui = ui


## B4: 递进式刷新费用 — 第 1 次 $3，之后 +$1/次
func _get_reroll_cost() -> int:
	return 3 + _reroll_count


func go_shop_pressed() -> void:
	## Phase C: In-scene shop overlay entry (no scene switch).
	## Phase E: No full game_layout fade — LeftPanel + NinjaBar stay visible.
	if _transition_guard:
		return
	_transition_guard = true
	GlobalTweens.play_sfx(SB.SHOP_EXIT)

	# Prepare shop data before transition
	var shop_mgr := ShopManager.new()
	shop_mgr.generate_stock()
	_shop_cache = {
		"mgr": shop_mgr,
		"gold": NinKingGameState.gold,
		"colors": BarrierTheme.get_colors(NinKingGameState.barrier_num),
	}

	# Keep LeftPanel + NinjaBar visible — only dim hand/dun play area
	# Shop panel starts at x:420, left column stays uncovered.
	if _ui.game_layout.has_node("CenterColumn/HandArea"):
		_ui.game_layout.get_node("CenterColumn/HandArea").modulate.a = 0.0

	# Transition to SHOP
	SealController.go_to_shop(NinKingGameState)
	_transition_guard = false


func on_enter_shop() -> void:
	## Called from game_manager's _on_state_changed when SHOP state is entered.
	_reroll_count = 0  # B4: 重置刷新次数
	var s_data: Dictionary = _shop_cache
	_ui.show_shop(s_data.get("mgr"), s_data.get("gold", 0), s_data.get("colors", {}))
	_ui.shop_panel_update_reroll_cost(_get_reroll_cost())  # B4: 通知 UI 当前刷新价格


func on_purchase_requested(ability: Dictionary) -> void:
	if NinKingGameState.owned_ninjas.size() >= NinKingGameState.max_ninja_slots:
		ToastManager.show(
			"忍者牌槽位已满 (%d/%d)!" % [NinKingGameState.max_ninja_slots, NinKingGameState.max_ninja_slots],
			2.0
		)
		return
	if ShopManager.buy_ninja(NinKingGameState, ability):
		GlobalTweens.play_sfx(SB.ITEM_PURCHASE)
		GlobalTweens.play_sfx(SB.UI_COIN)
		_ui.shop_panel_update_gold(NinKingGameState.gold)
		# Find the actual ninja slot node (filter out NinjaBarNode which is a plain Node)
		var all_children := _ui.ninja_bar_container.get_children()
		var ninja_slots: Array[Node] = []
		for c: Node in all_children:
			if c is NinjaSlotNode:
				ninja_slots.append(c)
		if ninja_slots.size() > 0:
			NinKingTween.play_ninja_pop_in(ninja_slots[-1] as CanvasItem)
		ToastManager.show("获得: %s!" % ability.get("name", "???"), 1.5)
	else:
		ToastManager.show("金币不足!", 1.5)


func on_item_purchase_requested(item: Dictionary) -> void:
	# B6: Star charts — buy and auto-apply (consumed on purchase, not stored)
	if item.has("hand_type"):
		_purchase_star_chart(item)
		return

	if ShopManager.buy_item(NinKingGameState, item):
		GlobalTweens.play_sfx(SB.ITEM_PURCHASE)
		GlobalTweens.play_sfx(SB.UI_COIN)
		_ui.shop_panel_update_gold(NinKingGameState.gold)
		ToastManager.show("获得: %s!" % item.get("name", "???"), 1.5)
	else:
		ToastManager.show("金币不足!", 1.5)


# ═══ B6: 星图卡 — 购买即升级（不存入背包）═══

func _purchase_star_chart(item: Dictionary) -> void:
	var cost: int = item.get("cost", 3)
	if NinKingGameState.gold < cost:
		ToastManager.show("金币不足!", 1.5)
		return

	var hand_type: int = item["hand_type"]
	var old_level: int = NinKingGameState.star_chart_levels.get(hand_type, 0)

	# Deduct gold
	NinKingGameState.gold -= cost
	NinKingGameState.gold_changed.emit(NinKingGameState.gold)
	GlobalTweens.play_sfx(SB.ITEM_PURCHASE)
	GlobalTweens.play_sfx(SB.UI_COIN)

	# Apply upgrade (increments level + triggers auto_arrange if in PLAYING)
	ShopManager.apply_star_chart(NinKingGameState, hand_type)

	# Update gold in UI
	_ui.shop_panel_update_gold(NinKingGameState.gold)

	# Mark card as purchased in the shop panel (greys out + disables)
	_ui.shop_panel_mark_item_purchased(item.get("id", ""))

	# Toast with hand type name + level info
	var hand_name: String = CardData.get_hand_type3_name(hand_type as CardData.HandType3)
	ToastManager.show("%s Lv.%d -> Lv.%d!" % [hand_name, old_level, old_level + 1], 2.0)

	# VFX: Manga burst at viewport center
	var vp_size: Vector2 = _ui.get_viewport_rect().size
	GlobalTweens.burst_particles(vp_size * 0.5, "manga_burst")


func on_reroll_requested() -> void:
	## B4: 递进式费用 $3 + _reroll_count。不够钱时给 Toast 提示。
	var cost: int = _get_reroll_cost()
	if NinKingGameState.gold < cost:
		ToastManager.show("需要 $%d 才能刷新!" % cost, 1.5)
		return
	NinKingGameState.gold -= cost
	_reroll_count += 1
	NinKingGameState.gold_changed.emit(NinKingGameState.gold)
	GlobalTweens.play_sfx(SB.SHOP_REROLL)

	if not _ui.is_shop_open():
		return
	_ui.shop_panel_update_gold(NinKingGameState.gold)
	_ui.shop_panel_update_reroll_cost(_get_reroll_cost())  # B4: 更新 UI 显示新价格

	var panel := _ui.get_current_shop_panel()
	if panel and is_instance_valid(panel):
		var old_cards: Array = panel.get_all_cards()
		var shop_mgr: ShopManager = _shop_cache.get("mgr")
		if shop_mgr:
			shop_mgr.generate_stock()
		await NinKingTween.play_reroll_vfx(old_cards, func():
			_ui.shop_panel_refresh_stock()
			return panel.get_all_cards() if is_instance_valid(panel) else []
		)


func on_continue_requested() -> void:
	## Phase C: Exit shop overlay -> advance to next seal (no scene switch).
	if _transition_guard:
		return
	_transition_guard = true

	if _ui.is_shop_open():
		await _ui.hide_shop()

	MusicManager.set_game_variation(NinKingGameState.barrier_num)
	SealController.continue_from_shop(NinKingGameState)
	_transition_guard = false
