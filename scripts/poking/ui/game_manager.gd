extends Control

## Main game flow coordinator — UI operations delegated to UIManager.

@onready var ui: UIManager = %UIManager


func _ready() -> void:
	ui.start_button.pressed.connect(_on_start_pressed)
	ui.play_button.pressed.connect(_on_play_pressed)
	ui.swap_btn.pressed.connect(_on_swap_pressed)
	ui.to_shop_button.pressed.connect(_on_go_shop_pressed)
	ui.retry_button.pressed.connect(_on_retry_pressed)

	PokingGameState.state_changed.connect(_on_state_changed)
	PokingGameState.score_updated.connect(_on_score_updated)
	PokingGameState.swap_used.connect(_on_swap_used)
	PokingGameState.gold_changed.connect(_on_gold_changed)
	PokingGameState.hand_updated.connect(_on_hand_updated)
	PokingGameState.level_started.connect(_on_level_started)

	_on_state_changed(PokingGameState.current_state)
	if PokingGameState.current_state != PokingGameState.State.MAIN_MENU:
		ui.restore_ui_state()


# ── State callbacks ──

func _on_state_changed(new_state: PokingGameState.State) -> void:
	match new_state:
		PokingGameState.State.MAIN_MENU:
			ui.show_view("menu")
		PokingGameState.State.LEVEL_INTRO:
			ui.show_view("intro")
		PokingGameState.State.PLAYING:
			ui.show_view("game")
			ui.clear_selection()
			ui.refresh_hand(PokingGameState.hand)
			ui.refresh_jokers(PokingGameState.owned_jokers, PokingGameState.max_joker_slots)
			ui.status_label.text = ""
		PokingGameState.State.LEVEL_COMPLETE:
			ui.show_view("complete")
			ui.clear_selection()
			var cfg: Dictionary = LevelConfig.get_level(PokingGameState.level)
			ui.set_level_complete(cfg.get("gold_reward", 0))
		PokingGameState.State.GAME_OVER:
			ui.show_view("gameover")
			ui.clear_selection()


func _on_score_updated(current: int, target: int) -> void:
	ui.update_score(current, target)


func _on_swap_used(_used: int, remaining: int) -> void:
	ui.update_match_info(remaining, PokingGameState.level)


func _on_gold_changed(amount: int) -> void:
	ui.update_gold(amount)


func _on_hand_updated(_hand: Array) -> void:
	ui.clear_selection()
	ui.refresh_hand(PokingGameState.hand)


func _on_level_started(level_num: int, target: int) -> void:
	ui.on_level_start(level_num, target)


# ── Button handlers ──

func _on_start_pressed() -> void:
	PokingGameState.start_new_run()


func _on_swap_pressed() -> void:
	if ui.selected_indices.is_empty():
		return
	var to_swap: Array[int] = ui.selected_indices.duplicate()
	ui.clear_selection()
	PokingGameState.execute_swap(to_swap, [])
	ui.refresh_hand(PokingGameState.hand)


func _on_play_pressed() -> void:
	if ui.selected_indices.size() != 5:
		return
	var to_play: Array[int] = ui.selected_indices.duplicate()
	ui.clear_selection()
	PokingGameState.execute_swap(to_play, [])


func _on_go_shop_pressed() -> void:
	PokingGameState.go_to_shop()
	get_tree().change_scene_to_file("res://scenes/poking/shop.tscn")


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
