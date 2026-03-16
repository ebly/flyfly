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
	"move_speed": "移动速度",
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
	# 获取UI控件
	money_display = $MoneyDisplay
	level_display = $LevelDisplay
	close_button = $CloseButton
	
	# 收集属性按钮
	property_buttons = [
		$AircraftContainer/PropertyGrid/PropertySlot1,  # 伤害
		$AircraftContainer/PropertyGrid/PropertySlot2,  # 射程
		$AircraftContainer/PropertyGrid/PropertySlot3,  # 子弹速度
		$AircraftContainer/PropertyGrid/PropertySlot4,  # 射速
		$AircraftContainer/PropertyGrid/PropertySlot5,  # 移动速度
		$AircraftContainer/PropertyGrid/PropertySlot6,  # 血量
		$AircraftContainer/PropertyGrid/PropertySlot7   # 护甲
	]
	
	# 连接信号
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 连接属性按钮信号
	for i in range(property_buttons.size()):
		var property_name = get_property_name_by_index(i)
		if property_name:
			property_buttons[i].pressed.connect(func(pn = property_name): _on_property_button_pressed(pn))
	
	# 从全局状态加载数据
	_load_from_global_state()
	
	# 初始化显示
	_update_display()

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
	money_display.text = "金钱: " + str(current_money)
	
	# 更新等级显示
	var level_text = "属性等级: "
	for property_name in property_name_map.keys():
		level_text += property_name_map[property_name] + ":" + str(property_levels[property_name]) + " "
	level_display.text = level_text
	
	# 更新属性按钮文本
	for i in range(property_buttons.size()):
		var property_name = get_property_name_by_index(i)
		if property_name:
			var current_level = property_levels[property_name]
			var cost = upgrade_costs[property_name]
			var button = property_buttons[i]
			
			if current_level >= 10:
				button.text = property_name_map[property_name] + " (MAX)"
				button.disabled = true
			else:
				button.text = property_name_map[property_name] + " (Lv" + str(current_level) + ")"
				button.disabled = current_money < cost

func get_property_name_by_index(index: int) -> String:
	# 根据索引获取属性名称
	var property_names = ["damage", "range", "bullet_speed", "fire_rate", "move_speed", "blood", "armor"]
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
