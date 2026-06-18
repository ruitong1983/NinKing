extends RefCounted

## ⚠️ 无 class_name — 通过 preload("res://scripts/ninking/logging/game_logger.gd") 引用。
##   调用方必须定义 const GameRunLogger = preload("...game_logger.gd") 后再使用 GameRunLogger.xxx()。

## 游戏回放日志系统 — 记录每次 run 的操作序列用于 Bug 复现。
##
## 全部静态方法，可通过 GameLogger.xxx() 全局调用。
## 一个 run 一个 JSON 文件，存到 user://logs/ 下，永不自动删除。
##
## 使用方式：
##   GameLogger.start_run(deck_name)
##   GameLogger.on_run_started(deck_name, starting_gold)
##   GameLogger.on_seal_started(barrier, seal_idx, target, lord_name)
##   ...

# ──────────────────────────── 配置 ────────────────────────────

## 日志总开关
static var enabled: bool = true

# ──────────────────────────── 内部状态（类级变量） ────────────────────────────

static var _entries: Array[Dictionary] = []
static var _seq: int = 0
static var _run_started: bool = false
static var _run_id: String = ""
static var _start_time: float = 0.0
static var _file_path: String = ""

# ──────────────────────────── 常量 ────────────────────────────

const LOG_DIR: String = "user://logs/"


# ════════════════════════════════════════════════════════════
# Run 生命周期
# ════════════════════════════════════════════════════════════

static func start_run(p_deck_name: String) -> void:
	if not enabled:
		return
	_entries.clear()
	_seq = 0
	_run_started = true
	_run_id = _generate_run_id()
	_start_time = Time.get_unix_time_from_system()

	# 确保 logs 目录存在
	var dir: DirAccess = DirAccess.open("user://")
	if dir and not dir.dir_exists("logs"):
		dir.make_dir("logs")

	_file_path = ""

	# ── 输出窗口提醒 ──
	var logs_dir: String = OS.get_user_data_dir().path_join("logs")
	var viewer_path: String = "docs/ninking/ninja-game-replay.html"
	print("")
	print("╔══════════════════════════════════════════════════════╗")
	print("║          📝 GameLogger 日志已启动                   ║")
	print("╠══════════════════════════════════════════════════════╣")
	print("║  日志 ID:   %s" % _run_id)
	print("║  牌组:      %s" % p_deck_name)
	print("║  保存目录:  %s" % logs_dir)
	print("║  文件名:    {时间}_{结果}_{ID}.json")
	print("╠══════════════════════════════════════════════════════╣")
	print("║  ▶ 回放查看: 用浏览器打开项目目录下的               ║")
	print("║    %s" % viewer_path)
	print("║    拖入日志 JSON 文件即可回放                       ║")
	print("╚══════════════════════════════════════════════════════╝")
	print("")


static func _generate_run_id() -> String:
	return Time.get_datetime_string_from_system(true).replace(":", "-").replace("T", "_")


# ════════════════════════════════════════════════════════════
# 公共 API — 事件记录
# ════════════════════════════════════════════════════════════

## 1) run_started — 新游戏开始
static func on_run_started(deck_name: String, starting_gold: int, starting_ninjas: Array = []) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("run_started", {
		"deck_name": deck_name,
		"starting_gold": starting_gold,
		"starting_ninjas": _serialize_ninjas(starting_ninjas),
	}, _build_full_gs_snapshot())


## 2) seal_started — 进入新封印
static func on_seal_started(barrier_num: int, seal_idx: int, target_score: int, seal_lord_name: String) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("seal_started", {
		"barrier_num": barrier_num,
		"seal_idx": seal_idx,
		"target_score": target_score,
		"seal_lord_name": seal_lord_name,
	}, _build_full_gs_snapshot())


## 3) cards_dealt — 发牌（每次出牌前发9张）
static func on_cards_dealt(hand: Array) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("cards_dealt", {
		"hand": _serialize_hand(hand),
	})


## 4) auto_arranged — AI 自动重排
static func on_auto_arranged(old_hand: Array, new_hand: Array) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("auto_arranged", {
		"old_hand": _serialize_hand(old_hand),
		"new_hand": _serialize_hand(new_hand),
		"arrangement": _serialize_arrangement(new_hand),
	})


## 5) card_swapped — 交换两张牌的位置
static func on_card_swapped(idx1: int, idx2: int, hand_after: Array) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("card_swapped", {
		"idx1": idx1,
		"idx2": idx2,
		"hand_after": _serialize_hand(hand_after),
	})


## 6) play_prepared — 出牌计分计算完成（动画前）
static func on_play_prepared(play_data: Dictionary) -> void:
	if not enabled or not _run_started:
		return
	var score_result = play_data.get("score_result")
	var xi_result = play_data.get("xi_result")
	var arr = play_data.get("current_arrangement", {})

	# ── 触发的忍者牌 ──
	var summary: Dictionary = play_data.get("summary", {})
	var triggered_ids: Array = summary.get("triggered_ids", [])
	var owned_ninjas: Array = play_data.get("owned_ninjas", [])
	var ninja_triggers: Array[Dictionary] = []
	for tid: String in triggered_ids:
		var nname: String = ""
		for n: Dictionary in owned_ninjas:
			if n.get("id", "") == tid:
				nname = n.get("name", "?")
				break
		ninja_triggers.append({
			"id": tid,
			"name": nname,
		})

	_add_entry("play_prepared", {
		"score_detail": {
			"total_score": score_result.total_score if score_result else 0,
			"head_score": score_result.head_score if score_result else 0,
			"mid_score": score_result.mid_score if score_result else 0,
			"tail_score": score_result.tail_score if score_result else 0,
			"head_type": CardData.get_hand_type3_name(arr.get("head_eval", {}).hand_type) if arr.get("head_eval") else "",
			"mid_type": CardData.get_hand_type3_name(arr.get("mid_eval", {}).hand_type) if arr.get("mid_eval") else "",
			"tail_type": CardData.get_hand_type3_name(arr.get("tail_eval", {}).hand_type) if arr.get("tail_eval") else "",
		},
		"xi_triggered": xi_result.triggered if xi_result and xi_result.has_any() else [],
		"arrangement": {
			"head": _serialize_group(arr.get("head", [])),
			"mid": _serialize_group(arr.get("mid", [])),
			"tail": _serialize_group(arr.get("tail", [])),
		},
		"ninja_triggers": ninja_triggers,
	})


## 7) play_executed — 出牌完成（状态变更后）
static func on_play_executed(score_gained: int, plays_left: int, new_hand: Array) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("play_executed", {
		"score_gained": score_gained,
		"plays_left": plays_left,
		"new_hand": _serialize_hand(new_hand),
	}, _build_delta_gs_snapshot())


## 8) seal_completed — 封印通关
static func on_seal_completed(final_score: int, gold_earned: int, interest: int) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("seal_completed", {
		"final_score": final_score,
		"gold_earned": gold_earned,
		"interest": interest,
	}, _build_full_gs_snapshot())


## 9) shop_entered — 进入商店
static func on_shop_entered(gold: int, barrier_num: int, seal_idx: int) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("shop_entered", {
		"gold": gold,
		"barrier_num": barrier_num,
		"seal_idx": seal_idx,
	})


## 10) ninja_acquired — 获得忍者
static func on_ninja_acquired(ninja: Dictionary, source: String) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("ninja_acquired", {
		"ninja": _serialize_ninja(ninja),
		"source": source,
	})


## 11) item_purchased — 购买道具
static func on_item_purchased(item: Dictionary, cost: int) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("item_purchased", {
		"item": item.duplicate(),
		"cost": cost,
	})


## 12) game_over — 游戏结束（失败）
static func on_game_over(barrier_num: int, seal_idx: int, score: int, reason: String = "") -> void:
	if not enabled or not _run_started:
		return
	_add_entry("game_over", {
		"barrier_num": barrier_num,
		"seal_idx": seal_idx,
		"final_score": score,
		"reason": reason,
	}, _build_full_gs_snapshot())
	_finalize_run("game_over")


## 13) victory — 通关胜利
static func on_victory(barrier_num: int, total_score: int) -> void:
	if not enabled or not _run_started:
		return
	_add_entry("victory", {
		"barrier_num": barrier_num,
		"total_score": total_score,
	}, _build_full_gs_snapshot())
	_finalize_run("victory")


## 通用自定义事件（未被 13 种覆盖的场合用此兜底）
static func on_custom_event(event_name: String, detail: Dictionary = {}, snapshot: Dictionary = {}) -> void:
	if not enabled or not _run_started:
		return
	_add_entry(event_name, detail, snapshot)


# ════════════════════════════════════════════════════════════
# 内部逻辑
# ════════════════════════════════════════════════════════════

static func _add_entry(event: String, detail: Dictionary, snapshot: Dictionary = {}) -> void:
	_seq += 1
	var entry: Dictionary = {
		"ts": Time.get_unix_time_from_system(),
		"seq": _seq,
		"event": event,
		"elapsed_ms": int((Time.get_unix_time_from_system() - _start_time) * 1000),
		"detail": detail,
	}
	if not snapshot.is_empty():
		entry["gs"] = snapshot
	_entries.append(entry)


## 完整 GS 快照（用于 seal_started / game_over / victory 等关键节点）
static func _build_full_gs_snapshot() -> Dictionary:
	return {
		"barrier_num": NinKingGameState.barrier_num,
		"seal_idx": NinKingGameState.seal_idx,
		"current_score": NinKingGameState.current_score,
		"target_score": NinKingGameState.target_score,
		"plays_remaining": NinKingGameState.plays_remaining,
		"gold": NinKingGameState.gold,
		"current_deck_name": NinKingGameState.current_deck_name,
		"current_seal_lord_name": NinKingGameState.current_seal_lord_name,
		"hand": _serialize_hand(NinKingGameState.hand),
		"ninja_count": NinKingGameState.owned_ninjas.size(),
		"ninjas": _serialize_ninjas(NinKingGameState.owned_ninjas),
		"star_chart_levels": NinKingGameState.star_chart_levels.duplicate(),
	}


## 增量 GS 快照（只记变化高频字段，用于 play_executed 等）
static func _build_delta_gs_snapshot() -> Dictionary:
	return {
		"current_score": NinKingGameState.current_score,
		"target_score": NinKingGameState.target_score,
		"plays_remaining": NinKingGameState.plays_remaining,
		"gold": NinKingGameState.gold,
		"hand": _serialize_hand(NinKingGameState.hand),
	}


## 写入文件并重置
static func _finalize_run(outcome: String) -> void:
	var run_data: Dictionary = {
		"run_id": _run_id,
		"version": "1.0",
		"started_at": _start_time,
		"ended_at": Time.get_unix_time_from_system(),
		"outcome": outcome,
		"deck_name": NinKingGameState.current_deck_name,
		"entries": _entries,
	}

	var timestamp: String = Time.get_datetime_string_from_system(true).replace(":", "-").replace("T", "_")
	var filename: String = "%s_%s_%s.json" % [timestamp, outcome, _run_id]
	_file_path = LOG_DIR + filename

	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		push_error("GameLogger: Failed to write %s" % _file_path)
		_reset()
		return

	file.store_string(JSON.stringify(run_data, "\t"))
	file.close()

	print("📝 GameLogger: 日志已写入 → %s (共 %d 条事件)" % [_file_path, _entries.size()])
	_reset()


static func _reset() -> void:
	_entries.clear()
	_seq = 0
	_run_started = false
	_run_id = ""
	_start_time = 0.0


# ════════════════════════════════════════════════════════════
# 序列化辅助
# ════════════════════════════════════════════════════════════

## 单张牌 → Dictionary
static func _serialize_card(card: CardData.PlayingCard) -> Dictionary:
	if card == null:
		return {}
	var card_dict: Dictionary = {
		"suit": CardData.SUIT_NAMES.get(card.suit, "?"),
		"rank": CardData.RANK_NAMES.get(card.rank, "?"),
		"display": card.get_display_name(),
	}
	if card.enhancement != CardData.Enhancement.NONE:
		card_dict["enhancement"] = CardData.ENHANCEMENT_SHORT_NAMES.get(card.enhancement, "?")
	if card.seal != CardData.Seal.NONE:
		card_dict["seal"] = card.seal
	if card.edition != CardData.Edition.NONE:
		card_dict["edition"] = card.edition
	return card_dict


## 一组 3 张牌
static func _serialize_group(cards: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card: CardData.PlayingCard in cards:
		result.append(_serialize_card(card))
	return result


## 9 张手牌 = 3 组
static func _serialize_hand(hand: Array) -> Dictionary:
	return {
		"head": _serialize_group(hand.slice(0, 3)) if hand.size() >= 3 else [],
		"mid": _serialize_group(hand.slice(3, 6)) if hand.size() >= 6 else [],
		"tail": _serialize_group(hand.slice(6, 9)) if hand.size() >= 9 else [],
	}


## 从 9 张手牌提取排列信息
static func _serialize_arrangement(hand: Array) -> Dictionary:
	return _serialize_hand(hand)


## 单个忍者序列化
static func _serialize_ninja(ninja: Dictionary) -> Dictionary:
	if ninja.is_empty():
		return {}
	return {
		"id": ninja.get("id", ""),
		"name": ninja.get("name", "?"),
		"effect": ninja.get("effect", {}).duplicate(),
	}


## 忍者列表
static func _serialize_ninjas(ninjas: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for n: Dictionary in ninjas:
		result.append(_serialize_ninja(n))
	return result
