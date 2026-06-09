@tool
extends CardFactory
class_name NinKingCardFactory

## Minimal factory placeholder — cards are created directly in UIManager.
## Exists only to satisfy CardManager's card_factory_scene requirement.

func create_card(_card_name: String, _target: CardContainer) -> Card:
	# Cards are created by UIManager via direct instantiation of ninking_card.tscn
	return null

func preload_card_data() -> void:
	# No preloading needed — NinKing uses procedural textures, not image assets
	pass
