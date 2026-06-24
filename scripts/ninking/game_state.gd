extends Node

const GameRunLogger = preload("res://scripts/ninking/logging/game_logger.gd")

## Core game state autoload — NinKing (忍者牌 × 比鸡).
## Barrier/Seal progression, 9-card hand → 3-group arrangement, scoring pipeline.
## Also handles Clean (elimination) mode branching.

enum State {
	MAIN_MENU,
	SEAL_INTRO,
	PLAYING,
	SCORING,
	SEAL_COMPLETE,
	SHOP,
	GAME_OVER,
	VICTORY,
}

signal state_changed(new_state: State)
signal score_updated(current_score: int, target_score: int)

## Emit score_updated from within this class (called by SealController)
func emit_score_updated() -> void:
	score_updated.emit(current_score, target_score)
signal plays_changed(remaining: int)

func emit_plays_changed() -> void:
	plays_changed.emit(plays_remaining)
@warning_ignore("unused_signal")
signal gold_changed(amount: int)
signal hand_updated(hand: Array)           # 9 cards, arranged: [0-2]=head, [3-5]=mid, [6-8]=tail
@warning_ignore("unused_signal")
signal hand_swapped(src: int, tgt: int)     # two cards exchanged in-place — light UI refresh
signal seal_started(barrier: int, seal_idx: int, target: int, seal_lord_name: String)
signal xi_triggered(xis: Array[String])

func emit_xi_triggered(xis: Array[String]) -> void:
	xi_triggered.emit(xis)

signal swaps_changed(remaining: int)  # Clean mode only

func emit_swaps_changed() -> void:
	swaps_changed.emit(swaps_remaining)

var current_state: State = State.MAIN_MENU

# Barrier/Seal tracking
var barrier_num: int = 1
var seal_idx: int = 0          # 0=修羅(序), 1=明王(破), 2=夜叉(急)
var target_score: int = 0
var current_score: int = 0
var current_seal_lord_name: String = ""
var current_seal_lord_effects: Dictionary = {}

# Resources
var plays_remaining: int = 3
var swaps_remaining: int = 5  # Clean mode only
var gold: int = 8

# Hand & deck
var hand: Array[CardData.PlayingCard] = []             # 9 cards, arranged
var current_arrangement: Arrangement = null
var current_col_evals: Array = []  # Array[HandEvaluator3.EvalResult], 3 elements or empty
var deck_manager: DeckManager = null
var current_deck_name: String = "standard"
var game_mode: String = "bi_ji"  # "bi_ji"=比鸡模式, "clean"=消除模式

# Clean mode
var _cascading: bool = false  # Chain wave in progress — lock input

## Public setter for chain resolution lock (accessed from CleanChainHandler).
func set_cascading(value: bool) -> void:
	_cascading = value

# Player inventory
var owned_ninjas: Array[Dictionary] = []
var owned_items: Array[Dictionary] = []
var max_ninja_slots: int = 5
var star_chart_levels: Dictionary = {}   # { HandType3: int }

func _ready() -> void:
	deck_manager = DeckManager.new()
	_reset_star_chart_levels()
	max_ninja_slots = ConfigManager.max_ninja_slots


func _reset_star_chart_levels() -> void:
	star_chart_levels.clear()
	for ht: CardData.HandType3 in CardData.HandType3.values():
		star_chart_levels[ht] = 0


# ══════════════════════════════════════════
# Run lifecycle
# ══════════════════════════════════════════

func start_new_run(deck_name: String = "standard", mode: String = "bi_ji") -> void:
	SaveManager.delete_run()
	current_deck_name = deck_name
	game_mode = mode
	barrier_num = 1
	seal_idx = 0
	gold = ConfigManager.starting_gold
	owned_ninjas.clear()
	owned_items.clear()
	_reset_star_chart_levels()
	if game_mode != "clean":
		for id: String in ConfigManager.starter_ninja_ids:
			var ninja: Dictionary = NinjaData.get_by_id(id)
			if not ninja.is_empty():
				owned_ninjas.append(ninja.duplicate())
			else:
				push_warning("GameState: starter ninja '%s' not found in NinjaData" % id)
	deck_manager = DeckManager.new()
	GameRunLogger.start_run(deck_name)
	GameRunLogger.on_run_started(deck_name, gold)
	_start_seal()


func _start_seal() -> void:
	var seal_cfg: Dictionary = BarrierConfig.get_seal(barrier_num, seal_idx)
	if seal_cfg.is_empty():
		_transition_to(State.VICTORY)
		return

	target_score = BarrierConfig.get_clean_target(barrier_num, seal_idx) if game_mode == "clean" else seal_cfg["target"]
	current_score = 0
	plays_remaining = ConfigManager.plays_per_seal
	swaps_remaining = ConfigManager.clean_swaps_per_seal if game_mode == "clean" else 0
	_cascading = false

	if game_mode == "clean":
		# Clean mode: extra_plays → extra_swaps, only_one_play → only_one_swap
		for ninja: Dictionary in owned_ninjas:
			swaps_remaining += ninja.get("effect", {}).get("extra_plays", 0)
		swaps_remaining = maxi(swaps_remaining, 1)
		for ninja: Dictionary in owned_ninjas:
			if ninja.get("effect", {}).get("only_one_play", false):
				swaps_remaining = 1
				break
	else:
		# Bi-ji mode: standard play handling
		for ninja: Dictionary in owned_ninjas:
			plays_remaining += ninja.get("effect", {}).get("extra_plays", 0)
		plays_remaining = maxi(plays_remaining, 1)
		for ninja: Dictionary in owned_ninjas:
			if ninja.get("effect", {}).get("only_one_play", false):
				plays_remaining = 1
				break

	# Seal Lord effects
	current_seal_lord_name = ""
	current_seal_lord_effects.clear()
	if seal_cfg.get("seal_lord", "") == "random":
		var lord: Dictionary = BarrierConfig.assign_seal_lord(barrier_num)
		current_seal_lord_name = lord["name"]
		current_seal_lord_effects = lord.get("effect", {}).duplicate()

	# Apply Seal Lord clean-mode specific effects
	if game_mode == "clean":
		if current_seal_lord_effects.has("column_blocked") or current_seal_lord_effects.has("row_blocked"):
			pass  # consumed by CleanController/game_manager at scoring time
		if current_seal_lord_effects.has("max_chain"):
			pass  # consumed by CleanController during chain resolution

	# Check if Seal Lord changes constraint — used by is_constraint_satisfied()
	if current_seal_lord_effects.has("constraint"):
		pass  # stored in current_seal_lord_effects, read by is_constraint_satisfied()

	# Apply Seal Lord ninja slot reduction
	if current_seal_lord_effects.has("ninja_slots_minus"):
		pass  # handled during scoring

	_begin_seal_phase()


# ══════════════════════════════════════════
# Auto-arrange (bi_ji only — thin wrapper)
# ══════════════════════════════════════════

## Compute the best arrangement and emit signals.
## Called externally by SealController and ShopManager.
func auto_arrange() -> void:
	if game_mode == "clean":
		return
	var old_hand: Array = hand.duplicate()
	ArrangeController.auto_arrange(self)
	_recompute_col_evals()
	GameRunLogger.on_auto_arranged(old_hand, hand)
	hand_updated.emit(hand)


## Re-evaluate the current manual arrangement without AI re-sorting.
## Preserves player's card positions, re-computes hand types and constraint.
func re_evaluate_arrangement() -> void:
	if game_mode == "clean" or hand.size() < 9:
		return
	var head_cards: Array[CardData.PlayingCard] = []
	var mid_cards: Array[CardData.PlayingCard] = []
	var tail_cards: Array[CardData.PlayingCard] = []
	for i: int in range(3):
		head_cards.append(hand[i])
		mid_cards.append(hand[i + 3])
		tail_cards.append(hand[i + 6])
	var he: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(head_cards)
	var me: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(mid_cards)
	var te: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(tail_cards)
	current_arrangement = Arrangement.new(head_cards, mid_cards, tail_cards, he, me, te)
	_recompute_col_evals()


## Recompute column evaluations from current arrangement.
func _recompute_col_evals() -> void:
	current_col_evals.clear()
	if not current_arrangement:
		return
	var head: Array = current_arrangement.head
	var mid: Array = current_arrangement.mid
	var tail: Array = current_arrangement.tail
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [head[i], mid[i], tail[i]]
		current_col_evals.append(HandEvaluator3.evaluate(col_cards))


func get_scoring_rules() -> Dictionary:
	return ArrangeController.get_scoring_rules(self)


# ══════════════════════════════════════════
# Play / Seal — delegated to controllers
# ══════════════════════════════════════════

func execute_play() -> void:
	if game_mode == "clean":
		# Clean mode: no "play" action — swaps handle scoring
		return
	SealController.execute_play(self)


func swap_cards(idx1: int, idx2: int) -> void:
	if game_mode == "clean":
		if _cascading:
			return  # Locked during chain wave
		if current_state != State.PLAYING:
			return
		if CleanController.do_swap(self, idx1, idx2):
			# Signal handler (_on_hand_swapped in game_manager) will trigger
			# chain resolution if matches found.
			pass
	else:
		SealController.swap_cards(self, idx1, idx2)


func go_to_shop() -> void:
	SealController.go_to_shop(self)


func continue_from_shop() -> void:
	SealController.continue_from_shop(self)


func skip_seal(tag_reward: Dictionary) -> void:
	SealController.skip_seal(self, tag_reward)


# ══════════════════════════════════════════
# Queries
# ══════════════════════════════════════════

func get_head_cards() -> Array[CardData.PlayingCard]:
	if current_arrangement:
		return current_arrangement.head
	if hand.size() >= 3:
		var result: Array[CardData.PlayingCard] = []
		for i: int in range(3):
			result.append(hand[i])
		return result
	var empty: Array[CardData.PlayingCard] = []
	return empty


func get_mid_cards() -> Array[CardData.PlayingCard]:
	if current_arrangement:
		return current_arrangement.mid
	if hand.size() >= 6:
		var result: Array[CardData.PlayingCard] = []
		for i: int in range(3, 6):
			result.append(hand[i])
		return result
	var empty: Array[CardData.PlayingCard] = []
	return empty


func get_tail_cards() -> Array[CardData.PlayingCard]:
	if current_arrangement:
		return current_arrangement.tail
	if hand.size() >= 9:
		var result: Array[CardData.PlayingCard] = []
		for i: int in range(6, 9):
			result.append(hand[i])
		return result
	var empty: Array[CardData.PlayingCard] = []
	return empty


func is_constraint_satisfied() -> bool:
	if game_mode == "clean":
		# Clean mode has no ascending constraint — always satisfied
		return true
	if not current_arrangement:
		return false
	var c: String = current_seal_lord_effects.get("constraint", "ascending")
	return current_arrangement.is_legal(c)


# ══════════════════════════════════════════
# Save / Continue
# ══════════════════════════════════════════

## Check if a saved run exists (for "Continue" button visibility).
func has_saved_run() -> bool:
	return SaveManager.has_run_save()


## Continue a run from the last checkpoint save.
## Restores state and resumes at the start of the current seal.
func continue_run() -> void:
	var data: Dictionary = SaveManager.load_run()
	if data.is_empty():
		return

	barrier_num = int(data.get("barrier_num", 1))
	seal_idx = int(data.get("seal_idx", 0))
	current_score = int(data.get("current_score", 0))
	target_score = int(data.get("target_score", 0))
	plays_remaining = int(data.get("plays_remaining", 3))
	swaps_remaining = int(data.get("swaps_remaining", 0))
	gold = int(data.get("gold", 4))
	current_deck_name = data.get("current_deck_name", "standard")

	owned_ninjas = data.get("owned_ninjas", [])
	owned_items = data.get("owned_items", [])
	var saved_levels: Dictionary = data.get("star_chart_levels", {})
	_reset_star_chart_levels()  # ensures all HandType3 keys exist
	for ht: CardData.HandType3 in saved_levels:
		star_chart_levels[ht] = int(saved_levels.get(ht, 0))

	current_seal_lord_name = data.get("current_seal_lord_name", "")
	current_seal_lord_effects = data.get("current_seal_lord_effects", {})

	_begin_seal_phase()


# ══════════════════════════════════════════
# Internal
# ══════════════════════════════════════════

## Shared seal startup: reset deck → deal 9 → arrange/generate → checkpoint → emit → await intro.
## Called by _start_seal (fresh seal) and continue_run (resumed seal).
func _begin_seal_phase() -> void:
	GameRunLogger.on_seal_started(barrier_num, seal_idx, target_score, current_seal_lord_name)

	deck_manager = DeckManager.new()
	deck_manager.reset()

	if game_mode == "clean":
		# Clean mode: generate 3x3 grid with no pre-existing matches
		hand = CleanLayoutGenerator.generate(deck_manager)
		hand_updated.emit(hand)  # 🐛 critical: update card grid for level transitions (level 2+ was showing stale cards)
	else:
		# Bi-ji mode: draw 9 and auto-arrange into 3 groups
		hand = deck_manager.draw(9)
		auto_arrange()

	GameRunLogger.on_cards_dealt(hand)

	# Checkpoint save after seal is fully set up
	SaveManager.save_run(SaveManager.build_run_data(self))

	_transition_to(State.SEAL_INTRO)
	seal_started.emit(barrier_num, seal_idx, target_score, current_seal_lord_name)

	# NOTE: SEAL_INTRO → PLAYING timer moved to game_manager._ready()
	# because change_scene_to_file destroys timers on the old scene tree.


func _transition_to(new_state: State) -> void:
	current_state = new_state
	# Reset cascading lock when returning to PLAYING in clean mode
	if new_state == State.PLAYING and game_mode == "clean":
		_cascading = false
	state_changed.emit(new_state)

	# Permanent death: record run result and delete checkpoint on terminal states
	if new_state == State.GAME_OVER:
		GameRunLogger.on_game_over(barrier_num, seal_idx, current_score, "plays_depleted")
		SaveManager.record_run_result(current_deck_name, barrier_num, false)
		SaveManager.delete_run()
	elif new_state == State.VICTORY:
		GameRunLogger.on_victory(barrier_num, current_score)
		SaveManager.record_run_result(current_deck_name, barrier_num, true)
		SaveManager.delete_run()
