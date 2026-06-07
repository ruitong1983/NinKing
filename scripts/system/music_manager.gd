# scripts/system/music_manager.gd
# ============================================================
# MusicManager — BGM 播放与交叉淡入淡出 (Autoload: MusicManager)
# 依赖: 无（自建 AudioStreamPlayer）
# ============================================================
extends Node

const CROSSFADE_DUR: float = 0.8
const DEFAULT_VOLUME_DB: float = -8.0

var _menu_bgm: AudioStream
var _game_bgm: AudioStream

var _active_player: AudioStreamPlayer
var _fading_out_player: AudioStreamPlayer
var _is_playing: bool = false


func _ready() -> void:
	_active_player = _create_player()
	_fading_out_player = _create_player()
	# 后台预加载音频，避免首次播放时阻塞
	_preload_audio.call_deferred()


func _preload_audio() -> void:
	_ensure_menu_bgm()
	_ensure_game_bgm()


func _ensure_menu_bgm() -> AudioStream:
	if _menu_bgm == null:
		_menu_bgm = load("res://assets/audio/music/start_menu_bgm.wav")
	return _menu_bgm


func _ensure_game_bgm() -> AudioStream:
	if _game_bgm == null:
		_game_bgm = load("res://assets/audio/music/main_game_bgm.wav")
	return _game_bgm


func play_menu_bgm() -> void:
	_crossfade_to(_ensure_menu_bgm())


func play_game_bgm() -> void:
	_crossfade_to(_ensure_game_bgm())


func stop_all() -> void:
	if _active_player.playing:
		var tw := _active_player.create_tween()
		tw.tween_property(_active_player, "volume_db", -60.0, 0.3)
		tw.tween_callback(_active_player.stop)
	if _fading_out_player.playing:
		_fading_out_player.stop()
	_is_playing = false


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
	add_child(p)
	return p
