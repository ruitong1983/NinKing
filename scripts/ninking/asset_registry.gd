class_name AssetRegistry
extends RefCounted
## 统一素材注册表 — 所有图标/底板路径映射的单一数据源。
##
## 消除 ninja_data.gd 和 consumable_data.gd 两处重复的路径硬编码。
## 新代码应直接引用 AssetRegistry，不再分别引用 NinjaData / ConsumableData 的图标方法。


# ═══ Rarity color constants ── single source of truth ═══
## Border/glow colors for StyleBoxFlat fallback when frame texture is not available.
const RARITY_BORDER_COLORS: Dictionary = {
	"common": Color(0.102, 0.102, 0.102),    # dark ink
	"uncommon": Color(0.831, 0.659, 0.263),   # gold
	"rare": Color(0.878, 0.251, 0.251),       # red
	"legendary": Color(1.0, 0.843, 0.0),      # gold bright
}
## Name/title colors for rarity text labels.
const RARITY_NAME_COLORS: Dictionary = {
	"common": Color("#888888"),
	"uncommon": Color("#4CAF50"),
	"rare": Color("#F44336"),
	"legendary": Color("#FFD700"),
}


# ═══ Ninja frame path ── rarity → frame file name ═══
const NINJA_FRAME_PATH: String = "res://assets/images/ninjas/frames/"

## Get the card frame texture path for a given rarity tier.
static func get_frame_path(rarity: String) -> String:
	return NINJA_FRAME_PATH + "ninja_frame_" + rarity + ".png"

## Load a frame texture for the given rarity, returns null on failure.
static func load_frame_texture(rarity: String) -> Texture2D:
	var path := get_frame_path(rarity)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# ═══ Ninja card path ── full card illustration ═══
const NINJA_CARD_PATH: String = "res://assets/images/cards/ninjas/"

## Get the full card illustration PNG path for a ninja by its ID.
static func get_ninja_card_path(ninja_id: String) -> String:
	return NINJA_CARD_PATH + ninja_id + ".png"


# ═══ Ninja icon path ── id prefix → icon file name ═══
# ⚠️ Order matters: more specific prefixes FIRST, catch-all "n_" LAST.
const NINJA_ICON_PATH: String = "res://assets/images/ninjas/icons/"
## Insertion order matters — generic "n_" must be last
const CATEGORY_ICONS: Dictionary = {
	"n_g": "icon_sword",  # 组别定向
	"n_r": "icon_seal",   # 规则变更
	"n_x": "icon_star",   # 喜之强化
	"n_s": "icon_scroll", # 成长修炼
	"n_e": "icon_coin",   # 经济
	"n_t": "icon_shield", # 忍法
	"n_l": "icon_crown",  # 传说
	"n_d": "icon_fire",   # 手替え激励
	"n_c": "icon_heart",  # 跨组联动
	"n_f": "icon_mult",   # 点数/人牌
	"n_": "icon_card",    # 通用加成 (catch-all — must be last!)
}


# ═══ Item icon / base plate mapping ── id prefix → asset info ═══
const ITEM_BASE_PATH: String = "res://assets/images/items/"
const ITEM_ICON_PATH: String = "res://assets/images/items/icons/"
const STAR_CHART_CARD_PATH: String = "res://assets/images/items/star_charts/"

## id prefix → { base, icon, category_name }
const ITEM_CATEGORY_MAP: Dictionary = {
	"enc_": { "base": "item_base_fujutsu", "icon": "icon_transform", "name": "符術" },
	"star_": { "base": "item_base_seiza",   "icon": "icon_constellation", "name": "星図" },
	"arc_": { "base": "item_base_kinjutsu", "icon": "icon_ritual", "name": "禁術" },
}


# ══════════════════════════════════════════
# Ninja icon path resolution
# ══════════════════════════════════════════

## Get icon path for a ninja by its ID prefix and optional effect dict.
## If effect is provided, sub-type icons are resolved (e.g. chips/mult/both for n_).
static func get_icon_path(ninja_id: String, effect: Dictionary = {}) -> String:
	var base_icon: String = ""
	for prefix: String in CATEGORY_ICONS:
		if ninja_id.begins_with(prefix):
			base_icon = CATEGORY_ICONS[prefix]
			break
	if base_icon.is_empty():
		base_icon = "icon_card"

	# Try sub-type suffix for effect-aware categories
	var sub_suffix: String = _get_effect_subtype_suffix(ninja_id, effect)
	if not sub_suffix.is_empty():
		var sub_path: String = NINJA_ICON_PATH + base_icon + "_" + sub_suffix + ".png"
		if ResourceLoader.exists(sub_path):
			return sub_path

	return NINJA_ICON_PATH + base_icon + ".png"


## Derive a sub-type icon suffix from effect keys for supported categories.
## Returns empty string to fall back to the base category icon.
## Current: n_ (通用加成) only — chips / mult / both suffixes.
static func _get_effect_subtype_suffix(ninja_id: String, effect: Dictionary) -> String:
	# Two-char prefixes (n_g, n_f, n_d, etc.) have a LETTER at index 2 → skip.
	# Only n_000 format IDs (index 2 is digit) get sub-type resolution.
	if ninja_id.length() < 3 or not ninja_id[2].is_valid_int():
		return ""

	var has_chips: bool = effect.has("add_chips")
	var has_mult: bool = effect.has("add_mult")
	if has_chips and has_mult:
		return "both"
	elif has_chips:
		return "chips"
	elif has_mult:
		return "mult"
	return ""


# ══════════════════════════════════════════
# Item asset path resolution
# ══════════════════════════════════════════

static func get_item_base_path(item_id: String) -> String:
	for prefix: String in ITEM_CATEGORY_MAP:
		if item_id.begins_with(prefix):
			return ITEM_BASE_PATH + ITEM_CATEGORY_MAP[prefix]["base"] + ".png"
	return ITEM_BASE_PATH + "item_base_fujutsu.png"


static func get_item_icon_path(item_id: String) -> String:
	for prefix: String in ITEM_CATEGORY_MAP:
		if item_id.begins_with(prefix):
			return ITEM_ICON_PATH + ITEM_CATEGORY_MAP[prefix]["icon"] + ".png"
	return ITEM_ICON_PATH + "icon_transform.png"


## Get the full star chart card illustration PNG path by its ID (e.g. "star_001").
static func get_star_chart_card_path(item_id: String) -> String:
	if not item_id.begins_with("star_"):
		return ""
	return STAR_CHART_CARD_PATH + item_id + ".png"
