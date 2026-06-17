# scripts/config/sound_bank.gd
# ============================================================
# SoundBank — 音效资源集中管理
# 用法: const SB = preload("res://scripts/config/sound_bank.gd")
#       GlobalTweens.play_sfx(SB.GROUP_REVEAL)
# ============================================================
extends RefCounted

# ─── BGM ───
const MENU_BGM: AudioStream = preload("res://assets/audio/music/start_menu_bgm.mp3")
const GAME_BGM: AudioStream = null  ## @deprecated 旧 FanKing 占位 (main_game_bgm.wav)，MusicManager 已改用 game_bgm_light/medium/heavy.mp3
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
# DISCARD: removed — 手替え机制已废弃 (A5)
# REDRAW_POP: removed — 手替え机制已废弃 (A5)

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

# ─── P2 SFX (素材已就绪，接线待功能实装) ───
const ENCHANT_CAST: AudioStream   = preload("res://assets/audio/sound/game/enchant_cast.ogg")   ## @pending 附魔使用
const STAR_UPGRADE: AudioStream   = preload("res://assets/audio/sound/game/star_upgrade.ogg")   ## @pending 星图升级
const RITUAL_PULSE: AudioStream   = preload("res://assets/audio/sound/game/ritual_pulse.ogg")   ## @pending 秘仪生效
const GROWTH_TICK: AudioStream    = preload("res://assets/audio/sound/game/growth_tick.ogg")    ## @pending 修炼成长
const NINJA_GEAR: AudioStream     = preload("res://assets/audio/sound/game/ninja_gear.ogg")     ## @pending 忍法使用
const GLASS_BREAK: AudioStream    = preload("res://assets/audio/sound/game/glass_break.ogg")    ## @pending 琉璃碎裂
const LUCKY_JINGLE: AudioStream   = preload("res://assets/audio/sound/game/lucky_jingle.ogg")   ## @pending 鸿运触发
const BANISH_FIRE: AudioStream    = preload("res://assets/audio/sound/game/banish_fire.ogg")    ## @pending 放逐销毁

# ─── 猫叫 SFX (彩蛋) ───
const CAT_MEOWS: Array[AudioStream] = [
	preload("res://assets/audio/sound/cat/beetpro-meou-cat-sound-effect-18-11098.ogg"),
	preload("res://assets/audio/sound/cat/Cat-loud-meows-sound-effect.ogg"),
	preload("res://assets/audio/sound/cat/Cat-meow.ogg"),
	preload("res://assets/audio/sound/cat/Cat-meow-audio-clip.ogg"),
	preload("res://assets/audio/sound/cat/Cat-meowing-sound-effect-free.ogg"),
	preload("res://assets/audio/sound/cat/Cat-meow-sound-2.ogg"),
	preload("res://assets/audio/sound/cat/Cats-loud-meow-sound-clip.ogg"),
	preload("res://assets/audio/sound/cat/Cat-sound-meow.ogg"),
	preload("res://assets/audio/sound/cat/Cute-cat-meow-sound.ogg"),
	preload("res://assets/audio/sound/cat/Domestic-cat-meow-sound-effect-short-expressive.ogg"),
	preload("res://assets/audio/sound/cat/dragon-studio-cartoon-cat-meow-487661.ogg"),
	preload("res://assets/audio/sound/cat/dragon-studio-cat-meow-401729.ogg"),
	preload("res://assets/audio/sound/cat/freesound_community-cat-meow-6226.ogg"),
	preload("res://assets/audio/sound/cat/Kitten-meow-sound.ogg"),
	preload("res://assets/audio/sound/cat/Meow.ogg"),
	preload("res://assets/audio/sound/cat/Meow-cat-sound-effect.ogg"),
	preload("res://assets/audio/sound/cat/Meowing-cat.ogg"),
	preload("res://assets/audio/sound/cat/Meowing-cat-noise.ogg"),
	preload("res://assets/audio/sound/cat/Meowing-cat-sound.ogg"),
	preload("res://assets/audio/sound/cat/Meow-noise.ogg"),
	preload("res://assets/audio/sound/cat/Meow-sound.ogg"),
	preload("res://assets/audio/sound/cat/Meow-sound-2.ogg"),
	preload("res://assets/audio/sound/cat/Meow-sound-3.ogg"),
	preload("res://assets/audio/sound/cat/Realistic-cat-meow-sound-effect.ogg"),
	preload("res://assets/audio/sound/cat/ribhavagrawal-cat-meowing-type-01-293291.ogg"),
	preload("res://assets/audio/sound/cat/ribhavagrawal-cat-meowing-type-02-293290.ogg"),
	preload("res://assets/audio/sound/cat/Short-meow-sound-effect.ogg"),
	preload("res://assets/audio/sound/cat/Single-cat-meow-sound-effect.ogg"),
	preload("res://assets/audio/sound/cat/soulfuljamtracks-cat-meow-1-fx-323465.ogg"),
	preload("res://assets/audio/sound/cat/soulfuljamtracks-cat-meow-6-fx-323468_cut.ogg"),
	preload("res://assets/audio/sound/cat/sound_garage-cat-meow-11-fx-306193.ogg"),
	preload("res://assets/audio/sound/cat/sound_garage-cat-meow-12-fx-306191_cut.ogg"),
	preload("res://assets/audio/sound/cat/soundreality-cat-meow-fx-461188_cut.ogg"),
	preload("res://assets/audio/sound/cat/virtual_vibes-real-cat-sound-effect-383821_cut.ogg"),
	preload("res://assets/audio/sound/cat/yodguard-cute-soft-cat-meow-3-535482.ogg"),
	preload("res://assets/audio/sound/cat/yodguard-cute-soft-cat-meow-4-535483.ogg"),
	preload("res://assets/audio/sound/cat/yoursperfectguy-cute-puppy-sound-effect-sfx-1-336356_cut.ogg"),
]

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
