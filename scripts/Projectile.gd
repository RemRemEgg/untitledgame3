class_name Projectile
extends CustomPhysicsObject

static var SCENE: PackedScene = preload("res://scenes/world/projectile.tscn")
func none() -> void: pass

@onready var collider: CollisionShape2D = $collider
@onready var sprite: Sprite2D = $sprite
@onready var hitbox: Area2D = $hitbox
@onready var hitbox_collider: CollisionShape2D = $hitbox/collider

var initalizer: Callable = kill
var base: Callable = kill
var base_type: int = 0   ###
var origin: Entity
var mem: Array[float] = []
var texture: ImageTexture   ###

var time: float = 0.0
var max_time: float = 0.0   ###
var pierce: int = 0   ###
var kill_no_origin: bool = true   ###
var terrain_active: bool = false   ###
var readied: bool = false

func fire(origin_: Entity, direction: Vector2) -> Projectile:
	var cproj := SCENE.instantiate()
	cproj.set_script(Projectile)
	var proj: Projectile = cproj as Projectile
	proj.origin = origin_
	proj.velocity = direction
	proj._ready()
	proj.solidify_from(self)
	proj.initalizer.call()
	return proj
	
func add_to_world() -> void:
	var parent: Node = get_parent()
	if parent: parent.remove_child(self)
	sprite.texture = texture
	Global.WORLD_PROJECTILES.add_child(self)

func solidify_from(other: Projectile) -> void:
	base_type = other.base_type
	base = base_to_callable()
	initalizer = base_to_init_callable()
	mem = other.mem.duplicate()
	texture = other.texture
	
	time = other.time
	max_time = other.max_time
	pierce = other.pierce
	kill_no_origin = other.kill_no_origin
	friction = other.friction
	air_friction = other.air_friction
	speed = other.speed
	acceleration = other.acceleration
	gravity = other.gravity
	
	friendly = other.friendly
	hostile = other.hostile
	terrain_active = other.terrain_active
	collision_layer = (Global.COLLISION.FRIENDLY_PROJ if friendly else 0x0) | (Global.COLLISION.HOSTILE_PROJ if hostile else 0x0)
	collision_mask = Global.COLLISION.WORLD if terrain_active else 0x0
	hitbox.collision_layer = 0x0
	hitbox.collision_mask = (Global.COLLISION.FRIENDLY_ENT if friendly else 0x0) | (Global.COLLISION.HOSTILE_ENT if hostile else 0x0)

func set_collisions(hurt_friendly: bool, hurt_hostile: bool, terrain: bool) -> void:
	friendly = hurt_friendly
	hostile = hurt_hostile
	terrain_active = terrain

func _ready() -> void:
	if !readied:
		readied = true
		hitbox_collider.shape = collider.shape
		hitbox.body_shape_entered.connect(collide_with_body)

func _process(delta) -> void:
	delta *= 60
	time += delta
	if time >= max_time: return kill()
	if kill_no_origin && !is_instance_valid(origin): return kill()
	idelta = delta
	if terrain_active: iof = is_on_floor()
	base.call()

func _physics_process(_delta) -> void: pass

func collide_with_body(body_rid: RID, body: Node2D, _bsi: int, _lsi: int) -> void:
	var has_origin := is_instance_valid(origin)
	if kill_no_origin && !has_origin: return kill()
	if has_origin && origin.get_rid() == body_rid: return
	if body is Entity:
		if has_origin: body.take_damage_from_entity(origin, generate_damage_event())
		if !has_origin: body.take_damage_from_dead_entity(generate_damage_event())
	pierce -= 1
	if pierce == -1: kill()

func generate_damage_event() -> DamageEvent:
	var dmg: DamageEvent = DamageEvent.create(10)
	return dmg

func kill() -> void: queue_free()

class bases: enum {SWING, ARROW}
func base_to_callable() -> Callable:
	match base_type:
		bases.SWING: return swing
		bases.ARROW: return arrow
	return none
func base_to_init_callable() -> Callable:
	match base_type:
		bases.SWING: return swing_initalizer
		bases.ARROW: return arrow_initalizer
	return none

#region base functions

func swing_initalizer() -> void:
	mem = [velocity.angle(), 0.0]
	sprite.flip_v = mem[0] < -PI/2 || PI/2 < mem[0]
	mem[1] = -1.6 if sprite.flip_v else 1.6
	mem[0] -= mem[1] / 2.0
	idelta = 0.0
	swing()
func swing() -> void:
	var angle: float = time * mem[1] / max_time + mem[0]
	transform = Transform2D(angle, origin.global_position + Vector2.from_angle(angle) * 14)

func arrow_initalizer() -> void:
	velocity = velocity.normalized() * speed
	transform = origin.global_transform
func arrow() -> void:
	apply_gravity((time/max_time + 0.5)**2)
	apply_friction()
	move_and_slide()

#endregion##########################################################################################
