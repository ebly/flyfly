# 游戏技能掉落表

## 敌人技能掉落概率与技能类型

| 敌人类型 | 敌人名称 | 掉落概率 | 可掉落技能 | 技能稀有度 | 敌人强度 |
|---------|---------|---------|-----------|-----------|---------|
| **基础敌人** | | | | | |
| enemy_basic | 基础敌机 | 5% | 冲刺 (dash) | 基础 | ★☆☆☆☆ |
| enemy_drone | 侦察无人机 | 3% | 冲刺 (dash) | 基础 | ★☆☆☆☆ |
| **中级敌人** | | | | | |
| enemy_fast | 高速敌机 | 8% | 冲刺 (dash), 护盾 (shield) | 基础-中级 | ★★☆☆☆ |
| enemy_heavy | 重型敌机 | 12% | 护盾 (shield), 快速射击 (rapid_fire) | 中级 | ★★★☆☆ |
| enemy_kamikaze | 自杀式敌机 | 6% | 冲刺 (dash), 快速射击 (rapid_fire) | 基础-中级 | ★★☆☆☆ |
| **高级敌人** | | | | | |
| enemy_elite | 精英敌机 | 20% | 护盾 (shield), 快速射击 (rapid_fire), 导弹齐射 (missile) | 中级-高级 | ★★★★☆ |
| enemy_boss | BOSS | 100% (必掉) | 导弹齐射 (missile), 激光束 (laser), 炸弹 (bomb) | 高级 | ★★★★★ |

## 技能稀有度分类

| 稀有度 | 包含技能 | 描述 |
|-------|---------|------|
| **基础技能** | 冲刺 (dash) | 容易获得，适合新手玩家 |
| **中级技能** | 护盾 (shield), 快速射击 (rapid_fire) | 中等难度获得，增强战斗能力 |
| **高级技能** | 导弹齐射 (missile), 激光束 (laser), 炸弹 (bomb) | 难以获得，提供强大战斗力 |

## 技能效果说明

| 技能名称 | 效果描述 | 冷却时间 | 持续时间 |
|---------|---------|---------|---------|
| 冲刺 (dash) | 快速向前冲刺一段距离，躲避敌人攻击 | 3.0秒 | 0.3秒 |
| 护盾 (shield) | 获得临时护盾，免疫所有伤害 | 5.0秒 | 3.0秒 |
| 快速射击 (rapid_fire) | 短时间内大幅提升射速，增加输出 | 4.0秒 | 2.0秒 |
| 导弹齐射 (missile) | 发射多枚追踪导弹，自动攻击敌人 | 8.0秒 | 立即生效 |
| 激光束 (laser) | 发射穿透性激光束，对直线上敌人造成大量伤害 | 6.0秒 | 1.5秒 |
| 炸弹 (bomb) | 投掷大范围伤害炸弹，清除区域内敌人 | 10.0秒 | 立即生效 |

## 掉落机制说明

1. **掉落概率计算**：每个敌人死亡时会根据其类型的掉落概率判断是否掉落技能
2. **技能类型选择**：如果判定掉落，会从该敌人的可掉落技能列表中随机选择一种
3. **稀有度控制**：高级技能只会从高级敌人掉落，确保游戏平衡性
4. **BOSS掉落**：BOSS必然掉落高级技能，是玩家获取高级技能的主要途径

## 游戏平衡性建议

- 基础敌人数量最多，掉落概率最低，确保技能不会过于泛滥
- 中级敌人提供过渡技能，帮助玩家逐步提升战斗力
- 高级敌人和BOSS掉落强力技能，为玩家提供挑战性目标
- 技能掉落机制鼓励玩家击败更多敌人，特别是高级敌人，获得更强力的技能

## 实施说明

要修改游戏中的技能掉落概率，可以在 `entities/enemy.gd` 文件中的 `_spawn_skill_drop()` 函数中添加敌人类型判断逻辑，根据不同敌人类型设置不同的掉落概率和可掉落技能列表。

```gdscript
func _spawn_skill_drop() -> void:
    # 根据敌人类型设置不同的掉落概率和可掉落技能
    var drop_chance: float = 0.0
    var available_skills: Array = []
    
    match aircraft_id:
        "enemy_basic":
            drop_chance = 0.05
            available_skills = ["dash"]
        "enemy_drone":
            drop_chance = 0.03
            available_skills = ["dash"]
        "enemy_fast":
            drop_chance = 0.08
            available_skills = ["dash", "shield"]
        "enemy_heavy":
            drop_chance = 0.12
            available_skills = ["shield", "rapid_fire"]
        "enemy_kamikaze":
            drop_chance = 0.06
            available_skills = ["dash", "rapid_fire"]
        "enemy_elite":
            drop_chance = 0.20
            available_skills = ["shield", "rapid_fire", "missile"]
        "enemy_boss":
            drop_chance = 1.0  # BOSS必掉
            available_skills = ["missile", "laser", "bomb"]
        _:
            # 默认掉落概率
            drop_chance = 0.05
            available_skills = ["dash"]
    
    # 按概率掉落技能
    if randf() > drop_chance:
        return
    
    # 随机选择一个技能
    if available_skills.is_empty():
        available_skills = AircraftConfig.get_unlockable_skills()
    
    var random_skill: String = available_skills[randi() % available_skills.size()]
    
    # 创建技能掉落物
    var skill_drop_scene: PackedScene = preload("res://scenes/skill_drop.tscn")
    var skill_drop = skill_drop_scene.instantiate()
    skill_drop.position = position + Vector2(randi() % 40 - 20, randi() % 40 - 20)
    skill_drop.set_skill_type(random_skill)
    
    get_parent().add_child.call_deferred(skill_drop)
    print("敌机掉落技能: " + random_skill)
```