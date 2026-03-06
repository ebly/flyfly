class_name HardStage
extends StageConfig

# ============================================
# 困难关卡配置
# ============================================
# 特点：
# - 敌人属性强化
# - 精英敌人频繁出现
# - 多BOSS战
# - 技能奖励：高级技能
# ============================================

func _init():
	stage_id = "hard"
	stage_name = "困难"
	description = "极具挑战的困难关卡，敌人强大且多样"
	max_waves = 7
	spawn_interval = 1.0  # 减少生成间隔，敌人出现更快
	max_enemies_per_wave = 2000  # 增加总敌人数量
	difficulty_multiplier = 1.5
	
	# 过关条件
	target_score = 2000  # 困难关卡需要2000分
	time_limit = 180.0  # 180秒时间限制
	
	# 困难关卡可掉落的技能（包含所有技能）
	skill_rewards = ["dash", "shield", "rapid_fire", "missile", "laser", "bomb", "homing", "explosion", "spread_shot"]

# 获取指定波次的敌人配置
func get_enemy_config(wave: int) -> Dictionary:
	var config = get_base_enemy_config()
	
	match wave:
		1:
			# 第一波：直接上强度
			config["enemy_types"] = ["enemy_fast", "enemy_heavy", "enemy_kamikaze"]
			config["spawn_weights"] = {
				"enemy_fast": 35,
				"enemy_heavy": 35,
				"enemy_kamikaze": 30
			}
			config["max_enemies"] = 600  # 大幅增加敌人数
			config["spawn_interval"] = 0.6  # 减少生成间隔，敌人出现更快
			config["elite_chance"] = 0.1
			
		2:
			# 第二波：加入精英
			config["enemy_types"] = ["enemy_elite", "enemy_heavy", "enemy_fast", "enemy_kamikaze"]
			config["spawn_weights"] = {
				"enemy_elite": 20,
				"enemy_heavy": 30,
				"enemy_fast": 25,
				"enemy_kamikaze": 25
			}
			config["max_enemies"] = 700  # 大幅增加敌人数
			config["spawn_interval"] = 0.55  # 减少生成间隔，敌人出现更快
			config["elite_chance"] = 0.15
			
		3:
			# 第三波：更多精英
			config["enemy_types"] = ["enemy_elite", "enemy_heavy", "enemy_kamikaze"]
			config["spawn_weights"] = {
				"enemy_elite": 35,
				"enemy_heavy": 35,
				"enemy_kamikaze": 30
			}
			config["max_enemies"] = 800  # 大幅增加敌人数
			config["spawn_interval"] = 0.5  # 减少生成间隔，敌人出现更快
			config["elite_chance"] = 0.2
			
		4:
			# 第四波：混合部队
			config["enemy_types"] = ["enemy_elite", "enemy_heavy", "enemy_fast", "enemy_basic"]
			config["spawn_weights"] = {
				"enemy_elite": 30,
				"enemy_heavy": 30,
				"enemy_fast": 25,
				"enemy_basic": 15
			}
			config["max_enemies"] = 900  # 大幅增加敌人数
			config["spawn_interval"] = 0.45  # 减少生成间隔，敌人出现更快
			config["elite_chance"] = 0.25
			
		5:
			# 第五波：第一个BOSS
			config["enemy_types"] = ["enemy_boss", "enemy_elite", "enemy_heavy"]
			config["spawn_weights"] = {
				"enemy_boss": 15,
				"enemy_elite": 40,
				"enemy_heavy": 45
			}
			config["max_enemies"] = 1000  # 大幅增加敌人数
			config["spawn_interval"] = 0.4  # 减少生成间隔，敌人出现更快
			config["elite_chance"] = 0.3
			config["boss_wave"] = true
			
		6:
			# 第六波：精英海
			config["enemy_types"] = ["enemy_elite", "enemy_heavy", "enemy_kamikaze"]
			config["spawn_weights"] = {
				"enemy_elite": 45,
				"enemy_heavy": 30,
				"enemy_kamikaze": 25
			}
			config["max_enemies"] = 1100  # 大幅增加敌人数
			config["spawn_interval"] = 0.35  # 减少生成间隔，敌人出现更快
			config["elite_chance"] = 0.35
			
		7:
			# 第七波：最终BOSS战
			config["enemy_types"] = ["enemy_boss", "enemy_elite", "enemy_heavy"]
			config["spawn_weights"] = {
				"enemy_boss": 25,
				"enemy_elite": 35,
				"enemy_heavy": 40
			}
			config["max_enemies"] = 1200  # 大幅增加敌人数
			config["spawn_interval"] = 0.3  # 减少生成间隔，敌人出现更快
			config["elite_chance"] = 0.4
			config["boss_wave"] = true
			
		_:
			# 默认配置
			config["enemy_types"] = ["enemy_elite", "enemy_heavy"]
			config["spawn_weights"] = {
				"enemy_elite": 50,
				"enemy_heavy": 50
			}
	
	return config

# 重写技能掉落概率 - 困难关卡掉落率更高
func get_skill_drop_chance(wave: int) -> float:
	# 基础概率 30%，每波增加 3%
	return 0.3 + (wave - 1) * 0.03
