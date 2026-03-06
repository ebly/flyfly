extends Control

const StageManager = preload("res://stages/stage_manager.gd")
const StageConfig = preload("res://stages/stage_config.gd")
@onready var EventBus: Node = get_node("/root/EventBus")
@onready var GlobalState: Node = get_node("/root/GlobalState")

var world: Node = null
var screen_size: Vector2 = Vector2(1920, 1080)
var map_size: Vector2 = Vector2(3840, 2160) # 放大后的地图尺寸
var money: int = 0
var money_label: Label = null
var enemies_killed: int = 0
var is_game_over: bool = false

var game_over_panel: Control = null
var game_over_enemies_label: Label = null
var game_over_money_label: Label = null
var confirm_button: Button = null

# 血量显示
var health_container: Control = null
var health_boxes: Array[Control] = []
var full_health_color: Color = Color(1, 0.2, 0.2, 1)  # 红色（满血）
var empty_health_color: Color = Color(0.3, 0.3, 0.3, 1)  # 灰色（空血）

# 关卡相关
var stage_manager: StageManager = null
var enemy_generator: Node = null

# 过关条件相关
var current_score: int = 0
var elapsed_time: float = 0.0
var is_stage_cleared: bool = false

# 敌人相关
var total_enemies_in_stage: int = 0  # 整个关卡的总敌人数量

# 技能图标管理
var skill_icons: Dictionary = {}  # 技能图标节点字典
var acquired_skills: Array = []  # 按获取顺序排列的技能列表
var icon_count: int = 0  # 当前已使用的图标数量

# UI显示
var score_label: Label = null
var score_progress_bar: ProgressBar = null  # 积分进度条

func _ready() -> void:
	world = get_node_or_null("World")
	screen_size = get_viewport().get_visible_rect().size
	money_label = get_node_or_null("MoneyLabel")
	
	# 获取过关条件UI节点
	score_label = get_node_or_null("ScoreLabel")
	score_progress_bar = get_node_or_null("ScoreProgressBar")
	
	# 初始化技能图标管理
	_init_skill_icon_management()
	
	# 获取血量显示节点
	health_container = get_node_or_null("HealthContainer")
	if health_container:
		for i in range(1, 6):
			var box: Control = health_container.get_node_or_null("HealthBox" + str(i))
			if box:
				health_boxes.append(box)
	
	
	
	# 获取结算面板节点
	game_over_panel = get_node_or_null("GameOverPanel")
	if game_over_panel:
		game_over_enemies_label = game_over_panel.get_node_or_null("EnemiesKilledLabel")
		game_over_money_label = game_over_panel.get_node_or_null("MoneyLabel")
		confirm_button = game_over_panel.get_node_or_null("ConfirmButton")
		if confirm_button:
			confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	# 连接事件总线
	_connect_events()
	
	# 初始化关卡
	_init_stage()
	
	update_money_display()
	update_health_display()
	update_score_display()

# 连接事件总线
func _connect_events() -> void:
	EventBus.ui_update_health.connect(_on_health_changed)
	EventBus.ui_update_money.connect(_on_money_changed)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_over.connect(_on_game_over)
	EventBus.skill_drop_collected.connect(_on_skill_unlocked)

# 初始化关卡
func _init_stage() -> void:
	# 从全局状态获取关卡管理器
	if GlobalState.instance != null and GlobalState.instance.stage_manager != null:
		stage_manager = GlobalState.instance.stage_manager
		money = GlobalState.instance.current_money
		print("游戏场景：加载关卡管理器，当前难度: " + GlobalState.instance.current_difficulty)
		
		# 获取关卡配置
		var stage_config: StageConfig = stage_manager.get_current_stage_config()
		if stage_config != null:
			print("当前关卡: " + stage_config.stage_name)
			print("最大波次: " + str(stage_config.max_waves))
			print("技能奖励: " + str(stage_config.skill_rewards))
			
			# 计算整个关卡的总敌人数量
			total_enemies_in_stage = _calculate_total_enemies(stage_config)
			print("整个关卡总敌人数量: " + str(total_enemies_in_stage))
		
		# 启动游戏
		GlobalState.instance.start_game(GlobalState.instance.current_difficulty)
	else:
		print("警告：未找到关卡管理器，使用默认配置")
		# 使用默认过关条件
		total_enemies_in_stage = 100  # 默认总敌人数量
	
	# 设置敌人生成器
	if world != null:
		enemy_generator = world.get_node_or_null("EnemyGenerator")
		if enemy_generator != null:
			if stage_manager != null:
				enemy_generator.set_stage_manager(stage_manager)
			enemy_generator.start_spawning()

# 计算整个关卡的总敌人数量
func _calculate_total_enemies(stage_config: StageConfig) -> int:
	var total: int = 0
	var max_waves: int = stage_config.max_waves
	
	# 遍历所有波次，累加每个波次的敌人数量
	for wave in range(1, max_waves + 1):
		var enemy_config: Dictionary = stage_config.get_enemy_config(wave)
		if not enemy_config.is_empty():
			var wave_enemies: int = enemy_config.get("max_enemies", stage_config.max_enemies_per_wave)
			total += wave_enemies
	
	return total

func _process(delta: float) -> void:
	if is_game_over or is_stage_cleared:
		return
	
	# 更新 elapsed_time
	elapsed_time += delta
	

	
	# 检查是否杀完所有敌人（唯一过关条件）
	if enemies_killed >= total_enemies_in_stage and total_enemies_in_stage > 0 and not is_stage_cleared:
		stage_clear("杀完所有敌人！")
		return
	
	# 检查当前波次是否完成，如果完成则切换到下一波
	_check_wave_completion()
	
	if world == null:
		return
	
	var player = world.get_node_or_null("Player")
	if player == null:
		return
	
	var player_pos = player.position

	# 计算地图应该的偏移量，使玩家始终在屏幕中心
	var target_world_offset = -player_pos + screen_size / 2

	# 限制地图偏移，确保地图边缘不超出屏幕
	var max_offset_x = screen_size.x - map_size.x
	var max_offset_y = screen_size.y - map_size.y
	target_world_offset.x = clamp(target_world_offset.x, max_offset_x, 0)
	target_world_offset.y = clamp(target_world_offset.y, max_offset_y, 0)

	# 应用地图偏移
	world.position = target_world_offset

# 事件回调
func _on_health_changed(current: int, _max_health: int) -> void:
	for i in range(health_boxes.size()):
		var box: Control = health_boxes[i]
		if i < current:
			box.modulate = full_health_color
		else:
			box.modulate = empty_health_color

func _on_money_changed(amount: int) -> void:
	money = amount
	update_money_display()

func _on_enemy_died(_enemy_id: StringName, _position: Vector2, _coin_value: int) -> void:
	enemies_killed += 1
	# 击败敌人获得积分
	var score_gain: int = 10  # 基础积分
	match _enemy_id:
		"enemy_basic":
			score_gain = 10
		"enemy_drone":
			score_gain = 15
		"enemy_fast":
			score_gain = 20
		"enemy_heavy":
			score_gain = 30
		"enemy_elite":
			score_gain = 50
		"enemy_kamikaze":
			score_gain = 25
		_:
			score_gain = 10
	
	add_score(score_gain)

func _on_coin_collected(amount: int) -> void:
	add_money(amount)
	print("获得金币: " + str(amount) + ", 当前金钱: " + str(money))

func _on_player_died() -> void:
	game_over("角色死亡")

func _on_game_over(_is_victory: bool, _score: int, _money: int) -> void:
	_show_game_over_panel()

func update_health_display() -> void:
	# 现在通过事件驱动更新，此方法保留用于初始化
	if world == null:
		return
	
	var player: Node = world.get_node_or_null("Player")
	if player == null:
		return
	
	var current_health: int = player.current_health
	var _max_health: int = player.max_health
	
	for i in range(health_boxes.size()):
		var box: Control = health_boxes[i]
		if i < current_health:
			box.modulate = full_health_color
		else:
			box.modulate = empty_health_color

func add_money(amount: int) -> void:
	if is_game_over or is_stage_cleared:
		return
	money += amount
	update_money_display()
	
	# 更新全局状态
	if GlobalState.instance != null:
		GlobalState.instance.current_money = money
	
	# 触发金钱变化事件
	EventBus.emit_player_money_changed(money)

func update_money_display() -> void:
	if money_label:
		money_label.text = "金钱: " + str(money)

func add_score(amount: int) -> void:
	if is_game_over or is_stage_cleared:
		return
	current_score += amount
	update_score_display()

func update_score_display() -> void:
	if score_label:
		score_label.text = "积分: " + str(current_score)
	
	# 更新进度条（使用已杀敌人数量和总敌人数量）
	if score_progress_bar:
		if total_enemies_in_stage > 0:
			var progress: float = float(enemies_killed) / float(total_enemies_in_stage)
			score_progress_bar.value = min(progress, 1.0)  # 最大值为1.0
			
			# 更新进度条上的文字
			var progress_label: Label = score_progress_bar.get_node_or_null("ScoreLabel")
			if progress_label:
				progress_label.text = str(enemies_killed) + " / " + str(total_enemies_in_stage)
			
			# 进度条颜色变化：根据进度改变颜色
			if progress >= 1.0:
				# 达标后变成绿色
				score_progress_bar.modulate = Color(0.2, 1.0, 0.2)
			elif progress >= 0.7:
				# 70%以上变成黄色
				score_progress_bar.modulate = Color(1.0, 1.0, 0.2)
			else:
				# 默认蓝色
				score_progress_bar.modulate = Color(0.2, 0.6, 1.0)
		else:
			score_progress_bar.value = 0.0



func add_enemy_killed() -> void:
	if is_game_over or is_stage_cleared:
		return
	enemies_killed += 1
	# 更新进度条显示
	update_score_display()

# 暂停所有敌人
func _pause_all_enemies() -> void:
	# 获取所有敌人节点
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	
	# 遍历并暂停每个敌人
	for enemy in enemies:
		if is_instance_valid(enemy):
			# 暂停所有处理
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			
			# 暂停物理处理
			if enemy is CharacterBody2D or enemy is RigidBody2D:
				enemy.set_physics_process(false)
				enemy.velocity = Vector2.ZERO  # 停止移动
			
			# 暂停定时器（如射击定时器）
			for child in enemy.get_children():
				if child is Timer:
					child.stop()
					print("暂停敌机" + enemy.name + "的定时器")
			
			print("暂停敌机: " + enemy.name)
	
	print("已暂停所有敌机，共 " + str(enemies.size()) + " 架")

func game_over(reason: String = "") -> void:
	if is_game_over:
		return
	is_game_over = true
	print("游戏结束: " + reason)
	
	# 停止敌人生成
	if enemy_generator != null:
		enemy_generator.stop_spawning()
		
	# 暂停所有敌人
	_pause_all_enemies()
	
	# 发送游戏结束事件
	EventBus.game_over.emit(false, current_score, money)
	
	# 显示失败界面
	_show_game_over_panel(false)

# 过关
func stage_clear(reason: String = "") -> void:
	if is_stage_cleared:
		return
	is_stage_cleared = true
	print("关卡过关! " + reason)
	print("击败敌机: " + str(enemies_killed) + "/" + str(total_enemies_in_stage))
	print("用时: " + str(elapsed_time) + "秒")
	
	# 停止敌人生成
	if enemy_generator != null:
		enemy_generator.stop_spawning()
		
	# 暂停所有敌人
	_pause_all_enemies()
	
	# 发送过关事件
	EventBus.game_over.emit(true, current_score, money)
	
	# 显示过关界面
	_show_game_over_panel(true)

func _show_game_over_panel(is_victory: bool = false) -> void:
	# 显示结算面板
	if game_over_panel:
		game_over_panel.visible = true
		
		# 更新标题
		var title_label: Label = game_over_panel.get_node_or_null("TitleLabel")
		if title_label:
			title_label.text = "关卡过关!" if is_victory else "游戏结束"
			title_label.modulate = Color(0, 1, 0) if is_victory else Color(1, 0, 0)
		
		if game_over_enemies_label:
			game_over_enemies_label.text = "击败敌机: " + str(enemies_killed)
		if game_over_money_label:
			game_over_money_label.text = "获得金钱: " + str(money)
		
		# 添加积分显示
	var score_label_node: Label = game_over_panel.get_node_or_null("ScoreLabel")
	if score_label_node:
		score_label_node.text = "获得积分: " + str(current_score)

func _check_wave_completion() -> void:
	# 检查波次完成情况
	if enemy_generator == null:
		return
	
	# 检查当前波次是否已经生成了所有敌人
	if enemy_generator.is_all_enemies_spawned():
		# 检查当前波次是否还有敌人在场景中
		var enemies_in_scene: Array[Node] = get_tree().get_nodes_in_group("enemies")
		if enemies_in_scene.size() == 0:
			# 当前波次所有敌人都已处理完毕，切换到下一波
			var current_wave: int = enemy_generator.get_current_wave()
			var max_waves: int = enemy_generator.get_max_waves()
			
			if current_wave < max_waves:
				# 还有波次，切换到下一波
				enemy_generator.next_wave()
				print("切换到第 " + str(current_wave + 1) + " 波")
			else:
				# 所有波次都已完成
				print("所有波次都已完成")
				# 这里可以添加所有波次完成后的逻辑
				# 但真正的过关条件还是杀完所有敌人

func _on_confirm_button_pressed() -> void:
	# 保存游戏数据到全局状态
	if GlobalState.instance != null:
		GlobalState.instance.current_money = money
	
	# 跳回地图场景
	var map_scene: PackedScene = load("res://scenes/map.tscn") as PackedScene
	if map_scene:
		get_tree().change_scene_to_packed(map_scene)

# 获取当前关卡可掉落的技能列表
func get_stage_skill_rewards() -> Array:
	if stage_manager == null:
		return []
	return stage_manager.get_current_stage_skill_rewards()

# 获取当前关卡技能掉落概率
func get_skill_drop_chance() -> float:
	if stage_manager == null:
		return 0.2
	var stage_config: StageConfig = stage_manager.get_current_stage_config()
	if stage_config == null:
		return 0.2
	return stage_config.get_skill_drop_chance(enemy_generator.get_current_wave() if enemy_generator else 1)

# 初始化技能图标管理
func _init_skill_icon_management() -> void:
	# 获取技能容器节点
	var ability_container = get_node_or_null("AbilityContainer")
	if not ability_container:
		print("警告：未找到AbilityContainer节点")
		return
	
	# 获取所有技能图标节点
	for i in range(1, 9):
		var icon_node = ability_container.get_node_or_null("SkillIcon" + str(i))
		if icon_node:
			skill_icons[i] = icon_node
			print("找到技能图标节点: SkillIcon" + str(i))
	
	# 初始化获取技能列表
	acquired_skills = []
	
	# 显示初始拥有的技能图标
	_display_initial_skill_icons()

# 显示初始拥有的技能图标
func _display_initial_skill_icons() -> void:
	# 检查全局状态中的初始技能
	if GlobalState.instance != null:
		for skill in GlobalState.instance.current_skills:
			_add_skill_to_display(skill)

# 添加技能到显示列表
func _add_skill_to_display(skill_type: String) -> void:
	# 如果技能已经在列表中，跳过
	if acquired_skills.has(skill_type):
		return
	
	# 将技能添加到获取列表
	acquired_skills.append(skill_type)
	
	# 更新技能图标的显示
	_update_skill_icons_display()

# 显示技能图标
func _update_skill_icons_display() -> void:
	update_skill_icons_display()

# 处理技能解锁事件
func _on_skill_unlocked(skill_type: String) -> void:
	_add_skill_to_display(skill_type)
	print("技能解锁事件触发: " + skill_type + "，添加到技能显示列表")

# 获取当前显示的技能图标数量
func get_visible_skill_icon_count() -> int:
	return icon_count

# 更新所有技能图标的显示状态
func update_skill_icons_display() -> void:
	for icon in skill_icons.values():
		icon.visible = false
	
	icon_count = 0
	
	acquired_skills.clear()
	if GlobalState.instance != null:
		for skill in GlobalState.instance.current_skills:
			if not acquired_skills.has(skill):
				acquired_skills.append(skill)
	
	for i in range(acquired_skills.size()):
		var skill = acquired_skills[i]
		var icon_index = i + 1
		var icon_node = skill_icons.get(icon_index)
		if icon_node:
			icon_node.visible = true
			icon_count += 1
	
	print("当前已显示" + str(icon_count) + "个技能图标")
