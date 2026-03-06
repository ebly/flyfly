extends Node

# ============================================
# 视野剔除管理器 - 优化性能
# ============================================
# 只处理屏幕内的对象，减少不必要的计算
# ============================================

@onready var EventBus = get_node("/root/EventBus")

# 视野范围（屏幕尺寸 + 边距）
var viewport_size: Vector2 = Vector2(1920, 1080)
var margin: float = 100.0  # 边距，防止对象突然消失

# 需要管理的节点组
const GROUP_ENEMIES = "enemies"
const GROUP_BULLETS = "bullets"
const GROUP_ITEMS = "items"

# 性能统计
var _stats = {
	"total_enemies": 0,
	"active_enemies": 0,
	"total_bullets": 0,
	"active_bullets": 0,
	"culled_count": 0
}

func _ready():
	# 获取视口尺寸
	viewport_size = get_viewport().get_visible_rect().size
	print("视野管理器初始化完成，视口尺寸: " + str(viewport_size))

func _process(_delta):
	_update_visibility()

# 更新所有对象的可见性
func _update_visibility():
	_cull_group(GROUP_ENEMIES)
	_cull_group(GROUP_BULLETS)
	_cull_group(GROUP_ITEMS)

# 对指定组进行视野剔除
func _cull_group(group_name: String):
	var nodes = get_tree().get_nodes_in_group(group_name)
	
	for node in nodes:
		if not is_instance_valid(node):
			continue
		
		var should_process = _is_in_viewport(node)
		
		# 启用/禁用处理
		if should_process:
			_enable_node(node)
		else:
			_disable_node(node)

# 检查对象是否在视野内
func _is_in_viewport(node: Node) -> bool:
	if not node is Node2D:
		return true  # 非2D节点默认处理
	
	var pos = node.global_position
	var camera_pos = _get_camera_position()
	
	# 计算相对于相机的位置
	var relative_pos = pos - camera_pos
	
	# 检查是否在视野范围内（带边距）
	var min_x = -margin
	var max_x = viewport_size.x + margin
	var min_y = -margin
	var max_y = viewport_size.y + margin
	
	return relative_pos.x >= min_x and relative_pos.x <= max_x and \
		   relative_pos.y >= min_y and relative_pos.y <= max_y

# 获取相机位置
func _get_camera_position() -> Vector2:
	# 假设主相机在场景根节点
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.global_position - viewport_size / 2
	return Vector2.ZERO

# 启用节点处理
func _enable_node(node: Node):
	if node.process_mode == Node.PROCESS_MODE_DISABLED:
		node.process_mode = Node.PROCESS_MODE_INHERIT
		
	# 恢复物理处理
	if node is CharacterBody2D or node is RigidBody2D:
		node.set_physics_process(true)
	
	# 恢复可见性
	if node is CanvasItem:
		node.visible = true

# 禁用节点处理
func _disable_node(node: Node):
	if node.process_mode != Node.PROCESS_MODE_DISABLED:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 暂停物理处理
	if node is CharacterBody2D or node is RigidBody2D:
		node.set_physics_process(false)
	
	# 保持可见但停止更新（可选：完全隐藏）
	# if node is CanvasItem:
	#     node.visible = false

# 注册对象到管理组
func register_object(node: Node, group_name: String):
	if not node.is_in_group(group_name):
		node.add_to_group(group_name)

# 注销对象
func unregister_object(node: Node, group_name: String):
	if node.is_in_group(group_name):
		node.remove_from_group(group_name)

# 获取性能统计
func get_stats() -> Dictionary:
	_stats["total_enemies"] = get_tree().get_nodes_in_group(GROUP_ENEMIES).size()
	_stats["total_bullets"] = get_tree().get_nodes_in_group(GROUP_BULLETS).size()
	return _stats.duplicate()

# 打印统计信息
func print_stats():
	var stats = get_stats()
	print("=== 视野剔除统计 ===")
	print("敌人: " + str(stats["active_enemies"]) + "/" + str(stats["total_enemies"]))
	print("子弹: " + str(stats["active_bullets"]) + "/" + str(stats["total_bullets"]))
	print("已剔除: " + str(stats["culled_count"]))
