class_name Entity
extends CustomPhysicsObject

@onready var collider: CollisionShape2D = $collider as CollisionShape2D
@onready var col_shape: Shape2D = collider.shape as Shape2D
@onready var sprite: Sprite2D = $sprite as Sprite2D

var proc_ai: ProcEnt
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

func _ready() -> void:
	update_collision_layers()

func _process(delta: float) -> void:
	idelta = delta * 60.0
	sprite.self_modulate = proc_ai.mod_color
	if !Server.is_host: return
	iof = is_on_floor()
	if death_time == 0:
		proc_ai.process(self)
		hurt_time -= idelta
		if hurt_time > 0: sprite.self_modulate = Color.PALE_VIOLET_RED
	else:
		var v: float = 0.5 / death_time
		sprite.self_modulate = Color(v, v, v, v)
		velocity *= 0.96
		global_position += velocity
		death_time += idelta
		if death_time > 30: queue_free()

@rpc("any_peer", "reliable", "call_local")
func player_remote_damage(shurt: Array) -> void:
	if multiplayer.get_remote_sender_id() != 1: return
	if self.is_ghost: return
	var hurt: DamageEvent = DamageEvent.from_array(shurt as Array[float])
	process_damage(hurt)
	player_remote_popup.rpc_id(1, hurt.damage)
@rpc("any_peer", "reliable", "call_local")
func player_remote_popup(damage: float) -> void:
	if !Server.is_host: return
	popup_update(damage)

# TODO update taking damage
func take_damage(hurt: DamageEvent) -> void:
	if !Server.is_host: return
	if self is Player:
		if self.is_ghost: return
		self.player_remote_damage.rpc_id(self.peer_uuid, hurt.to_array())
		return
	process_damage(hurt)
	popup_update(hurt.damage)

func process_damage(hurt: DamageEvent) -> void:
	health -= hurt.damage
	hurt_time = 10.0
	if health <= 0.0: die()

func popup_update(damage: float) -> void:
	if lhurt_pop && is_instance_valid(lhurt_pop) && lhurt_pop.time < 30 && lhurt_pop.global_position.distance_squared_to(global_position) < 32**2:
		damage += int(lhurt_pop.text)
		lhurt_pop.queue_free()
	var apos: Vector2 = self.global_position + Vector2(0.0, -8)
	lhurt_pop = Global.WORLD.popups_spawner.spawn([str(int(damage)), apos.x, apos.y]) as TextPopup

# TODO update dying
func die() -> void:
	if !Server.is_host: return
	death_time = 1
	collision_layer = 0x0
	collision_mask = 0x0
	velocity /= 80.0

func jump(x_boost: float) -> void: velocity = Vector2(velocity.x + x_boost * speed, -jump_power)

func get_feet_pos() -> Vector2: return global_position - Vector2(0.0, col_shape.size.y / 2.0)
