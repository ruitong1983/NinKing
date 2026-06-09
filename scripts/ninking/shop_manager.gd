class_name ShopManager
extends RefCounted

## Manages the 萬屋 between seals.
## Shop types: Shura/Myouou 萬屋 (smaller) vs Yasha 萬屋 (larger).
## Also handles inventory operations (buy/sell/apply) moved from NinKingGameState.

const SHURA_SHOP_NINJA_COUNT: int = 2
const SHURA_SHOP_FUJUTSU_COUNT: int = 1
const SHURA_SHOP_STAR_COUNT: int = 1

const YASHA_SHOP_NINJA_COUNT: int = 3
const YASHA_SHOP_FUJUTSU_COUNT: int = 2
const YASHA_SHOP_STAR_COUNT: int = 2

var available_ninjas: Array[Dictionary] = []
var available_fujutsu: Array[Dictionary] = []
var available_star_charts: Array[Dictionary] = []
var available_kinjutsu: Array[Dictionary] = []
var is_yasha_shop: bool = false


func generate_stock(yasha_shop: bool = false, exclude_ninja_ids: Array = []) -> void:
	is_yasha_shop = yasha_shop

	var ninja_count: int = YASHA_SHOP_NINJA_COUNT if yasha_shop else SHURA_SHOP_NINJA_COUNT
	var fujutsu_count: int = YASHA_SHOP_FUJUTSU_COUNT if yasha_shop else SHURA_SHOP_FUJUTSU_COUNT
	var star_count: int = YASHA_SHOP_STAR_COUNT if yasha_shop else SHURA_SHOP_STAR_COUNT

	available_ninjas = NinjaPool.get_random_ninjas(ninja_count, exclude_ninja_ids)
	available_fujutsu = ConsumableData.get_random_fujutsu(fujutsu_count)
	available_star_charts = ConsumableData.get_random_star_charts(star_count)

	# 禁術 packs are rare — only in Yasha shops, 50% chance
	if yasha_shop and randf() < 0.5:
		available_kinjutsu = ConsumableData.get_random_kinjutsu(1)
	else:
		available_kinjutsu.clear()


func get_ninjas_for_display() -> Array[Dictionary]:
	return available_ninjas


func get_fujutsu_for_display() -> Array[Dictionary]:
	return available_fujutsu


func get_star_charts_for_display() -> Array[Dictionary]:
	return available_star_charts


func get_kinjutsu_for_display() -> Array[Dictionary]:
	return available_kinjutsu


# ══════════════════════════════════════════
# Inventory operations (moved from NinKingGameState)
# Use static methods taking NinKingGameState autoload to keep ShopManager decoupled.
# ══════════════════════════════════════════

static func buy_ninja(gs: Node, ninja: Dictionary) -> bool:
	if gs.owned_ninjas.size() >= gs.max_ninja_slots:
		return false
	if gs.gold < ninja["cost"]:
		return false
	gs.gold -= ninja["cost"]
	gs.gold_changed.emit(gs.gold)
	gs.owned_ninjas.append(ninja.duplicate(true))
	return true


static func sell_ninja(gs: Node, index: int) -> void:
	if index < 0 or index >= gs.owned_ninjas.size():
		return
	gs.owned_ninjas.remove_at(index)
	if gs.current_state == gs.State.PLAYING:
		gs.auto_arrange()


static func buy_item(gs: Node, item: Dictionary) -> bool:
	if gs.gold < item["cost"]:
		return false
	gs.gold -= item["cost"]
	gs.gold_changed.emit(gs.gold)
	gs.owned_items.append(item)
	return true


static func apply_star_chart(gs: Node, hand_type: int) -> void:
	gs.star_chart_levels[hand_type] = gs.star_chart_levels.get(hand_type, 0) + 1
	if gs.current_state == gs.State.PLAYING:
		gs.auto_arrange()
