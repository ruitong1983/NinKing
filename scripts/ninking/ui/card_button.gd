extends Button
## Card button used in the player's hand area (比鸡三墩).
## Supports swap and discard interactions.

enum CardState { NORMAL, SWAP_SOURCE, DISCARD_TARGET }

signal card_clicked(index: int)

var card_index: int = -1
var current_state: int = CardState.NORMAL

const COLOR_NORMAL: Color = Color.WHITE
const COLOR_SWAP_SOURCE: Color = Color(0.4, 0.6, 1.0)  # Blue glow
const COLOR_DISCARD: Color = Color(1.0, 0.3, 0.3)      # Red highlight


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(idx: int) -> void:
	card_index = idx


func set_card_state(state: int) -> void:
	current_state = state
	match state:
		CardState.NORMAL:
			modulate = COLOR_NORMAL
		CardState.SWAP_SOURCE:
			modulate = COLOR_SWAP_SOURCE
		CardState.DISCARD_TARGET:
			modulate = COLOR_DISCARD


func _on_pressed() -> void:
	card_clicked.emit(card_index)
