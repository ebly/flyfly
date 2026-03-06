extends Area2D

const AircraftConfig = preload("res://config/aircraft_config.gd")

var skill_type: String = ""
var config: Dictionary = {}
var EventBus: Node

func _ready():
	_load_config()
	_update_visual()
	
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	
	# 添加到物品组
	add_to_group("items")
	
	# 获取事件总线
	EventBus = get_node("/root/EventBus")

func _load_config():
	if skill_type.is_empty():
		return
	
	config = AircraftConfig.get_skill_config(skill_type)
	if config.is_empty():
		push_error("无法加载技能配置: " + skill_type)

func _update_visual():
	if config.is_empty():
		return
	
	var texture_rect = $SkillIcon
	if not texture_rect:
		return
	
	# 获取技能图片资源
	var skills_texture = preload("res://assets/skills.png")
	
	# 根据技能类型设置图标
	match skill_type:
		"dash":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(0, 0, 90, 90)
			texture_rect.texture = atlas_texture
		"shield":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(105, 0, 90, 90)
			texture_rect.texture = atlas_texture
		"rapid_fire":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(210, 0, 90, 90)
			texture_rect.texture = atlas_texture
		"missile":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(0, 105, 90, 90)
			texture_rect.texture = atlas_texture
		"laser":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(105, 105, 90, 90)
			texture_rect.texture = atlas_texture
		"bomb":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(210, 105, 90, 90)
			texture_rect.texture = atlas_texture
		"homing":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(0, 210, 90, 90)
			texture_rect.texture = atlas_texture
		"explosion":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(105, 210, 90, 90)
			texture_rect.texture = atlas_texture
		"spread_shot":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(210, 210, 90, 90)
			texture_rect.texture = atlas_texture
		_:
			# 默认图标
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = skills_texture
			atlas_texture.region = Rect2(0, 0, 90, 90)
			texture_rect.texture = atlas_texture

func _on_body_entered(body):
	# 检查是否是玩家
	if body.is_in_group("player") or body.name == "Player":
		# 给玩家解锁技能
		if body.has_method("unlock_skill"):
			if body.unlock_skill(skill_type):
				print("玩家获得技能: " + config.get("name", skill_type))
				queue_free()
			else:
				print("玩家已有此技能或无法解锁")

# 设置技能类型
func set_skill_type(type: String):
	skill_type = type
	_load_config()
	_update_visual()
