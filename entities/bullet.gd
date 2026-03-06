extends Area2D

const AircraftConfig = preload("res://config/aircraft_config.gd")

var direction: Vector2 = Vector2(1, 0)
var is_player_bullet: bool = true
var bullet_type: String = "basic"
var pending_target = null
var pending_damage: int = 1
var initial_position: Vector2 = Vector2.ZERO
var bullet_range: float = 300.0

const MAP_SIZE: Vector2 = Vector2(3840, 2160)

func _ready() -> void:
	initial_position = position
	_apply_bullet_config()
	_update_rotation()
	
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_return_to_pool_or_free)
	timer.start()
	
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true
	add_to_group("bullets")

func _update_rotation() -> void:
	var sprite = $Sprite2D
	if sprite:
		rotation = direction.angle()

func _apply_bullet_config() -> void:
	var config = AircraftConfig.get_bullet_config(bullet_type)
	if config.is_empty():
		return
	
	var base_levels = get_meta("base_levels", {})
	
	var sprite = $Sprite2D
	if sprite:
		sprite.modulate = config.color
		sprite.scale = Vector2(config.scale, config.scale)
	
	var damage_level = base_levels.get("damage", 1)
	var range_level = base_levels.get("range", 1)
	var bullet_speed_level = base_levels.get("bullet_speed", 1)
	
	pending_damage = AircraftConfig.BASE_LEVELS["damage"].get(damage_level, 1)
	bullet_range = AircraftConfig.BASE_LEVELS["range"].get(range_level, 300.0)
	
	var bullet_speed = AircraftConfig.BASE_LEVELS["bullet_speed"].get(bullet_speed_level, 400.0)
	self.set_meta("bullet_speed", bullet_speed)

func _return_to_pool_or_free() -> void:
	if has_meta("pool_id"):
		ObjectPool.return_object(get_meta("pool_id"), self)
	else:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body is CharacterBody2D:
		return
	
	var actual_damage: int = pending_damage
	
	if is_player_bullet:
		if body.is_in_group("enemies") or body.name.contains("敌机") or body.name.contains("Enemy"):
			if body.has_method("take_damage"):
				var died: bool = body.take_damage(actual_damage)
				if died:
					add_enemy_killed()
			_return_to_pool_or_free()
	else:
		if body.name == "Player":
			if body.has_method("take_damage"):
				body.take_damage(actual_damage)
			_return_to_pool_or_free()

func _physics_process(delta: float) -> void:
	var speed: float = get_meta("bullet_speed", 800.0)
	
	if is_player_bullet:
		_update_direction_to_mouse()
	
	position += direction * speed * delta
	
	if initial_position.distance_to(position) > bullet_range:
		_return_to_pool_or_free()
		return
	
	if position.x < -100 or position.x > MAP_SIZE.x + 100 or position.y < -100 or position.y > MAP_SIZE.y + 100:
		_return_to_pool_or_free()

func _update_direction_to_mouse() -> void:
	var viewport = get_viewport()
	if viewport == null:
		return
	
	var camera = viewport.get_camera_2d()
	if camera == null:
		return
	
	var mouse_world_pos: Vector2 = camera.get_global_mouse_position()
	var new_direction: Vector2 = (mouse_world_pos - position).normalized()
	rotation = new_direction.angle()
	direction = new_direction

func add_enemy_killed() -> void:
	var main_node = get_parent().get_parent() if get_parent() else null
	if main_node and main_node.has_method("add_enemy_killed"):
		main_node.add_enemy_killed()

func reset() -> void:
	direction = Vector2(1, 0)
	is_player_bullet = true
	bullet_type = "basic"
	pending_target = null
	pending_damage = 1
	position = Vector2.ZERO
	rotation = 0
	monitoring = true
	monitorable = true
	
	for timer in get_children():
		if timer is Timer:
			timer.queue_free()
	
	var sprite = $Sprite2D
	if sprite:
		sprite.rotation = 0
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.scale = Vector2(1, 1)
