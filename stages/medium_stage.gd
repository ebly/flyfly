class_name MediumStage
extends StageConfig

# ============================================
# 中等关卡配置
# ============================================
# 特点：
# - 敌人类型多样化
# - 出现精英敌人
# - 技能奖励：中级技能
# ============================================

func _init():
	stage_id = "medium"
	stage_name = "中等"
	description = "有一定挑战的中等关卡，敌人类型多样"
	max_waves = 5
	spawn_interval = 1.2  # 减少生成间隔，敌人出现更快
	max_enemies_per_wave = 1500  # 增加总敌人数量
	difficulty_multiplier = 1.0
	
	# 过关条件
	target_score = 1000  # 中等关卡需要1000分
	time_limit = 120.0  # 120秒时间限制
	
	# 中等关卡可掉落的技能
	skill_rewards = ["dash", "shield", "rapid_fire", "missile", "homing"]

# 获取指定波次的敌人配置
func get_enemy_config(wave: int) -> Dictionary:
	var config = get_base_enemy_config()
	
	match wave:
		1:
			# 第一波：基础敌机为主
			config["enemy_types"] = ["enemy_basic", "enemy_fast", "enemy_drone"]
			config["spawn_weights"] = {
				"enemy_basic": 40,
				"enemy_fast": 30,
				"enemy_drone": 30
			}
			config["max_enemies"] = 600  # 增加敌人数
			config["spawn_interval"] = 0.7  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 4  # 每次生成4个敌人
			config["elite_chance"] = 0.0
			
		2:
			# 第二波：加入重型敌机
			config["enemy_types"] = ["enemy_basic", "enemy_fast", "enemy_heavy", "enemy_drone"]
			config["spawn_weights"] = {
				"enemy_basic": 30,
				"enemy_fast": 25,
				"enemy_heavy": 25,
				"enemy_drone": 20
			}
			config["max_enemies"] = 750  # 增加敌人数
			config["spawn_interval"] = 0.6  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 5  # 每次生成5个敌人
			config["elite_chance"] = 0.05
			
		3:
			# 第三波：加入自杀式敌机
			config["enemy_types"] = ["enemy_fast", "enemy_heavy", "enemy_kamikaze", "enemy_basic"]
			config["spawn_weights"] = {
				"enemy_fast": 25,
				"enemy_heavy": 25,
				"enemy_kamikaze": 30,
				"enemy_basic": 20
			}
			config["max_enemies"] = 850  # 增加敌人数
			config["spawn_interval"] = 0.5  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 6  # 每次生成6个敌人
			config["elite_chance"] = 0.1
			
		4:
			# 第四波：出现精英敌机
			config["enemy_types"] = ["enemy_heavy", "enemy_elite", "enemy_fast", "enemy_kamikaze"]
			config["spawn_weights"] = {
				"enemy_heavy": 30,
				"enemy_elite": 20,
				"enemy_fast": 25,
				"enemy_kamikaze": 25
			}
			config["max_enemies"] = 950  # 增加敌人数
			config["spawn_interval"] = 0.45  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 8  # 每次生成8个敌人
			config["elite_chance"] = 0.15
			
		5:
			# 第五波：BOSS战
			config["enemy_types"] = ["enemy_boss", "enemy_elite", "enemy_heavy", "enemy_kamikaze"]
			config["spawn_weights"] = {
				"enemy_boss": 10,
				"enemy_elite": 40,
				"enemy_heavy": 30,
				"enemy_kamikaze": 20
			}
			config["max_enemies"] = 1050  # 增加敌人数
			config["spawn_interval"] = 0.4  # 减少生成间隔，敌人出现更快
			config["enemies_per_spawn"] = 10  # 每次生成10个敌人
			config["elite_chance"] = 0.2
			config["boss_wave"] = true
			
		_:
			# 默认配置
			config["enemy_types"] = ["enemy_basic", "enemy_fast"]
			config["spawn_weights"] = {
				"enemy_basic": 50,
				"enemy_fast": 50
			}
	
	return config
