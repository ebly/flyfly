extends Node
class_name ResourceManagerClass

# ============================================
# 资源管理器 - 统一资源加载与卸载
# ============================================
# 用于优化资源加载和管理资源生命周期
# 功能：
# - 资源预加载
# - 资源缓存与引用计数
# - 资源异步加载
# - 资源加载进度跟踪
# ============================================

# 资源缓存
var _resource_cache: Dictionary = {}

# 异步加载任务
var _async_tasks: Dictionary = {}

# 资源组定义
var _resource_groups: Dictionary = {}

# 资源引用计数
var _resource_ref_counts: Dictionary = {}

# 资源加载进度
var _load_progress: float = 0.0

# 资源数据结构
class ResourceData:
	var resource: Resource
	var ref_count: int
	var last_access_time: float
	var auto_unload_time: float
	
	func _init(p_resource: Resource, p_auto_unload_time: float = 30.0):
		resource = p_resource
		ref_count = 1
		last_access_time = Time.get_unix_time_from_system()
		auto_unload_time = p_auto_unload_time

# ============================================
# 资源加载与缓存
# ============================================

# 同步加载资源
func load_resource(path: String, auto_unload_time: float = 30.0) -> Resource:
	# 检查缓存
	if _resource_cache.has(path):
		var resource_data = _resource_cache[path]
		resource_data.ref_count += 1
		resource_data.last_access_time = Time.get_unix_time_from_system()
		return resource_data.resource
	
	# 加载资源
	var resource: Resource = load(path)
	if not resource:
		push_error("无法加载资源: " + path)
		return null
	
	# 添加到缓存
	var resource_data = ResourceData.new(resource, auto_unload_time)
	_resource_cache[path] = resource_data
	_resource_ref_counts[path] = 1
	
	print("资源加载完成: " + path)
	return resource

# 异步加载资源
func async_load_resource(path: String, callback: Callable, auto_unload_time: float = 30.0) -> int:
	var task_id: int = randi() % 1000000
	
	# 检查缓存
	if _resource_cache.has(path):
		var resource_data = _resource_cache[path]
		resource_data.ref_count += 1
		resource_data.last_access_time = Time.get_unix_time_from_system()
		
		# 立即调用回调
		callback.call(resource_data.resource)
		return -1
	
	# 创建异步加载任务
	var task = {
		"path": path,
		"callback": callback,
		"auto_unload_time": auto_unload_time,
		"status": "loading"
	}
	
	_async_tasks[task_id] = task
	
	# 使用同步加载资源包 (Godot 4.x 使用 ProjectSettings.load_resource_pack)
	var success = ProjectSettings.load_resource_pack(path)
	
	# 直接调用完成处理函数
	_on_async_resource_loaded(task_id, path, null)
	
	return task_id

# 异步加载完成处理
func _on_async_resource_loaded(task_id: int, path: String, resource: Resource):
	if not _async_tasks.has(task_id):
		return
	
	var task = _async_tasks[task_id]
	
	if not resource:
		push_error("异步加载资源失败: " + path)
		if task.callback:
			task.callback.call(null)
		_async_tasks.erase(task_id)
		return
	
	# 添加到缓存
	var resource_data = ResourceData.new(resource, task.auto_unload_time)
	_resource_cache[path] = resource_data
	_resource_ref_counts[path] = 1
	
	# 调用回调
	if task.callback:
		task.callback.call(resource)
	
	# 更新加载进度
	_update_load_progress()
	
	print("异步资源加载完成: " + path)
	_async_tasks.erase(task_id)

# 释放资源引用
func release_resource(path: String) -> void:
	if not _resource_cache.has(path):
		return
	
	var resource_data = _resource_cache[path]
	resource_data.ref_count -= 1
	
	# 如果引用计数为0，标记为可卸载
	if resource_data.ref_count <= 0:
		print("资源引用计数为0，准备卸载: " + path)
		
		# 立即卸载或延迟卸载
		if resource_data.auto_unload_time <= 0:
			_unload_resource(path)
		else:
			# 等待一段时间后自动卸载
			var timer: Timer = Timer.new()
			add_child(timer)
			timer.wait_time = resource_data.auto_unload_time
			timer.one_shot = true
			timer.timeout.connect(func():
				# 再次检查引用计数
				if _resource_cache.has(path):
					var data = _resource_cache[path]
					if data.ref_count <= 0:
						_unload_resource(path)
					timer.queue_free()
			)
			timer.start()

# 强制卸载资源
func _unload_resource(path: String) -> void:
	if not _resource_cache.has(path):
		return
	
	# 移除缓存
	_resource_cache.erase(path)
	_resource_ref_counts.erase(path)
	
	print("资源已卸载: " + path)

# ============================================
# 资源组管理
# ============================================

# 定义资源组
func define_resource_group(group_name: String, resources: Array) -> void:
	_resource_groups[group_name] = resources

# 预加载资源组
func preload_resource_group(group_name: String) -> void:
	if not _resource_groups.has(group_name):
		push_error("资源组不存在: " + group_name)
		return
	
	var resources = _resource_groups[group_name]
	for resource_path in resources:
		load_resource(resource_path)
	
	print("资源组预加载完成: " + group_name)

# 卸载资源组
func unload_resource_group(group_name: String) -> void:
	if not _resource_groups.has(group_name):
		return
	
	var resources = _resource_groups[group_name]
	for resource_path in resources:
		release_resource(resource_path)

# ============================================
# 资源加载进度
# ============================================

# 获取资源加载进度
func get_load_progress() -> float:
	return _load_progress

# 更新加载进度
func _update_load_progress() -> void:
	if _async_tasks.is_empty():
		_load_progress = 1.0
		return
	
	var total_tasks: int = _async_tasks.size()
	var completed_tasks: int = 0
	
	for task_id in _async_tasks.keys():
		var task = _async_tasks[task_id]
		if task.status == "completed":
			completed_tasks += 1
	
	_load_progress = completed_tasks / float(total_tasks)

# ============================================
# 资源管理
# ============================================

# 清理所有未使用的资源
func cleanup_unused_resources() -> void:
	var current_time: float = Time.get_unix_time_from_system()
	var paths_to_unload: Array = []
	
	for path in _resource_cache.keys():
		var resource_data = _resource_cache[path]
		if resource_data.ref_count <= 0:
			var time_since_last_access: float = current_time - resource_data.last_access_time
			if time_since_last_access > resource_data.auto_unload_time:
				paths_to_unload.append(path)
	
	for path in paths_to_unload:
		_unload_resource(path)

# 清空资源缓存
func clear_cache() -> void:
	for path in _resource_cache.keys():
		_unload_resource(path)

# 获取缓存资源数量
func get_cache_size() -> int:
	return _resource_cache.size()

# 定时清理未使用资源
func _ready() -> void:
	# 设置定时器定期清理未使用资源
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = 60.0  # 每分钟清理一次
	timer.timeout.connect(cleanup_unused_resources)
	timer.start()
	
	print("资源管理器初始化完成")

# 预加载常用资源
func preload_common_resources() -> void:
	# 定义常用资源组
	var common_resources = [
		"res://assets/bg.png",
		"res://icon.svg",
		# 可以添加更多常用资源路径
	]
	
	define_resource_group("common", common_resources)
	preload_resource_group("common")
