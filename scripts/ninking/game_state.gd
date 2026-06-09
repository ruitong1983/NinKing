extends Node

## Core game state autoload — NinKing (忍者牌 × 比鸡).
## Barrier/Seal progression, 9-card hand → 3-group arrangement, scoring pipeline.

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
signal redraws_changed(remaining: int)

func emit_redraws_changed() -> void:
	redraws_changed.emit(redraws_remaining)
@warning_ignore("unused_signal")
signal gold_changed(amount: int)
signal hand_updated(hand: Array)           # 9 cards, arranged: [0-2]=head, [3-5]=mid, [6-8]=tail
signal arrangement_changed(arrangement: AutoArranger.Arrangement)
signal seal_started(barrier: int, seal_idx: int, target: int, seal_lord_name: String)
signal xi_triggered(xis: Array[String])

func emit_xi_triggered(xis: Array[String]) -> void:
	xi_triggered.emit(xis)

var current_state: State = State.MAIN_MENU

# Barrier/Seal tracking
var barrier_num: int = 1
var seal_idx: int = 0          # 0=修羅, 1=明王, 2=夜叉
var target_score: int = 0
var current_score: int = 0
var current_seal_lord_name: String = ""
var current_seal_lord_effects: Dictionary = {}

# Resources
var plays_remaining: int = 3
var redraws_remaining: int = 2
var gold: int = 8

# Hand & deck
var hand: Array[CardData.PlayingCard] = []             # 9 cards, arranged
var current_arrangement: AutoArranger.Arrangement = null
var current_col_evals: Array = []  # Array[HandEvaluator3.EvalResult], 3 elements or empty
var deck_manager: DeckManager = null
var current_deck_name: String = "standard"

# Player inventory
var owned_ninjas: Array[Dictionary] = []
var owned_items: Array[Dictionary] = []
var max_ninja_slots: int = 5
var star_chart_levels: Dictionary = {}   # { HandType3: int }

func _ready() -> void:
	deck_manager = DeckManager.new()
	_reset_star_chart_levels()


func _reset_star_chart_levels() -> void:
	star_chart_levels.clear()
	for ht: CardData.HandType3 in CardData.HandType3.values():
		star_chart_levels[ht] = 0


# ══════════════════════════════════════════
# Run lifecycle
# ══════════════════════════════════════════

func start_new_run(deck_name: String = "standard") -> void:
	SaveManager.delete_run()
	current_deck_name = deck_name
	barrier_num = 1
	seal_idx = 0
	gold = 8
	owned_ninjas.clear()
	owned_items.clear()
	_reset_star_chart_levels()
	deck_manager = DeckManager.new()
	_start_seal()


func _start_seal() -> void:
	var seal_cfg: Dictionary = BarrierConfig.get_seal(barrier_num, seal_idx)
	if seal_cfg.is_empty():
		_transition_to(State.VICTORY)
		return

	target_score = seal_cfg["target"]
	current_score = 0
	plays_remaining = 3
	redraws_remaining = 2

	# Seal Lord effects
	current_seal_lord_name = ""
	current_seal_lord_effects.clear()
	if seal_cfg.get("seal_lord", "") == "random":
		var lord: Dictionary = BarrierConfig.assign_seal_lord(barrier_num)
		current_seal_lord_name = lord["name"]
		current_seal_lord_effects = lord.get("effect", {}).duplicate()

	# Check if Seal Lord disables redraws
	if current_seal_lord_effects.get("no_redraw", false):
		redraws_remaining = 0

	# Check if Seal Lord changes constraint
	if current_seal_lord_effects.has("constraint"):
		pass  # handled by auto_arranger via scoring_rules

	# Apply Seal Lord ninja slot reduction
	if current_seal_lord_effects.has("ninja_slots_minus"):
		pass  # handled during scoring

	_begin_seal_phase()


# ══════════════════════════════════════════
# Auto-arrange (thin wrapper — logic in ArrangeController)
# ══════════════════════════════════════════

## Compute the best arrangement and emit signals.
## Called externally by SealController and ShopManager.
func auto_arrange() -> void:
	ArrangeController.auto_arrange(self)
	_recompute_col_evals()
	arrangement_changed.emit(current_arrangement)
	hand_updated.emit(hand)


## Re-evaluate the current manual arrangement without AI re-sorting.
## Preserves player's card positions, re-computes hand types and constraint.
func re_evaluate_arrangement() -> void:
	if hand.size() < 9:
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
	current_arrangement = AutoArranger.Arrangement.new(head_cards, mid_cards, tail_cards, he, me, te)
	_recompute_col_evals()
	arrangement_changed.emit(current_arrangement)
	hand_updated.emit(hand)


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
# Play / Redraw / Seal — delegated to SealController
# ══════════════════════════════════════════

func execute_play() -> void:
	SealController.execute_play(self)


func swap_cards(idx1: int, idx2: int) -> void:
	SealController.swap_cards(self, idx1, idx2)


func execute_redraw(indices: Array[int]) -> void:
	SealController.execute_redraw(self, indices)


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
	if not current_arrangement:
		return false
	return current_arrangement.is_legal()


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
	redraws_remaining = int(data.get("redraws_remaining", 2))
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

## Shared seal startup: reset deck → deal 9 → auto-arrange → checkpoint → emit signals → await intro.
## Called by _start_seal (fresh seal) and continue_run (resumed seal).
func _begin_seal_phase() -> void:
	deck_manager = DeckManager.new()
	deck_manager.reset()
	hand = deck_manager.draw(9)
	auto_arrange()

	# Checkpoint save after seal is fully set up
	SaveManager.save_run(SaveManager.build_run_data(self))

	_transition_to(State.SEAL_INTRO)
	seal_started.emit(barrier_num, seal_idx, target_score, current_seal_lord_name)

	await get_tree().create_timer(2.0).timeout
	if current_state == State.SEAL_INTRO:
		_transition_to(State.PLAYING)


func _transition_to(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)

	# Permanent death: record run result and delete checkpoint on terminal states
	if new_state == State.GAME_OVER:
		SaveManager.record_run_result(current_deck_name, barrier_num, false)
		SaveManager.delete_run()
	elif new_state == State.VICTORY:
		SaveManager.record_run_result(current_deck_name, barrier_num, true)
		SaveManager.delete_run()
