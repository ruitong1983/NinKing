# scripts/system/music_manager.gd
# ============================================================
# MusicManager — BGM 播放与交叉淡入淡出 (Autoload: MusicManager)
# 依赖: 无（自建 AudioStreamPlayer）
# ============================================================
extends Node

const CROSSFADE_DUR: float = 0.8
const DEFAULT_VOLUME_DB: float = -8.0

var _menu_bgm: AudioStream
var _game_bgm_light: AudioStream
var _game_bgm_medium: AudioStream
var _game_bgm_heavy: AudioStream
var _shop_bgm: AudioStream

var _active_player: AudioStreamPlayer
var _fading_out_player: AudioStreamPlayer
var _is_playing: bool = false

var _current_variation: String = ""  # "light" | "medium" | "heavy" | "menu" | "shop"


func _ready() -> void:
	_active_player = _create_player()
	_fading_out_player = _create_player()
	# 后台预加载音频，避免首次播放时阻塞
	_preload_audio.call_deferred()


func _preload_audio() -> void:
	_ensure_menu_bgm()
	_ensure_game_bgm_light()
	_ensure_game_bgm_medium()
	_ensure_game_bgm_heavy()
	_ensure_shop_bgm()


func _ensure_menu_bgm() -> AudioStream:
	if _menu_bgm == null:
		_menu_bgm = load("res://assets/audio/music/start_menu_bgm.mp3")
	return _menu_bgm


func _ensure_game_bgm_light() -> AudioStream:
	if _game_bgm_light == null:
		_game_bgm_light = load("res://assets/audio/music/game_bgm_light.mp3")
	return _game_bgm_light


func _ensure_game_bgm_medium() -> AudioStream:
	if _game_bgm_medium == null:
		_game_bgm_medium = load("res://assets/audio/music/game_bgm_medium.mp3")
	return _game_bgm_medium


func _ensure_game_bgm_heavy() -> AudioStream:
	if _game_bgm_heavy == null:
		_game_bgm_heavy = load("res://assets/audio/music/game_bgm_heavy.mp3")
	return _game_bgm_heavy


func _ensure_shop_bgm() -> AudioStream:
	if _shop_bgm == null:
		_shop_bgm = load("res://assets/audio/music/dova_Cooler Ninjari Ninjarous miaster.mp3")
	return _shop_bgm


func get_game_stream_for_barrier(barrier: int) -> AudioStream:
	## Return the appropriate game BGM variation based on barrier number.
	## barrier 1-3 → light, 4-6 → medium, 7-8 → heavy.
	if barrier <= 3:
		return _ensure_game_bgm_light()
	elif barrier <= 6:
		return _ensure_game_bgm_medium()
	else:
		return _ensure_game_bgm_heavy()


func play_menu_bgm() -> void:
	_crossfade_to(_ensure_menu_bgm())
	_current_variation = "menu"


func play_game_bgm() -> void:
	## Play default game BGM (light). Prefer set_game_variation(barrier) instead.
	_crossfade_to(_ensure_game_bgm_light())
	_current_variation = "light"


func set_game_variation(barrier: int) -> void:
	## Automatically select and play game BGM based on barrier difficulty.
	## barrier 1-3: light, 4-6: medium, 7-8: heavy.
	## Crossfades if already playing a different variation.
	var stream: AudioStream = get_game_stream_for_barrier(barrier)
	if stream == null:
		return

	var var_name: String = "light" if barrier <= 3 else ("medium" if barrier <= 6 else "heavy")

	# Don't restart if same variation is already playing
	if _active_player.stream == stream and _active_player.playing:
		_current_variation = var_name
		return

	_crossfade_to(stream)
	_current_variation = var_name


func play_shop_bgm() -> void:
	_crossfade_to(_ensure_shop_bgm())
	_current_variation = "shop"


func stop_all() -> void:
	if _active_player.playing:
		var tw := _active_player.create_tween()
		tw.tween_property(_active_player, "volume_db", -60.0, 0.3)
		tw.tween_callback(_active_player.stop)
	if _fading_out_player.playing:
		_fading_out_player.stop()
	_is_playing = false
	_current_variation = ""


func set_master_volume(db: float) -> void:
	var bus_idx := AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_volume_db(bus_idx, db)


func _crossfade_to(stream: AudioStream) -> void:
	if stream == null:
		return
	if _active_player.stream == stream and _active_player.playing:
		return

	# Swap: active → fading_out
	var old := _active_player
	_active_player = _fading_out_player
	_fading_out_player = old

	# Start new track
	_active_player.stream = stream
	_active_player.volume_db = -60.0
	_active_player.play()
	_is_playing = true

	var tw := _active_player.create_tween()
	tw.tween_property(_active_player, "volume_db", DEFAULT_VOLUME_DB, CROSSFADE_DUR)

	# Fade out old
	if _fading_out_player.playing:
		var fade_tw := _fading_out_player.create_tween()
		fade_tw.tween_property(_fading_out_player, "volume_db", -60.0, CROSSFADE_DUR)
		fade_tw.tween_callback(_fading_out_player.stop)


func _create_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "BGM"
	p.volume_db = DEFAULT_VOLUME_DB
	p.finished.connect(_on_player_finished.bind(p))
	add_child(p)
	return p


func _on_player_finished(player: AudioStreamPlayer) -> void:
	# 兜底循环：若导入设置 loop_mode 失效，代码层重新播放
	if player == _active_player and player.stream != null:
		player.play()
