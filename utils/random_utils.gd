class_name RandomUtils
extends RefCounted

# ============================================
# 随机工具类
# ============================================

# 随机布尔值
static func random_bool(probability: float = 0.5) -> bool:
	return randf() < probability

# 随机符号（-1 或 1）
static func random_sign() -> int:
	return 1 if randf() < 0.5 else -1

# 随机范围（包含边界）
static func random_range(min_val: float, max_val: float) -> float:
	return randf_range(min_val, max_val)

# 随机整数范围（包含边界）
static func random_range_int(min_val: int, max_val: int) -> int:
	return randi() % (max_val - min_val + 1) + min_val

# 从数组中随机选择一个元素
static func random_choice(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi() % array.size()]

# 从数组中随机选择多个元素（不重复）
static func random_choices(array: Array, count: int) -> Array:
	if array.is_empty() or count <= 0:
		return []
	
	var result = []
	var temp = array.duplicate()
	count = min(count, temp.size())
	
	for i in range(count):
		var index = randi() % temp.size()
		result.append(temp[index])
		temp.remove_at(index)
	
	return result

# 根据权重随机选择
static func weighted_choice(items: Array, weights: Array) -> Variant:
	if items.is_empty() or weights.is_empty() or items.size() != weights.size():
		return null
	
	var total_weight = 0.0
	for weight in weights:
		total_weight += weight
	
	if total_weight <= 0:
		return items[0]
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(items.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return items[i]
	
	return items[items.size() - 1]

# 随机打乱数组
static func shuffle_array(array: Array) -> Array:
	var result = array.duplicate()
	result.shuffle()
	return result

# 随机角度（0 到 360 度）
static func random_angle() -> float:
	return randf_range(0, 360)

# 随机方向（单位向量）
static func random_direction() -> Vector2:
	var angle = random_angle()
	return Vector2(cos(angle), sin(angle))

# 在圆内随机点
static func random_point_in_circle(radius: float) -> Vector2:
	var r = radius * sqrt(randf())
	var theta = randf() * 2 * PI
	return Vector2(r * cos(theta), r * sin(theta))

# 在矩形内随机点
static func random_point_in_rect(rect_size: Vector2) -> Vector2:
	return Vector2(randf() * rect_size.x, randf() * rect_size.y)

# 随机颜色
static func random_color(alpha: float = 1.0) -> Color:
	return Color(randf(), randf(), randf(), alpha)

# 随机灰度
static func random_gray(min_val: float = 0.0, max_val: float = 1.0) -> Color:
	var value = randf_range(min_val, max_val)
	return Color(value, value, value)

# 生成唯一ID
static func generate_id(length: int = 8) -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var result = ""
	for i in range(length):
		result += chars[randi() % chars.length()]
	return result

# 随机延迟（用于计时器）
static func random_delay(min_time: float, max_time: float) -> float:
	return randf_range(min_time, max_time)

# 高斯分布随机数（Box-Muller变换）
static func gaussian_random(mean: float = 0.0, std_dev: float = 1.0) -> float:
	var u1 = randf()
	var u2 = randf()
	while u1 == 0:
		u1 = randf()
	
	var mag = std_dev * sqrt(-2.0 * log(u1))
	var z0 = mag * cos(2.0 * PI * u2) + mean
	return z0
