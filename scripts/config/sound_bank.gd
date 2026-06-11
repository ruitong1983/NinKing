# scripts/config/sound_bank.gd
# ============================================================
# SoundBank — 音效资源集中管理
# 用法: const SB = preload("res://scripts/config/sound_bank.gd")
#       GlobalTweens.play_sfx(SB.GROUP_REVEAL)
# ============================================================
extends RefCounted

# ─── BGM ───
const MENU_BGM: AudioStream = preload("res://assets/audio/music/start_menu_bgm.wav")
const GAME_BGM: AudioStream = preload("res://assets/audio/music/main_game_bgm.wav")
const GAME_BGM_LIGHT: AudioStream = preload("res://assets/audio/music/game_bgm_light.mp3")
const GAME_BGM_MEDIUM: AudioStream = preload("res://assets/audio/music/game_bgm_medium.mp3")
const GAME_BGM_HEAVY: AudioStream = preload("res://assets/audio/music/game_bgm_heavy.mp3")
const SHOP_BGM: AudioStream = preload("res://assets/audio/music/dova_Cooler Ninjari Ninjarous miaster.mp3")

# ─── 游戏 SFX (忍者主题命名) ───
# Phase 1-2 matching — Anime Game Pack 20/20 匹配完成

# ── 出牌/揭示 ──
const DEAL: AudioStream          = preload("res://assets/audio/sound/game/deal.ogg")
const GROUP_REVEAL: AudioStream  = preload("res://assets/audio/sound/game/group_reveal.ogg")
const BOSS_REVEAL: AudioStream   = preload("res://assets/audio/sound/game/boss_reveal.ogg")
const BOSS_FINAL_LAYER: AudioStream = preload("res://assets/audio/sound/game/boss_final_layer.ogg")

# ── 卡牌操作 ──
const SWAP: AudioStream          = preload("res://assets/audio/sound/game/swap.ogg")
const DISCARD: AudioStream       = preload("res://assets/audio/sound/game/discard.ogg")
const REDRAW_POP: AudioStream    = preload("res://assets/audio/sound/game/redraw_pop.ogg")

# ── 计分/喜/结算 ──
const COUNT_TICK: AudioStream    = preload("res://assets/audio/sound/game/count_tick.ogg")
const XI_TRIGGER: AudioStream    = preload("res://assets/audio/sound/game/xi_trigger.ogg")
const XI_FANFARE: AudioStream    = preload("res://assets/audio/sound/game/xi_fanfare.ogg")
const NINJA_ACTIVATE: AudioStream= preload("res://assets/audio/sound/game/ninja_activate.ogg")
const SEAL_CLEAR: AudioStream    = preload("res://assets/audio/sound/game/seal_clear.ogg")
const SEAL_FAIL: AudioStream     = preload("res://assets/audio/sound/game/seal_fail.ogg")

# ── 商店 ──
const SHOP_ENTER: AudioStream    = preload("res://assets/audio/sound/game/shop_enter.ogg")
const SHOP_EXIT: AudioStream     = preload("res://assets/audio/sound/game/shop_exit.ogg")
const ITEM_PURCHASE: AudioStream = preload("res://assets/audio/sound/game/item_purchase.ogg")
const SHOP_REROLL: AudioStream   = preload("res://assets/audio/sound/game/shop_reroll.ogg")

# ─── 通用 UI SFX ───
const UI_CLICK: AudioStream  = preload("res://assets/audio/sound/ui/ui_click.ogg")
const UI_COIN: AudioStream   = preload("res://assets/audio/sound/ui/ui_coin.ogg")
const UI_ERROR: AudioStream  = preload("res://assets/audio/sound/ui/ui_error.ogg")
const HOVER: AudioStream     = preload("res://assets/audio/sound/game/hover.ogg")

# ─── 旧名 alias (FanKing 遗留，deprecated) ───
# 待所有引用迁移后删除
const DRAW: AudioStream       = DEAL          ## @deprecated 改用 DEAL
const HU: AudioStream         = GROUP_REVEAL  ## @deprecated 改用 GROUP_REVEAL
const YAKU_REVEAL: AudioStream= XI_TRIGGER    ## @deprecated 改用 XI_TRIGGER
const BAO_ACTIVATE: AudioStream=NINJA_ACTIVATE## @deprecated 改用 NINJA_ACTIVATE
const SELECT: AudioStream     = preload("res://assets/audio/sound/game/select.ogg")
const LEVEL_CLEAR: AudioStream= SEAL_CLEAR    ## @deprecated 改用 SEAL_CLEAR
const LEVEL_FAIL: AudioStream = SEAL_FAIL     ## @deprecated 改用 SEAL_FAIL
const EXPLOSION: AudioStream  = DEAL          ## @deprecated 未使用，占位
const LOTTERY: AudioStream    = DEAL          ## @deprecated 未使用，占位
