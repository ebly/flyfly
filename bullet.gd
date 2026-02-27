extends Area2D

const SPEED = 800
var direction = Vector2(1, 0) # 默认向右

func _ready():
	# 设置子弹的生命周期
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0 # 2秒后自动销毁
	timer.one_shot = true
	timer.timeout.connect(func():
		queue_free()
	)
	timer.start()
	
	# 连接碰撞检测信号
	body_entered.connect(func(body):
		print("Bullet hit:", body.name)
		if body is CharacterBody2D:
			# 子弹击中飞机
			print("Destroying body:", body.name)
			body.queue_free()
			print("Destroying bullet")
			queue_free()
	)

func _process(delta):
	# 子弹移动
	position += direction * SPEED * delta

	# 检查是否超出地图范围
	var map_size = Vector2(3840, 2160) # 与地图尺寸一致
	if position.x < -100 or position.x > map_size.x + 100 or position.y < -100 or position.y > map_size.y + 100:
		queue_free()