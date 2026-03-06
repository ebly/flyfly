extends CharacterBody2D
class_name AircraftBase

const AircraftConfig = preload("res://config/aircraft_config.gd")

# 基础属性
var aircraft_id: String = ""
var config: Dictionary = {}
var current_health: int = 1
var max_health: int = 1
var armor: int = 0  # 护甲值，减免伤害

# 视觉
var sprite: Sprite2D = null

func _ready() -> void:
	_load_config()
	_get_references()
	_apply_visual_config()

# 设置飞机类型（用于动态创建时）
func set_aircraft_type(type_id: String) -> void:
	aircraft_id = type_id
	_load_config()
	_apply_visual_config()
	# 移除自动调用_setup_spawn_position，改为在添加到场景后手动调用

func _load_config() -> void:
	if aircraft_id.is_empty():
		push_error("aircraft_id 未设置")
		return
	
	config = AircraftConfig.get_aircraft_config(aircraft_id)
	if config.is_empty():
		push_error("无法加载飞机配置: " + aircraft_id)
		return
	
	# 应用基础配置
	max_health = config.get("health", 1)
	current_health = max_health
	armor = config.get("armor", 0)  # 加载护甲属性

func _get_references() -> void:
	sprite = $Sprite2D if has_node("Sprite2D") else null

func _apply_visual_config() -> void:
	if sprite == null or config.is_empty():
		return
	
	var color: Color = config.get("color", Color.WHITE)
	var scale_value: float = config.get("scale", 1.0)
	
	sprite.modulate = color
	sprite.scale = Vector2(scale_value, scale_value)

# 空的位置设置方法，子类可以重写它
func _setup_spawn_position() -> void:
	pass

# 受到伤害
func take_damage(damage: int) -> bool:
	# 计算实际伤害，护甲减免伤害，最低造成1点伤害
	var actual_damage = max(damage - armor, 1)
	current_health -= actual_damage
	_on_damage_taken(actual_damage)
	
	if current_health <= 0:
		die()
		return true
	return false

func _on_damage_taken(_damage: int) -> void:
	# 子类可重写
	pass

# 死亡处理
func die() -> void:
	_on_before_die()
	queue_free()

func _on_before_die() -> void:
	# 子类可重写
	pass

# 治疗
func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	_on_healed(amount)

func _on_healed(_amount: int) -> void:
	# 子类可重写
	pass

# 获取配置值（带默认值）
func get_config_value(key: String, default_value = null) -> Variant:
	return config.get(key, default_value)

# 检查是否存活
func is_alive() -> bool:
	return current_health > 0

# 获取血量百分比
func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)
