extends Node

## Main game state autoload — manages the entire game lifecycle.

enum State {
	MAIN_MENU,
	LEVEL_INTRO,
	PLAYING,
	SCORING,
	LEVEL_COMPLETE,
	SHOP,
	GAME_OVER,
}

signal state_changed(new_state: State)
signal score_updated(current_score: int, target_score: int)
signal swap_used(used: int, remaining: int)
signal gold_changed(amount: int)
signal hand_updated(hand: Array)
signal level_started(level: int, target: int)

var current_state: State = State.MAIN_MENU
var level: int = 1
var target_score: int = 0
var current_score: int = 0
var gold: int = 10
var swaps_remaining: int = 5
var total_swaps: int = 5
var hand: Array[CardData.Card] = []
var owned_jokers: Array[Dictionary] = []
var owned_items: Array[Dictionary] = []
var max_joker_slots: int = 5
var deck_manager: DeckManager = null
var used_item_this_turn: Dictionary = {}


func _ready() -> void:
	deck_manager = DeckManager.new()


func start_new_run() -> void:
	level = 1
	gold = 10
	owned_jokers.clear()
	owned_items.clear()
	deck_manager = DeckManager.new()
	start_level()


func start_level() -> void:
	var cfg: Dictionary = LevelConfig.get_level(level)
	if cfg.is_empty():
		_transition_to(State.GAME_OVER)
		return

	target_score = cfg["target_score"]
	current_score = 0
	swaps_remaining = total_swaps

	deck_manager.reset()
	hand = deck_manager.draw(8)

	_transition_to(State.LEVEL_INTRO)
	level_started.emit(level, target_score)

	# Auto-transition to playing after a brief intro
	await get_tree().create_timer(2.0).timeout
	if current_state == State.LEVEL_INTRO:
		_transition_to(State.PLAYING)


func execute_swap(swap_indices: Array[int], fill_indices: Array[int]) -> void:
	if current_state != State.PLAYING:
		return
	if swaps_remaining <= 0:
		return
	if swap_indices.is_empty():
		return

	swaps_remaining -= 1
	swap_used.emit(total_swaps - swaps_remaining, swaps_remaining)

	# Both swap_indices and fill_indices refer to original hand positions
	var scored_cards: Array[CardData.Card] = []
	for i: int in swap_indices:
		scored_cards.append(hand[i])
	for i: int in fill_indices:
		scored_cards.append(hand[i])

	# Discard played cards
	deck_manager.discard(scored_cards)

	# Remove played cards from hand (reverse order to avoid index shift)
	var all_played: Array[int] = swap_indices + fill_indices
	all_played.sort()
	for i: int in range(all_played.size() - 1, -1, -1):
		hand.remove_at(all_played[i])

	# Calculate score
	var result: ScoreCalculator.ScoreResult = ScoreCalculator.calculate(scored_cards, owned_jokers)
	current_score += result.total_score
	score_updated.emit(current_score, target_score)

	# Draw new cards to refill hand to 8
	var to_draw: int = 8 - hand.size()
	var new_cards: Array[CardData.Card] = deck_manager.draw(to_draw)
	for c: CardData.Card in new_cards:
		hand.append(c)

	hand_updated.emit(hand)

	# Check win/lose
	if current_score >= target_score:
		complete_level()
	elif swaps_remaining <= 0:
		_transition_to(State.GAME_OVER)


func complete_level() -> void:
	var cfg: Dictionary = LevelConfig.get_level(level)
	gold += cfg["gold_reward"]
	gold_changed.emit(gold)

	if level >= LevelConfig.get_total_levels():
		_transition_to(State.GAME_OVER)
	else:
		_transition_to(State.LEVEL_COMPLETE)


func buy_joker(joker: Dictionary) -> bool:
	if owned_jokers.size() >= max_joker_slots:
		return false
	if gold < joker["cost"]:
		return false
	gold -= joker["cost"]
	gold_changed.emit(gold)
	owned_jokers.append(joker)
	return true


func buy_item(item: Dictionary) -> bool:
	if gold < item["cost"]:
		return false
	gold -= item["cost"]
	gold_changed.emit(gold)
	owned_items.append(item)
	return true


func use_item(item: Dictionary) -> bool:
	var idx: int = owned_items.find(item)
	if idx == -1:
		return false
	owned_items.remove_at(idx)
	used_item_this_turn = item
	return true


func next_level() -> void:
	level += 1
	start_level()


func go_to_shop() -> void:
	_transition_to(State.SHOP)


func continue_from_shop() -> void:
	next_level()


func get_hand_size() -> int:
	return hand.size()


func get_state() -> Dictionary:
	return {
		"level": level,
		"gold": gold,
		"owned_jokers": owned_jokers.duplicate(true),
		"owned_items": owned_items.duplicate(true),
	}


func _transition_to(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)
