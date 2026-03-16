extends Node
class_name GlobalStateClass

# ============================================
# 全局状态管理器 - 单例模式
# ============================================
# 用于在场景间共享数据
# 使用方法：GlobalState.current_money += 100
# ============================================

static var instance: GlobalStateClass = null

@onready var EventBus: Node = get_node("/root/EventBus")

# 关卡相关
var stage_manager: Node = null
var current_difficulty: String = ""
var current_stage_id: String = ""

# 玩家数据（本局游戏）
var current_money: int = 0
var current_skills: Array[String] = []
var current_score: int = 0
var player_health: int = 5
var player_max_health: int = 5

# 属性等级
var property_levels: Dictionary = {
	"damage": 1,
	"range": 1,
	"bullet_speed": 1,
	"fire_rate": 1,
	"move_speed": 1,
	"blood": 1,
	"armor": 1
}

# 游戏状态
var is_game_active: bool = false
var is_paused: bool = false
var current_wave: int = 1

# 统计
var total_enemies_killed: int = 0
var total_coins_collected: int = 0
var total_skills_unlocked: int = 0

func _init() -> void:
	if instance != null:
		push_error("GlobalState 是单例，不能重复创建")
		return
	instance = self
	print("GlobalState 初始化完成")

# ============================================
# 关卡方法
# ============================================

func set_stage_manager(manager: Node) -> void:
	stage_manager = manager

func get_stage_manager() -> Node:
	return stage_manager

func set_current_stage(stage_id: String) -> void:
	current_stage_id = stage_id
	current_difficulty = stage_id

# ============================================
# 玩家数据方法
# ============================================

func add_money(amount: int) -> void:
	current_money += amount
	EventBus.emit_player_money_changed(current_money)

func add_score(amount: int) -> void:
	current_score += amount
	EventBus.player_score_changed.emit(amount)

func unlock_skill(skill_id: String) -> bool:
	if current_skills.has(skill_id):
		return false
	current_skills.append(skill_id)
	total_skills_unlocked += 1
	EventBus.skill_drop_collected.emit(skill_id)
	return true

func has_skill(skill_id: String) -> bool:
	return current_skills.has(skill_id)

# ============================================
# 属性等级方法
# ============================================

func get_property_level(property_name: String) -> int:
	if property_levels.has(property_name):
		return property_levels[property_name]
	return 1

func set_property_level(property_name: String, level: int) -> void:
	if property_levels.has(property_name):
		property_levels[property_name] = max(1, min(10, level))  # 限制在1-10级

# ============================================
# 游戏状态方法
# ============================================

func start_game(difficulty: String) -> void:
	is_game_active = true
	is_paused = false
	current_difficulty = difficulty
	current_wave = 1
	total_enemies_killed = 0
	total_coins_collected = 0
	EventBus.game_started.emit(difficulty)

func pause_game() -> void:
	is_paused = true
	EventBus.game_paused.emit()

func resume_game() -> void:
	is_paused = false
	EventBus.game_resumed.emit()

func end_game(is_victory: bool) -> void:
	is_game_active = false
	EventBus.game_over.emit(is_victory, current_score, current_money)

# ============================================
# 统计方法
# ============================================

func record_enemy_killed() -> void:
	total_enemies_killed += 1

func record_coin_collected(amount: int) -> void:
	total_coins_collected += amount

# ============================================
# 重置方法
# ============================================

func reset_game_data() -> void:
	current_money = 0
	current_skills.clear()
	current_score = 0
	player_health = 5
	current_wave = 1
	total_enemies_killed = 0
	total_coins_collected = 0

func reset_session() -> void:
	reset_game_data()
	stage_manager = null
	current_difficulty = ""
	current_stage_id = ""
	is_game_active = false
	is_paused = false
