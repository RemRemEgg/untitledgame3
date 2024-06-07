class_name Entity
extends CustomPhysicsObject

@onready var collider: CollisionShape2D = $collider
@onready var sprite: Sprite2D = $sprite

var proc_ai: ProcAI
var lock_timer: float = 0.0
var is_attack_locked: bool = false
var locks: Array[int] = []
var mem: Array[float] = []
var target: Entity

var health: float = 0.0 : set = health_mod
var max_health: float = 0.0

var jump_power: float = 256.0

var lhurt_pop: TextPopup

static var TEMP_CONST_PROCAI: ProcAI
static var RAND := true

func _ready() -> void:
	if RAND: TEMP_CONST_PROCAI = ProcAI.generate_new()
	TEMP_CONST_PROCAI.register_entity(self)
	update_collision_layers()

func _process(delta) -> void:
	idelta = delta * 60.0
	iof = is_on_floor()
	proc_ai.process(self)

# TODO update taking damage
func take_damage(attack: DamageEvent) -> void:
	health -= attack.damage
	if lhurt_pop && is_instance_valid(lhurt_pop) && lhurt_pop.anim.current_animation_position < 0.4 && lhurt_pop.global_position.distance_squared_to(global_position) < 32**2:
		attack.damage += int(lhurt_pop.text)
		lhurt_pop.queue_free()
	lhurt_pop = TextPopup.create(str(int(attack.damage))).add_to_world(self.get_tree().root, self.global_position + Vector2(0.0, -8))

func health_mod(amo: float) -> void:
	health = amo
	if health <= 0.0: die()

# TODO update dying
func die() -> void: queue_free()

func jump(x_boost: float) -> void: velocity = Vector2(velocity.x + x_boost * speed, -jump_power)

func get_feet_pos() -> Vector2: return global_position - Vector2(0, collider.shape.size.y / 2)

