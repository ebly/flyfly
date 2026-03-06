extends Node
class_name EventBusClass

# ============================================
# 事件总线 - 全局信号管理
# ============================================
# 用于解耦各模块之间的通信
# 使用方法：EventBus.enemy_died.emit(enemy_id, position)
# 优先级支持：EventBus.connect_with_priority("enemy_died", self, "_on_enemy_died", [], 10)
# 参数验证：自动验证事件发射时的参数类型
# ============================================

# 信号订阅者数据结构
class SignalSubscriber:
	var callable: Callable
	var priority: int
	
	func _init(p_callable: Callable, p_priority: int):
		callable = p_callable
		priority = p_priority

# 存储带有优先级的信号订阅者
var _signal_subscribers: Dictionary = {}

# 信号参数类型定义
var _signal_param_types: Dictionary = {}

# 初始化信号参数类型定义
func _init():
	# 玩家相关事件
	_signal_param_types["player_spawned"] = ["Node"]
	_signal_param_types["player_died"] = []
	_signal_param_types["player_health_changed"] = ["int", "int"]
	_signal_param_types["player_money_changed"] = ["int"]
	_signal_param_types["player_score_changed"] = ["int"]
	_signal_param_types["player_skill_activated"] = ["String"]
	_signal_param_types["player_skill_switched"] = ["String"]
	
	# 输入事件
	_signal_param_types["player_shoot_pressed"] = []
	_signal_param_types["player_shoot_released"] = []
	_signal_param_types["player_skill_pressed"] = []
	_signal_param_types["player_next_skill"] = []
	_signal_param_types["player_previous_skill"] = []
	_signal_param_types["game_pause_requested"] = []
	
	# 敌人相关事件
	_signal_param_types["enemy_spawned"] = ["String", "Vector2"]
	_signal_param_types["enemy_fully_entered_map"] = ["String", "Vector2"]
	_signal_param_types["enemy_died"] = ["String", "Vector2", "int"]
	_signal_param_types["enemy_damaged"] = ["String", "int"]
	
	# 子弹相关事件
	_signal_param_types["bullet_fired"] = ["String", "Vector2", "Vector2", "bool"]
	_signal_param_types["bullet_hit"] = ["Node", "Node"]
	
	# 游戏状态事件
	_signal_param_types["game_started"] = ["String"]
	_signal_param_types["game_paused"] = []
	_signal_param_types["game_resumed"] = []
	_signal_param_types["game_over"] = ["bool", "int", "int"]
	_signal_param_types["wave_started"] = ["int", "bool"]
	_signal_param_types["wave_completed"] = ["int"]
	
	# 物品收集事件
	_signal_param_types["coin_collected"] = ["int"]
	_signal_param_types["skill_drop_collected"] = ["String"]
	
	# UI更新事件
	_signal_param_types["ui_update_health"] = ["int", "int"]
	_signal_param_types["ui_update_money"] = ["int"]
	_signal_param_types["ui_update_score"] = ["int"]
	_signal_param_types["ui_show_message"] = ["String", "float"]
	
	# 关卡事件
	_signal_param_types["stage_changed"] = ["String"]
	_signal_param_types["difficulty_changed"] = ["String"]

# 玩家相关事件
signal player_spawned(player)
signal player_died
signal player_health_changed(current_health, max_health)
signal player_money_changed(amount)
signal player_score_changed(amount)
signal player_skill_activated(skill_id)
signal player_skill_switched(skill_id)

# 输入事件
signal player_shoot_pressed
signal player_shoot_released
signal player_skill_pressed
signal player_next_skill
signal player_previous_skill
signal game_pause_requested

# 敌人相关事件
signal enemy_spawned(enemy_id, position)
signal enemy_fully_entered_map(enemy_id, position)
signal enemy_died(enemy_id, position, coin_value)
signal enemy_damaged(enemy_id, damage)

# 子弹相关事件
signal bullet_fired(bullet_type, position, direction, is_player)
signal bullet_hit(bullet, target)

# 游戏状态事件
signal game_started(difficulty)
signal game_paused
signal game_resumed
signal game_over(is_victory, score, money)
signal wave_started(wave_number, is_boss_wave)
signal wave_completed(wave_number)

# 物品收集事件
signal coin_collected(amount)
signal skill_drop_collected(skill_id)

# UI更新事件
signal ui_update_health(current, max)
signal ui_update_money(amount)
signal ui_update_score(amount)
signal ui_show_message(message, duration)

# 关卡事件
signal stage_changed(stage_id)
signal difficulty_changed(difficulty)

# ============================================
# 便捷方法
# ============================================

func _ready():
	# 连接所有信号到虚拟处理函数以消除 unused_signal 警告
	# 这些信号由其他类发射和监听，此处仅消除编译器警告
	_connect_all_signals()
	
	# 初始化信号订阅者字典
	for signal_name in _signal_param_types.keys():
		_signal_subscribers[signal_name] = []

# 连接信号并指定优先级
func connect_with_priority(signal_name: String, target: Object, method: String, binds: Array = [], priority: int = 0) -> void:
	if not _signal_param_types.has(signal_name):
		push_error("信号不存在: " + signal_name)
		return
	
	# 创建可调用对象
	var callable = Callable(target, method)
	if not binds.is_empty():
		callable = callable.bind_array(binds)
	
	# 创建订阅者
	var subscriber = SignalSubscriber.new(callable, priority)
	
	# 添加到订阅者列表
	if not _signal_subscribers.has(signal_name):
		_signal_subscribers[signal_name] = []
	
	_signal_subscribers[signal_name].append(subscriber)
	
	# 按优先级排序（从高到低）
	_signal_subscribers[signal_name].sort_custom(func(a, b):
		if a.priority > b.priority:
			return -1
		elif a.priority < b.priority:
			return 1
		else:
			return 0
	)

# 断开信号连接
func disconnect_signal(signal_name: String, target: Object, method: String) -> void:
	if not _signal_subscribers.has(signal_name):
		return
	
	var subscribers = _signal_subscribers[signal_name]
	var index = 0
	
	while index < subscribers.size():
		var subscriber = subscribers[index]
		if subscriber.callable.object == target and subscriber.callable.method == method:
			subscribers.remove_at(index)
		else:
			index += 1

# 验证并发射信号
func emit_signal_with_validation(signal_name: String, args: Array) -> bool:
	# 验证信号是否存在
	if not _signal_param_types.has(signal_name):
		push_error("信号不存在: " + signal_name)
		return false
	
	# 验证参数数量
	var expected_types = _signal_param_types[signal_name]
	if args.size() != expected_types.size():
		push_error("信号参数数量不匹配: " + signal_name + ", 预期 " + str(expected_types.size()) + " 个参数，实际 " + str(args.size()) + " 个")
		return false
	
	# 验证参数类型
	for i in range(args.size()):
		var expected_type = expected_types[i]
		var actual_value = args[i]
		var actual_type = typeof(actual_value)
		
		var valid = _validate_param_type(expected_type, actual_value, actual_type)
		if not valid:
			push_error("信号参数类型不匹配: " + signal_name + ", 参数 " + str(i) + " 预期类型 " + expected_type + "，实际类型 " + str(actual_type))
			return false
	
	# 发射内置信号
	var emit_signal_callable = Callable(self, "emit_signal")
	emit_signal_callable.callv([signal_name] + args)
	
	# 调用带有优先级的订阅者
	if _signal_subscribers.has(signal_name):
		for subscriber in _signal_subscribers[signal_name]:
			if is_instance_valid(subscriber.callable.object):
				# 直接调用订阅者，不使用错误处理
				subscriber.callable.callv(args)
	
	return true

# 验证参数类型
func _validate_param_type(expected_type: String, actual_value, actual_type: int) -> bool:
	match expected_type:
		"int":
			return actual_type == TYPE_INT
		"float":
			return actual_type == TYPE_FLOAT or actual_type == TYPE_INT
		"String":
			return actual_type == TYPE_STRING
		"bool":
			return actual_type == TYPE_BOOL
		"Vector2":
			return actual_type == TYPE_VECTOR2
		"Vector3":
			return actual_type == TYPE_VECTOR3
		"Color":
			return actual_type == TYPE_COLOR
		"Node":
			return actual_type == TYPE_OBJECT and actual_value is Node
		"Callable":
			return actual_type == TYPE_CALLABLE
		_:
			return true

# 便捷发射方法（保持向后兼容）
func emit_player_health_changed(current: int, max_health: int) -> void:
	emit_signal_with_validation("player_health_changed", [current, max_health])
	emit_signal_with_validation("ui_update_health", [current, max_health])

func emit_player_money_changed(amount: int) -> void:
	emit_signal_with_validation("player_money_changed", [amount])
	emit_signal_with_validation("ui_update_money", [amount])

func emit_enemy_died(enemy_id: String, position: Vector2, coin_value: int) -> void:
	emit_signal_with_validation("enemy_died", [enemy_id, position, coin_value])

func emit_wave_started(wave: int, is_boss: bool = false) -> void:
	emit_signal_with_validation("wave_started", [wave, is_boss])
	if is_boss:
		emit_signal_with_validation("ui_show_message", ["BOSS Wave!", 3.0])

func _connect_all_signals() -> void:
	# 玩家相关
	player_spawned.connect(_on_void_signal_player)
	player_died.connect(_on_void_signal)
	player_health_changed.connect(_on_void_signal_2_int)
	player_money_changed.connect(_on_void_signal_1_int)
	player_score_changed.connect(_on_void_signal_1_int)
	player_skill_activated.connect(_on_void_signal_1_string)
	player_skill_switched.connect(_on_void_signal_1_string)
	
	# 输入事件
	player_shoot_pressed.connect(_on_void_signal)
	player_shoot_released.connect(_on_void_signal)
	player_skill_pressed.connect(_on_void_signal)
	player_next_skill.connect(_on_void_signal)
	player_previous_skill.connect(_on_void_signal)
	game_pause_requested.connect(_on_void_signal)
	
	# 敌人相关
	enemy_spawned.connect(_on_void_signal_string_vec2)
	enemy_fully_entered_map.connect(_on_void_signal_string_vec2)
	enemy_died.connect(_on_void_signal_string_vec2_int)
	enemy_damaged.connect(_on_void_signal_string_int)
	
	# 子弹相关
	bullet_fired.connect(_on_void_signal_bullet_fired)
	bullet_hit.connect(_on_void_signal)
	
	# 游戏状态
	game_started.connect(_on_void_signal_1_string)
	game_paused.connect(_on_void_signal)
	game_resumed.connect(_on_void_signal)
	game_over.connect(_on_void_signal)
	wave_started.connect(_on_void_signal_int_bool)
	wave_completed.connect(_on_void_signal_1_int)
	
	# 物品收集
	coin_collected.connect(_on_void_signal_1_int)
	skill_drop_collected.connect(_on_void_signal_1_string)
	
	# UI更新
	ui_update_health.connect(_on_void_signal_2_int)
	ui_update_money.connect(_on_void_signal_1_int)
	ui_update_score.connect(_on_void_signal_1_int)
	ui_show_message.connect(_on_void_signal_string_float)
	
	# 关卡事件
	stage_changed.connect(_on_void_signal_1_string)
	difficulty_changed.connect(_on_void_signal_1_string)

# 虚拟处理函数 - 仅用于消除警告
func _on_void_signal() -> void:
	pass

func _on_void_signal_1_int(_a: int) -> void:
	pass

func _on_void_signal_2_int(_a: int, _b: int) -> void:
	pass

func _on_void_signal_1_string(_a: String) -> void:
	pass

func _on_void_signal_string_vec2(_a: String, _b: Vector2) -> void:
	pass

func _on_void_signal_string_vec2_int(_a: String, _b: Vector2, _c: int) -> void:
	pass

func _on_void_signal_string_int(_a: String, _b: int) -> void:
	pass

func _on_void_signal_int_bool(_a: int, _b: bool) -> void:
	pass

func _on_void_signal_string_float(_a: String, _b: float) -> void:
	pass

func _on_void_signal_player(_player) -> void:
	pass

func _on_void_signal_bullet_fired(_bullet_type: String, _position: Vector2, _direction: Vector2, _is_player: bool) -> void:
	pass
