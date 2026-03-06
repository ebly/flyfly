extends Control

const AircraftConfig = preload("res://config/aircraft_config.gd")
const GameDataManager = preload("res://config/game_data_manager.gd")

# 当前游戏数据（从地图传入）
var current_money: int = 0
var current_skills: Array[String] = []

# UI节点
var money_label: Label = null
var skill_list: VBoxContainer = null

func _ready() -> void:
	# 获取UI节点
	money_label = get_node_or_null("MoneyLabel")
	skill_list = get_node_or_null("SkillList")
	
	# 更新显示
	_update_money_display()
	_update_skill_list()

# 更新金钱显示
func _update_money_display() -> void:
	if money_label:
		money_label.text = "金币: " + str(current_money)

# 更新技能列表
func _update_skill_list() -> void:
	if not skill_list:
		return
	
	# 清除旧项
	for child in skill_list.get_children():
		child.queue_free()
	
	# 获取可解锁的技能
	var unlockable_skills: Array[String] = AircraftConfig.get_unlockable_skills()
	
	for skill_id in unlockable_skills:
		var skill_config: Dictionary = AircraftConfig.get_skill_config(skill_id)
		var cost: int = AircraftConfig.get_skill_unlock_cost(skill_id)
		
		# 创建技能项
		var hbox: HBoxContainer = HBoxContainer.new()
		
		# 技能名称
		var name_label: Label = Label.new()
		name_label.text = skill_config.name
		name_label.custom_minimum_size = Vector2(150.0, 0.0)
		hbox.add_child(name_label)
		
		# 技能描述
		var desc_label: Label = Label.new()
		desc_label.text = skill_config.description
		desc_label.custom_minimum_size = Vector2(300.0, 0.0)
		hbox.add_child(desc_label)
		
		# 价格
		var price_label: Label = Label.new()
		price_label.text = str(cost) + " 金币"
		price_label.custom_minimum_size = Vector2(100.0, 0.0)
		hbox.add_child(price_label)
		
		# 购买按钮
		var buy_button: Button = Button.new()
		
		# 检查是否已拥有
		if current_skills.has(skill_id):
			buy_button.text = "已拥有"
			buy_button.disabled = true
		elif current_money < cost:
			buy_button.text = "金币不足"
			buy_button.disabled = true
		else:
			buy_button.text = "购买"
			buy_button.pressed.connect(func() -> void: _buy_skill(skill_id, cost))
		
		hbox.add_child(buy_button)
		skill_list.add_child(hbox)

# 购买技能
func _buy_skill(skill_id: String, cost: int) -> void:
	if current_money >= cost:
		current_money -= cost
		current_skills.append(skill_id)
		_update_money_display()
		_update_skill_list()
		print("购买技能成功: " + skill_id)

# 返回地图
func _on_return_button_pressed() -> void:
	# 保存当前数据到全局或传回地图
	var map_data: Dictionary = {
		"money": current_money,
		"skills": current_skills
	}
	
	# 切换到地图场景
	var map_scene: PackedScene = load("res://scenes/map.tscn") as PackedScene
	if map_scene:
		# 可以在这里传递数据
		get_tree().change_scene_to_packed(map_scene)
