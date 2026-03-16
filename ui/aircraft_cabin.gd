extends Control

const AircraftConfig = preload("res://config/aircraft_config.gd")

# 本局游戏数据
var current_money: int = 0
var current_skills: Array = []

# UI控件
var money_display: Label = null
var level_display: Label = null
var close_button: Button = null
var property_buttons: Array = []

# 属性等级
var property_levels: Dictionary = {
	"damage": 1,
	"range": 1,
	"bullet_speed": 1,
	"fire_rate": 1,
	"move_speed": 1,
	"blood": 1,
	"armor": 1
}

# 属性名称映射
var property_name_map: Dictionary = {
	"damage": "伤害",
	"range": "射程",
	"bullet_speed": "子弹速度",
	"fire_rate": "射速",
	"move_speed": "移速",
	"blood": "血量",
	"armor": "护甲"
}

# 属性升级费用
var upgrade_costs: Dictionary = {
	"damage": 10,
	"range": 10,
	"bullet_speed": 10,
	"fire_rate": 10,
	"move_speed": 10,
	"blood": 10,
	"armor": 10
}

func _ready() -> void:
	# 基础调试信息
	print("=== AircraftCabin _ready() 开始 ===")
	print("当前节点: " + self.name)
	print("当前节点类型: " + self.get_class())
	
	# 获取基础UI控件
	money_display = get_node_or_null("MoneyDisplay")
	level_display = get_node_or_null("LevelDisplay")
	close_button = get_node_or_null("CloseButton")
	
	# 连接关闭按钮信号
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# 动态创建所有需要的节点
	property_buttons = []
	
	# 1. 获取或创建AircraftContainer
	var container = get_node_or_null("AircraftContainer")
	if not container:
		print("创建AircraftContainer节点")
		container = Control.new()
		container.name = "AircraftContainer"
		container.anchors_preset = -1
		container.anchor_left = 0.5
		container.anchor_top = 0.5
		container.anchor_right = 0.5
		container.anchor_bottom = 0.5
		container.offset_left = -150.0
		container.offset_top = -150.0
		container.offset_right = 150.0
		container.offset_bottom = 150.0
		add_child(container)
	
	# 2. 获取或创建PropertyGrid
	var property_grid = container.get_node_or_null("PropertyGrid")
	if not property_grid:
		print("创建PropertyGrid节点")
		property_grid = Control.new()
		property_grid.name = "PropertyGrid"
		property_grid.anchors_preset = 15
		property_grid.anchor_right = 1.0
		property_grid.anchor_bottom = 1.0
		container.add_child(property_grid)
	
	# 3. 创建7个属性按钮
	print("创建7个属性按钮")
	
	# 按钮配置：[位置(左, 上), 文本, 尺寸(宽, 高)]
	var button_configs = []
	button_configs.append([0.5, 0.1, "伤害", 80, 40])    # 上方：左, 上, 文本, 宽, 高
	button_configs.append([0.75, 0.2, "射速", 80, 40])   # 右上角：左, 上, 文本, 宽, 高
	button_configs.append([0.85, 0.5, "子弹速度", 80, 40]) # 右侧中间：左, 上, 文本, 宽, 高
	button_configs.append([0.75, 0.8, "护甲", 80, 40])   # 右下角：左, 上, 文本, 宽, 高
	button_configs.append([0.5, 0.9, "飞行速度", 80, 40]) # 下方：左, 上, 文本, 宽, 高
	button_configs.append([0.25, 0.8, "血量", 80, 40])   # 左下角：左, 上, 文本, 宽, 高
	button_configs.append([0.15, 0.5, "射程", 80, 40])    # 左上角：左, 上, 文本, 宽, 高
	
	for i in range(button_configs.size()):
		var config = button_configs[i]
		var left = config[0]
		var top = config[1]
		var text = config[2]
		var width = config[3]
		var height = config[4]
		
		# 创建按钮
		var button = Button.new()
		button.name = "PropertySlot" + str(i+1)
		button.text = text
		
		# 设置锚点和位置
		button.anchors_preset = -1
		button.anchor_left = left
		button.anchor_top = top
		button.anchor_right = left
		button.anchor_bottom = top
		button.offset_left = -width/2
		button.offset_top = -height/2
		button.offset_right = width/2
		button.offset_bottom = height/2
		
		# 添加到PropertyGrid
		property_grid.add_child(button)
		
		# 添加到数组
		property_buttons.append(button)
		
		# 连接信号
		var property_name = get_property_name_by_index(i)
		button.pressed.connect(func(pn = property_name): _on_property_button_pressed(pn))
		
		print("已创建: " + button.name + " (" + text + ")")
	
	# 调试信息
	print("\n=== 节点创建结果 ===")
	print("收集到的属性按钮数量: " + str(property_buttons.size()))
	for i in range(property_buttons.size()):
		if property_buttons[i]:
			print("按钮[" + str(i+1) + "]: " + property_buttons[i].name + " (类型: " + property_buttons[i].get_class() + ")")
		else:
			print("按钮[" + str(i+1) + "]: null")
	
	# 从全局状态加载数据
	_load_from_global_state()
	
	# 初始化显示
	_update_display()
	
	print("=== AircraftCabin _ready() 结束 ===")

func _on_close_button_pressed() -> void:
	# 关闭界面
	queue_free()

func _on_property_button_pressed(property_name: String) -> void:
	# 处理属性升级
	if _can_upgrade_property(property_name):
		_upgrade_property(property_name)

func _can_upgrade_property(property_name: String) -> bool:
	# 检查是否可以升级该属性
	var current_level = property_levels[property_name]
	var max_level = 10  # BASE_LEVELS 中的最大等级
	var cost = upgrade_costs[property_name]
	
	if current_level >= max_level:
		print("该属性已达到最大等级")
		return false
	
	if current_money < cost:
		print("金钱不足")
		return false
	
	return true

func _upgrade_property(property_name: String) -> void:
	# 升级属性
	var cost = upgrade_costs[property_name]
	
	# 扣除金钱
	current_money -= cost
	
	# 提升属性等级
	property_levels[property_name] += 1
	
	# 更新显示
	_update_display()
	
	# 更新全局状态
	_update_global_state()
	
	print("升级" + property_name_map[property_name] + "到等级" + str(property_levels[property_name]))

func _update_display() -> void:
	# 更新金钱显示
	if money_display != null:
		money_display.text = "金钱: " + str(current_money)
	
	# 更新等级显示
	var level_text = "属性等级: "
	for property_name in property_name_map.keys():
		level_text += property_name_map[property_name] + ":" + str(property_levels[property_name]) + " "
	if level_display != null:
		level_display.text = level_text
	
	# 更新属性按钮文本
	for i in range(property_buttons.size()):
		var property_name = get_property_name_by_index(i)
		if property_name:
			var current_level = property_levels[property_name]
			var cost = upgrade_costs[property_name]
			var button = property_buttons[i]
			
			if button != null:
				if current_level >= 10:
					button.text = property_name_map[property_name] + " (MAX)"
					button.disabled = true
				else:
					button.text = property_name_map[property_name] + " (Lv" + str(current_level) + ")"
					button.disabled = current_money < cost

func get_property_name_by_index(index: int) -> String:
	# 根据索引获取属性名称（与按钮位置对应）
	var property_names = ["damage", "fire_rate", "bullet_speed", "armor", "move_speed", "blood", "range"]
	if index >= 0 and index < property_names.size():
		return property_names[index]
	return ""

func _update_global_state() -> void:
	# 更新全局状态中的属性等级
	if GlobalState.instance != null:
		# 将属性等级存储到全局状态
		for property_name in property_levels.keys():
			GlobalState.instance.set_property_level(property_name, property_levels[property_name])

func _load_from_global_state() -> void:
	# 从全局状态加载数据
	if GlobalState.instance != null:
		current_money = GlobalState.instance.current_money
		current_skills = GlobalState.instance.current_skills.duplicate()
		
		# 加载属性等级
		for property_name in property_levels.keys():
			property_levels[property_name] = GlobalState.instance.get_property_level(property_name)

func _process(_delta: float) -> void:
	# 实时更新显示
	_update_display()
