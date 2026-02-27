extends CharacterBody2D

const SPEED = 300
const FIRE_COOLDOWN = 0.1 # 射击冷却时间（秒）
var bullet_scene = preload("res://bullet.tscn")
var fire_cooldown_timer = 0

func _physics_process(delta):
	var movement = Vector2.ZERO
	
	# 使用Key枚举值
	if Input.is_key_pressed(KEY_W): # W键
		movement.y -= SPEED
	if Input.is_key_pressed(KEY_S): # S键
		movement.y += SPEED
	if Input.is_key_pressed(KEY_A): # A键
		movement.x -= SPEED
	if Input.is_key_pressed(KEY_D): # D键
		movement.x += SPEED
	
	if movement.length() > 0:
		movement = movement.normalized() * SPEED
	
	self.velocity = movement
	move_and_slide()
	
	# 鼠标控制飞机方向
	var mouse_pos = get_viewport().get_mouse_position()
	# 计算角色在屏幕上的位置（考虑地图偏移）
	var world_node = get_parent()
	var player_screen_pos = position + world_node.position
	# 计算从角色屏幕位置到鼠标位置的方向
	var direction = (mouse_pos - player_screen_pos).normalized()
	rotation = direction.angle()
	
	# 检测碰撞
	if world_node:
		var bodies = world_node.get_children()
		for body in bodies:
			if body != self and body is CharacterBody2D:
				var distance = position.distance_to(body.position)
				if distance < 15: # 碰撞半径（缩小）
					print("Player collided with enemy")
					body.queue_free()
					queue_free()

	# 更新射击冷却计时器
	fire_cooldown_timer -= delta
	
	# 发射子弹
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_cooldown_timer <= 0: # 鼠标左键
		fire_bullet()
		fire_cooldown_timer = FIRE_COOLDOWN



func fire_bullet():
	# 实例化子弹
	var bullet = bullet_scene.instantiate()
	# 计算子弹方向（与飞机方向一致）
	var direction = Vector2(cos(rotation), sin(rotation))
	# 设置子弹位置为飞机前方
	bullet.position = position + direction * 20
	# 设置子弹方向
	bullet.direction = direction
	# 将子弹添加到场景中
	get_parent().add_child(bullet)