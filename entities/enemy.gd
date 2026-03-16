extends "res://entities/aircraft_base.gd"

@onready var global_state = get_node("/root/GlobalState")

@onready var event_bus = get_node("/root/EventBus")

var fire_timer: Timer = null

var bullet_library: Array = []

var health_bar: ProgressBar = null

var is_fully_entered_map: bool = false
var sprite_size: Vector2 = Vector2.ZERO

var locked_fly_direction: Vector2 = Vector2.ZERO
var fly_direction: Vector2 = Vector2.ZERO
var move_speed: float = 150.0

var cached_player: CharacterBody2D = null

const SKILL_RARITY = {
	"common": ["dash", "shield"],
	"uncommon": ["rapid_fire", "heal"],
	"rare": ["missile", "homing"],
	"epic": ["laser", "bomb", "explosion"],
	"legendary": ["spread_shot"]
}

func _init():
	aircraft_id = "enemy_basic"

func _ready() -> void:
	super._ready()
	_load_bullet_library()
	_setup_fire_timer()
	_calculate_move_speed()
	
	add_to_group("enemies")
	
	if has_node("HealthBar"):
		health_bar = $HealthBar
	
	_update_health_bar()
	
	if has_node("Sprite2D"):
		sprite_size = $Sprite2D.texture.get_size()
	else:
		sprite_size = Vector2(50, 50)
	
	_calculate_fly_direction()
	locked_fly_direction = fly_direction

func _setup_spawn_position() -> void:
	var screen_size: Vector2 = Vector2(1920, 1080)
	var viewport = get_viewport()
	if viewport:
		screen_size = viewport.get_visible_rect().size
	
	var direction: float = randf_range(0, 360)
	var spawn_distance: float = randf_range(200, 500)
	var spawn_x: float
	var spawn_y: float
	
	if direction < 90:
		spawn_x = screen_size.x + spawn_distance
		spawn_y = randf_range(0, screen_size.y)
	elif direction < 180:
		spawn_x = randf_range(0, screen_size.x)
		spawn_y = -spawn_distance
	elif direction < 270:
		spawn_x = -spawn_distance
		spawn_y = randf_range(0, screen_size.y)
	else:
		spawn_x = randf_range(0, screen_size.x)
		spawn_y = screen_size.y + spawn_distance
	
	position = Vector2(spawn_x, spawn_y)
	_calculate_fly_direction()

func _setup_fire_timer() -> void:
	var fire_rate: float = config.get("fire_rate", 0)
	if fire_rate > 0 and not bullet_library.is_empty():
		fire_timer = Timer.new()
		add_child(fire_timer)
		fire_timer.wait_time = fire_rate
		fire_timer.autostart = true
		fire_timer.timeout.connect(_on_fire_timer_timeout)

func _load_bullet_library() -> void:
	bullet_library = AircraftConfig.get_enemy_bullet_library(aircraft_id)
	if bullet_library.is_empty():
		bullet_library = ["basic"]

func _calculate_move_speed() -> void:
	var move_speed_level = 1
	if config.has("base") and config["base"].has("move_speed"):
		move_speed_level = config["base"]["move_speed"]
	move_speed = AircraftConfig.get_base_level_value("move_speed", move_speed_level)

func _physics_process(_delta: float) -> void:
	if config.is_empty():
		return
	
	_check_fully_entered_map()
	
	var tree = get_tree()
	if tree:
		var player = tree.get_first_node_in_group("player")
		if player != null:
			var direction: Vector2 = (player.position - position).normalized()
			var movement: Vector2 = direction * move_speed
			self.velocity = movement
			move_and_slide()
		else:
			_fly_in_locked_direction()
	else:
		_fly_in_locked_direction()

func _fly_in_locked_direction() -> void:
	var movement: Vector2 = locked_fly_direction * move_speed
	self.velocity = movement
	move_and_slide()

func _check_fully_entered_map() -> void:
	if is_fully_entered_map:
		return
	
	var screen_size: Vector2 = Vector2(1920, 1080)
	var viewport = get_viewport()
	if viewport:
		screen_size = viewport.get_visible_rect().size
	
	var sprite_half_width: float = sprite_size.x / 2
	var sprite_half_height: float = sprite_size.y / 2
	
	if position.x + sprite_half_width > 0 and \
	   position.x - sprite_half_width < screen_size.x and \
	   position.y + sprite_half_height > 0 and \
	   position.y - sprite_half_height < screen_size.y:
		is_fully_entered_map = true
		event_bus.enemy_fully_entered_map.emit(aircraft_id, position)

func _calculate_fly_direction() -> void:
	var tree = get_tree()
	if tree:
		var player = tree.get_first_node_in_group("player")
		if player != null:
			fly_direction = (player.position - position).normalized()
		else:
			_fly_toward_center()
	else:
		fly_direction = Vector2(0, 1).normalized()

func _fly_toward_center() -> void:
	var screen_size: Vector2 = Vector2(1920, 1080)
	var viewport = get_viewport()
	if viewport:
		screen_size = viewport.get_visible_rect().size
	var center: Vector2 = Vector2(screen_size.x / 2, screen_size.y / 2)
	fly_direction = (center - position).normalized()

func _on_fire_timer_timeout() -> void:
	fire_bullet()

func fire_bullet() -> void:
	if config.is_empty():
		return
	
	var selected_bullet_type: String = _get_random_bullet_from_library()
	
	var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
	if bullet_scene == null:
		return
	
	var bullet = bullet_scene.instantiate()
	bullet.is_player_bullet = false
	bullet.bullet_type = selected_bullet_type
	bullet.position = position + Vector2(-20, 0)
	bullet.direction = Vector2(-1, 0)
	
	var parent = get_parent()
	if parent:
		parent.add_child(bullet)
		event_bus.bullet_fired.emit(selected_bullet_type, bullet.position, Vector2(-1, 0), false)

func _get_random_bullet_from_library() -> String:
	if bullet_library.is_empty():
		return "basic"
	return bullet_library[randi() % bullet_library.size()]

func _on_damage_taken(_damage: int) -> void:
	event_bus.enemy_damaged.emit(aircraft_id, _damage)
	_update_health_bar()

func _update_health_bar() -> void:
	if health_bar == null:
		return
	
	if max_health > 0:
		var health_percent = float(current_health) / float(max_health)
		health_bar.value = health_percent
		
		if health_percent > 0.6:
			health_bar.modulate = Color(0.2, 1.0, 0.2)
		elif health_percent > 0.3:
			health_bar.modulate = Color(1.0, 1.0, 0.2)
		else:
			health_bar.modulate = Color(1.0, 0.2, 0.2)
		
		health_bar.visible = true
	else:
		health_bar.value = 1.0
		health_bar.visible = true

func _on_before_die() -> void:
	var coin_value = config.get("coin_value", 0)
	event_bus.emit_enemy_died(aircraft_id, position, coin_value)
	
	if global_state.instance != null:
		global_state.instance.record_enemy_killed()
	
	_spawn_coin()
	_spawn_skill_drop()

func _spawn_skill_drop() -> void:
	var drop_config = _get_base_drop_config()
	var base_drop_chance: float = drop_config["chance"]
	var base_skills: Array = drop_config["skills"]
	
	var wave_config = _calculate_wave_bonus()
	var wave_bonus: float = wave_config["bonus"]
	var wave_skill_bonus: Array = wave_config["skills"]
	var higher_rarity_chance: float = wave_config["rarity_chance"]
	
	var final_drop_chance = _calculate_final_drop_chance(base_drop_chance, wave_bonus)
	var available_skills = _merge_skill_lists(base_skills, wave_skill_bonus)
	
	if randf() > final_drop_chance:
		return
	
	if available_skills.is_empty():
		available_skills = AircraftConfig.get_unlockable_skills()
	
	var random_skill = _select_weighted_skill(available_skills, higher_rarity_chance)
	_create_skill_drop(random_skill, final_drop_chance)

func _get_base_drop_config() -> Dictionary:
	match aircraft_id:
		"enemy_basic", "enemy_drone":
			return {"chance": 0.0, "skills": []}
		"enemy_fast":
			return {"chance": 0.08, "skills": ["dash"]}  # 快速飞机掉落dash技能
		"enemy_heavy":
			return {"chance": 0.12, "skills": ["shield"]}  # 防护飞机（重型）掉落shield技能
		"enemy_kamikaze":
			return {"chance": 0.06, "skills": SKILL_RARITY["common"]}
		"enemy_elite":
			return {"chance": 0.20, "skills": SKILL_RARITY["uncommon"] + SKILL_RARITY["rare"]}
		"enemy_boss":
			return {"chance": 1.0, "skills": SKILL_RARITY["rare"] + SKILL_RARITY["epic"] + SKILL_RARITY["legendary"]}
		_:
			return {"chance": 0.0, "skills": []}

func _calculate_wave_bonus() -> Dictionary:
	var result = {"bonus": 0.0, "skills": [], "rarity_chance": 0.0}
	
	if global_state.instance == null:
		return result
	
	var current_wave = global_state.instance.current_wave
	
	result["bonus"] = clamp(current_wave / 30.0, 0.0, 0.5)
	result["rarity_chance"] = clamp((current_wave - 5) / 25.0, 0.0, 0.8)
	
	if current_wave >= 20:
		result["skills"] = SKILL_RARITY["rare"] + SKILL_RARITY["epic"] + SKILL_RARITY["legendary"]
	elif current_wave >= 15:
		result["skills"] = SKILL_RARITY["rare"] + SKILL_RARITY["epic"]
	elif current_wave >= 10:
		result["skills"] = SKILL_RARITY["rare"]
	elif current_wave >= 5:
		result["skills"] = SKILL_RARITY["uncommon"]
	
	return result

func _calculate_final_drop_chance(base_chance: float, wave_bonus: float) -> float:
	var final_chance = base_chance + wave_bonus
	
	if global_state.instance != null and global_state.instance.current_difficulty != "":
		match global_state.instance.current_difficulty:
			"hard":
				final_chance += 0.1
			"nightmare":
				final_chance += 0.2
	
	return clamp(final_chance, 0.0, 0.8)

func _merge_skill_lists(base_skills: Array, wave_skills: Array) -> Array:
	var result = base_skills.duplicate()
	for skill in wave_skills:
		if not result.has(skill):
			result.append(skill)
	return result

func _select_weighted_skill(available_skills: Array, higher_rarity_chance: float) -> String:
	if available_skills.is_empty():
		return "dash"
	
	if global_state.instance == null or higher_rarity_chance <= 0.0:
		return available_skills[randi() % available_skills.size()]
	
	var skill_groups = _group_skills_by_rarity(available_skills)
	var weighted_skills = _build_weighted_skill_list(skill_groups, higher_rarity_chance)
	
	if weighted_skills.is_empty():
		return available_skills[randi() % available_skills.size()]
	
	return weighted_skills[randi() % weighted_skills.size()]

func _group_skills_by_rarity(skills: Array) -> Dictionary:
	var groups = {
		"common": [],
		"uncommon": [],
		"rare": [],
		"epic": [],
		"legendary": []
	}
	
	for skill in skills:
		for rarity in SKILL_RARITY.keys():
			if SKILL_RARITY[rarity].has(skill):
				groups[rarity].append(skill)
				break
	
	return groups

func _build_weighted_skill_list(groups: Dictionary, rarity_chance: float) -> Array:
	var weighted = []
	
	for skill in groups["common"]:
		weighted.append(skill)
	
	_add_weighted_skills(weighted, groups["uncommon"], int(1 + rarity_chance * 2))
	_add_weighted_skills(weighted, groups["rare"], int(1 + rarity_chance * 3))
	_add_weighted_skills(weighted, groups["epic"], int(1 + rarity_chance * 4))
	_add_weighted_skills(weighted, groups["legendary"], int(1 + rarity_chance * 5))
	
	return weighted

func _add_weighted_skills(weighted_list: Array, skills: Array, weight: int) -> void:
	if skills.is_empty():
		return
	for i in range(weight):
		weighted_list.append(skills[randi() % skills.size()])

func _create_skill_drop(skill_type: String, drop_chance: float) -> void:
	var skill_drop_scene: PackedScene = preload("res://scenes/skill_drop.tscn")
	if skill_drop_scene == null:
		return
	
	var skill_drop = skill_drop_scene.instantiate()
	skill_drop.position = position + Vector2(randi() % 40 - 20, randi() % 40 - 20)
	skill_drop.set_skill_type(skill_type)
	
	var parent = get_parent()
	if parent:
		parent.add_child.call_deferred(skill_drop)
	
	var wave_info = 0
	if global_state.instance != null:
		wave_info = global_state.instance.current_wave
	print("敌机掉落技能: " + skill_type + " (波次: " + str(wave_info) + ", 概率: " + str(int(drop_chance * 100)) + "%)")

func _spawn_coin() -> void:
	var coin_value: int = config.get("coin_value", 0)
	if coin_value <= 0:
		return
	
	var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
	if coin_scene == null:
		return
	
	var coin = coin_scene.instantiate()
	coin.position = position
	coin.value = coin_value
	
	var color_rect = coin.get_node("ColorRect")
	if color_rect:
		_setup_coin_appearance(color_rect, coin_value)
	
	var parent = get_parent()
	if parent:
		parent.add_child.call_deferred(coin)

func _setup_coin_appearance(color_rect: ColorRect, value: int) -> void:
	if value >= 50:
		color_rect.color = Color(1, 0.8, 0, 1)
		color_rect.size = Vector2(20, 20)
		color_rect.position = Vector2(-10, -10)
	elif value >= 10:
		color_rect.color = Color(0.8, 0, 0.8, 1)
		color_rect.size = Vector2(16, 16)
		color_rect.position = Vector2(-8, -8)
	elif value >= 5:
		color_rect.color = Color(1, 0.5, 0, 1)
		color_rect.size = Vector2(14, 14)
		color_rect.position = Vector2(-7, -7)
	else:
		color_rect.color = Color(1, 0.8, 0, 1)
		color_rect.size = Vector2(10, 10)
		color_rect.position = Vector2(-5, -5)
