class_name ShopSlot
extends Control
## Shop card slot — Kenney beige (暖纸风) card with click-to-reveal buy button.
##
## Root is a Control (not VBoxContainer), manually positioned:
##   NinjaCard (125x175) at y=0
##   BuyBtn    (125x40 ) at y=181 (175 height + 6px separation)
##
## Left-click card -> raise 30px + show BuyBtn below card.
## Click BuyBtn -> purchase_requested. Click card again / blank area -> reset.
##
## Interaction flow:
##   Card click -> card_raised(self) -> ShopPanel tracks _active_slot
##   BuyBtn press -> purchase_requested(data) (same as before)

# ═══ Signals ═══
signal purchase_requested(data: Dictionary)
signal card_raised(slot: ShopSlot)

# ═══ @onready references ═══
@onready var ninja_card: NinjaInventoryCard = $NinjaCard
@onready var buy_button: Button = $BuyBtn

# ═══ Constants ═══
const RAISE_Y: float = -30.0        ## Card lifts 30px when clicked
const LIFT_DURATION: float = 0.15
const RESET_DURATION: float = 0.12

# ═══ State ═══
var _data: Dictionary = {}
var _is_item: bool = false
var _is_purchased: bool = false
var _is_raised: bool = false
var _anim_guard: bool = false
var _lift_tween: Tween = null

# Sound
const SB = preload("res://scripts/config/sound_bank.gd")


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

func setup(data: Dictionary, is_ninja_bar_full: bool = false) -> void:
	_data = data
	_is_item = data.has("hand_type") or data.get("type") == "item"


	ninja_card.setup_shop(data)
	_load_illustration(data)

	_apply_card_style()
	_apply_purchase_button_style()
	_update_button_state()

	# ── Signal connections ──
	# Card left-click -> toggle raise/reset (not direct buy anymore)
	if ninja_card.card_clicked.is_connected(_on_card_clicked):
		ninja_card.card_clicked.disconnect(_on_card_clicked)
	ninja_card.card_clicked.connect(_on_card_clicked)

	# Buy button -> actual purchase
	if buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.disconnect(_on_buy_pressed)
	buy_button.pressed.connect(_on_buy_pressed)

	# Reset state
	_is_purchased = false
	_is_raised = false
	_anim_guard = false
	_kill_lift_tween()

	ninja_card.position.y = 0.0
	buy_button.visible = false
	visible = true


func set_purchased() -> void:
	_is_purchased = true
	GlobalTweens.kill_domain(buy_button, "modulate")
	visible = false


func get_card_id() -> String:
	return _data.get("id", "")


## Snap-reset without animation (used by ShopPanel on reroll/continue).
func reset_immediate() -> void:
	_kill_lift_tween()
	if _is_raised:
		_is_raised = false
		ninja_card.position.y = 0.0
		GlobalTweens.kill_domain(buy_button, "modulate")
		buy_button.visible = false
	_anim_guard = false


# ══════════════════════════════════════════
# Card click -> raise / reset toggle
# ══════════════════════════════════════════

func _on_card_clicked(_card_data: Dictionary) -> void:
	if _is_purchased or _anim_guard:
		return
	_anim_guard = true

	if not _is_raised:
		_do_raise()
	else:
		_do_reset()


func _do_raise() -> void:
	_is_raised = true
	buy_button.visible = true
	# 购买按钮统一入场动效（弹跳 + 粒子 + 脉冲 + hover + 点击）
	ButtonStyles.attach_entrance_animation(buy_button)

	_kill_lift_tween()
	_lift_tween = create_tween()
	_lift_tween.tween_property(ninja_card, "position:y", RAISE_Y, LIFT_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_lift_tween.tween_callback(func():
		_anim_guard = false
	)

	card_raised.emit(self)
	GlobalTweens.play_sfx(SB.SELECT)


func _do_reset() -> void:
	_is_raised = false

	_kill_lift_tween()
	_lift_tween = create_tween()
	_lift_tween.tween_property(ninja_card, "position:y", 0.0, RESET_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_lift_tween.tween_callback(func():
		GlobalTweens.kill_domain(buy_button, "modulate")
		buy_button.visible = false
		_anim_guard = false
	)


func _kill_lift_tween() -> void:
	if _lift_tween and _lift_tween.is_valid():
		_lift_tween.kill()
	_lift_tween = null


# ══════════════════════════════════════════
# Card style
# ══════════════════════════════════════════

func _apply_card_style() -> void:
	if ninja_card.has_method("apply_barrier_theme"):
		ninja_card.apply_barrier_theme({"panel": Color(0.961, 0.941, 0.910), "accent": Color(0.169, 0.118, 0.063)})

	if not _is_item:
		var r: String = _data.get("rarity", "common")
		ninja_card.set_frame(r)


# ══════════════════════════════════════════
# Purchase button — ButtonStyles Kenney square, brown
# ══════════════════════════════════════════

func _apply_purchase_button_style() -> void:
	ButtonStyles.apply_kenney_square(buy_button, "brown")

	# Disabled state: grey texture (ButtonStyles doesn't set disabled)
	var tex_grey: Texture2D = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonSquare_grey.png")
	var s_d := StyleBoxTexture.new()
	s_d.texture = tex_grey
	var PM: int = 8
	s_d.set("patch_margin_left", PM); s_d.set("patch_margin_top", PM); s_d.set("patch_margin_right", PM); s_d.set("patch_margin_bottom", PM)
	buy_button.add_theme_stylebox_override("disabled", s_d)
	buy_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))


func _update_button_state() -> void:
	var cost: int = _data.get("cost", 0)
	buy_button.text = "¥%d" % cost
	buy_button.disabled = false


# ══════════════════════════════════════════
# Illustration loading
# ══════════════════════════════════════════

func _load_illustration(data: Dictionary) -> void:
	var path: String = ""
	var id: String = data.get("id", "")

	if _is_item:
		path = AssetRegistry.get_star_chart_card_path(id)
	else:
		path = AssetRegistry.get_ninja_card_path(id)

	if path.is_empty() or not ResourceLoader.exists(path):
		return

	var tex: Texture2D = _load_texture_safe(path)
	if tex:
		ninja_card.set_content_texture(tex)
		ninja_card.set_detail_data(
			data.get("name", "???"),
			data.get("desc", ""),
			tex,
			data.get("effect", {})
		)


static func _load_texture_safe(path: String) -> Texture2D:
	return load(path) as Texture2D


# ══════════════════════════════════════════
# Purchase
# ══════════════════════════════════════════

func _on_buy_pressed() -> void:
	if not _is_purchased:
		purchase_requested.emit(_data)
