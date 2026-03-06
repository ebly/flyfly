extends Resource
class_name StageConfigResource

# ============================================
# 关卡配置资源 - 可序列化的关卡数据
# ============================================

@export var stage_id: String = ""
@export var stage_name: String = ""
@export var description: String = ""
@export var max_waves: int = 5
@export var base_spawn_interval: float = 2.0
@export var max_enemies_per_wave: int = 20
@export var difficulty_multiplier: float = 1.0
@export var skill_rewards: Array[String] = []
@export var wave_configs: Array[WaveConfig] = []
@export var background_texture: Texture2D = null
@export var music_track: AudioStream = null

# 过关条件
@export var target_score: int = 1000  # 过关所需积分
@export var time_limit: float = 120.0  # 时间限制（秒）

# 获取指定波次的配置
func get_wave_config(wave: int) -> WaveConfig:
	for config in wave_configs:
		if config.wave_number == wave:
			return config
	
	# 如果没有找到，返回默认配置
	return _create_default_wave_config(wave)

# 创建默认波次配置
func _create_default_wave_config(wave: int) -> WaveConfig:
	var config = WaveConfig.new()
	config.wave_number = wave
	config.enemy_types = ["enemy_basic"]
	config.spawn_weights = {"enemy_basic": 100}
	config.max_enemies = max_enemies_per_wave
	config.spawn_interval = base_spawn_interval
	config.elite_chance = 0.0
	config.is_boss_wave = (wave == max_waves)
	return config

# 获取技能掉落概率
func get_skill_drop_chance(wave: int) -> float:
	var base_chance = 0.2
	var wave_config = get_wave_config(wave)
	if wave_config != null:
		base_chance += wave_config.skill_drop_bonus
	
	# 根据难度调整
	return base_chance * difficulty_multiplier

# 验证配置
func validate() -> bool:
	if stage_id.is_empty():
		push_error("关卡ID不能为空")
		return false
	
	if stage_name.is_empty():
		push_error("关卡名称不能为空")
		return false
	
	if max_waves <= 0:
		push_error("最大波次必须大于0")
		return false
	
	# 验证所有波次配置
	for wave_config in wave_configs:
		if not wave_config.validate():
			return false
	
	return true

# 获取配置摘要
func get_summary() -> String:
	return "%s (%s): %d 波, 难度 %.1fx, %d 个技能奖励" % [
		stage_name,
		stage_id,
		max_waves,
		difficulty_multiplier,
		skill_rewards.size()
	]

# 保存为资源文件
func save_to_file(path: String) -> Error:
	return ResourceSaver.save(self, path)

# 从资源文件加载
static func load_from_file(path: String) -> StageConfigResource:
	return ResourceLoader.load(path) as StageConfigResource
