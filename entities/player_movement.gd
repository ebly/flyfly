extends Node

# ============================================
# 玩家移动控制模块
# ============================================
# 负责玩家角色的移动和旋转控制
# ============================================

# 玩家引用
var player: CharacterBody2D

# 移动速度
var move_speed: float = 500.0

# 旋转速度
var rotation_speed: float = 15.0  # 旋转速度（弧度/秒）

func _init(p_player: CharacterBody2D):
	player = p_player

func _process(delta: float) -> void:
	_handle_movement()
	_handle_rotation()

# 处理玩家移动
func _handle_movement() -> void:
	var movement: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement.x += 1

	if movement.length() > 0:
		movement = movement.normalized() * move_speed

	player.velocity = movement
	player.move_and_slide()
	
	# 调试输出
	if Engine.get_process_frames() % 30 == 0:
		print("Player Pos:", player.position, " Velocity:", player.velocity)

# 处理玩家旋转
func _handle_rotation() -> void:
	var movement: Vector2 = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	
	if movement.length() > 0:
		movement = movement.normalized()
		
		# 根据移动方向设置角色旋转（Godot logo 的正面朝上，需要 -90 度偏移）
		var target_rotation: float = movement.angle() - PI / 2
		
		# 平滑旋转
		var delta: float = get_process_delta_time()
		player.rotation = lerp_angle(player.rotation, target_rotation, rotation_speed * delta)

# 设置移动速度
func set_move_speed(speed: float) -> void:
	move_speed = speed

# 获取移动速度
func get_move_speed() -> float:
	return move_speed
