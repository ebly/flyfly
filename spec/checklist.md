# 优化检查清单

## 阶段一：高优先级修复

- [x] 1.1 修复 player.gd 重复函数定义
- [x] 1.2 修复 bullet.gd 缩进错误
- [x] 1.3 修复 enemy.gd 缺失字典键
- [x] 1.4 修复 bullet.gd 重复销毁逻辑

## 阶段二：代码质量优化

- [x] 2.1 提取对象池返回逻辑到公共方法
- [x] 2.2 删除 enemy.gd 未使用变量
- [x] 2.3 删除 player.gd 未使用变量
- [x] 2.4 合并 game.gd 重复函数
- [x] 2.5 创建游戏常量文件

## 阶段三：性能优化

- [x] 3.1 优化 player.gd 碰撞检测
- [x] 3.2 缓存玩家引用避免每帧查找
- [x] 3.3 移除 bullet.gd 重复碰撞检测
- [x] 3.4 拆分 enemy.gd 过长函数

## 阶段四：错误处理增强

- [x] 4.1 添加 GlobalState.instance 空值检查
- [x] 4.2 添加 get_parent() 空值检查
- [x] 4.3 添加 get_tree() 空值检查
- [x] 4.4 添加 preload() 返回值检查

## 验收测试

- [ ] 项目可正常启动
- [ ] 玩家移动正常
- [ ] 玩家射击正常
- [ ] 敌人生成正常
- [ ] 敌人移动正常
- [ ] 敌人射击正常
- [ ] 碰撞检测正常
- [ ] 技能掉落正常
- [ ] 金币收集正常
- [ ] 无控制台错误输出

## 优化完成总结

### 已完成的所有优化：

**高优先级修复：**
- player.gd 重复函数定义已删除
- bullet.gd 完全重写，修复缩进和销毁逻辑
- enemy.gd 添加了缺失的 legendary 键

**代码质量优化：**
- 提取 `_return_to_pool_or_free()` 公共方法
- 删除约 15 个未使用变量
- 合并重复的技能图标显示函数
- 创建 `constants/game_constants.gd`

**性能优化：**
- 优化碰撞检测逻辑
- 缓存玩家引用
- 移除重复碰撞检测

**函数拆分 (_spawn_skill_drop)：**
- `_get_base_drop_config()` - 获取基础掉落配置
- `_calculate_wave_bonus()` - 计算波次奖励
- `_calculate_final_drop_chance()` - 计算最终掉落概率
- `_merge_skill_lists()` - 合并技能列表
- `_select_weighted_skill()` - 选择加权技能
- `_group_skills_by_rarity()` - 按稀有度分组
- `_build_weighted_skill_list()` - 构建加权技能列表
- `_add_weighted_skills()` - 添加加权技能
- `_create_skill_drop()` - 创建技能掉落物
- `_setup_coin_appearance()` - 设置金币外观

**空值检查：**
- `GlobalState.instance` 检查
- `get_parent()` 检查
- `get_tree()` 检查
- `preload()` 返回值检查
