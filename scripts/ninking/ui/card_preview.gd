extends Control

func _ready() -> void:
	# Full-screen background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 1)
	bg.size = get_viewport_rect().size
	add_child(bg)

	# Sample ninja data
	var sample_data: Dictionary = {
		"id": "ninja_sample",
		"name": "疾风",
		"rarity": "rare",
		"cost": 7,
		"effect_desc": "头墩 +2 分",
		"condition_desc": "头墩有对子",
	}

	# Instantiate ability card
	var card := preload("res://scenes/ninking/shop_ability_card.tscn").instantiate()
	add_child(card)
	card.setup(sample_data)
	card.apply_barrier_theme({
		"bg": Color(0.08, 0.08, 0.12),
		"panel": Color(0.12, 0.12, 0.2),
		"accent": Color(0.831, 0.659, 0.263),
		"name": Color(0.9, 0.9, 0.85),
		"particle_color": Color(0.831, 0.659, 0.263),
	})

	# Center on screen
	card.position = Vector2(
		(get_viewport_rect().size.x - card.size.x) / 2,
		(get_viewport_rect().size.y - card.size.y) / 2
	)
