class_name ProcAI

var entity: Entity
var mas: bool = false
var l_size: int = 0
var init_mem: Array[float] = []

var target_distance: float = 0.0
var target_vector: Vector2 = Vector2(0, 0)
var target_foot_vector: Vector2 = Vector2(0, 0)

class MOVE_TYPE: enum {LAND, AIR, GROUND, ALL, STATIC}
const move_names: Array[String] = ["land", "air", "ground", "all", "static"]
var move_type: int = 0
var mod_color: Color = Color.WHITE

func process(entity_: Entity) -> void:
	entity = entity_
	entity.lock_timer -= entity.idelta
	if entity.lock_timer <= 0.0:
		if entity.lock_timer + entity.idelta > 0.0: entity.was_attack_locked = entity.is_attack_locked
		entity.is_attack_locked = false
	update_target()
	
	target_vector = entity.target.global_position - entity.global_position
	target_foot_vector = entity.target.get_feet_pos() - entity.get_feet_pos()
	target_distance = target_vector.length_squared()
	
	root.root_call(self)
	if mas: entity.move_and_slide()

func update_target() -> void: entity.target = entity.get_tree().root.get_node("world/players/player") as Entity

static func generate_new() -> ProcAI:
	var ai: ProcAI = ProcAI.new()
	ai.move_type = Global.TEMP.FORCE_AI_TYPE if Global.TEMP.FORCE_AI_TYPE != -1 else randi_range(MOVE_TYPE.LAND, MOVE_TYPE.ALL)
	
	var rootfw := AIFramework.generate_new()
	
	AIFramework.AI = ai
	AIAction.AI = ai
	rootfw.finalize()
	
	ai.root = rootfw
	
	ai.mod_color = Color.from_hsv(randf(), 0.5 + (randf() * 0.3), 1, 1)
	
	return ai

func register_entity(ent: Entity):
	ent.proc_ai = self
	ent.locks.clear()
	ent.mem.clear()
	ent.locks.resize(l_size)
	ent.locks.fill(0)
	ent.mem.resize(0)
	ent.mem.append_array(init_mem)
	
	ent.sprite.texture = ItemData.load_texture("res://assets/textures/mobs/type_%s.png" % move_names[move_type]) as Texture2D
	
	ent.collision_layer = Global.COLLISION.HOSTILE_ENT
	match move_type:
		MOVE_TYPE.GROUND, MOVE_TYPE.ALL: ent.terrain = false

func _to_string() -> String:
	var sb := "[color=#aea]ProcAI<%s> iM: %s[/color]" % [move_names[move_type], init_mem]
	sb += "\n  " + root.to_string().replace("\n", "\n  ")
	return sb

var root: AIFramework

class AIProcessor:
	var process: Callable
	func finalize() -> AIProcessor: return self

class AIFramework extends AIProcessor:
	static var AI: ProcAI
##framework add############################################################
	enum {DEADWEIGHT, DISTANCE_2, DISTANCE_3, CYCLE, RANDOM, ENTITY_HEALTH, TARGET_HEALTH, WAS_ATTACK_LOCKED}
	var type: int
	var actions: Array[AIProcessor] = []
	var l_index: int = -1
	var m_index: int = -1
	
	func _init() -> void: pass
	func finalize() -> AIProcessor:
		process = type_to_callable()
		for i in range(min_array_sizes().x): if actions.size() <= i: actions.push_back(AIAction.generate_new().finalize())
		for action in actions: action.finalize()
		calc_index()
		calc_action_indexes()
##framework add############################################################
		match type:
			DISTANCE_2: AI.init_mem[m_index] = 100
			DISTANCE_3:
				AI.init_mem[m_index] = 100
				AI.init_mem[m_index+1] = 250
			ENTITY_HEALTH: AI.init_mem[m_index] = 0.5
			TARGET_HEALTH: AI.init_mem[m_index] = 0.5
		return self
##framework add############################################################
	func type_to_callable() -> Callable:
		match self.type:
			DEADWEIGHT: return deadweight
			DISTANCE_2: return distance_2
			DISTANCE_3: return distance_3
			CYCLE: return cycle
			RANDOM: return random
			ENTITY_HEALTH: return entity_health
			TARGET_HEALTH: return target_health
			WAS_ATTACK_LOCKED: return was_attack_locked
			_: return deadweight
##framework add############################################################
	func min_array_sizes() -> Vector2i: # (actions, mem)
		match self.type:
			DISTANCE_2: return Vector2i(2, 1)
			DISTANCE_3: return Vector2i(3, 2)
			CYCLE: return Vector2i(1, 1)
			RANDOM: return Vector2i(1, 0)
			ENTITY_HEALTH: return Vector2i(2, 1)
			TARGET_HEALTH: return Vector2i(2, 1)
			WAS_ATTACK_LOCKED: return Vector2i(2, 0)
			_: return Vector2i(0, 0)
	func root_call(ai: ProcAI) -> void:
		AIFramework.AI = ai
		AIAction.AI = ai
		process.call()
	func call_with_lock(dir: int) -> void:
		AI.entity.locks[l_index] = dir
		actions[dir].process.call()
	func forced_lock_dir() -> bool:
		var ret := AI.entity.lock_timer > 0.0
		if ret: actions[AI.entity.locks[l_index]].process.call()
		return ret
	func calc_index() -> void:
		var x = AI.l_size
		l_index = AI.l_size
		AI.l_size += 1
		var mas := min_array_sizes()
		if mas.y > 0:
			m_index = AI.init_mem.size()
			for i in mas.y: AI.init_mem.append(0.0)
	func calc_action_indexes() -> void:
		for i in actions.size(): 
			if actions[i] is AIAction: (actions[i] as AIAction).calc_index()
##framework add############################################################
	static func generate_new() -> AIFramework:
		var fw := AIFramework.new()
		fw.type = randi_range(DISTANCE_2, WAS_ATTACK_LOCKED)
		
		for i in randi_range(0, 3):
			if randf() <= 0.4:
				var naif := AIFramework.generate_new()
				fw.actions.append(naif)
			else:
				var naia := AIAction.generate_new()
				fw.actions.append(naia)
		
		return fw
	
#regionFrameworkTypeMethods###################################################################################################################################################################
##############################################################################################################################################################################################
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #

	func deadweight() -> void: AIAction.DEADWEIGHT_ACTION.process.call()
	
	func distance_2() -> void:
		if forced_lock_dir(): return
		if AI.target_distance <= AI.entity.mem[m_index]**2: call_with_lock(0)
		else: call_with_lock(1)
	
	func distance_3() -> void:
		if forced_lock_dir(): return
		if AI.target_distance <= AI.entity.mem[m_index]**2: call_with_lock(0)
		elif AI.target_distance <= AI.entity.mem[m_index+1]**2: call_with_lock(1)
		else: call_with_lock(2)
	
	func cycle() -> void:
		if forced_lock_dir(): return
		AI.entity.mem[m_index] = int(AI.entity.mem[m_index] + 1) % actions.size()
		call_with_lock(int(AI.entity.mem[m_index]))
	
	func random() -> void:
		if forced_lock_dir(): return
		call_with_lock(randi() % actions.size())
	
	func entity_health() -> void:
		if forced_lock_dir(): return
		if AI.entity.health / AI.entity.max_health >= AI.entity.mem[m_index]: call_with_lock(0)
		else: call_with_lock(1)
	
	func target_health() -> void:
		if forced_lock_dir(): return
		if !AI.entity.target || AI.entity.target.health / AI.entity.target.max_health >= AI.entity.mem[m_index]: call_with_lock(0)
		else: call_with_lock(1)
	
	func was_attack_locked() -> void:
		if forced_lock_dir(): return
		call_with_lock(int(!AI.entity.was_attack_locked))

#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
##############################################################################################################################################################################################
#endregion####################################################################################################################################################################################

	func _to_string() -> String:
		var sb := "[color=aqua]AIF<%s> Li: %s, Mi: %s[/color]" % [process.get_method(), l_index, m_index]
		for action in actions: sb += "\n" + action.to_string()
		return sb.trim_suffix("\n").replace("\n", "\n| ")

class AIAction extends AIProcessor:
	static var DEADWEIGHT_ACTION: AIAction = AIAction.new().set_type(DEADWEIGHT).finalize()
	static var AI: ProcAI
##action add###############################################################
	enum {DEADWEIGHT, APPROACH_AND_MELEE, ALIGN_AND_RANGE, ALIGN_AND_POUNCE, ALIGN_AND_CHARGE, LURE_AND_MELEE}
	var type: int = DEADWEIGHT
	var m_index: int = -1
	var init_mem: Array[float] = []
	var attack: Attack
	var mover: Callable = movement_branch
	
	func set_type(type_: int) -> AIAction:
		type = type_
		return self
	func finalize() -> AIAction:
		process = type_to_callable()
		attack = Attack.from_action(self)
		return self
##action add###############################################################
	func type_to_callable() -> Callable:
		match self.type:
			DEADWEIGHT: return deadweight
			APPROACH_AND_MELEE: return approach_and_melee
			ALIGN_AND_RANGE: return align_and_range
			ALIGN_AND_POUNCE: return align_and_pounce
			ALIGN_AND_CHARGE: return align_and_charge
			LURE_AND_MELEE: return lure_and_melee
			_: return deadweight
##action add###############################################################
	func min_memory_size() -> int:
		match type:
			APPROACH_AND_MELEE: return 1
			ALIGN_AND_RANGE: return 1
			ALIGN_AND_POUNCE: return 1
			ALIGN_AND_CHARGE: return 3
			LURE_AND_MELEE: return 1
		return 0
	func calc_index() -> void:
		m_index = AI.init_mem.size()
		while init_mem.size() < min_memory_size(): init_mem.append(0.0)
		if init_mem.size() > 0: AI.init_mem.append_array(init_mem)
	
##action add###############################################################
	static func generate_new() -> AIAction:
		var ac := AIAction.new()
		ac.type = randi_range(APPROACH_AND_MELEE, LURE_AND_MELEE)
		return ac

#regionMoverTypes#############################################################################################################################################################################
	func movement_branch(x_dir: float, y_dir: int) -> void:
		match AI.move_type:
			MOVE_TYPE.LAND: mover = land_mover
			MOVE_TYPE.AIR: mover = air_mover
			MOVE_TYPE.GROUND: mover = ground_mover
			MOVE_TYPE.ALL: mover = all_mover
			MOVE_TYPE.STATIC: mover = static_mover
			_: return
		mover.call(x_dir, y_dir)
	
	func land_mover(x_dir: float, y_dir: float) -> void:
		AI.mas = true
		if AI.entity.iof && AI.entity.lock_timer > 0.0 && AI.entity.velocity.x == 0 && x_dir: AI.entity.jump(x_dir)
		if !AI.entity.iof && AI.entity.mem[m_index] == 1 && y_dir < 0 && AI.entity.velocity.y > 0: AI.entity.jump(x_dir)
		AI.entity.xccelerate(x_dir)
		AI.entity.apply_gravity(1.0)
		AI.entity.mem[m_index] = 1 if AI.entity.iof else 0
	
	func air_mover(x_dir: float, y_dir: float) -> void:
		AI.mas = true
		AI.entity.xyccelerate(x_dir, y_dir)
		var t := randf_range(-1.05, 1.05)
		AI.entity.mem[m_index] += t ** 30
		if x_dir == 0 && y_dir == 0: AI.entity.xyvccelerate(Vector2.RIGHT.rotated(AI.entity.mem[m_index]))
	
	func ground_mover(x_dir: float, y_dir: float) -> void:
		AI.mas = true
		var pp := PhysicsPointQueryParameters2D.new()
		pp.collision_mask = Global.COLLISION.WORLD
		pp.position = AI.entity.global_position
		if AI.entity.get_world_2d().direct_space_state.intersect_point(pp, 1):
			var d := Vector2(x_dir, y_dir) * 5 + AI.entity.velocity
			AI.entity.xyvccelerate(d.normalized() * 1.4)
		else: AI.entity.apply_gravity(0.2)
	
	func all_mover(x_dir: float, y_dir: float) -> void:
		AI.mas = true
		AI.entity.xyccelerate(x_dir, y_dir)
		var t := randf_range(-1.05, 1.05)
		AI.entity.mem[m_index] += t ** 30
		if x_dir == 0 && y_dir == 0: AI.entity.xyvccelerate(Vector2.RIGHT.rotated(AI.entity.mem[m_index]))
	
	func static_mover(x_dir: float, y_dir: float) -> void: pass
#endregion####################################################################################################################################################################################
	
#regionActionTypeMethods######################################################################################################################################################################
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
##############################################################################################################################################################################################
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #

	func deadweight() -> void:
		AI.mas = true
		mover.call(0, 0)
	
	func approach_and_melee() -> void:
		if AI.entity.is_attack_locked: mover.call(0, 0)
		elif AI.target_distance > 20**2:
			mover.call(sign(AI.target_vector.x), sign(AI.target_foot_vector.y))
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 180
		else:
			AI.entity.is_attack_locked = true
			AI.entity.lock_timer = 40.0
			mover.call(0, 0)
			attack.fire(AI, AI.target_vector)
	
	func align_and_range() -> void:
		if AI.entity.is_attack_locked: mover.call(0, 0)
		elif AI.target_distance < 120**2 || AI.target_distance > 180**2:
			mover.call(Global.fsign(AI.target_distance-140**2) * Global.fsign(AI.target_vector.x), Global.fsign(AI.target_foot_vector.y))
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 180
		else:
			AI.entity.is_attack_locked = true
			AI.entity.lock_timer = 40.0
			mover.call(0, 0)
			var fdir := AI.target_vector * 1.6 + Vector2(0.0, -(sqrt(AI.target_distance) * 1.2 - 80))
			attack.fire(AI, fdir.rotated(randf() * 0.2 - 0.1))
	
	func align_and_pounce() -> void:
		if AI.entity.is_attack_locked: mover.call(0, 0)
		elif (AI.target_distance < 130**2 || AI.target_distance > 140**2):
			mover.call(Global.fsign(AI.target_distance-135**2) * Global.fsign(AI.target_vector.x), Global.fsign(AI.target_foot_vector.y))
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 180
		else:
			AI.entity.is_attack_locked = true
			AI.entity.lock_timer = 120.0
			mover.call(0, 0)
			AI.entity.velocity = ((AI.entity.target.get_feet_pos() - AI.entity.get_feet_pos()).normalized() -
				Vector2(0, 0.3)).normalized() * 0.03 * AI.entity.speed * sqrt(AI.target_distance)
			attack.fire(AI, AI.target_vector)
			
	func align_and_charge() -> void:
		if AI.entity.is_attack_locked:
			AI.entity.mem[m_index + 1] += Global.fsign(AI.entity.mem[m_index + 1])
			mover.call(AI.entity.mem[m_index + 1] * 0.3, 0)
			AI.entity.mem[m_index + 2] -= AI.entity.idelta
			if AI.entity.mem[m_index + 2] < 0:
				AI.entity.mem[m_index + 2] += 16
				attack.fire(AI, Vector2(AI.entity.mem[m_index + 1], 0))
		elif (AI.target_distance < 130**2 || AI.target_distance > 140**2):
			mover.call(Global.fsign(AI.target_distance-135**2) * Global.fsign(AI.target_vector.x), Global.fsign(AI.target_foot_vector.y))
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 180
		else:
			AI.entity.is_attack_locked = true
			AI.entity.lock_timer = 40.0
			AI.entity.mem[m_index + 1] = Global.fsign(AI.target_vector.x)
			AI.entity.mem[m_index + 2] = 16
			attack.fire(AI, Vector2(AI.entity.mem[m_index + 1], 0))
			mover.call(AI.entity.mem[m_index + 1] * 2, 0)
	
	func lure_and_melee() -> void:
		if AI.entity.is_attack_locked: mover.call(0, 0)
		elif (AI.target_distance > 32**2 && AI.target_distance < 300**2):
			mover.call(sign(AI.target_vector.x) * -0.2, sign(AI.target_foot_vector.y) * 0.1)
			if AI.entity.lock_timer <= 0.0: AI.entity.lock_timer = 360
		elif AI.target_distance > 32**2: mover.call(0, 0)
		else:
			AI.entity.is_attack_locked = true
			AI.entity.lock_timer = 45.0
			mover.call(0, 0)
			AI.entity.velocity = (AI.target_foot_vector.normalized() -
				Vector2(0, 0.15)).normalized() * 0.075 * AI.entity.speed * sqrt(AI.target_distance)
			attack.fire(AI, AI.target_vector)

#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
##############################################################################################################################################################################################
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#endregion####################################################################################################################################################################################

	func _to_string() -> String:
		var sb := "[color=#f90]AIA<%s> Mi: %s[/color]" % [process.get_method(), m_index]
		if attack == null: return sb
		for proj in attack.projectiles: sb += "\n\t[color=#b4f]" + proj.to_string() + "[/color]"
		return sb

class Attack:
	var projectiles: Array[Projectile] = []
	
	static func from_action(action: AIAction) -> Attack:
		var attack: Attack = Attack.new()
		match action.type:
			AIAction.APPROACH_AND_MELEE, AIAction.ALIGN_AND_POUNCE, AIAction.ALIGN_AND_CHARGE, AIAction.LURE_AND_MELEE:
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
				proj.texture = ItemData.texture_lookup(ItemData.ids.ROCK)
				print("AAR : %s : %s" % [proj.texture, ItemData.lookup(ItemData.ids.ROCK).texture])
				proj.set_collisions(true, false, true)
				attack.projectiles.push_back(proj)
		return attack
	
	func fire(ai: ProcAI, dir: Vector2) -> void: for proj in projectiles: proj.fire(ai.entity, dir).add_to_world()
