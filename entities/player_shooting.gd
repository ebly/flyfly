extends Node

# ============================================
# 玩家射击逻辑模块
# ============================================
# 负责玩家角色的射击逻辑
# ============================================

# 玩家引用
var player: CharacterBody2D

# 射击冷却时间
var fire_cooldown_timer: float = 0.0

# 基础射击间隔
var fire_interval: float = 1.0  # 1秒

# 射速倍数（受技能影响）
var fire_multiplier: float = 1.0

# 事件总线
var EventBus: Node

func _init(p_player: CharacterBody2D):
	player = p_player

func _ready():
	# 延迟获取事件总线，此时节点已添加到场景树
	EventBus = get_node("/root/EventBus")

func _process(delta: float) -> void:
	_handle_shooting(delta)

# 处理射击逻辑
func _handle_shooting(delta: float) -> void:
	fire_cooldown_timer -= delta
	# 移除鼠标点击条件，改为自动发射
	if fire_cooldown_timer <= 0:
		fire_bullet()
		fire_cooldown_timer = fire_interval

# 发射子弹
func fire_bullet() -> void:
	# 设置子弹类型（从飞机配置获取）
	var bullet_type = "basic"
	var shot_type = "single"  # 默认单发
	
	if not player.config.is_empty():
		bullet_type = player.config.get("bullet_type", "basic")
		shot_type = player.config.get("shot_type", "single")
	
	# 寻找最近的敌人
	var nearest_enemy = _find_nearest_enemy()
	var base_direction: Vector2
	
	if nearest_enemy != null:
		# 如果找到敌人，朝向敌人射击
		base_direction = (nearest_enemy.global_position - player.global_position).normalized()
		print("朝向最近的敌人射击")
	else:
		# 如果没有敌人，使用玩家当前的朝向作为子弹方向
		base_direction = Vector2(cos(player.rotation), sin(player.rotation))
		
		# 如果没有旋转，默认向上发射
		if base_direction.length() < 0.1:
			base_direction = Vector2(0, -1)
		print("没有敌人，朝向角色方向射击")
	
	# 根据射击类型发射子弹
	match shot_type:
		"single":
			# 单发：发射一枚子弹
			_fire_single_bullet(bullet_type, base_direction)
		"double":
			# 双发：发射两枚子弹，左右对称
			_fire_double_bullet(bullet_type, base_direction)
		"spread":
			# 散弹：发射多枚子弹，呈扇形分布
			_fire_spread_bullet(bullet_type, base_direction)
		_:
			# 默认单发
			_fire_single_bullet(bullet_type, base_direction)

# 发射单发子弹
func _fire_single_bullet(bullet_type: String, direction: Vector2) -> void:
	var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullet.is_player_bullet = true
	bullet.bullet_type = bullet_type
	
	# 设置子弹位置和方向
	bullet.position = player.position + direction * 25
	bullet.direction = direction
	bullet.rotation = direction.angle()
	
	# 设置子弹的基础属性等级
	bullet.set_meta("base_levels", player.get_all_base_attribute_levels())
	
	# 添加子弹到场景
	player.get_parent().add_child(bullet)
	
	# 触发子弹发射事件
	EventBus.bullet_fired.emit(bullet_type, bullet.position, direction, true)

# 发射双发子弹
func _fire_double_bullet(bullet_type: String, base_direction: Vector2) -> void:
	var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
	
	# 计算左右两侧的射击方向（15度角）
	var left_angle = base_direction.angle() - deg_to_rad(15)
	var right_angle = base_direction.angle() + deg_to_rad(15)
	var left_direction = Vector2(cos(left_angle), sin(left_angle))
	var right_direction = Vector2(cos(right_angle), sin(right_angle))
	
	# 获取玩家的基础属性等级
	var base_levels = player.get_all_base_attribute_levels()
	
	# 发射左侧子弹
	var left_bullet = bullet_scene.instantiate()
	left_bullet.is_player_bullet = true
	left_bullet.bullet_type = bullet_type
	left_bullet.position = player.position + left_direction * 25
	left_bullet.direction = left_direction
	left_bullet.rotation = left_angle
	left_bullet.set_meta("base_levels", base_levels)
	player.get_parent().add_child(left_bullet)
	
	# 发射右侧子弹
	var right_bullet = bullet_scene.instantiate()
	right_bullet.is_player_bullet = true
	right_bullet.bullet_type = bullet_type
	right_bullet.position = player.position + right_direction * 25
	right_bullet.direction = right_direction
	right_bullet.rotation = right_angle
	right_bullet.set_meta("base_levels", base_levels)
	player.get_parent().add_child(right_bullet)
	
	# 触发子弹发射事件
	EventBus.bullet_fired.emit(bullet_type, left_bullet.position, left_direction, true)
	EventBus.bullet_fired.emit(bullet_type, right_bullet.position, right_direction, true)

# 发射散弹
func _fire_spread_bullet(bullet_type: String, base_direction: Vector2) -> void:
	var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
	var spread_angle = deg_to_rad(30)  # 总扩散角度30度
	var bullet_count = 5  # 5发散弹
	
	# 获取玩家的基础属性等级
	var base_levels = player.get_all_base_attribute_levels()
	
	for i in bullet_count:
		# 计算每枚子弹的角度
		var offset_angle = spread_angle * (i / (bullet_count - 1) - 0.5)
		var current_angle = base_direction.angle() + offset_angle
		var current_direction = Vector2(cos(current_angle), sin(current_angle))
		
		# 创建并发射子弹
		var bullet = bullet_scene.instantiate()
		bullet.is_player_bullet = true
		bullet.bullet_type = bullet_type
		bullet.position = player.position + current_direction * 25
		bullet.direction = current_direction
		bullet.rotation = current_angle
		bullet.set_meta("base_levels", base_levels)
		player.get_parent().add_child(bullet)
		
		# 触发子弹发射事件
		EventBus.bullet_fired.emit(bullet_type, bullet.position, current_direction, true)

# 发射导弹
func fire_missile(angle: float) -> void:
	var missile_scene: PackedScene = preload("res://scenes/bullet.tscn")
	var missile = missile_scene.instantiate()
	missile.is_player_bullet = true
	missile.bullet_type = "plasma"
	missile.position = player.position
	missile.direction = Vector2(cos(angle), sin(angle))
	player.get_parent().add_child(missile)
	
	EventBus.bullet_fired.emit("plasma", missile.position, Vector2(cos(angle), sin(angle)), true)

# 设置射速倍数
func set_fire_multiplier(multiplier: float) -> void:
	fire_multiplier = multiplier

# 设置射击间隔
func set_fire_interval(interval: float) -> void:
	fire_interval = interval

# 获取最近的敌人
func _find_nearest_enemy() -> Node:
	var nearest_enemy = null
	var min_distance = INF
	
	# 获取所有敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# 计算距离
		var distance = player.global_position.distance_to(enemy.global_position)
		
		# 更新最近的敌人
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy
