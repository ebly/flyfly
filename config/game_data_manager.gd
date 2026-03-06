extends Node

# ============================================
# 游戏数据管理器 - 持久化数据
# ============================================
# 这个管理器保存跨游戏会话的数据
# 包括：总积分、解锁的皮肤、武器、血量升级等
# ============================================

const SAVE_FILE_PATH = "user://game_data.save"

# 玩家永久数据
var total_score: int = 0  # 总积分（永久保存）
var unlocked_skins: Array = []  # 已解锁的皮肤
var unlocked_weapons: Array = []  # 已解锁的武器类型
var max_health_upgrade: int = 0  # 血量升级等级
var speed_upgrade: int = 0  # 速度升级等级

# 升级配置
const UPGRADE_CONFIG = {
	"max_health": {
		"base_cost": 500,
		"cost_increase": 200,
		"max_level": 5,
		"bonus_per_level": 1
	},
	"speed": {
		"base_cost": 300,
		"cost_increase": 150,
		"max_level": 5,
		"bonus_per_level": 20
	}
}

# 皮肤解锁配置
const SKIN_CONFIG = {
	"skin_gold": {"name": "黄金战机", "cost": 1000, "color": Color(1, 0.8, 0, 1)},
	"skin_stealth": {"name": "隐形战机", "cost": 2000, "color": Color(0.2, 0.2, 0.3, 1)},
	"skin_legendary": {"name": "传说战机", "cost": 5000, "color": Color(1, 0, 1, 1)}
}

# 武器解锁配置
const WEAPON_CONFIG = {
	"weapon_plasma": {"name": "等离子炮", "cost": 1500, "bullet_type": "plasma"},
	"weapon_spread": {"name": "散射炮", "cost": 2500, "bullet_type": "spread"}
}

func _ready():
	load_data()

# 保存数据到文件
func save_data():
	var data_to_save = {
		"total_score": total_score,
		"unlocked_skins": unlocked_skins,
		"unlocked_weapons": unlocked_weapons,
		"max_health_upgrade": max_health_upgrade,
		"speed_upgrade": speed_upgrade
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data_to_save)
		file.close()
		print("游戏数据已保存")

# 从文件加载数据
func load_data():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("没有找到存档文件，使用默认数据")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()
		
		total_score = loaded_data.get("total_score", 0)
		unlocked_skins = loaded_data.get("unlocked_skins", [])
		unlocked_weapons = loaded_data.get("unlocked_weapons", [])
		max_health_upgrade = loaded_data.get("max_health_upgrade", 0)
		speed_upgrade = loaded_data.get("speed_upgrade", 0)
		
		print("游戏数据已加载，总积分: " + str(total_score))

# 添加积分
func add_score(amount: int):
	total_score += amount
	save_data()
	print("获得积分: " + str(amount) + "，总积分: " + str(total_score))

# 检查是否已解锁皮肤
func has_skin(skin_id: String) -> bool:
	return unlocked_skins.has(skin_id)

# 解锁皮肤
func unlock_skin(skin_id: String) -> bool:
	if has_skin(skin_id):
		return false
	
	if not SKIN_CONFIG.has(skin_id):
		return false
	
	var cost = SKIN_CONFIG[skin_id].cost
	if total_score < cost:
		return false
	
	total_score -= cost
	unlocked_skins.append(skin_id)
	save_data()
	print("解锁皮肤: " + SKIN_CONFIG[skin_id].name)
	return true

# 检查是否已解锁武器
func has_weapon(weapon_id: String) -> bool:
	return unlocked_weapons.has(weapon_id)

# 解锁武器
func unlock_weapon(weapon_id: String) -> bool:
	if has_weapon(weapon_id):
		return false
	
	if not WEAPON_CONFIG.has(weapon_id):
		return false
	
	var cost = WEAPON_CONFIG[weapon_id].cost
	if total_score < cost:
		return false
	
	total_score -= cost
	unlocked_weapons.append(weapon_id)
	save_data()
	print("解锁武器: " + WEAPON_CONFIG[weapon_id].name)
	return true

# 升级血量
func upgrade_max_health() -> bool:
	var config = UPGRADE_CONFIG["max_health"]
	if max_health_upgrade >= config.max_level:
		return false
	
	var cost = config.base_cost + (max_health_upgrade * config.cost_increase)
	if total_score < cost:
		return false
	
	total_score -= cost
	max_health_upgrade += 1
	save_data()
	print("血量升级至等级: " + str(max_health_upgrade))
	return true

# 升级速度
func upgrade_speed() -> bool:
	var config = UPGRADE_CONFIG["speed"]
	if speed_upgrade >= config.max_level:
		return false
	
	var cost = config.base_cost + (speed_upgrade * config.cost_increase)
	if total_score < cost:
		return false
	
	total_score -= cost
	speed_upgrade += 1
	save_data()
	print("速度升级至等级: " + str(speed_upgrade))
	return true

# 获取升级费用
func get_upgrade_cost(upgrade_type: String) -> int:
	if not UPGRADE_CONFIG.has(upgrade_type):
		return 0
	
	var config = UPGRADE_CONFIG[upgrade_type]
	var current_level = 0
	
	match upgrade_type:
		"max_health":
			current_level = max_health_upgrade
		"speed":
			current_level = speed_upgrade
	
	if current_level >= config.max_level:
		return -1  # 已满级
	
	return config.base_cost + (current_level * config.cost_increase)

# 获取当前升级等级
func get_upgrade_level(upgrade_type: String) -> int:
	match upgrade_type:
		"max_health":
			return max_health_upgrade
		"speed":
			return speed_upgrade
	return 0

# 获取升级提供的加成
func get_upgrade_bonus(upgrade_type: String) -> int:
	if not UPGRADE_CONFIG.has(upgrade_type):
		return 0
	
	var config = UPGRADE_CONFIG[upgrade_type]
	var level = get_upgrade_level(upgrade_type)
	return level * config.bonus_per_level

# 获取所有可解锁的皮肤
func get_available_skins() -> Dictionary:
	return SKIN_CONFIG

# 获取所有可解锁的武器
func get_available_weapons() -> Dictionary:
	return WEAPON_CONFIG

# 重置所有数据（调试用）
func reset_all_data():
	total_score = 0
	unlocked_skins = []
	unlocked_weapons = []
	max_health_upgrade = 0
	speed_upgrade = 0
	save_data()
	print("所有数据已重置")
