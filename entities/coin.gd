extends Area2D

const SPEED: float = 100.0
const FLY_SPEED: float = 800.0
var value: int = 1
var direction: Vector2 = Vector2.ZERO
var is_flying_to_ui: bool = false
var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	
	body_entered.connect(_on_body_entered)
	
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(_start_fly_to_ui)
	timer.start()
	
	add_to_group("items")

func _process(delta: float) -> void:
	if is_flying_to_ui:
		var current_pos = global_position
		var to_target = target_position - current_pos
		var distance = to_target.length()
		
		if distance < 20.0:
			_collect_coin()
		else:
			global_position = current_pos + to_target.normalized() * FLY_SPEED * delta
	else:
		position += direction * SPEED * delta
		direction = direction.lerp(Vector2.ZERO, delta * 2.0)

func _start_fly_to_ui() -> void:
	is_flying_to_ui = true
	
	var viewport = get_viewport()
	if viewport:
		var screen_size = viewport.get_visible_rect().size
		target_position = Vector2(screen_size.x - 110.0, 50.0)

func _collect_coin() -> void:
	var main_node: Node = get_tree().get_root().find_child("Main", true, false)
	if main_node and main_node.has_method("add_money"):
		main_node.add_money(value)
	
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.coin_collected.emit(value)
	
	var global_state: Node = get_node_or_null("/root/GlobalState")
	if global_state:
		global_state.record_coin_collected(value)
	
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("add_money"):
		_collect_coin()

func set_coin_value(new_value: int) -> void:
	value = new_value
	_update_appearance()

func _update_appearance() -> void:
	var color_rect: ColorRect = $ColorRect
	if not color_rect:
		return
	
	if value >= 50:
		color_rect.color = Color(1.0, 0.8, 0.0, 1.0)
		color_rect.size = Vector2(20.0, 20.0)
		color_rect.position = Vector2(-10.0, -10.0)
	elif value >= 10:
		color_rect.color = Color(0.8, 0.0, 0.8, 1.0)
		color_rect.size = Vector2(16.0, 16.0)
		color_rect.position = Vector2(-8.0, -8.0)
	elif value >= 5:
		color_rect.color = Color(1.0, 0.5, 0.0, 1.0)
		color_rect.size = Vector2(14.0, 14.0)
		color_rect.position = Vector2(-7.0, -7.0)
	else:
		color_rect.color = Color(1.0, 0.8, 0.0, 1.0)
		color_rect.size = Vector2(10.0, 10.0)
		color_rect.position = Vector2(-5.0, -5.0)
