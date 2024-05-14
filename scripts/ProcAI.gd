class_name ProcAI

var entity: Entity
var mas: bool = false
var l_size: int = 0
var init_mem: Array[float] = []

var target_distance: float = 0.0
var target_vector: Vector2 = Vector2(0, 0)

func process(entity_: Entity) -> void:
	entity = entity_
	entity.lock_timer -= entity.idelta
	if entity.lock_timer <= 0.0: entity.is_attack_locked = false
	update_target()
	
	target_vector = entity.target.global_position - entity.global_position
	target_distance = target_vector.length_squared()
	
	processor.root_call(self)
	if mas: entity.move_and_slide()
func update_target() -> void: entity.target = entity.get_tree().root.get_node("world/player") as Entity

static func generate_new(_difficulty: int) -> ProcAI:
	var ai: ProcAI = ProcAI.new()
	
	var rootfw: AIFramework = AIFramework.new()
	
	AIFramework.AI = ai
	AIAction.AI = ai
	rootfw.calc_index()
	rootfw.calc_action_indexes()
	
	ai.processor = rootfw
	
	return ai

func register_entity(ent: Entity):
	ent.proc_ai = self
	ent.locks.clear()
	ent.mem.clear()
	ent.locks.resize(l_size)
	ent.locks.fill(0)
	ent.mem = init_mem.duplicate()

var processor: AIProcessor

class AIProcessor: var process: Callable

class AIFramework extends AIProcessor:
	static var AI: ProcAI
	enum {DEADWEIGHT, DISTANCE_2, CYCLE, RANDOM}
	var init_mem: Array[float] = []
	var type: int
	var actions: Array[AIProcessor] = []
	var l_index: int = -1
	var m_index: int = -1
	
	func _init() -> void:
		type = RANDOM
		actions.push_back(AIAction.new().set_type(AIAction.ALIGN_AND_POUNCE).finalize())
		actions.push_back(AIAction.new().set_type(AIAction.ALIGN_AND_RANGE).finalize())
		actions.push_back(AIAction.new().set_type(AIAction.APPROACH_AND_MELEE).finalize())
		finalize()
	func finalize() -> AIProcessor:
		process = type_to_callable()
		for i in range(min_array_sizes().x): if actions.size() <= i: actions.push_back(AIAction.new().finalize())
		return self
	func type_to_callable() -> Callable:
		match self.type:
			DEADWEIGHT: return deadweight
			DISTANCE_2: return distance_2
			CYCLE: return cycle
			RANDOM: return random
			_: return deadweight
	func min_array_sizes() -> Vector2i: # (actions, mem)
		match self.type:
			DISTANCE_2: return Vector2i(2, 1)
			CYCLE: return Vector2i(1, 1)
			RANDOM: return Vector2i(1, 0)
			_: return Vector2i(0, 0)
	func root_call(ai: ProcAI) -> void:
		AIFramework.AI = ai
		AIAction.AI = ai
		process.call()
	func call_with_lock(dir: int) -> void:
		AI.entity.locks[l_index] = dir
		actions[dir].process.call()
	func forced_lock_dir() -> bool:
		var ret = AI.entity.lock_timer > 0.0
		if ret: actions[AI.entity.locks[l_index]].process.call()
		return ret
	func calc_index() -> void:
		l_index = AI.l_size
		AI.l_size += 1
		m_index = AI.init_mem.size()
		var mas := min_array_sizes()
		while init_mem.size() < mas.y: init_mem.append(0.0)
		if init_mem.size() > 0: AI.init_mem.append_array(init_mem)
		for i in range(actions.size()): if actions[i] is AIFramework:
			actions[i].calc_index()
	func calc_action_indexes() -> void:
		for i in range(actions.size()): 
			if actions[i] is AIFramework: actions[i].calc_action_indexes()
			elif actions[i] is AIAction: actions[i].calc_index()
	
#region Framework Type Methods
	func deadweight() -> void: AIAction.DEADWEIGHT_ACTION.process.call()
	
	func distance_2() -> void:
		if forced_lock_dir(): return
		if AI.target_distance >= AI.entity.mem[m_index]**2: call_with_lock(0)
		else: call_with_lock(1)
	
	func cycle() -> void:
		if forced_lock_dir(): return
		AI.entity.mem[m_index] = int(AI.entity.mem[m_index] + 1) % actions.size()
		call_with_lock(int(AI.entity.mem[m_index]))
	
	func random() -> void:
		if forced_lock_dir(): return
		call_with_lock(randi() % actions.size())
#endregion##########################################################################################

class AIAction extends AIProcessor:
	static var DEADWEIGHT_ACTION: AIAction = AIAction.new().set_type(DEADWEIGHT).finalize()
	static var AI: ProcAI
	enum {DEADWEIGHT, APPROACH_AND_MELEE, ALIGN_AND_RANGE, ALIGN_AND_POUNCE}
	var type: int = DEADWEIGHT
	var m_index: int = -1
	var init_mem: Array[float] = []
	var attack: Attack
	
	func set_type(type_: int) -> AIAction:
		type = type_
		return self
	func finalize() -> AIAction:
		process = type_to_callable()
		attack = Attack.from_action(self)
		return self
	func type_to_callable() -> Callable:
		match self.type:
			DEADWEIGHT: return deadweight
			APPROACH_AND_MELEE: return approach_and_melee
			ALIGN_AND_RANGE: return align_and_range
			ALIGN_AND_POUNCE: return align_and_pounce
			_: return deadweight
	func min_memory_size() -> int:
		match type:
			APPROACH_AND_MELEE: return 1
			ALIGN_AND_RANGE: return 1
			ALIGN_AND_POUNCE: return 1
		return 0
	func calc_index() -> void:
		m_index = AI.init_mem.size()
		while init_mem.size() < min_memory_size(): init_mem.append(0.0)
		if init_mem.size() > 0: AI.init_mem.append_array(init_mem)
	
	func basic_path_towards(x_dir: float, y_target: float):
		AI.mas = true
		if AI.entity.iof && AI.entity.lock_timer > 0.0 && AI.entity.velocity.x == 0: AI.entity.jump(x_dir)
		if !AI.entity.iof && AI.entity.mem[m_index] == 1 && y_target <= AI.entity.global_position.y + 8 && AI.entity.velocity.y > 0: AI.entity.jump(x_dir)
		AI.entity.xccelerate(x_dir)
		AI.entity.apply_gravity(1.0)
		AI.entity.mem[m_index] = 1 if AI.entity.iof else 0
	
#region Action Type Methods
	func deadweight() -> void:
		AI.mas = true
		AI.entity.apply_friction()
		AI.entity.apply_gravity(1.0)
	
	func approach_and_melee() -> void:
		if AI.entity.is_attack_locked:
			AI.entity.apply_gravity(1.0)
			AI.entity.apply_friction()
		elif AI.target_distance > 20**2:
			basic_path_towards(sign(AI.target_vector.x), AI.entity.target.global_position.y)
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 180
		else:
			AI.entity.lock_timer = 40.0
			AI.entity.is_attack_locked = true
			attack.fire(AI, AI.target_vector)
	
	func align_and_range() -> void:
		if AI.entity.is_attack_locked:
			AI.entity.apply_gravity(1.0)
			AI.entity.apply_friction()
		elif AI.target_distance < 120**2 || AI.target_distance > 180**2:
			basic_path_towards(sign(AI.target_distance-140**2) * sign(AI.target_vector.x), AI.entity.target.global_position.y)
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 180
		else:
			AI.entity.lock_timer = 40.0
			AI.entity.is_attack_locked = true
			var fdir := AI.target_vector * 1.6 + Vector2(0.0, -(sqrt(AI.target_distance) * 1.2 - 80))
			attack.fire(AI, fdir.rotated(randf() * 0.2 - 0.1))
	
	func align_and_pounce() -> void:
		if AI.entity.is_attack_locked:
			AI.entity.apply_gravity(1.0)
			if AI.entity.iof: AI.entity.apply_friction()
		elif AI.target_distance < 130**2 || AI.target_distance > 140**2:
			basic_path_towards(sign(AI.target_distance-135**2) * sign(AI.target_vector.x), AI.entity.target.global_position.y)
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 180
		else:
			if AI.entity.iof:
				AI.entity.lock_timer = 120.0
				AI.entity.is_attack_locked = true
				AI.entity.velocity = ((AI.entity.target.get_feet_pos() - AI.entity.get_feet_pos()).normalized() -
					Vector2(0, 0.3)).normalized() * 0.03 * AI.entity.speed * sqrt(AI.target_distance)
				attack.fire(AI, AI.target_vector)
			else: basic_path_towards(sign(AI.target_distance-140**2) * sign(AI.target_vector.x), AI.entity.target.global_position.y)
#endregion

class Attack:
	var projectiles: Array[Projectile] = []
	
	static func from_action(action: AIAction) -> Attack:
		var attack: Attack = Attack.new()
		match action.type:
			AIAction.APPROACH_AND_MELEE, AIAction.ALIGN_AND_POUNCE:
				var proj := Projectile.new()
				proj.base_type = Projectile.bases.SWING
				proj.max_time = 20
				proj.pierce = -1
				proj.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://assets/textures/mobs/golem_fist.png")))
				proj.set_collisions(true, false, false)
				attack.projectiles.push_back(proj)
			AIAction.ALIGN_AND_RANGE:
				var proj := Projectile.new()
				proj.base_type = Projectile.bases.ARROW
				proj.max_time = 60
				proj.speed *= 2.4
				proj.friction = 0.1
				proj.air_friction = 0.0
				proj.texture = ItemData.lookup(ItemData.ids.ROCK).texture
				proj.set_collisions(true, false, true)
				attack.projectiles.push_back(proj)
				pass
		return attack
	
	func fire(ai: ProcAI, dir: Vector2) -> void: for proj in projectiles: proj.fire(ai.entity, dir).add_to_world()