extends Node

const StageConfig = preload("res://stages/stage_config.gd")

# ============================================
# 关卡管理器 - 管理所有关卡配置
# ============================================
# 使用方法：
# 1. 注册关卡：StageManager.register_stage("easy", EasyStage.new())
# 2. 获取关卡配置：var config = StageManager.get_stage_config("easy")
# 3. 获取当前关卡敌人：var enemies = StageManager.get_stage_enemies("easy", wave)
# ============================================

# 存储所有关卡配置
var _stages: Dictionary = {}

# 当前关卡ID
var _current_stage_id: String = ""

# ============================================
# 关卡注册
# ============================================

# 注册一个关卡
func register_stage(stage_id: String, stage_config: StageConfig) -> void:
	_stages[stage_id] = stage_config
	print("注册关卡: " + stage_id + " - " + stage_config.stage_name)

# 注销一个关卡
func unregister_stage(stage_id: String) -> void:
	if _stages.has(stage_id):
		_stages.erase(stage_id)
		print("注销关卡: " + stage_id)

# ============================================
# 关卡配置获取
# ============================================

# 获取关卡配置
func get_stage_config(stage_id: String) -> StageConfig:
	if _stages.has(stage_id):
		return _stages[stage_id]
	push_error("未找到关卡配置: " + stage_id)
	return null

# 获取所有已注册关卡ID
func get_all_stage_ids() -> Array:
	return _stages.keys()

# 获取所有关卡配置
func get_all_stages() -> Dictionary:
	return _stages.duplicate()

# ============================================
# 当前关卡管理
# ============================================

# 设置当前关卡
func set_current_stage(stage_id: String) -> bool:
	if not _stages.has(stage_id):
		push_error("无法设置当前关卡，关卡不存在: " + stage_id)
		return false
	_current_stage_id = stage_id
	print("当前关卡设置为: " + stage_id)
	return true

# 获取当前关卡ID
func get_current_stage_id() -> String:
	return _current_stage_id

# 获取当前关卡配置
func get_current_stage_config() -> StageConfig:
	if _current_stage_id.is_empty():
		push_error("当前没有设置关卡")
		return null
	return get_stage_config(_current_stage_id)

# ============================================
# 关卡数据获取（便捷方法）
# ============================================

# 获取关卡的敌人配置
func get_stage_enemies(stage_id: String, wave: int = 1) -> Dictionary:
	var config = get_stage_config(stage_id)
	if config == null:
		return {}
	return config.get_enemy_config(wave)

# 获取关卡的技能奖励
func get_stage_skill_rewards(stage_id: String) -> Array:
	var config = get_stage_config(stage_id)
	if config == null:
		return []
	return config.skill_rewards

# 获取关卡最大波次
func get_stage_max_waves(stage_id: String) -> int:
	var config = get_stage_config(stage_id)
	if config == null:
		return 1
	return config.max_waves

# 获取关卡生成间隔
func get_stage_spawn_interval(stage_id: String) -> float:
	var config = get_stage_config(stage_id)
	if config == null:
		return 2.0
	return config.spawn_interval

# ============================================
# 当前关卡数据获取
# ============================================

# 获取当前关卡敌人配置
func get_current_stage_enemies(wave: int = 1) -> Dictionary:
	return get_stage_enemies(_current_stage_id, wave)

# 获取当前关卡技能奖励
func get_current_stage_skill_rewards() -> Array:
	return get_stage_skill_rewards(_current_stage_id)

# 获取当前关卡最大波次
func get_current_stage_max_waves() -> int:
	return get_stage_max_waves(_current_stage_id)

# 获取当前关卡生成间隔
func get_current_stage_spawn_interval() -> float:
	return get_stage_spawn_interval(_current_stage_id)

# ============================================
# 初始化
# ============================================

func _ready():
	print("关卡管理器已初始化")
