extends Control

func _ready() -> void:
	# Full-screen background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 1)
	bg.size = get_viewport_rect().size
	add_child(bg)

	# Sample ninja data — use real ID so image loads
	var sample_data: Dictionary = {
		"id": "n_001",
		"name": "手里剑",
		"rarity": "rare",
		"cost": 7,
		"desc": "头墩 +2 分",
		"condition_desc": "头墩有对子",
	}

	# Sample item data for star chart
	var item_data: Dictionary = {
		"id": "star_001",
		"name": "南斗六星·破军",
		"hand_type": 1,
		"cost": 5,
		"desc": "散牌 Lv.1",
	}

	var colors: Dictionary = {
		"bg": Color(0.08, 0.08, 0.12),
		"panel": Color(0.12, 0.12, 0.2),
		"accent": Color(0.831, 0.659, 0.263),
		"name": Color(0.9, 0.9, 0.85),
		"particle_color": Color(0.831, 0.659, 0.263),
	}

	# Instantiate ability card slot
	var slot := preload("res://scenes/ninking/shop_slot.tscn").instantiate()
	add_child(slot)
	slot.setup(sample_data)
	slot.apply_barrier_theme(colors)

	# Place ability slot on left
	var vsize := get_viewport_rect().size
	slot.position = Vector2(
		(vsize.x - (slot.size.x * 2 + 40)) / 2,
		(vsize.y - slot.size.y) / 2
	)

	# Instantiate item card slot (star chart)
	var item_slot := preload("res://scenes/ninking/shop_slot.tscn").instantiate()
	add_child(item_slot)
	item_slot.setup(item_data)
	item_slot.apply_barrier_theme(colors)

	# Place item slot to the right
	item_slot.position = Vector2(
		slot.position.x + slot.size.x + 40,
		(vsize.y - item_slot.size.y) / 2
	)
