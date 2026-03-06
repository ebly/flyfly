extends Node
class_name VisualEffectManagerClass

# ==========================================
# 视觉效果管理器
# ==========================================
# 用于统一管理和创建各种视觉反馈效果
# 支持：
# 1. 技能使用效果
# 2. 金币拾取效果
# 3. 敌人击中效果
# 4. 爆炸效果
# 5. 伤害数字显示
# ==========================================

# 事件总线
var EventBus: Node

# 预设的视觉效果配置
var effect_configs = {
	# 技能效果
	"skill_dash": {
		"sprite_path": "res://scenes/effects/dash_effect.tscn",
		"duration": 0.3,
		"scale": 1.5
	},
	"skill_shield": {
		"sprite_path": "res://scenes/effects/shield_effect.tscn",
		"duration": 0.5,
		"scale": 2.0
	},
	"skill_rapid_fire": {
		"sprite_path": "res://scenes/effects/rapid_fire_effect.tscn",
		"duration": 0.4,
		"scale": 1.8
	},
	"skill_missile": {
		"sprite_path": "res://scenes/effects/missile_launch_effect.tscn",
		"duration": 0.3,
		"scale": 1.2
	},
	"skill_laser": {
		"sprite_path": "res://scenes/effects/laser_charge_effect.tscn",
		"duration": 0.5,
		"scale": 2.5
	},
	"skill_bomb": {
		"sprite_path": "res://scenes/effects/bomb_prepare_effect.tscn",
		"duration": 0.6,
		"scale": 2.2
	},
	
	# 拾取效果
	"pickup_coin": {
		"sprite_path": "res://scenes/effects/coin_pickup_effect.tscn",
		"duration": 0.4,
		"scale": 1.0
	},
	"pickup_skill": {
		"sprite_path": "res://scenes/effects/skill_pickup_effect.tscn",
		"duration": 0.6,
		"scale": 1.5
	},
	
	# 敌人效果
	"enemy_hit": {
		"sprite_path": "res://scenes/effects/enemy_hit_effect.tscn",
		"duration": 0.2,
		"scale": 1.0
	},
	"enemy_destroy": {
		"sprite_path": "res://scenes/effects/enemy_destroy_effect.tscn",
		"duration": 0.8,
		"scale": 2.0
	}
}

func _ready():
	EventBus = get_node("/root/EventBus")
	
	# 连接事件
	_connect_events()

# 连接相关事件
func _connect_events():
	# 技能事件
	EventBus.player_skill_activated.connect(_on_skill_activated)
	
	# 拾取事件
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.skill_drop_collected.connect(_on_skill_collected)
	
	# 敌人事件
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_died.connect(_on_enemy_destroyed)

# 播放技能效果
func play_skill_effect(_skill_type: String, _position: Vector2, _parent: Node = null) -> void:
	# 暂时禁用效果播放，因为缺少效果文件
	# 如需启用效果，请创建 res://scenes/effects/ 目录和相应的效果文件
	return
	
	# 以下是原代码，暂时注释
	# var config = effect_configs.get("skill_" + _skill_type)
	# if config:
	#	 _create_effect(config, _position, _parent)

# 播放拾取效果
func play_pickup_effect(_pickup_type: String, _position: Vector2, _parent: Node = null) -> void:
	# 暂时禁用效果播放，因为缺少效果文件
	# 如需启用效果，请创建 res://scenes/effects/ 目录和相应的效果文件
	return
	
	# 以下是原代码，暂时注释
	# var config = effect_configs.get("pickup_" + _pickup_type)
	# if config:
	#	 _create_effect(config, _position, _parent)

# 播放敌人效果
func play_enemy_effect(_effect_type: String, _position: Vector2, _parent: Node = null) -> void:
	# 暂时禁用效果播放，因为缺少效果文件
	# 如需启用效果，请创建 res://scenes/effects/ 目录和相应的效果文件
	return
	
	# 以下是原代码，暂时注释
	# var config = effect_configs.get("enemy_" + _effect_type)
	# if config:
	#	 _create_effect(config, _position, _parent)

# 创建基础效果
func _create_effect(config: Dictionary, position: Vector2, parent: Node = null) -> Node2D:
	# 安全检查：确保配置和路径有效
	if not config or not config.has("sprite_path"):
		print("警告: 无效的效果配置")
		return null
	
	var sprite_path = config.sprite_path
	
	# 创建效果节点
	var effect_scene: PackedScene
	
	# 使用load而不是preload，因为preload需要常量字符串
	effect_scene = load(sprite_path)
	
	if not effect_scene:
		# 只打印警告而不是错误，避免游戏中断
		print("警告: 无法加载效果场景: " + sprite_path)
		return null
	
	var effect = effect_scene.instantiate()
	
	# 设置属性
	effect.position = position
	
	# 设置缩放
	if config.has("scale"):
		effect.scale = Vector2.ONE * config.scale
	
	# 设置父节点
	if parent:
		parent.add_child(effect)
	else:
		get_tree().get_root().add_child(effect)
	
	# 设置自动移除
	if config.has("duration"):
		effect.set_meta("lifetime", config.duration)
		
		# 使用定时器自动移除效果
		var timer = Timer.new()
		timer.wait_time = config.duration
		timer.autostart = true
		timer.one_shot = true
		timer.timeout.connect(func():
			if is_instance_valid(effect):
				effect.queue_free()
		)
		effect.add_child(timer)
	
	return effect

# 播放伤害数字
func play_damage_number(damage: int, position: Vector2, color: Color = Color(1, 0.2, 0.2, 1), parent: Node = null) -> void:
	# 创建文本节点
	var damage_label = Label.new()
	damage_label.text = str(damage)
	damage_label.position = position
	damage_label.modulate = color
	damage_label.set("horizontal_alignment", HORIZONTAL_ALIGNMENT_CENTER)
	damage_label.set("vertical_alignment", VERTICAL_ALIGNMENT_CENTER)
	damage_label.add_theme_font_size_override("font_size", 24)
	
	# 添加到场景
	if parent:
		parent.add_child(damage_label)
	else:
		get_tree().get_root().add_child(damage_label)
	
	# 动画参数
	var duration = 1.0
	var start_pos = position
	var end_pos = position + Vector2(0, -50)
	var timer = 0.0
	
	# 创建动画协程
	var tween = create_tween()
	tween.tween_property(damage_label, "position", end_pos, duration)
	tween.tween_property(damage_label, "modulate:a", 0.0, duration)
	tween.tween_property(damage_label, "scale", Vector2(1.5, 1.5), duration/2)
	tween.tween_property(damage_label, "scale", Vector2(1.0, 1.0), duration/2).set_trans(Tween.TRANS_BACK)
	
	# 完成后移除
	tween.finished.connect(func():
		if is_instance_valid(damage_label):
			damage_label.queue_free()
	)

# 事件处理

# 技能激活事件
func _on_skill_activated(skill_type: String) -> void:
	# 获取玩家位置
	var player = get_tree().get_first_node_in_group("player")
	if player:
		play_skill_effect(skill_type, player.position, player.get_parent())

# 金币收集事件
func _on_coin_collected(amount: int) -> void:
	# 获取玩家位置
	var player = get_tree().get_first_node_in_group("player")
	if player:
		play_pickup_effect("coin", player.position, player.get_parent())

# 技能收集事件
func _on_skill_collected(skill_id: String) -> void:
	# 获取玩家位置
	var player = get_tree().get_first_node_in_group("player")
	if player:
		play_pickup_effect("skill", player.position, player.get_parent())

# 敌人受伤事件
func _on_enemy_damaged(enemy_id: String, damage: int) -> void:
	# 找到受伤的敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.aircraft_id == enemy_id:
			# play_enemy_effect("hit", enemy.position, enemy.get_parent())  # 暂时禁用效果
			play_damage_number(damage, enemy.position + Vector2(0, -20), Color(1, 0.2, 0.2, 1), enemy.get_parent())
			break

# 敌人销毁事件
func _on_enemy_destroyed(enemy_id: String, position: Vector2, coin_value: int) -> void:
	# play_enemy_effect("destroy", position)  # 暂时禁用效果
	# 敌人死亡时不显示金币数量，只在拾取时显示
	pass
