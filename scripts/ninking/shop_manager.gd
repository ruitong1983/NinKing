class_name ShopManager
extends RefCounted

const GameRunLogger = preload("res://scripts/ninking/logging/game_logger.gd")

## Manages the 萬屋 between seals.
## Phase D: fixed 4 ninjas + 2 items for all shop types.
## Also handles inventory operations (buy/apply) moved from NinKingGameState.




var available_ninjas: Array[Dictionary] = []
var available_star_charts: Array[Dictionary] = []


func generate_stock(_yasha_shop: bool = false, exclude_ninja_ids: Array = []) -> void:
	available_ninjas = NinjaPool.get_random_ninjas(ConfigManager.shop_ninja_count, exclude_ninja_ids)
	assert(available_ninjas.size() == ConfigManager.shop_ninja_count,
		"ShopManager: pool too small — need %d ninjas, got %d" % [ConfigManager.shop_ninja_count, available_ninjas.size()])

	available_star_charts = ConsumableData.get_random_star_charts(ConfigManager.shop_item_count)
	assert(available_star_charts.size() == ConfigManager.shop_item_count,
		"ShopManager: expected %d star charts, got %d" % [ConfigManager.shop_item_count, available_star_charts.size()])


func get_ninjas_for_display() -> Array[Dictionary]:
	return available_ninjas


func get_star_charts_for_display() -> Array[Dictionary]:
	return available_star_charts


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
	GameRunLogger.on_ninja_acquired(ninja, "shop")
	return true


static func buy_item(gs: Node, item: Dictionary) -> bool:
	if gs.gold < item["cost"]:
		return false
	gs.gold -= item["cost"]
	gs.gold_changed.emit(gs.gold)
	gs.owned_items.append(item.duplicate(true))
	GameRunLogger.on_item_purchased(item, item["cost"])
	return true


static func apply_star_chart(gs: Node, hand_type: int) -> void:
	gs.star_chart_levels[hand_type] = gs.star_chart_levels.get(hand_type, 0) + 1
	if gs.current_state == gs.State.PLAYING:
		gs.auto_arrange()
