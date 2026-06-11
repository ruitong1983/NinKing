class_name BarrierConfig
extends RefCounted

## Barrier + Seal structure for NinKing (v3.3 — Plan C: column values reduced to ~1.8x,
## Barrier 1-3 targets raised, Barrier 6-8 targets lowered to match column contribution curve).
## 8 Barriers × 3 Seals (Shura / Myouou / Yasha) = 24 total seals.

enum SealType { SHURA, MYOUOU, YASHA }

const BARRIERS: Array[Dictionary] = [
	# 壱ノ結界
	{
		"barrier": 1,
		"seals": [
			{ "type": SealType.SHURA,   "target": 300,  "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 500,  "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 900,  "gold": 8, "seal_lord": "" },
		]
	},
	# 弐ノ結界
	{
		"barrier": 2,
		"seals": [
			{ "type": SealType.SHURA,   "target": 800,  "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 1300, "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 2200, "gold": 8, "seal_lord": "random" },
		]
	},
	# 参ノ結界
	{
		"barrier": 3,
		"seals": [
			{ "type": SealType.SHURA,   "target": 2200, "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 3200, "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 5500, "gold": 8, "seal_lord": "random" },
		]
	},
	# 肆ノ結界
	{
		"barrier": 4,
		"seals": [
			{ "type": SealType.SHURA,   "target": 5500,  "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 8000,  "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 14000, "gold": 8, "seal_lord": "random" },
		]
	},
	# 伍ノ結界
	{
		"barrier": 5,
		"seals": [
			{ "type": SealType.SHURA,   "target": 13000, "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 20000, "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 33000, "gold": 8, "seal_lord": "random" },
		]
	},
	# 陸ノ結界
	{
		"barrier": 6,
		"seals": [
			{ "type": SealType.SHURA,   "target": 28000, "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 40000, "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 65000, "gold": 8, "seal_lord": "random" },
		]
	},
	# 漆ノ結界
	{
		"barrier": 7,
		"seals": [
			{ "type": SealType.SHURA,   "target": 70000,  "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 95000,  "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 150000, "gold": 8, "seal_lord": "random" },
		]
	},
	# 捌ノ結界
	{
		"barrier": 8,
		"seals": [
			{ "type": SealType.SHURA,   "target": 150000, "gold": 3, "seal_lord": "" },
			{ "type": SealType.MYOUOU,  "target": 220000, "gold": 5, "seal_lord": "" },
			{ "type": SealType.YASHA,   "target": 380000, "gold": 8, "seal_lord": "random" },
		]
	},
]


## 10 Seal Lords (封印ノ主) (v3.1 — redesigned per grill session)
## Pool order reflects Barrier assignment:
##   0-1: 弐ノ結界  (断尾/无头)
##   2-3: 参ノ結界  (独柱/铁链)
##   4-6: 肆ノ結界  (反目/封印师/散牌王)
##   6-7: 伍ノ結界  (散牌王/饿鬼)
##   7-8: 陸ノ結界  (饿鬼/喜之克星)
##   8:   漆ノ結界  (喜之克星)
##   9:   捌ノ結界  (终焉)
const SEAL_LORD_POOL: Array[Dictionary] = [
	# 弐ノ結界
	{ "name": "断尾", "effect": {"skip_tail": true} },
	{ "name": "无头", "effect": {"skip_head": true} },
	# 参ノ結界
	{ "name": "独柱", "effect": {"skip_head": true, "skip_mid": true, "tail_x2": true} },
	# 肆ノ結界
	{ "name": "反目", "effect": {"constraint": "descending"} },
	{ "name": "封印师", "effect": {"lowest_group_zero": true} },
	# 肆-伍ノ結界
	{ "name": "散牌王", "effect": {"scatter_king": true} },
	# 伍-陸ノ結界
	{ "name": "饿鬼", "effect": {"hungry_ghost": true} },
	# 陸-漆ノ結界
	{ "name": "喜之克星", "effect": {"no_xi": true} },
	# 捌ノ結界
	{ "name": "终焉", "effect": {"no_xi": true} },
]


## Get a specific seal config
## @param barrier_num: 1-8
## @param seal_idx: 0 (Shura), 1 (Myouou), 2 (Yasha)
static func get_seal(barrier_num: int, seal_idx: int) -> Dictionary:
	var idx: int = barrier_num - 1
	if idx < 0 or idx >= BARRIERS.size():
		return {}
	var barrier: Dictionary = BARRIERS[idx]
	var seals: Array = barrier["seals"]
	if seal_idx < 0 or seal_idx >= seals.size():
		return {}
	return seals[seal_idx]


static func get_total_barriers() -> int:
	return BARRIERS.size()


static func get_seals_per_barrier() -> int:
	return 3


## Get total number of seals in the whole run
static func get_total_seals() -> int:
	return BARRIERS.size() * 3


## Assign a random seal lord to a Yasha seal from the appropriate pool
static func assign_seal_lord(barrier_num: int) -> Dictionary:
	var pool_start: int
	var pool_end: int

	match barrier_num:
		2:
			pool_start = 0; pool_end = 2    # 断尾, 无头
		3:
			pool_start = 2; pool_end = 4    # 独柱, 铁链
		4:
			pool_start = 4; pool_end = 7    # 反目, 封印师, 散牌王
		5:
			pool_start = 6; pool_end = 8    # 散牌王, 饿鬼
		6:
			pool_start = 7; pool_end = 9    # 饿鬼, 喜之克星
		7:
			pool_start = 8; pool_end = 9    # 喜之克星
		_:
			pool_start = 9; pool_end = 10   # 终焉

	var pool: Array[Dictionary] = SEAL_LORD_POOL.slice(pool_start, pool_end)
	pool.shuffle()
	return pool[0]
