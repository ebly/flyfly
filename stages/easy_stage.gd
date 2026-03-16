class_name EasyStage
extends StageConfig

# ============================================
# 简单关卡配置
# ============================================
# 特点：
# - 敌人血量低、速度慢
# - 敌人类型单一
# - 技能奖励：基础技能
# ============================================

func _init():
	stage_id = "easy"
	stage_name = "简单"
	description = "适合新手的简单关卡，敌人较弱"
	max_waves = 5
	spawn_interval = 1.5  # 减少生成间隔，敌人出现更快
	max_enemies_per_wave = 1500  # 增加总敌人数量
	difficulty_multiplier = 0.8
	
	# 过关条件
	target_score = 5000  # 简单关卡需要5000分
	time_limit = 180.0  # 180秒时间限制
	
	# 简单关卡可掉落的技能
	skill_rewards = ["dash", "shield", "rapid_fire"]

# 获取指定波次的敌人配置
func get_enemy_config(wave: int) -> Dictionary:
	var config = get_base_enemy_config()
	
	match wave:
		1:
			# 第一波：只有基础敌机
			config["enemy_types"] = ["enemy_basic", "enemy_drone"]
			config["spawn_weights"] = {
				"enemy_basic": 60,
				"enemy_drone": 40
			}
			config["max_enemies"] = 500  # 增加敌人数
			config["spawn_interval"] = 0.8  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 3  # 每次生成3个敌人
			config["elite_chance"] = 0.0
				
		2:
			# 第二波：加入高速敌机
			config["enemy_types"] = ["enemy_basic", "enemy_drone", "enemy_fast"]
			config["spawn_weights"] = {
				"enemy_basic": 40,
				"enemy_drone": 30,
				"enemy_fast": 30
			}
			config["max_enemies"] = 600  # 增加敌人数
			config["spawn_interval"] = 0.7  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 4  # 每次生成4个敌人
			config["elite_chance"] = 0.05
			
		3:
			# 第三波：加入少量重型敌机
			config["enemy_types"] = ["enemy_basic", "enemy_fast", "enemy_heavy"]
			config["spawn_weights"] = {
				"enemy_basic": 35,
				"enemy_fast": 35,
				"enemy_heavy": 30
			}
			config["max_enemies"] = 800  # 增加敌人数
			config["spawn_interval"] = 0.6  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 5  # 每次生成5个敌人
			config["elite_chance"] = 0.1
			
		4:
			# 第四波：加入精英敌人
			config["enemy_types"] = ["enemy_basic", "enemy_fast", "enemy_heavy", "enemy_elite"]
			config["spawn_weights"] = {
				"enemy_basic": 30,
				"enemy_fast": 30,
				"enemy_heavy": 25,
				"enemy_elite": 15
			}
			config["max_enemies"] = 900  # 增加敌人数
			config["spawn_interval"] = 0.5  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 6  # 每次生成6个敌人
			config["elite_chance"] = 0.15
			
		5:
			# 第五波：最终波次
			config["enemy_types"] = ["enemy_basic", "enemy_fast", "enemy_heavy", "enemy_elite", "enemy_kamikaze"]
			config["spawn_weights"] = {
				"enemy_basic": 25,
				"enemy_fast": 25,
				"enemy_heavy": 20,
				"enemy_elite": 20,
				"enemy_kamikaze": 10
			}
			config["max_enemies"] = 1000  # 增加敌人数
			config["spawn_interval"] = 0.4  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 8  # 每次生成8个敌人
			config["elite_chance"] = 0.2
				
		_:
			# 默认配置
			config["enemy_types"] = ["enemy_basic", "enemy_drone"]
			config["spawn_weights"] = {
				"enemy_basic": 50,
				"enemy_drone": 50
			}
	
	return config
