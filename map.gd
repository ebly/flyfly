extends Control

func _ready():
	# 连接简单难度点的点击信号
	$EasyPoint.pressed.connect(func():
		# 加载游戏场景
		var game_scene = load("res://game.tscn")
		if game_scene:
			# 替换当前场景为游戏场景
			self.get_tree().change_scene_to_packed(game_scene)
	)
	
	# 连接中等难度点的点击信号
	$MediumPoint.pressed.connect(func():
		# 加载游戏场景
		var game_scene = load("res://game.tscn")
		if game_scene:
			# 替换当前场景为游戏场景
			self.get_tree().change_scene_to_packed(game_scene)
	)
	
	# 连接困难难度点的点击信号
	$HardPoint.pressed.connect(func():
		# 加载游戏场景
		var game_scene = load("res://game.tscn")
		if game_scene:
			# 替换当前场景为游戏场景
			self.get_tree().change_scene_to_packed(game_scene)
	)
	
	# 连接返回按钮的点击信号
	$BackButton.pressed.connect(func():
		# 加载主页面场景
		var main_scene = load("res://main.tscn")
		if main_scene:
			# 替换当前场景为主页面场景
			self.get_tree().change_scene_to_packed(main_scene)
	)