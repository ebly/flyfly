extends Control

var money = 0

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
	
	# 连接商店按钮的点击信号
	$ShopButton.pressed.connect(func():
		# 显示商店界面
		$Shop.visible = true
		# 更新金钱显示
		$Shop/MoneyLabel.text = "金钱: " + str(money)
	)
	
	# 连接关闭按钮的点击信号
	$Shop/CloseButton.pressed.connect(func():
		# 隐藏商店界面
		$Shop.visible = false
	)
	
	# 连接购买按钮的点击信号
	$Shop/ItemList/Item1/BuyButton.pressed.connect(func():
		# 武器升级价格
		var price = 10
		if money >= price:
			# 扣除金钱
			money -= price
			# 更新金钱显示
			$Shop/MoneyLabel.text = "金钱: " + str(money)
			print("购买了武器升级")
		else:
			print("金钱不足")
	)
	
	$Shop/ItemList/Item2/BuyButton.pressed.connect(func():
		# 护盾升级价格
		var price = 15
		if money >= price:
			# 扣除金钱
			money -= price
			# 更新金钱显示
			$Shop/MoneyLabel.text = "金钱: " + str(money)
			print("购买了护盾升级")
		else:
			print("金钱不足")
	)