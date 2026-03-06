extends Node

# ============================================
# 对象池管理器 - 优化频繁创建/销毁的对象
# ============================================
# 使用方法：
# 1. 注册池：ObjectPool.register_pool("bullet", bullet_scene, 50)
# 2. 获取对象：var bullet = ObjectPool.get_object("bullet")
# 3. 回收对象：ObjectPool.return_object("bullet", bullet)
# ============================================

# 存储所有对象池
var _pools: Dictionary = {}

# 对象池配置
class PoolConfig:
	var scene: PackedScene
	var initial_size: int
	var max_size: int
	var active_objects: Array = []
	var inactive_objects: Array = []
	
	func _init(p_scene: PackedScene, p_initial: int, p_max: int):
		scene = p_scene
		initial_size = p_initial
		max_size = p_max

# ============================================
# 池管理
# ============================================

# 注册对象池
func register_pool(pool_id: String, scene: PackedScene, initial_size: int = 20, max_size: int = 100) -> void:
	if _pools.has(pool_id):
		push_warning("对象池已存在: " + pool_id)
		return
	
	var config = PoolConfig.new(scene, initial_size, max_size)
	_pools[pool_id] = config
	
	# 预创建对象
	_preload_objects(pool_id, initial_size)
	print("注册对象池: " + pool_id + ", 初始大小: " + str(initial_size))

# 注销对象池
func unregister_pool(pool_id: String) -> void:
	if not _pools.has(pool_id):
		return
	
	var config = _pools[pool_id]
	# 清理所有对象
	for obj in config.active_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	for obj in config.inactive_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	
	_pools.erase(pool_id)
	print("注销对象池: " + pool_id)

# 预创建对象
func _preload_objects(pool_id: String, count: int) -> void:
	if not _pools.has(pool_id):
		return
	
	var config = _pools[pool_id]
	for i in range(count):
		var obj = config.scene.instantiate()
		obj.set_meta("pool_id", pool_id)
		config.inactive_objects.append(obj)

# ============================================
# 对象获取与回收
# ============================================

# 获取对象
func get_object(pool_id: String) -> Node:
	if not _pools.has(pool_id):
		push_error("对象池不存在: " + pool_id)
		return null
	
	var config = _pools[pool_id]
	var obj = null
	
	# 从空闲列表获取
	while not config.inactive_objects.is_empty():
		obj = config.inactive_objects.pop_back()
		if is_instance_valid(obj):
			break
		obj = null
	
	# 如果没有空闲对象，创建新的（未超过最大限制）
	if obj == null and config.active_objects.size() < config.max_size:
		obj = config.scene.instantiate()
		obj.set_meta("pool_id", pool_id)
	
	if obj != null:
		config.active_objects.append(obj)
		_reset_object(obj)
	
	return obj

# 回收对象
func return_object(pool_id: String, obj: Node) -> void:
	if obj == null or not is_instance_valid(obj):
		return
	
	if not _pools.has(pool_id):
		obj.queue_free()
		return
	
	var config = _pools[pool_id]
	
	# 从活跃列表移除
	var index = config.active_objects.find(obj)
	if index != -1:
		config.active_objects.remove_at(index)
	
	# 重置对象状态
	_reset_object(obj)
	
	# 如果未超过最大限制，放回空闲列表
	if config.inactive_objects.size() < config.max_size:
		config.inactive_objects.append(obj)
	else:
		obj.queue_free()

# 重置对象状态
func _reset_object(obj: Node) -> void:
	# 停止所有动画和物理
	if obj.has_method("reset"):
		obj.reset()
	
	# 隐藏对象
	obj.visible = false
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 从父节点移除
	if obj.get_parent() != null:
		obj.get_parent().remove_child(obj)

# 准备对象使用
func prepare_object(obj: Node) -> void:
	if obj == null or not is_instance_valid(obj):
		return
	
	obj.visible = true
	obj.process_mode = Node.PROCESS_MODE_INHERIT

# ============================================
# 便捷方法
# ============================================

# 批量回收对象
func return_objects(pool_id: String, objects: Array) -> void:
	for obj in objects:
		return_object(pool_id, obj)

# 清空指定池
func clear_pool(pool_id: String) -> void:
	if not _pools.has(pool_id):
		return
	
	var config = _pools[pool_id]
	return_objects(pool_id, config.active_objects.duplicate())

# 获取池统计信息
func get_pool_stats(pool_id: String) -> Dictionary:
	if not _pools.has(pool_id):
		return {}
	
	var config = _pools[pool_id]
	return {
		"active": config.active_objects.size(),
		"inactive": config.inactive_objects.size(),
		"total": config.active_objects.size() + config.inactive_objects.size(),
		"max": config.max_size
	}

# 打印所有池的统计
func print_all_stats() -> void:
	print("=== 对象池统计 ===")
	for pool_id in _pools.keys():
		var stats = get_pool_stats(pool_id)
		print(pool_id + ": 活跃=" + str(stats.get("active", 0)) + 
			", 空闲=" + str(stats.get("inactive", 0)) + 
			", 总计=" + str(stats.get("total", 0)))
