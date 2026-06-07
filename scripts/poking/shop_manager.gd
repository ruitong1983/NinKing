class_name ShopManager
extends RefCounted

## Manages the shop between levels.

const SHOP_JOKER_COUNT: int = 3
const SHOP_ITEM_COUNT: int = 3

var available_jokers: Array[Dictionary] = []
var available_items: Array[Dictionary] = []


func generate_stock() -> void:
	available_jokers = JokerData.get_random_jokers(SHOP_JOKER_COUNT)
	available_items = ItemData.get_random_items(SHOP_ITEM_COUNT)


func get_jokers_for_display() -> Array[Dictionary]:
	return available_jokers


func get_items_for_display() -> Array[Dictionary]:
	return available_items
