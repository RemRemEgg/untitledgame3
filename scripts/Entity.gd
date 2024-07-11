class_name Entity
extends CustomPhysicsObject

@onready var collider: CollisionShape2D = $collider as CollisionShape2D
@onready var col_shape: Shape2D = collider.shape as Shape2D
@onready var sprite: Sprite2D = $sprite as Sprite2D

var proc_ai: ProcAI
var lock_timer: float = 0.0
var is_attack_locked: bool = false
var was_attack_locked: bool = false
var locks: Array[int] = []
var mem: Array[float] = []
var target: Entity

var health: float = 30.0
var max_health: float = 30.0

var jump_power: float = 256.0

var lhurt_pop: TextPopup
var hurt_time: float = 0.0
var death_time: float = 0.0

static var TEMP_CONST_PROCAI: ProcAI
static var AIS: Array[ProcAI] = []
static var AI_STEP = -1
static var RAND := true

func _ready() -> void:
	if RAND:
		AI_STEP += 1
		if AIS.size() == 0 || AI_STEP % int(AIS.size()**1.6) == 0:
			var n := ProcAI.generate_new()
			AIS.append(n)
			n.register_entity(self)
		else: AIS[randi_range(0, AIS.size() - 1)].register_entity(self)
	else: TEMP_CONST_PROCAI.register_entity(self)
	update_collision_layers()

func _process(delta: float) -> void:
	idelta = delta * 60.0
	iof = is_on_floor()
	if death_time == 0:
		proc_ai.process(self)
		hurt_time -= idelta
		sprite.self_modulate = proc_ai.mod_color
		if hurt_time > 0: sprite.self_modulate = Color.PALE_VIOLET_RED
	else:
		var v: float = 0.5 / death_time
		sprite.self_modulate = Color(v, v, v, v)
		velocity *= 0.96
		global_position += velocity
		death_time += idelta
		if death_time > 30: queue_free()

# TODO update taking damage
func take_damage(attack: DamageEvent) -> void:
	health -= attack.damage
	hurt_time = 10.0
	if health <= 0.0: die()
	if lhurt_pop && is_instance_valid(lhurt_pop) && lhurt_pop.anim.current_animation_position < 0.4 && lhurt_pop.global_position.distance_squared_to(global_position) < 32**2:
		attack.damage += int(lhurt_pop.text)
		lhurt_pop.queue_free()
	lhurt_pop = TextPopup.create(str(int(attack.damage))).add_to_world(self.get_tree().root, self.global_position + Vector2(0.0, -8))

# TODO update dying
func die() -> void:
	#queue_free()
	death_time = 1
	collision_layer = 0x0
	collision_mask = 0x0
	velocity /= 80.0

func jump(x_boost: float) -> void: velocity = Vector2(velocity.x + x_boost * speed, -jump_power)

func get_feet_pos() -> Vector2: return global_position - Vector2(0.0, col_shape.size.y / 2.0)
