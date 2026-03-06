extends Node

# ============================================
# 玩家技能管理模块
# ============================================
# 负责玩家角色的技能管理
# ============================================

# 玩家引用
var player: CharacterBody2D

# 技能数据
var unlocked_skills: Array = []  # 已解锁的技能
var current_skill_index: int = 0  # 当前选中的技能索引
var skill_cooldowns: Dictionary = {}  # 技能冷却时间

# 技能状态
var is_skill_active: bool = false  # 是否有技能正在激活
var active_skill_timer: float = 0.0  # 激活技能剩余时间
var current_active_skill: String = ""  # 当前激活的技能

# 技能效果
var is_shield_active: bool = false  # 护盾是否激活
var rapid_fire_multiplier: float = 1.0  # 射速倍数

# 事件总线
var EventBus: Node

# 射击模块引用
var shooting_module: Node

func _init(p_player: CharacterBody2D, p_shooting_module: Node):
	player = p_player
	shooting_module = p_shooting_module

func _ready():
	# 延迟获取事件总线，此时节点已添加到场景树
	EventBus = get_node("/root/EventBus")

func _process(delta: float) -> void:
	_update_skill_cooldowns(delta)
	_update_skill_duration(delta)
	_handle_skills()

# 处理技能输入
func _handle_skills() -> void:
	# 使用技能
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		use_skill()

	# 切换技能
	if Input.is_action_just_pressed("ui_scroll_up"):
		next_skill()
	if Input.is_action_just_pressed("ui_scroll_down"):
		previous_skill()

# 更新技能冷却时间
func _update_skill_cooldowns(delta: float) -> void:
	for skill in skill_cooldowns.keys():
		if skill_cooldowns[skill] > 0:
			skill_cooldowns[skill] -= delta

# 更新技能持续时间
func _update_skill_duration(delta: float) -> void:
	if is_skill_active and active_skill_timer > 0:
		active_skill_timer -= delta
		if active_skill_timer <= 0:
			_deactivate_skill()

# 使用当前选中的技能
func use_skill() -> bool:
	var skill_type: String = get_current_skill()
	if skill_type == "none":
		return false
	
	if skill_cooldowns.get(skill_type, 0) > 0:
		return false
	
	var success: bool = _execute_skill(skill_type)
	if success:
		EventBus.player_skill_activated.emit(skill_type)
	return success

# 执行技能
func _execute_skill(skill_type: String) -> bool:
	var skill_config = player.AircraftConfig.get_skill_config(skill_type)
	if skill_config.is_empty():
		return false
	
	print("使用技能: " + skill_config.name)
	
	match skill_type:
		"dash":
			return _skill_dash()
		"shield":
			return _skill_shield(skill_config.duration)
		"rapid_fire":
			return _skill_rapid_fire(skill_config.duration)
		"missile":
			return _skill_missile()
		"laser":
			return _skill_laser(skill_config.duration)
		"bomb":
			return _skill_bomb()
		"homing":
			return _skill_homing()
		"explosion":
			return _skill_explosion()
		"heal":
			return _skill_heal()
		_:
			return false

# 冲刺技能
func _skill_dash() -> bool:
	var dash_direction: Vector2 = Vector2(cos(player.rotation), sin(player.rotation))
	player.position += dash_direction * 200.0
	skill_cooldowns["dash"] = player.AircraftConfig.get_skill_config("dash").cooldown
	return true

# 护盾技能
func _skill_shield(duration: float) -> bool:
	is_shield_active = true
	is_skill_active = true
	active_skill_timer = duration
	current_active_skill = "shield"
	var sprite = player.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(0, 0.5, 1, 1)
	skill_cooldowns["shield"] = player.AircraftConfig.get_skill_config("shield").cooldown
	return true

# 快速射击技能
func _skill_rapid_fire(duration: float) -> bool:
	rapid_fire_multiplier = 3.0
	is_skill_active = true
	active_skill_timer = duration
	current_active_skill = "rapid_fire"
	# 设置射击模块的射速倍数
	if shooting_module and shooting_module.has_method("set_fire_multiplier"):
		shooting_module.set_fire_multiplier(rapid_fire_multiplier)
	skill_cooldowns["rapid_fire"] = player.AircraftConfig.get_skill_config("rapid_fire").cooldown
	return true

# 导弹技能
func _skill_missile() -> bool:
	for i in range(3):
		var angle_offset: float = (i - 1) * 0.3
		if shooting_module and shooting_module.has_method("fire_missile"):
			shooting_module.fire_missile(player.rotation + angle_offset)
	skill_cooldowns["missile"] = player.AircraftConfig.get_skill_config("missile").cooldown
	return true

# 激光技能
func _skill_laser(duration: float) -> bool:
	print("激光技能激活")
	is_skill_active = true
	active_skill_timer = duration
	current_active_skill = "laser"
	skill_cooldowns["laser"] = player.AircraftConfig.get_skill_config("laser").cooldown
	return true

# 炸弹技能
func _skill_bomb() -> bool:
	print("炸弹投掷")
	skill_cooldowns["bomb"] = player.AircraftConfig.get_skill_config("bomb").cooldown
	return true

# 取消激活技能
func _deactivate_skill() -> void:
	is_skill_active = false
	
	match current_active_skill:
		"shield":
			is_shield_active = false
			var sprite = player.get_node_or_null("Sprite2D")
			if sprite and player.has("config") and not player.config.is_empty():
				sprite.modulate = player.config.color
		"rapid_fire":
			rapid_fire_multiplier = 1.0
			# 重置射击模块的射速倍数
			if shooting_module and shooting_module.has_method("set_fire_multiplier"):
				shooting_module.set_fire_multiplier(rapid_fire_multiplier)
	
	current_active_skill = ""

# 切换到下一个技能
func next_skill() -> void:
	if unlocked_skills.size() <= 1:
		return
	current_skill_index = (current_skill_index + 1) % unlocked_skills.size()
	var skill: String = get_current_skill()
	print("切换技能: " + skill)
	EventBus.player_skill_switched.emit(skill)

# 切换到上一个技能
func previous_skill() -> void:
	if unlocked_skills.size() <= 1:
		return
	current_skill_index = (current_skill_index - 1 + unlocked_skills.size()) % unlocked_skills.size()
	var skill: String = get_current_skill()
	print("切换技能: " + skill)
	EventBus.player_skill_switched.emit(skill)

# 获取当前选中的技能
func get_current_skill() -> String:
	if unlocked_skills.is_empty():
		return "none"
	return unlocked_skills[current_skill_index]

# 检查是否拥有技能
func has_skill(skill_type: String) -> bool:
	return unlocked_skills.has(skill_type)

# 解锁技能
func unlock_skill(skill_type: String) -> bool:
	if not player.AircraftConfig.is_skill_unlockable(skill_type):
		return false
	
	if unlocked_skills.has(skill_type):
		return false
	
	unlocked_skills.append(skill_type)
	skill_cooldowns[skill_type] = 0.0
	
	print("解锁技能: " + skill_type)
	return true

# 初始化技能
func init_skills(skills: Array) -> void:
	unlocked_skills = skills.duplicate()
	for skill in unlocked_skills:
		skill_cooldowns[skill] = 0.0

# 获取技能冷却时间
func get_skill_cooldown(skill_type: String) -> float:
	return skill_cooldowns.get(skill_type, 0.0)

# 获取已解锁的技能列表
func get_unlocked_skills() -> Array:
	return unlocked_skills.duplicate()

# 应用技能效果到玩家
func apply_skill_effects():
	# 这里可以添加技能效果的应用逻辑
	pass

# 追踪导弹技能
func _skill_homing() -> bool:
	for i in range(5):
		var angle_offset: float = (i - 2) * 0.2
		if shooting_module and shooting_module.has_method("fire_missile"):
			shooting_module.fire_missile(player.rotation + angle_offset, true)
	skill_cooldowns["homing"] = player.AircraftConfig.get_skill_config("homing").cooldown
	return true

# 爆炸波技能
func _skill_explosion() -> bool:
	# 创建爆炸范围检测
	var explosion_radius = 150.0
	var explosion_damage = 3
	
	# 获取场景中的所有敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# 对爆炸范围内的敌人造成伤害
	for enemy in enemies:
		if enemy is CharacterBody2D:
			var distance = enemy.position.distance_to(player.position)
			if distance <= explosion_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(explosion_damage)
	
	print("释放爆炸波，伤害范围: " + str(explosion_radius) + "，伤害: " + str(explosion_damage))
	skill_cooldowns["explosion"] = player.AircraftConfig.get_skill_config("explosion").cooldown
	return true

# 治疗技能
func _skill_heal() -> bool:
	# 恢复1点生命值
	if player.has_method("heal"):
		player.heal(1)
	else:
		# 兼容没有heal方法的情况
		player.current_health = min(player.current_health + 1, player.max_health)
	
	print("使用治疗技能，当前生命值: " + str(player.current_health) + "/" + str(player.max_health))
	skill_cooldowns["heal"] = player.AircraftConfig.get_skill_config("heal").cooldown
	return true
