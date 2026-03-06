extends Control

@onready var GlobalState: Node = get_node("/root/GlobalState")

var world: Node = null
var screen_size: Vector2 = Vector2(1920, 1080)
var map_size: Vector2 = Vector2(3840, 2160) # 放大后的地图尺寸
var score_label: Label = null
var money_label: Label = null

func _ready() -> void:
	world = get_node("World")
	screen_size = get_viewport().get_visible_rect().size
	
	# 获取显示控件
	score_label = $ScoreLabel
	money_label = $MoneyLabel
	
	# 初始化全局状态（如果是新会话）
	if GlobalState.instance == null:
		var gs: Node = GlobalState.new()
		add_child(gs)
	
	# 初始化显示
	_update_ui()

	# 连接开始按钮的点击信号
	$StartButton.pressed.connect(func() -> void:
		# 加载地图场景
		var map_scene: PackedScene = load("res://scenes/map.tscn") as PackedScene
		if map_scene:
			# 替换当前场景为地图场景
			self.get_tree().change_scene_to_packed(map_scene)
	)

	# 连接退出按钮的点击信号
	$QuitButton.pressed.connect(func() -> void:
		# 退出游戏
		get_tree().quit()
	)

func _process(_delta: float) -> void:
	if world and world.visible and has_node("World/Player"):
		var player: Node = get_node("World/Player")
		var player_pos: Vector2 = player.position

		# 计算地图应该的偏移量，使玩家始终在屏幕中心
		var target_world_offset: Vector2 = -player_pos + screen_size / 2.0

		# 限制地图偏移，确保地图边缘不超出屏幕
		var max_offset_x: float = screen_size.x - map_size.x
		var max_offset_y: float = screen_size.y - map_size.y
		target_world_offset.x = clamp(target_world_offset.x, max_offset_x, 0.0)
		target_world_offset.y = clamp(target_world_offset.y, max_offset_y, 0.0)

		# 应用地图偏移
		world.position = target_world_offset
	
	# 实时更新UI
	_update_ui()

func _update_ui() -> void:
	if GlobalState.instance != null:
		if score_label:
			score_label.text = "积分: " + str(GlobalState.instance.current_score)
		if money_label:
			money_label.text = "金钱: " + str(GlobalState.instance.current_money)
