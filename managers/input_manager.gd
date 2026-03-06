extends Node

# ============================================
# 输入管理器 - 集中处理所有输入
# ============================================
# 将输入转换为游戏动作，解耦输入与游戏逻辑
# ============================================

@onready var EventBus: Node = get_node("/root/EventBus")

# 输入状态
var _input_state: Dictionary = {}
var _previous_input_state: Dictionary = {}

# 动作映射
const ACTION_MOVE_UP = "move_up"
const ACTION_MOVE_DOWN = "move_down"
const ACTION_MOVE_LEFT = "move_left"
const ACTION_MOVE_RIGHT = "move_right"
const ACTION_SHOOT = "shoot"
const ACTION_USE_SKILL = "use_skill"
const ACTION_NEXT_SKILL = "next_skill"
const ACTION_PREVIOUS_SKILL = "previous_skill"
const ACTION_PAUSE = "pause"

func _ready() -> void:
	_initialize_input_state()
	print("输入管理器初始化完成")

func _initialize_input_state() -> void:
	_input_state = {
		ACTION_MOVE_UP: false,
		ACTION_MOVE_DOWN: false,
		ACTION_MOVE_LEFT: false,
		ACTION_MOVE_RIGHT: false,
		ACTION_SHOOT: false,
		ACTION_USE_SKILL: false,
		ACTION_NEXT_SKILL: false,
		ACTION_PREVIOUS_SKILL: false,
		ACTION_PAUSE: false,
	}
	_previous_input_state = _input_state.duplicate()

func _input(event: InputEvent) -> void:
	# 处理按键按下事件
	if event is InputEventKey:
		_match_key_action(event)
	
	# 处理鼠标事件
	if event is InputEventMouseButton:
		_match_mouse_action(event)
	
	# 处理滚轮事件
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_match_scroll_action(event)

func _match_key_action(event: InputEventKey) -> void:
	match event.keycode:
		KEY_W, KEY_UP:
			_update_action_state(ACTION_MOVE_UP, event.pressed)
		KEY_S, KEY_DOWN:
			_update_action_state(ACTION_MOVE_DOWN, event.pressed)
		KEY_A, KEY_LEFT:
			_update_action_state(ACTION_MOVE_LEFT, event.pressed)
		KEY_D, KEY_RIGHT:
			_update_action_state(ACTION_MOVE_RIGHT, event.pressed)
		KEY_SPACE:
			_update_action_state(ACTION_USE_SKILL, event.pressed)
		KEY_TAB:
			if event.pressed and not event.is_echo():
				_update_action_state(ACTION_NEXT_SKILL, true)
		KEY_ESCAPE:
			if event.pressed and not event.is_echo():
				_update_action_state(ACTION_PAUSE, true)

func _match_mouse_action(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_update_action_state(ACTION_SHOOT, event.pressed)
		MOUSE_BUTTON_RIGHT:
			_update_action_state(ACTION_USE_SKILL, event.pressed)

func _match_scroll_action(event: InputEventMouseButton) -> void:
	if event.pressed:  # 滚轮事件在pressed时为true
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_update_action_state(ACTION_NEXT_SKILL, true)
			MOUSE_BUTTON_WHEEL_DOWN:
				_update_action_state(ACTION_PREVIOUS_SKILL, true)

func _update_action_state(action: StringName, pressed: bool) -> void:
	_previous_input_state[action] = _input_state[action]
	_input_state[action] = pressed
	
	# 触发事件
	if pressed and not _previous_input_state[action]:
		_emit_action_pressed(action)
	elif not pressed and _previous_input_state[action]:
		_emit_action_released(action)

func _emit_action_pressed(action: StringName) -> void:
	match action:
		ACTION_SHOOT:
			EventBus.player_shoot_pressed.emit()
		ACTION_USE_SKILL:
			EventBus.player_skill_pressed.emit()
		ACTION_NEXT_SKILL:
			EventBus.player_next_skill.emit()
		ACTION_PREVIOUS_SKILL:
			EventBus.player_previous_skill.emit()
		ACTION_PAUSE:
			EventBus.game_pause_requested.emit()

func _emit_action_released(action: StringName) -> void:
	match action:
		ACTION_SHOOT:
			EventBus.player_shoot_released.emit()

# 获取移动方向
func get_movement_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		direction.y += 1.0
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		direction.x += 1.0
	
	if direction.length() > 0.0:
		direction = direction.normalized()
	
	return direction

# 检查动作是否按下
func is_action_pressed(action: StringName) -> bool:
	return _input_state.get(action, false)

# 检查动作是否刚刚按下（一帧）
func is_action_just_pressed(action: StringName) -> bool:
	return _input_state.get(action, false) and not _previous_input_state.get(action, false)

# 检查动作是否刚刚释放（一帧）
func is_action_just_released(action: StringName) -> bool:
	return not _input_state.get(action, false) and _previous_input_state.get(action, false)

# 获取鼠标位置
func get_mouse_position() -> Vector2:
	return get_viewport().get_mouse_position()

# 重置输入状态
func reset() -> void:
	_initialize_input_state()
