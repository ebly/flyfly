extends Node

# ============================================
# 飞机配置管理器 - 可扩展版本
# ============================================
# 使用说明：
# 1. 添加新飞机：在 AIRCRAFT_CONFIGS 中添加新配置
# 2. 添加新子弹：在 BULLET_TYPES 中添加新配置
# 3. 添加新技能：在 SKILL_TYPES 中添加新配置
# ============================================

# 基础属性等级配置 - 每个属性单独升级，每个属性有10级
const BASE_LEVELS = {
	# 伤害 - 10级
	"damage": {
		1: 1, 2: 2, 3: 3, 4: 4, 5: 5,
		6: 6, 7: 7, 8: 8, 9: 9, 10: 10
	},
	# 射程 - 10级 (像素)
	"range": {
		1: 200.0, 2: 330.0, 3: 360.0, 4: 390.0, 5: 420.0,
		6: 450.0, 7: 480.0, 8: 510.0, 9: 540.0, 10: 600.0
	},
	# 子弹速度 - 10级 (像素/秒)
	"bullet_speed": {
		1: 400.0, 2: 440.0, 3: 480.0, 4: 520.0, 5: 560.0,
		6: 600.0, 7: 640.0, 8: 680.0, 9: 720.0, 10: 800.0
	},
	# 射速 - 10级 (射击间隔秒数，越小越快)
	"fire_rate": {
		1: 0.4, 2: 0.9, 3: 0.8, 4: 0.7, 5: 0.6,
		6: 0.5, 7: 0.4, 8: 0.35, 9: 0.3, 10: 0.25
	},
	# 移动速度 - 10级 (像素/秒)
	"move_speed": {
		1: 150.0, 2: 165.0, 3: 180.0, 4: 195.0, 5: 210.0,
		6: 225.0, 7: 240.0, 8: 255.0, 9: 270.0, 10: 300.0
	},
	# 血量 - 10级
	"blood": {
		1: 5, 2: 6, 3: 7, 4: 8, 5: 9,
		6: 10, 7: 11, 8: 12, 9: 13, 10: 14
	},
	# 护甲 - 10级
	"armor": {
		1: 0, 2: 1, 3: 2, 4: 3, 5: 4,
		6: 5, 7: 6, 8: 7, 9: 8, 10: 9
	}
}

# 子弹类型配置 - 可扩展
const BULLET_TYPES = {
	"basic": {
		"id": "basic",
		"name": "基础子弹",
		"scale": 0.2,
		"color": Color(1, 1, 0, 1),
		"description": "标准子弹，平衡的伤害和速度"
	},
	"fast": {
		"id": "fast",
		"name": "快速子弹",
		"scale": 0.15,
		"color": Color(0, 0.5, 1, 1),
		"description": "高速子弹，适合快速攻击"
	},
	"heavy": {
		"id": "heavy",
		"name": "重型子弹",
		"scale": 0.3,
		"color": Color(1, 0, 0, 1),
		"description": "高伤害但速度较慢"
	},
	"spread": {
		"id": "spread",
		"name": "散射子弹",
		"scale": 0.2,
		"color": Color(0, 1, 0, 1),
		"description": "散射攻击，可同时打击多个目标"
	},
	"plasma": {
		"id": "plasma",
		"name": "等离子弹",
		"scale": 0.4,
		"color": Color(0.5, 0, 1, 1),
		"description": "高伤害能量弹"
	}
}

# 技能类型配置 - 可扩展
const SKILL_TYPES = {

	"spread_shot": {
		"id": "spread_shot",
		"name": "散射攻击",
		"cooldown": 2.0,
		"duration": 0.0,
		"description": "同时发射多枚子弹攻击多个目标",
		"unlockable": true,
		"unlock_cost": 50
	},
	"dash": {
		"id": "dash",
		"name": "冲刺",
		"cooldown": 3.0,
		"duration": 0.3,
		"description": "快速向前冲刺一段距离",
		"unlockable": true,
		"unlock_cost": 100
	},
	"shield": {
		"id": "shield",
		"name": "护盾",
		"cooldown": 5.0,
		"duration": 3.0,
		"description": "获得临时护盾，免疫伤害",
		"unlockable": true,
		"unlock_cost": 150
	},
	"rapid_fire": {
		"id": "rapid_fire",
		"name": "快速射击",
		"cooldown": 4.0,
		"duration": 2.0,
		"description": "短时间内大幅提升射速",
		"unlockable": true,
		"unlock_cost": 200
	},
	"missile": {
		"id": "missile",
		"name": "导弹齐射",
		"cooldown": 8.0,
		"duration": 0.0,
		"description": "发射追踪导弹攻击敌人",
		"unlockable": true,
		"unlock_cost": 300
	},
	"laser": {
		"id": "laser",
		"name": "激光束",
		"cooldown": 6.0,
		"duration": 1.5,
		"description": "发射穿透性激光束",
		"unlockable": true,
		"unlock_cost": 400
	},
	"bomb": {
		"id": "bomb",
		"name": "炸弹",
		"cooldown": 10.0,
		"duration": 0.0,
		"description": "投掷大范围伤害炸弹",
		"unlockable": true,
		"unlock_cost": 500
	},
	"homing": {
		"id": "homing",
		"name": "追踪导弹",
		"cooldown": 7.0,
		"duration": 0.0,
		"description": "发射自动追踪目标的导弹",
		"unlockable": true,
		"unlock_cost": 600
	},
	"explosion": {
		"id": "explosion",
		"name": "爆炸波",
		"cooldown": 9.0,
		"duration": 0.0,
		"description": "释放范围爆炸波，伤害周围敌人",
		"unlockable": true,
		"unlock_cost": 700
	},
	"heal": {
		"id": "heal",
		"name": "治疗",
		"cooldown": 15.0,
		"duration": 0.0,
		"description": "恢复一定量的生命值",
		"unlockable": true,
		"unlock_cost": 800
	}
}

# ============================================
# 飞机配置 - 可扩展
# ============================================# 模板：
# "your_plane_id": {
#     "id": "your_plane_id",
#     "name": "飞机名称",
#     "team": "player" | "enemy",
#     "speed": 移动速度,
#     "health": 血量,
#     "fire_rate": 射击间隔(秒),
#     "bullet_type": "子弹类型ID",
#     "shot_type": "射击类型",  # 可选值：single(单发), double(双发), spread(散弹)
#     "default_skill": "默认技能ID",  # 飞机自带技能
#     "coin_value": 死亡掉落金币(玩家设为0),
#     "texture": "纹理路径",
#     "color": Color(r, g, b, a),
#     "scale": 大小缩放,
#     "description": "描述"
# }
# ============================================

const AIRCRAFT_CONFIGS = {
	# ============================================
	# 玩家飞机 - 可扩展
	# ============================================
	"player_basic": {
		"id": "player_basic",
		"name": "基础战机",
		"team": "player",
		"base": {
			"damage": 1,
			"range": 1,
			"bullet_speed": 1,
			"fire_rate": 1,
			"move_speed": 1,
			"blood": 1,
			"armor": 1,
		},
		"bullet_type": "basic",
		"default_skill": ["heal"],
		"coin_value": 1,
		"texture": "res://icon.svg",
		"color": Color(1, 1, 1, 1),
		"scale": 0.4,
		"description": "平衡的入门级战机，无自带技能"
	},
	"player_fast": {
		"id": "player_fast",
		"name": "高速战机",
		"team": "player",
		"base": {
			"damage": 1,
			"range": 1,
			"bullet_speed": 1,
			"fire_rate": 1,
			"move_speed": 1,
			"blood": 1,
			"armor": 1,
		},
		"bullet_type": "fast",
		"default_skill": [],
		"coin_value": 1,
		"texture": "res://icon.svg",
		"color": Color(0, 0.8, 1, 1),
		"scale": 0.4,
		"description": "高机动性战机，自带冲刺技能"
	},
	"player_heavy": {
		"id": "player_heavy",
		"name": "重型战机",
		"team": "player",
		"base": {
			"damage": 1,
			"range": 1,
			"bullet_speed": 1,
			"fire_rate": 1,
			"move_speed": 1,
			"blood": 1,
			"armor": 1,
		},
		"bullet_type": "heavy",
		"default_skill": [],
		"coin_value": 1,
		"texture": "res://icon.svg",
		"color": Color(0.5, 0.5, 0.5, 1),
		"scale": 0.5,
		"description": "高血量高伤害，自带护盾技能"
	},
	"player_ace": {
		"id": "player_ace",
		"name": "王牌战机",
		"team": "player",
		"base": {
			"damage": 1,
			"range": 1,
			"bullet_speed": 1,
			"fire_rate": 1,
			"move_speed": 1,
			"blood": 1,
			"armor": 1,
		},
		"bullet_type": "spread",
		"default_skill": [],
		"coin_value": 1,
		"texture": "res://icon.svg",
		"color": Color(1, 0.8, 0, 1),
		"scale": 0.45,
		"description": "散射攻击，自带快速射击技能"
	},
	
	# ============================================
	# 敌人飞机 - 可扩展
	# ============================================
	# 敌人子弹库说明：
	# bullet_library: 数组，包含1-3种子弹类型
	# 敌人会随机选择子弹库中的子弹进行射击
	# ============================================
	"enemy_basic": {
		"id": "enemy_basic",
		"name": "基础敌机",
		"team": "enemy",
		"base": {
			"damage": 1,
			"range": 1,
			"bullet_speed": 1,
			"fire_rate": 1,
			"move_speed": 1,
			"blood": 1,
			"armor": 1,
		},
		"bullet_library": ["basic"],
		"default_skill": [],
		"coin_value": 1,
		"texture": "res://icon.svg",
		"color": Color(1, 0, 0, 1),
		"scale": 0.4,
		"description": "最基础的敌人"
	}
}

# 敌机生成权重配置 - 可扩展
const ENEMY_SPAWN_WEIGHTS = {
	"enemy_basic": {"weight": 100, "min_wave": 1}
}

# ============================================
# 配置获取函数
# ============================================

static func get_aircraft_config(aircraft_id: String) -> Dictionary:
	if AIRCRAFT_CONFIGS.has(aircraft_id):
		return AIRCRAFT_CONFIGS[aircraft_id].duplicate(true)
	push_error("未知的飞机ID: " + aircraft_id)
	return {}

static func get_bullet_config(bullet_type: String) -> Dictionary:
	if BULLET_TYPES.has(bullet_type):
		return BULLET_TYPES[bullet_type].duplicate(true)
	push_error("未知的子弹类型: " + bullet_type)
	return {}

static func get_skill_config(skill_type: String) -> Dictionary:
	if SKILL_TYPES.has(skill_type):
		return SKILL_TYPES[skill_type].duplicate(true)
	push_error("未知的技能类型: " + skill_type)
	return {}

# ============================================
# 技能相关函数
# ============================================

# 获取所有可解锁的技能
static func get_unlockable_skills() -> Array:
	var skills = []
	for id in SKILL_TYPES.keys():
		if SKILL_TYPES[id].get("unlockable", false):
			skills.append(id)
	return skills

# 获取技能解锁费用
static func get_skill_unlock_cost(skill_type: String) -> int:
	if SKILL_TYPES.has(skill_type):
		return SKILL_TYPES[skill_type].get("unlock_cost", 0)
	return 0

# 检查技能是否可解锁
static func is_skill_unlockable(skill_type: String) -> bool:
	if SKILL_TYPES.has(skill_type):
		return SKILL_TYPES[skill_type].get("unlockable", false)
	return false

# 获取基础属性等级值
static func get_base_level_value(attribute: String, level: int) -> float:
	if BASE_LEVELS.has(attribute) and BASE_LEVELS[attribute].has(level):
		return BASE_LEVELS[attribute][level]
	match attribute:
		"damage":
			return 1
		"range":
			return 300.0
		"bullet_speed":
			return 400.0
		"fire_rate":
			return 2.0
		"move_speed":
			return 150.0
		"blood":
			return 5
		"armor":
			return 0
		_:
			return 0.0

# 获取最大基础属性等级
static func get_max_base_level() -> int:
	return 10

# 获取所有可升级的基础属性列表
static func get_upgradable_attributes() -> Array:
	return BASE_LEVELS.keys()

# ============================================
# 列表获取函数
# ============================================

static func get_all_aircraft_ids() -> Array:
	return AIRCRAFT_CONFIGS.keys()

static func get_all_bullet_types() -> Array:
	return BULLET_TYPES.keys()

static func get_all_skill_types() -> Array:
	return SKILL_TYPES.keys()

static func get_player_aircraft_ids() -> Array:
	var players = []
	for id in AIRCRAFT_CONFIGS.keys():
		if AIRCRAFT_CONFIGS[id]["team"] == "player":
			players.append(id)
	return players

static func get_enemy_aircraft_ids() -> Array:
	var enemies = []
	for id in AIRCRAFT_CONFIGS.keys():
		if AIRCRAFT_CONFIGS[id]["team"] == "enemy":
			enemies.append(id)
	return enemies

# ============================================
# 敌机生成函数
# ============================================

static func get_spawnable_enemies(wave: int) -> Array:
	var spawnable = []
	for enemy_id in ENEMY_SPAWN_WEIGHTS.keys():
		var config = ENEMY_SPAWN_WEIGHTS[enemy_id]
		if wave >= config["min_wave"]:
			spawnable.append({
				"id": enemy_id,
				"weight": config["weight"]
			})
	return spawnable

static func random_enemy_type(wave: int) -> String:
	var spawnable = get_spawnable_enemies(wave)
	if spawnable.is_empty():
		return "enemy_basic"
	
	var total_weight = 0
	for item in spawnable:
		total_weight += item["weight"]
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for item in spawnable:
		current_weight += item["weight"]
		if random_value < current_weight:
			return item["id"]
	
	return spawnable[0]["id"]

# ============================================
# 验证函数
# ============================================

# 获取敌人的子弹库
static func get_enemy_bullet_library(aircraft_id: String) -> Array:
	if not AIRCRAFT_CONFIGS.has(aircraft_id):
		push_error("飞机配置不存在: " + aircraft_id)
		return ["basic"]
	
	var config = AIRCRAFT_CONFIGS[aircraft_id]
	
	# 如果是敌人，返回子弹库
	if config["team"] == "enemy":
		if config.has("bullet_library"):
			return config["bullet_library"].duplicate()
		# 兼容旧配置，如果没有bullet_library则使用bullet_type
		elif config.has("bullet_type"):
			return [config["bullet_type"]]
	
	# 玩家飞机返回空数组
	return []

# 从子弹库中随机选择一种子弹
static func get_random_bullet_from_library(aircraft_id: String) -> String:
	var library = get_enemy_bullet_library(aircraft_id)
	if library.is_empty():
		return "basic"
	
	var random_index = randi() % library.size()
	return library[random_index]

static func validate_config(aircraft_id: String) -> bool:
	if not AIRCRAFT_CONFIGS.has(aircraft_id):
		push_error("飞机配置不存在: " + aircraft_id)
		return false
	
	var config = AIRCRAFT_CONFIGS[aircraft_id]
	
	var required_fields = ["id", "name", "team", "base", "default_skill"]
	for field in required_fields:
		if not config.has(field):
			push_error("飞机配置缺少字段 '" + field + "': " + aircraft_id)
			return false
	
	if config["team"] == "player":
		if not config.has("bullet_type"):
			push_error("玩家飞机配置缺少 bullet_type: " + aircraft_id)
			return false
	
	if config["team"] == "enemy":
		if config.has("bullet_library"):
			for bullet_type in config["bullet_library"]:
				if not BULLET_TYPES.has(bullet_type):
					push_error("子弹库中无效的子弹类型 '" + bullet_type + "' 在飞机配置: " + aircraft_id)
					return false
	
	return true
