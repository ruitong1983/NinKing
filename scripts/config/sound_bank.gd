# scripts/config/sound_bank.gd
# ============================================================
# SoundBank — 音效资源集中管理
# 通过 preload 引用，非 class_name（避免全局类冲突）
# 用法: const SB = preload("res://scripts/config/sound_bank.gd")
#       GlobalTweens.play_sfx(SB.DRAW)
# ============================================================
extends RefCounted

# ─── BGM ───
const MENU_BGM: AudioStream = preload("res://assets/audio/music/start_menu_bgm.wav")
const GAME_BGM: AudioStream = preload("res://assets/audio/music/main_game_bgm.wav")

# ─── 游戏 SFX (assets/audio/sound/game/) — 暂用 FanKing 占位 ───
const DRAW: AudioStream          = preload("res://assets/audio/sound/game/draw.ogg")
const DISCARD: AudioStream       = preload("res://assets/audio/sound/game/discard.ogg")
const HU: AudioStream            = preload("res://assets/audio/sound/game/hu.ogg")
const DEAL: AudioStream          = preload("res://assets/audio/sound/game/deal.ogg")
const SELECT: AudioStream        = preload("res://assets/audio/sound/game/select.ogg")
const SWAP: AudioStream          = preload("res://assets/audio/sound/game/swap.ogg")
const YAKU_REVEAL: AudioStream   = preload("res://assets/audio/sound/game/yaku_reveal.ogg")
const BAO_ACTIVATE: AudioStream  = preload("res://assets/audio/sound/game/bao_activate.ogg")
const COUNT_TICK: AudioStream    = preload("res://assets/audio/sound/game/count_tick.ogg")
const EXPLOSION: AudioStream     = preload("res://assets/audio/sound/game/explosion.ogg")
const LEVEL_CLEAR: AudioStream   = preload("res://assets/audio/sound/game/level_clear.ogg")
const LEVEL_FAIL: AudioStream    = preload("res://assets/audio/sound/game/level_fail.ogg")
const LOTTERY: AudioStream       = preload("res://assets/audio/sound/game/lottery.ogg")
const HOVER: AudioStream         = preload("res://assets/audio/sound/game/hover.ogg")

# ─── 通用 UI SFX (assets/audio/sound/ui/) ───
const UI_CLICK: AudioStream  = preload("res://assets/audio/sound/ui/ui_click.ogg")
const UI_COIN: AudioStream   = preload("res://assets/audio/sound/ui/ui_coin.ogg")
const UI_ERROR: AudioStream  = preload("res://assets/audio/sound/ui/ui_error.ogg")
