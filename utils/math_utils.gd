class_name MathUtils
extends RefCounted

# ============================================
# 数学工具类
# ============================================

# 计算两点之间的距离
static func distance(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

# 计算两点之间的方向
static func direction(from: Vector2, to: Vector2) -> Vector2:
	return (to - from).normalized()

# 限制值在范围内
static func clamp_value(value: float, min_val: float, max_val: float) -> float:
	return clamp(value, min_val, max_val)

# 线性插值
static func lerp_value(a: float, b: float, t: float) -> float:
	return lerp(a, b, t)

# 角度转方向向量
static func angle_to_direction(angle: float) -> Vector2:
	return Vector2(cos(angle), sin(angle))

# 方向向量转角度
static func direction_to_angle(direction: Vector2) -> float:
	return direction.angle()

# 检查点是否在矩形内
static func is_point_in_rect(point: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return point.x >= rect_pos.x and point.x <= rect_pos.x + rect_size.x and \
		   point.y >= rect_pos.y and point.y <= rect_pos.y + rect_size.y

# 计算加权随机索引
static func weighted_random_index(weights: Array[float]) -> int:
	var total_weight = 0.0
	for weight in weights:
		total_weight += weight
	
	if total_weight <= 0:
		return 0
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return i
	
	return weights.size() - 1

# 计算百分比
static func calculate_percent(value: float, max_value: float) -> float:
	if max_value <= 0:
		return 0.0
	return (value / max_value) * 100.0

# 平滑阻尼
static func smooth_damp(current: float, target: float, current_velocity: float, 
					smooth_time: float, max_speed: float, delta: float) -> Dictionary:
	var omega = 2.0 / smooth_time
	var x = omega * delta
	var exp_val = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change = current - target
	var max_change = max_speed * smooth_time
	change = clamp(change, -max_change, max_change)
	var temp = (current_velocity + omega * change) * delta
	var new_velocity = (current_velocity - omega * temp) * exp_val
	var output = target + (change + temp) * exp_val
	
	if (target - current > 0.0) == (output > target):
		output = target
		new_velocity = (output - target) / delta
	
	return {"value": output, "velocity": new_velocity}
