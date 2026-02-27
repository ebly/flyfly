extends Node2D

var enemy_scene = preload("res://enemy.tscn")
var spawn_timer = null

func _ready():
	# 初始化随机数种子
	randomize()
	print("Enemy generator ready")
	
	# 设置生成敌人的定时器
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = 1.0 # 初始生成间隔
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(func():
		spawn_enemy()
		# 重置定时器为随机间隔
		spawn_timer.wait_time = randf_range(1.0, 3.0)
	)
	spawn_timer.start()
	print("Spawn timer started with interval:", spawn_timer.wait_time)

func spawn_enemy():
	# 实例化敌方飞机
	var enemy = enemy_scene.instantiate()
	# 将敌人添加到场景中
	get_parent().add_child(enemy)
	print("Enemy spawned at position:", enemy.position)