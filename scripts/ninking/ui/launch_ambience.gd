class_name LaunchAmbience
extends RefCounted

## Ambient effects for the Launch/MainMenu scene.
## Background slow breathing + sakura particle bursts.
## Extracted from main_menu.gd to keep file under 300 lines.

var _parent: Node
var _bg: TextureRect
var _bg_breath_tween: Tween
var _ambient_timer: Timer
var _particle_layer: CanvasLayer
var _sakura_tex: ImageTexture


func setup(parent: Node, bg: TextureRect) -> void:
	_parent = parent
	_bg = bg


func start() -> void:
	# ── Background slow breathing: scale 1.0↔1.04, 14s cycle ──
	_bg.pivot_offset = _bg.size * 0.5
	_bg_breath_tween = _bg.create_tween()
	_bg_breath_tween.set_loops()
	_bg_breath_tween.tween_property(_bg, "scale", Vector2(1.04, 1.04), 7.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bg_breath_tween.tween_property(_bg, "scale", Vector2(1.0, 1.0), 7.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# ── Particle CanvasLayer (layer 128 — above everything) ──
	_particle_layer = CanvasLayer.new()
	_particle_layer.name = "ParticleLayer"
	_particle_layer.layer = 128
	_parent.add_child(_particle_layer)

	# ── Cache sakura texture once ──
	_sakura_tex = _make_sakura_tex()

	# ── Ambient sakura petals: local burst, Timer-driven ──
	_ambient_timer = Timer.new()
	_ambient_timer.name = "AmbientTimer"
	_ambient_timer.wait_time = randf_range(1.0, 2.0)
	_ambient_timer.timeout.connect(_on_ambient_tick)
	_particle_layer.add_child(_ambient_timer)
	_ambient_timer.start()


func _on_ambient_tick() -> void:
	var vp: Rect2 = _bg.get_viewport().get_visible_rect()
	var pos := Vector2(randf_range(0.0, vp.size.x), randf_range(0.0, vp.size.y * 0.4))
	_spawn_sakura_burst(pos)
	_ambient_timer.wait_time = randf_range(1.0, 2.0)


## Spawn a one-shot sakura particle burst at the given position.
func _spawn_sakura_burst(at: Vector2) -> void:
	const SAKURA_LIFETIME: float = 3.0
	const SAKURA_AMOUNT: int = 40
	const SAKURA_SPREAD: float = 120.0
	const SAKURA_COLOR := Color(1.0, 0.7, 0.8, 1.0)

	var p := CPUParticles2D.new()
	p.texture = _sakura_tex
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = SAKURA_AMOUNT
	p.lifetime = SAKURA_LIFETIME
	p.spread = SAKURA_SPREAD
	p.direction = Vector2(0, -1)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.damping_min = 2.0
	p.damping_max = 4.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.modulate = SAKURA_COLOR
	p.position = at
	p.finished.connect(p.queue_free)
	_particle_layer.add_child(p)
	p.emitting = true


func _make_sakura_tex() -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		for x in range(8):
			var d := Vector2(float(x) - 3.5, float(y) - 3.5).length() / 3.5
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)
