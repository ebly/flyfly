class_name StageConfig
extends RefCounted

# ============================================
# 关卡配置基类 - 所有关卡配置的父类
# ============================================
# 使用方法：
# 1. 继承此类创建新的关卡配置
# 2. 重写 _init() 方法设置关卡参数
# 3. 重写 get_enemy_config() 方法定义每波敌人
# ============================================

# 关卡ID
var stage_id: String = ""

# 关卡名称
var stage_name: String = ""

# 关卡描述
var description: String = ""

# 最大波次
var max_waves: int = 5

# 敌人生成间隔（秒）
var spawn_interval: float = 2.0

# 每波最大敌人数
var max_enemies_per_wave: int = 20

# 技能奖励列表 - 本关卡可掉落的技能
var skill_rewards: Array = []

# 关卡难度系数（影响敌人属性）
var difficulty_multiplier: float = 1.0

# 过关条件
var target_score: int = 1000  # 过关所需积分
var time_limit: float = 120.0  # 时间限制（秒）

# ============================================
# 构造函数
# ============================================

func _init():
	# 子类需要重写此方法设置关卡参数
	pass

# ============================================
# 敌人配置（子类必须重写）
# ============================================

# 获取指定波次的敌人配置
# 返回字典：{
#   "enemy_types": ["enemy_basic", "enemy_fast"],  # 该波次可能出现的敌人类型
#   "spawn_weights": {"enemy_basic": 50, "enemy_fast": 30},  # 生成权重
#   "max_enemies": 20,  # 该波次最大敌人数
#   "spawn_interval": 2.0,  # 该波次生成间隔
#   "elite_chance": 0.1,  # 精英敌人出现概率
#   "boss_wave": false  # 是否为BOSS波
# }
func get_enemy_config(_wave: int) -> Dictionary:
	push_error("StageConfig.get_enemy_config() 必须被子类重写")
	return {}

# ============================================
# 便捷方法
# ============================================

# 获取基础敌人配置模板
func get_base_enemy_config() -> Dictionary:
	return {
		"enemy_types": [],
		"spawn_weights": {},
		"max_enemies": max_enemies_per_wave,
		"spawn_interval": spawn_interval,
		"elite_chance": 0.0,
		"boss_wave": false
	}

# 根据权重随机选择敌人类型
func random_enemy_type(spawn_weights: Dictionary) -> String:
	if spawn_weights.is_empty():
		return "enemy_basic"
	
	var total_weight = 0
	for weight in spawn_weights.values():
		total_weight += weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for enemy_id in spawn_weights.keys():
		current_weight += spawn_weights[enemy_id]
		if random_value < current_weight:
			return enemy_id
	
	return spawn_weights.keys()[0]

# 检查是否是BOSS波
func is_boss_wave(wave: int) -> bool:
	var config = get_enemy_config(wave)
	return config.get("boss_wave", false)

# 获取该波次的技能掉落概率
func get_skill_drop_chance(wave: int) -> float:
	# 基础概率 20%，每波增加 2%
	return 0.2 + (wave - 1) * 0.02

# 获取随机技能奖励
func get_random_skill_reward() -> String:
	if skill_rewards.is_empty():
		return ""
	return skill_rewards[randi() % skill_rewards.size()]
