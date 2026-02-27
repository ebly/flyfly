extends CharacterBody2D

const SPEED = 100
var bullet_scene = preload("res://bullet.tscn")
var fire_timer = null

# 全局变量，存储玩家的金钱
var money = 0

func _ready():
	# 设置随机初始位置（四面八方）
	var screen_size = get_viewport().get_visible_rect().size
	print("Screen size:", screen_size)
	
	# 随机选择一个方向
	var direction = randf_range(0, 360)
	var spawn_distance = 100
	var spawn_x
	var spawn_y
	
	if direction < 90: # 右侧
		spawn_x = screen_size.x + spawn_distance
		spawn_y = randf_range(0, screen_size.y)
	elif direction < 180: # 上方
		spawn_x = randf_range(0, screen_size.x)
		spawn_y = -spawn_distance
	elif direction < 270: # 左侧
		spawn_x = -spawn_distance
		spawn_y = randf_range(0, screen_size.y)
	else: # 下方
		spawn_x = randf_range(0, screen_size.x)
		spawn_y = screen_size.y + spawn_distance
	
	position = Vector2(spawn_x, spawn_y)
	print("Enemy spawn position:", position)
	
	# 设置发射子弹的定时器
	fire_timer = Timer.new()
	add_child(fire_timer)
	fire_timer.wait_time = randf_range(1.0, 3.0) # 随机发射间隔
	fire_timer.autostart = true
	fire_timer.timeout.connect(func():
		fire_bullet()
	)

func _physics_process(_delta):
	# 向屏幕中心移动
	var screen_size = get_viewport().get_visible_rect().size
	var center = Vector2(screen_size.x / 2, screen_size.y / 2)
	var direction = (center - position).normalized()
	var movement = direction * SPEED
	self.velocity = movement
	move_and_slide()
	
	# 检测碰撞
	var world = get_parent()
	if world:
		var bodies = world.get_children()
		for body in bodies:
			if body != self and body is CharacterBody2D:
				var distance = position.distance_to(body.position)
				if distance < 15: # 碰撞半径（缩小）
					print("Enemy collided with player")
					# 增加金钱
					money += 1
					print("获得1块钱，当前金钱: " + str(money))
					body.queue_free()
					queue_free()

	# 检查是否超出屏幕范围
	if position.x < -50:
		queue_free()

func fire_bullet():
	# 实例化子弹
	var bullet = bullet_scene.instantiate()
	# 设置子弹位置为飞机前方
	bullet.position = position + Vector2(-20, 0)
	# 设置子弹方向
	bullet.direction = Vector2(-1, 0) # 向左
	# 将子弹添加到场景中
	get_parent().add_child(bullet)