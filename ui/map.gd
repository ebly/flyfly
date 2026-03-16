extends Control

const StageManager = preload("res://stages/stage_manager.gd")


# 关卡管理器
var stage_manager: StageManager = null

# 本局游戏数据
var current_money: int = 0
var current_skills: Array = []
var current_score: int = 0
var score_label: Label = null
var money_label: Label = null

func _ready() -> void:
	# 初始化全局状态（如果是新会话）
	if GlobalState.instance == null:
		var gs: Node = GlobalState.new()
		add_child(gs)
	
	# 获取显示控件（带安全检查）
	score_label = $ScoreLabel if has_node("ScoreLabel") else null
	money_label = $MoneyLabel if has_node("MoneyLabel") else null
	
	# 从全局状态恢复数据
	if GlobalState.instance != null:
		current_money = GlobalState.instance.current_money
		current_skills = GlobalState.instance.current_skills.duplicate()
		current_score = GlobalState.instance.current_score
	
	# 初始化关卡管理器
	_init_stage_manager()
	
	# 连接事件
	_connect_events()
	
	# 初始化显示
	_update_ui()
	
	# 连接简单难度点的点击信号
	if has_node("EasyPoint"):
		$EasyPoint.pressed.connect(func() -> void: _start_game("easy"))
	else:
		print("警告: 未找到 EasyPoint 节点")

	# 连接中等难度点的点击信号
	if has_node("MediumPoint"):
		$MediumPoint.pressed.connect(func() -> void: _start_game("medium"))
	else:
		print("警告: 未找到 MediumPoint 节点")

	# 连接困难难度点的点击信号
	if has_node("HardPoint"):
		$HardPoint.pressed.connect(func() -> void: _start_game("hard"))
	else:
		print("警告: 未找到 HardPoint 节点")

	# 连接返回按钮的点击信号
	if has_node("BackButton"):
		$BackButton.pressed.connect(func() -> void:
			# 加载主页面场景
			var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
			if main_scene:
				self.get_tree().change_scene_to_packed(main_scene)
		)
	else:
		print("警告: 未找到 BackButton 节点")

	# 连接商店按钮的点击信号
	if has_node("ShopButton"):
		$ShopButton.pressed.connect(func() -> void: _open_shop())
	else:
		print("警告: 未找到 ShopButton 节点")

	# 连接机舱按钮的点击信号
	if has_node("CabinButton"):
		$CabinButton.pressed.connect(func() -> void: _open_cabin())
	else:
		print("警告: 未找到 CabinButton 节点")

# 连接事件总线
func _connect_events() -> void:
	EventBus.game_over.connect(_on_game_over)

# 初始化关卡管理器
func _init_stage_manager() -> void:
	stage_manager = StageManager.new()
	
	# 注册所有关卡
	stage_manager.register_stage("easy", EasyStage.new())
	stage_manager.register_stage("medium", MediumStage.new())
	stage_manager.register_stage("hard", HardStage.new())
	
	print("关卡管理器初始化完成，已注册关卡: " + str(stage_manager.get_all_stage_ids()))

# 开始游戏
func _start_game(difficulty: StringName) -> void:
	print("开始游戏，难度: " + String(difficulty))
	print("当前金币: " + str(current_money) + ", 技能: " + str(current_skills))
	
	# 设置当前关卡
	if stage_manager != null:
		stage_manager.set_current_stage(String(difficulty))
		
		# 获取关卡信息并显示
		var stage_config: StageConfig = stage_manager.get_current_stage_config()
		if stage_config != null:
			print("关卡名称: " + stage_config.stage_name)
			print("关卡描述: " + stage_config.description)
			print("最大波次: " + str(stage_config.max_waves))
			print("技能奖励: " + str(stage_config.skill_rewards))
		
		# 将关卡管理器存储到全局，供游戏场景使用
		if GlobalState.instance != null:
			GlobalState.instance.set_stage_manager(stage_manager)
			GlobalState.instance.set_current_stage(String(difficulty))
			GlobalState.instance.current_money = current_money
			GlobalState.instance.current_skills = current_skills.duplicate()
	
	# 加载游戏场景
	var game_scene: PackedScene = load("res://scenes/game.tscn") as PackedScene
	if game_scene:
		self.get_tree().change_scene_to_packed(game_scene)

# 打开商店
func _open_shop() -> void:
	var shop_scene: PackedScene = load("res://scenes/shop.tscn") as PackedScene
	if shop_scene:
		var shop: Node = shop_scene.instantiate()
		shop.current_money = current_money
		shop.current_skills = current_skills
		get_tree().root.add_child(shop)

# 打开机舱
func _open_cabin() -> void:
	var cabin_scene: PackedScene = load("res://scenes/aircraft_cabin.tscn") as PackedScene
	if cabin_scene:
		var cabin: Node = cabin_scene.instantiate()
		cabin.current_money = current_money
		cabin.current_skills = current_skills
		get_tree().root.add_child(cabin)

# 游戏结束回调
func _on_game_over(is_victory: bool, score: int, money: int) -> void:
	if is_victory:
		on_game_victory(money, GlobalState.instance.current_skills.duplicate(), score)
	else:
		on_game_defeat(score)

# 游戏胜利后调用（从游戏场景返回时）
func on_game_victory(money: int, skills: Array, score: int) -> void:
	current_money = money
	current_skills = skills
	current_score += score
	
	# 同步到全局状态
	if GlobalState.instance != null:
		GlobalState.instance.current_money = current_money
		GlobalState.instance.current_skills = current_skills.duplicate()
		GlobalState.instance.current_score = current_score
	
	print("游戏胜利！带回金币: " + str(money) + ", 技能: " + str(skills))

# 游戏失败后调用
func on_game_defeat(score: int) -> void:
	# 死亡后清零金币和技能，但保留积分
	current_money = 0
	current_skills = []
	current_score += score
	
	# 同步到全局状态
	if GlobalState.instance != null:
		GlobalState.instance.current_money = 0
		GlobalState.instance.current_skills.clear()
		GlobalState.instance.current_score = current_score
	
	print("游戏失败！金币和技能清零，获得积分: " + str(score))

func _process(_delta: float) -> void:
	# 实时更新UI
	_update_ui()

func _update_ui() -> void:
	if score_label:
		score_label.text = "积分: " + str(current_score)
	if money_label:
		money_label.text = "金钱: " + str(current_money)
		
	# 同步到商店显示
	if has_node("Shop") and has_node("Shop/MoneyLabel"):
		var shop_money_label: Label = $Shop/MoneyLabel
		if shop_money_label != null:
			shop_money_label.text = "金钱: " + str(current_money)
