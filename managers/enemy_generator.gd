extends Node2D

const AircraftConfig = preload("res://config/aircraft_config.gd")
const StageManager = preload("res://stages/stage_manager.gd")
const StageConfig = preload("res://stages/stage_config.gd")

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var spawn_timer: Timer = null
var max_enemies: int = 20
var spawned_enemies: int = 0
var current_wave: int = 1

# 关卡相关
var stage_manager: StageManager = null
var current_stage_config: StageConfig = null
var enemy_config: Dictionary = {}  # 当前波次的敌人配置

func _ready() -> void:
	# 创建生成定时器
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = 2.0 # 每2秒生成一个敌机
	spawn_timer.autostart = false  # 先不自动启动，等待关卡设置
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

# 设置关卡管理器
func set_stage_manager(manager: StageManager) -> void:
	stage_manager = manager
	_apply_stage_config()

# 应用关卡配置
func _apply_stage_config() -> void:
	if stage_manager == null:
		return
	
	current_stage_config = stage_manager.get_current_stage_config()
	if current_stage_config == null:
		push_error("未设置当前关卡配置")
		return
	
	# 应用关卡基础配置
	max_enemies = current_stage_config.max_enemies_per_wave
	spawn_timer.wait_time = current_stage_config.spawn_interval
	
	# 获取第一波敌人配置
	_update_wave_config(1)
	
	print("关卡配置已应用: " + current_stage_config.stage_name)

# 更新波次配置
func _update_wave_config(wave: int) -> void:
	if current_stage_config == null:
		return
	
	enemy_config = current_stage_config.get_enemy_config(wave)
	if not enemy_config.is_empty():
		max_enemies = enemy_config.get("max_enemies", max_enemies)
		spawn_timer.wait_time = enemy_config.get("spawn_interval", spawn_timer.wait_time)
		print("第 " + str(wave) + " 波配置已更新，最大敌人: " + str(max_enemies))

func _on_spawn_timer_timeout() -> void:
	if spawned_enemies >= max_enemies:
		spawn_timer.stop()
		print("当前波次已生成所有敌人 (" + str(spawned_enemies) + "/" + str(max_enemies) + ")，停止生成")
		return
	
	_spawn_enemy()

func _spawn_enemy() -> void:
	var enemy_type: String = _get_random_enemy_type()
	if enemy_type.is_empty():
		push_error("无法获取敌人类型")
		return
	
	var config: Dictionary = AircraftConfig.get_aircraft_config(enemy_type)
	
	if config.is_empty():
		push_error("无法生成敌机，配置为空: " + enemy_type)
		return
	
	# 实例化敌机
	var enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	
	# 先设置类型，但不设置位置（因为位置依赖于视口）
	enemy.set_aircraft_type(enemy_type)
	
	# 应用难度系数
	if current_stage_config != null:
		_apply_difficulty_multiplier(enemy, current_stage_config.difficulty_multiplier)
	
	# 添加到场景
	add_child(enemy)
	
	# 现在敌人已经在场景中，可以获取视口，设置正确的出生位置
	if enemy.has_method("_setup_spawn_position"):
		enemy._setup_spawn_position()
	
	# 发送敌人生成事件
	var EventBus = get_node("/root/EventBus")
	EventBus.enemy_spawned.emit(enemy_type, enemy.position)
	
	spawned_enemies += 1
	print("生成敌机: " + config.name + " (" + enemy_type + "), 剩余: " + str(max_enemies - spawned_enemies))

# 根据权重随机选择敌人类型
func _get_random_enemy_type() -> String:
	if enemy_config.is_empty() or not enemy_config.has("spawn_weights"):
		# 如果没有关卡配置，使用默认配置
		return AircraftConfig.random_enemy_type(current_wave)
	
	var spawn_weights: Dictionary = enemy_config["spawn_weights"]
	if spawn_weights.is_empty():
		return "enemy_basic"
	
	var total_weight: int = 0
	for weight in spawn_weights.values():
		total_weight += weight
	
	var random_value: int = randi() % total_weight
	var current_weight: int = 0
	
	for enemy_id in spawn_weights.keys():
		current_weight += spawn_weights[enemy_id]
		if random_value < current_weight:
			return enemy_id
	
	return spawn_weights.keys()[0]

# 应用难度系数
func _apply_difficulty_multiplier(enemy: CharacterBody2D, multiplier: float) -> void:
	if multiplier != 1.0:
		# 可以在这里修改敌人的属性，如血量、速度等
		# 具体实现取决于 enemy.gd 的接口
		if enemy.has_method("set_difficulty_multiplier"):
			enemy.set_difficulty_multiplier(multiplier)

# 增加波次
func next_wave() -> void:
	current_wave += 1
	spawned_enemies = 0
	
	# 更新波次配置
	_update_wave_config(current_wave)
	
	spawn_timer.start()
	print("第 " + str(current_wave) + " 波开始!")
	
	# 检查是否是BOSS波
	if current_stage_config != null and current_stage_config.is_boss_wave(current_wave):
		print("警告：BOSS波次!")

# 获取当前波次
func get_current_wave() -> int:
	return current_wave

# 检查是否所有敌机都已生成
func is_all_enemies_spawned() -> bool:
	return spawned_enemies >= max_enemies

# 开始生成敌人
func start_spawning() -> void:
	spawn_timer.start()
	print("开始生成敌人")

# 停止生成敌人
func stop_spawning() -> void:
	spawn_timer.stop()
	print("停止生成敌人")

# 获取当前关卡最大波次
func get_max_waves() -> int:
	if current_stage_config == null:
		return 5
	return current_stage_config.max_waves

# 检查是否已完成所有波次
func is_all_waves_complete() -> bool:
	return current_wave > get_max_waves()
