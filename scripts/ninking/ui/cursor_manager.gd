extends Node
## NinKing 光标管理器 — Kenney 自定义光标系统 (Autoload)
##
## 一次性注册光标图片到两种形状，并通过 SceneTree.node_added 信号自动为
## 交互节点设置 mouse_default_cursor_shape = POINTING_HAND，让 Godot 在
## 悬停时自动切换形状显示蓝手。零手动接入，全局生效。
##
## 自动设蓝手的节点类型:
##   - Button          → 所有按钮
##   - Card 及其子类   → 手牌卡牌、忍者栏卡牌、商店卡牌等所有交互卡牌
##
## 已注册形状：
##   CURSOR_ARROW          → cursorHand_beige (暖手, 默认, 治愈漫画风)
##   CURSOR_POINTING_HAND  → cursorHand_blue  (蓝手, 按钮悬停)
##
## ⚠️ 2026-06-23 风格统一: 默认光标从金剑(cursorSword_gold) 改为暖手(cursorHand_beige),
## 匹配治愈漫画(Iyashikei)风格。旧金剑光标保留在 assets 中备用。
##
## 用 _enter_tree 而非 _ready，确保在首个场景（Launch）的节点加入场景树
## 之前就连接好 node_added 信号，避免首次加载时错过按钮的入场事件。

const CURSOR_DEFAULT := preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/cursorHand_beige.png")
const CURSOR_HOVER := preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/cursorHand_blue.png")


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	_register_cursors()
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


## 注册光标图片到对应形状
func _register_cursors() -> void:
	if CURSOR_DEFAULT:
		Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW, Vector2(4, 2))
	if CURSOR_HOVER:
		Input.set_custom_mouse_cursor(CURSOR_HOVER, Input.CURSOR_POINTING_HAND, Vector2(2, 2))


## 任意节点加入场景树时自动设蓝手光标
## 适用于 Button（所有按钮）+ Card 及其子类（手牌/忍栏/商店卡牌）
func _on_node_added(node: Node) -> void:
	if node is Button or node is Card:
		node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## 切换到暖手默认光标 (用于非 Button/Card 的自定义交互控件)
static func set_default() -> void:
	if CURSOR_DEFAULT:
		Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW, Vector2(2, 2))

## 切换到蓝手 hover 光标 (用于非 Button/Card 的自定义交互控件)
static func set_hover() -> void:
	if CURSOR_HOVER:
		Input.set_custom_mouse_cursor(CURSOR_HOVER, Input.CURSOR_POINTING_HAND, Vector2(2, 2))

## 恢复到系统默认箭头
static func set_system_arrow() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
