class_name HandInteraction
extends RefCounted

## Delegates to HandCardContainer.set_cards_interactable().
## Click-based swap removed; drag-drop swap handled by HandCardContainer.move_cards().


func set_cards_interactable(card_grid: HandCardContainer, interactable: bool) -> void:
	card_grid.set_cards_interactable(interactable)
