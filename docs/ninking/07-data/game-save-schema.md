# 存档格式 (JSON Schema)

> **最后更新：** 2026-06-16
> **关联文档：** [`01-gameplay/06-complete-redesign.md`](../01-gameplay/06-complete-redesign.md) · `scripts/ninking/save_manager.gd`

---

## 存档结构

```json
{
    "ante_num": 3,
    "blind_index": 1,
    "gold": 25,
    "owned_ninjas": [
        {
            "id": "n_001",
            "name": "手里剑",
            "effect": {"add_chips": 10.0},
            "cost": 3,
            "rarity": "common"
        }
    ],
    "owned_items": [],
    "star_chart_levels": {
        "0": 2, "1": 1, "2": 0, "3": 0, "4": 0, "5": 1
    }
}
```

## 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `ante_num` | `int` | 当前 Ante 编号 (1-8) |
| `blind_index` | `int` | 当前 Blind 索引 (0=Small, 1=Big, 2=Boss) |
| `gold` | `int` | 持有金币 |
| `owned_ninjas` | `Array[Dictionary]` | 已拥有的忍者牌列表 |
| `owned_items` | `Array` | 已拥有的道具列表（预留） |
| `star_chart_levels` | `Dictionary[int, int]` | 星图等级映射 (牌型索引→等级) |

### owned_ninjas 条目字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `String` | 忍者牌 ID（如 `n_001`） |
| `name` | `String` | 忍者牌名称 |
| `effect` | `Dictionary` | 效果参数字典 |
| `cost` | `int` | 购买价格 |
| `rarity` | `String` | 稀有度 (common/uncommon/rare/legendary) |

## 存档路径

`user://ninking_save.json`

## 存档行为

- **永久死亡**：失败/胜利自动记录战绩 + 删除 run 存档
- **Checkpoint**：在封印开始时保存
- **继续游戏**：通过 `continue_run` / `has_saved_run` 判断
- **仅保留解锁进度**：通关解锁内容跨 run 保留
