extends Resource
class_name WaveConfig

# ============================================
# 波次配置资源 - 可序列化的波次数据
# ============================================

@export var wave_number: int = 1
@export var enemy_types: Array[String] = []
@export var spawn_weights: Dictionary = {}
@export var max_enemies: int = 10
@export var spawn_interval: float = 2.0
@export var elite_chance: float = 0.0
@export var is_boss_wave: bool = false
@export var skill_drop_bonus: float = 0.0

# 获取随机敌人类型（根据权重）
func get_random_enemy_type() -> String:
	if enemy_types.is_empty():
		return "enemy_basic"
	
	if spawn_weights.is_empty():
		return enemy_types[randi() % enemy_types.size()]
	
	# 计算总权重
	var total_weight = 0
	for weight in spawn_weights.values():
		total_weight += weight
	
	if total_weight <= 0:
		return enemy_types[0]
	
	# 随机选择
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for enemy_id in spawn_weights.keys():
		current_weight += spawn_weights[enemy_id]
		if random_value < current_weight:
			return enemy_id
	
	return enemy_types[0]

# 验证配置
func validate() -> bool:
	if enemy_types.is_empty():
		push_error("波次 " + str(wave_number) + " 没有配置敌人类型")
		return false
	
	if max_enemies <= 0:
		push_error("波次 " + str(wave_number) + " 最大敌人数无效")
		return false
	
	if spawn_interval <= 0:
		push_error("波次 " + str(wave_number) + " 生成间隔无效")
		return false
	
	return true

# 获取配置摘要
func get_summary() -> String:
	return "波次 %d: %d 种敌人, 最大 %d 个, 间隔 %.1f 秒%s" % [
		wave_number,
		enemy_types.size(),
		max_enemies,
		spawn_interval,
		" [BOSS]" if is_boss_wave else ""
	]
