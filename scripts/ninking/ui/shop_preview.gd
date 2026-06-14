extends Control

func _ready() -> void:
	# Full-screen background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 1)
	bg.size = get_viewport_rect().size
	add_child(bg)

	# Create stock directly (avoid ShopManager for now)
	var shop_mgr := ShopManager.new()

	# Minimal stock: just 2 ninjas
	var all_ninjas = NinjaData.ALL_NINJAS.duplicate()
	all_ninjas.shuffle()
	shop_mgr.available_ninjas = all_ninjas.slice(0, 2)

	# Barrier colors (barrier 1 = 修罗)
	var colors: Dictionary = BarrierTheme.get_colors(1)

	# Load, add to tree FIRST (so @onready vars init), then call init()
	var panel: ShopPanel = preload("res://scenes/ninking/shop_panel.tscn").instantiate()
	add_child(panel)
	panel.init(shop_mgr, 99, colors)
