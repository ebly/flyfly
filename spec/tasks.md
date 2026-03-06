# 优化任务列表

## 阶段一：高优先级修复

### 任务 1.1：修复 player.gd 重复函数定义
- **文件**: `entities/player.gd`
- **问题**: `set_base_attribute_level` 函数定义两次，第二个覆盖第一个
- **操作**: 删除第二个定义（第157-166行），保留第一个完整版本

### 任务 1.2：修复 bullet.gd 缩进错误
- **文件**: `entities/bullet.gd`
- **问题**: 第200-203行缩进不正确
- **操作**: 修正 `_handle_collision` 函数中的缩进

### 任务 1.3：修复 enemy.gd 缺失字典键
- **文件**: `entities/enemy.gd`
- **问题**: `skill_rarity` 字典缺少 `legendary` 键
- **操作**: 添加 `legendary` 键定义

### 任务 1.4：修复 bullet.gd 重复销毁逻辑
- **文件**: `entities/bullet.gd`
- **问题**: 敌人子弹同时调用 queue_free 和对象池返回
- **操作**: 使用 elif 替代独立的 if 语句

## 阶段二：代码质量优化

### 任务 2.1：提取对象池返回逻辑
- **文件**: `entities/bullet.gd`
- **操作**: 创建 `_return_to_pool_or_free()` 方法，替换所有重复的对象池返回代码

### 任务 2.2：删除 enemy.gd 未使用变量
- **文件**: `entities/enemy.gd`
- **操作**: 删除以下未使用变量：
  - `fly_direction`
  - `cached_player`
  - `player_last_position`
  - `player_pos_update_timer`
  - `flight_pattern`
  - `pattern_params`
  - `movement_smoothing`
  - `enemy_velocity`
  - `last_player_position_for_shooting`
  - `shooting_angle`

### 任务 2.3：删除 player.gd 未使用变量
- **文件**: `entities/player.gd`
- **操作**: 删除 `crit_chance` 和 `crit_multiplier` 从 `base_attribute_levels`

### 任务 2.4：合并 game.gd 重复函数
- **文件**: `managers/game.gd`
- **操作**: 合并 `_update_skill_icons_display` 和 `update_skill_icons_display` 为一个函数

### 任务 2.5：提取硬编码值为常量
- **文件**: 多个文件
- **操作**: 创建 `constants/game_constants.gd`，定义：
  - `BASE_SPEED = 300.0`
  - `BASE_DAMAGE = 1`
  - `BASE_RANGE = 2000.0`
  - `MAP_SIZE = Vector2(3840, 2160)`
  - `SCREEN_SIZE = Vector2(1920, 1080)`

## 阶段三：性能优化

### 任务 3.1：优化 player.gd 碰撞检测
- **文件**: `entities/player.gd`
- **操作**: 使用 Area2D 信号替代每帧手动检测敌人碰撞

### 任务 3.2：缓存玩家引用
- **文件**: `entities/enemy.gd`
- **操作**: 在 `_ready()` 中缓存玩家引用，避免每帧查找

### 任务 3.3：移除重复碰撞检测
- **文件**: `entities/bullet.gd`
- **操作**: 只保留 `body_entered` 信号检测，移除 `_check_collisions()` 手动检测

### 任务 3.4：拆分过长函数
- **文件**: `entities/enemy.gd`
- **操作**: 将 `_spawn_skill_drop` 拆分为：
  - `_get_skill_rarity_config()`
  - `_calculate_drop_chance()`
  - `_select_random_skill()`

## 阶段四：错误处理增强

### 任务 4.1：添加空值检查
- **文件**: 多个文件
- **操作**: 为以下调用添加空值检查：
  - `GlobalState.instance`
  - `get_parent()`
  - `get_tree()`
  - `load()` 返回值
