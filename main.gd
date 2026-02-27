extends Control

var world = null
var screen_size = Vector2(1920, 1080)
var map_size = Vector2(3840, 2160) # 放大后的地图尺寸

func _ready():
	world = get_node("World")
	screen_size = get_viewport().get_visible_rect().size
	
	# 连接开始按钮的点击信号
	$StartButton.pressed.connect(func():
		# 隐藏主页面元素
		$ColorRect.visible = false
		$Label.visible = false
		$StartButton.visible = false
		$QuitButton.visible = false
		# 显示游戏世界
		world.visible = true
	)
	
	# 连接退出按钮的点击信号
	$QuitButton.pressed.connect(func():
		# 退出游戏
		get_tree().quit()
	)

func _process(_delta):
	if world and world.visible and has_node("World/Player"):
		var player = get_node("World/Player")
		var player_pos = player.position
		
		# 计算地图应该的偏移量，使玩家始终在屏幕中心
		var target_world_offset = -player_pos + screen_size / 2
		
		# 限制地图偏移，确保地图边缘不超出屏幕
		var max_offset_x = screen_size.x - map_size.x
		var max_offset_y = screen_size.y - map_size.y
		target_world_offset.x = clamp(target_world_offset.x, max_offset_x, 0)
		target_world_offset.y = clamp(target_world_offset.y, max_offset_y, 0)
		
		# 应用地图偏移
		world.position = target_world_offset