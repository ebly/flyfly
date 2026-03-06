extends "res://entities/aircraft_base.gd"

const GameDataManager = preload("res://config/game_data_manager.gd")
const PlayerMovement = preload("res://entities/player_movement.gd")
const PlayerShooting = preload("res://entities/player_shooting.gd")
const PlayerSkills = preload("res://entities/player_skills.gd")

@onready var global_state = get_node("/root/GlobalState")
@onready var event_bus = get_node("/root/EventBus")

# 本局游戏数据（临时）
var current_money: int = 0  # 本局金币
var current_score: int = 0  # 本局积分

# 基础属性等级 - 每个属性单独管理，初始为1级
var base_attribute_levels: Dictionary = {
	"damage": 1,
	"range": 1,
	"bullet_speed": 1,
	"fire_rate": 1,
	"move_speed": 1,
	"blood": 1,
	"armor": 1
}

# 模块引用
var movement_module: PlayerMovement
var shooting_module: PlayerShooting
var skills_module: PlayerSkills

# AircraftConfig 引用已在父类中定义
func _init():
	aircraft_id = "player_basic"

func _ready() -> void:
	super._ready()
	_apply_permanent_upgrades()
	_restore_from_global_state()
	
	# 添加到玩家组
	add_to_group("player")
	
	# 初始化模块
	_init_modules()
	
	# 设置拾取区域的碰撞检测
	var pickup_area = get_node_or_null("PickupArea")
	if pickup_area:
		pickup_area.area_entered.connect(_on_pickup_area_entered)
	
	# 发送玩家生成事件
	event_bus.player_spawned.emit(self)
	event_bus.emit_player_health_changed(current_health, max_health)

# 初始化模块
func _init_modules():
	movement_module = PlayerMovement.new(self)
	movement_module.move_speed = AircraftConfig.BASE_LEVELS["move_speed"].get(1, 150.0)
	add_child(movement_module)
	
	var fire_rate_level = base_attribute_levels.get("fire_rate", 1)
	var fire_interval = AircraftConfig.BASE_LEVELS["fire_rate"].get(fire_rate_level, 1.0)
	shooting_module = PlayerShooting.new(self)
	shooting_module.set_fire_interval(fire_interval)
	add_child(shooting_module)
	
	skills_module = PlayerSkills.new(self, shooting_module)
	if global_state.instance != null:
		skills_module.init_skills(global_state.instance.current_skills)
	add_child(skills_module)

func _restore_from_global_state() -> void:
	if global_state.instance != null:
		current_money = global_state.instance.current_money

# 应用永久升级
func _apply_permanent_upgrades() -> void:
	var game_data = GameDataManager.new()
	
	var health_bonus: int = game_data.get_upgrade_bonus("max_health")
	max_health += health_bonus
	current_health = max_health
	
	_apply_all_attribute_bonuses()
	
	print("应用永久升级 - 血量: +" + str(health_bonus))

# 应用所有属性等级加成
func _apply_all_attribute_bonuses() -> void:
	_apply_blood_bonus()
	_apply_armor_bonus()
	_apply_move_speed_bonus()
	_apply_fire_rate_bonus()

# 应用血量等级加成
func _apply_blood_bonus() -> void:
	var blood_level = base_attribute_levels.get("blood", 1)
	var final_health = AircraftConfig.BASE_LEVELS["blood"].get(blood_level, 5)
	
	var health_increase = final_health - max_health
	max_health = final_health
	current_health += health_increase
	if current_health > max_health:
		current_health = max_health
	
	print("应用血量等级加成 - 等级: " + str(blood_level) + ", 血量: " + str(final_health))

# 应用护甲等级加成
func _apply_armor_bonus() -> void:
	var armor_level = base_attribute_levels.get("armor", 1)
	var final_armor = AircraftConfig.BASE_LEVELS["armor"].get(armor_level, 0)
	
	armor = final_armor
	
	print("应用护甲等级加成 - 等级: " + str(armor_level) + ", 护甲: " + str(final_armor))

# 应用移动速度等级加成
func _apply_move_speed_bonus() -> void:
	var move_speed_level = base_attribute_levels.get("move_speed", 1)
	var final_speed = AircraftConfig.BASE_LEVELS["move_speed"].get(move_speed_level, 150.0)
	
	if movement_module:
		movement_module.set_move_speed(final_speed)
	
	print("应用移动速度等级加成 - 等级: " + str(move_speed_level) + 
		", 速度: " + str(final_speed))

# 应用射速等级加成
func _apply_fire_rate_bonus() -> void:
	var fire_rate_level = base_attribute_levels.get("fire_rate", 1)
	var fire_interval = AircraftConfig.BASE_LEVELS["fire_rate"].get(fire_rate_level, 1.0)
	
	if shooting_module:
		shooting_module.set_fire_interval(fire_interval)
	
	print("应用射速等级加成 - 等级: " + str(fire_rate_level) + 
		", 射击间隔: " + str(fire_interval) + "秒")

# 重写设置攻击等级函数，添加属性加成更新
func set_base_attribute_level(attribute: String, level: int) -> bool:
	var result = false
	# 检查属性是否可升级
	if not AircraftConfig.get_upgradable_attributes().has(attribute):
		return result
	
	# 限制等级范围
	var max_level = AircraftConfig.get_max_base_level()
	base_attribute_levels[attribute] = clamp(level, 1, max_level)
	result = true
	
	# 根据属性类型更新对应的值
	match attribute:
		"move_speed":
			_apply_move_speed_bonus()
		"blood":
			_apply_blood_bonus()
		"armor":
			_apply_armor_bonus()
		"fire_rate":
			_apply_fire_rate_bonus()
	
	return result

# 获取基础属性等级
func get_base_attribute_level(attribute: String) -> int:
	return base_attribute_levels.get(attribute, 1)

# 提升基础属性等级
func increase_base_attribute_level(attribute: String, amount: int = 1) -> bool:
	var current_level = get_base_attribute_level(attribute)
	return set_base_attribute_level(attribute, current_level + amount)

# 获取所有基础属性等级
func get_all_base_attribute_levels() -> Dictionary:
	return base_attribute_levels.duplicate(true)

func _physics_process(_delta: float) -> void:
	if config.is_empty():
		return
	
	# 检查与敌人的碰撞
	_check_enemy_collision()

# 技能相关方法（代理给技能模块）
func use_skill() -> bool:
	return skills_module.use_skill()

func next_skill() -> void:
	skills_module.next_skill()

func previous_skill() -> void:
	skills_module.previous_skill()

func unlock_skill(skill_type: String) -> bool:
	var success = skills_module.unlock_skill(skill_type)
	if success:
		# 同步到全局状态
		if global_state.instance != null:
			global_state.instance.unlock_skill(skill_type)
	return success

func has_skill(skill_type: String) -> bool:
	return skills_module.has_skill(skill_type)

func get_current_skill() -> String:
	return skills_module.get_current_skill()

# 移动相关方法（代理给移动模块）
func set_move_speed(speed: float) -> void:
	movement_module.set_move_speed(speed)

func get_move_speed() -> float:
	return movement_module.get_move_speed()

# 射击相关方法（代理给射击模块）
func set_fire_interval(interval: float) -> void:
	shooting_module.set_fire_interval(interval)

func fire_bullet() -> void:
	shooting_module.fire_bullet()

func fire_missile(angle: float) -> void:
	if shooting_module.has_method("fire_missile"):
		shooting_module.fire_missile(angle)

# 添加金币
func add_money(amount: int) -> void:
	current_money += amount
	global_state.instance.add_money(amount)
	print("获得金币: " + str(amount) + ", 当前: " + str(current_money))

# 添加积分
func add_score(amount: int) -> void:
	current_score += amount
	global_state.instance.add_score(amount)
	print("获得积分: " + str(amount) + ", 当前: " + str(current_score))

# 处理拾取区域的碰撞
func _on_pickup_area_entered(area: Area2D) -> void:
	print("拾取区域检测到碰撞")
	
	# 直接尝试访问属性，使用if语句检查是否为null
	if area.get("value") != null:
		var coin_value = area.get("value")
		add_money(coin_value)
		print("拾取金币: " + str(coin_value))
		
		# 播放金币拾取效果
		VisualEffectManager.play_pickup_effect("coin", area.position, area.get_parent())
		
		area.queue_free()
	elif area.get("skill_type") != null:
		var skill_type = area.get("skill_type")
		unlock_skill(skill_type)
		print("拾取技能: " + skill_type)
		
		# 播放技能拾取效果
		VisualEffectManager.play_pickup_effect("skill", area.position, area.get_parent())
		
		area.queue_free()

# 移除不需要的技能实现方法，已移到skills_module中

# 移除不需要的射击实现方法，已移到shooting_module中

# 重写：受到伤害
func _on_damage_taken(damage: int) -> void:
	# 检查护盾是否激活
	if skills_module.is_shield_active:
		print("护盾抵挡了伤害")
		current_health += damage  # 恢复被扣除的血量
		return
	
	event_bus.emit_player_health_changed(current_health, max_health)

# 重写：死亡前处理
func _on_before_die() -> void:
	# 保存积分到永久数据
	var game_data = GameDataManager.new()
	game_data.add_score(current_score)
	
	# 发送玩家死亡事件
	event_bus.player_died.emit()
	global_state.instance.end_game(false)
	
	trigger_game_over("角色死亡")

func trigger_game_over(reason: String) -> void:
	var main_node = get_parent().get_parent()
	if main_node and main_node.has_method("game_over"):
		main_node.game_over(reason)

# 胜利时保存数据
func on_victory() -> void:
	# 保存积分
	var game_data = GameDataManager.new()
	game_data.add_score(current_score)
	print("胜利！获得积分: " + str(current_score))
	
	global_state.instance.end_game(true)

# 获取本局数据（用于结算）
func get_game_data() -> Dictionary:
	# 从技能模块获取技能列表
	var skills_list = []
	if skills_module and skills_module.has_method("get_unlocked_skills"):
		skills_list = skills_module.get_unlocked_skills()
	
	return {
		"money": current_money,
		"score": current_score,
		"skills": skills_list.duplicate()
	}

# 检查与敌人的碰撞
func _check_enemy_collision() -> void:
	# 检查是否与敌人组中的任何节点发生碰撞
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_colliding_with(enemy):
			print("玩家与敌人碰撞，准备销毁")
			
			# 销毁敌人
			if enemy.has_method("die"):
				enemy.die()
			
			# 获取主游戏节点
			var main_node = get_parent().get_parent()
			
			# 立即销毁玩家
			queue_free()
			
			# 如果找到了主游戏节点，创建延迟显示结算界面的逻辑
			if main_node:
				# 创建一个临时节点来处理延迟
				var delay_node = Node.new()
				main_node.add_child(delay_node)
				
				# 创建定时器，2-3秒后显示结算界面
				var timer: Timer = Timer.new()
				timer.wait_time = randf_range(2, 3)
				timer.one_shot = true
				
				# 连接定时器信号
				timer.timeout.connect(func():
					print("延迟结束，显示结算界面")
					# 触发游戏结束
					main_node.game_over("与敌人相撞")
					# 清理临时节点
					delay_node.queue_free()
				)
				
				delay_node.add_child(timer)
				timer.start()
			break

# 检查是否与另一个CharacterBody2D发生碰撞
func is_colliding_with(other: CharacterBody2D) -> bool:
	# 获取自身的碰撞形状
	var my_collision_shape = get_node("CollisionShape2D")
	var other_collision_shape = other.get_node("CollisionShape2D")
	
	if not my_collision_shape or not other_collision_shape:
		return false
	
	# 获取碰撞形状的全局位置
	var my_global_pos: Vector2 = my_collision_shape.get_global_position()
	var other_global_pos: Vector2 = other_collision_shape.get_global_position()
	
	# 计算两个碰撞形状之间的距离
	var distance: float = my_global_pos.distance_to(other_global_pos)
	
	# 检查距离是否小于两个碰撞形状的半径之和
	var my_radius: float = (my_collision_shape.shape as CircleShape2D).radius
	var other_radius: float = (other_collision_shape.shape as CircleShape2D).radius
	
	return distance < (my_radius + other_radius)
