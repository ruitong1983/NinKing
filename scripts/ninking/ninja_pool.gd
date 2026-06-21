class_name NinjaPool
extends RefCounted

## Random ninja generation for 萬屋 and special drops.
## Extracted from NinjaData. References NinjaData.ALL_NINJAS for the card pool.


## Get random ninjas for 萬屋 display
## @param count: number to pick
## @param exclude_ids: IDs already owned (to avoid duplicates)
## @param rarity_filter: optional rarity filter ("common", "uncommon", "rare")
static func get_random_ninjas(count: int, exclude_ids: Array = [], rarity_filter: String = "") -> Array[Dictionary]:
	var pool: Array[Dictionary] = NinjaData.ALL_NINJAS.duplicate(true)

	# Filter out deferred cards (not yet active)
	pool = pool.filter(func(n: Dictionary) -> bool: return not n.get("deferred", false))

	# Filter out already-owned
	if not exclude_ids.is_empty():
		var filtered: Array[Dictionary] = []
		for ninja: Dictionary in pool:
			if not exclude_ids.has(ninja["id"]):
				filtered.append(ninja)
		pool = filtered

	# Filter mutex groups
	for ninja: Dictionary in NinjaData.ALL_NINJAS:
		if exclude_ids.has(ninja["id"]) and ninja.has("mutex_group"):
			var mutex: String = ninja["mutex_group"]
			pool = pool.filter(func(n: Dictionary) -> bool:
				return not n.has("mutex_group") or n["mutex_group"] != mutex
			)

	# Filter legendary (not sold in 萬屋)
	pool = pool.filter(func(n: Dictionary) -> bool: return n["rarity"] != "legendary")

	# Rarity filter
	if rarity_filter != "":
		pool = pool.filter(func(n: Dictionary) -> bool: return n["rarity"] == rarity_filter)

	pool.shuffle()
	var result: Array[Dictionary] = []
	for i: int in range(min(count, pool.size())):
		result.append(pool[i])
	return result


## Get a random legendary ninja (for special drops)
static func get_random_legendary() -> Dictionary:
	var legends: Array[Dictionary] = []
	for ninja: Dictionary in NinjaData.ALL_NINJAS:
		if ninja["rarity"] == "legendary":
			legends.append(ninja)
	legends.shuffle()
	return legends[0] if not legends.is_empty() else {}
