class_name Projectile_old
extends CharacterBody2D

const HALF_PI: float = PI/2.0
const SNAP_ANGLE: float = PI / 8.0

@onready var sprite: Sprite2D = $sprite
@onready var collider: CollisionShape2D = $collider
@onready var hitbox: Area2D = $hitbox
@onready var hitbox_collider: CollisionShape2D = $hitbox/collider

var origin_ent: Entity
var readied: bool = false
var ai_mode: int = 0
var idelta: float = 0.0
var is_dead: bool = false

var hurt_hostile: bool = false
var hurt_friendly: bool = false
var lifetime: float = 0.0
var time: float = 0.0
var kill_no_origin: bool = true
var stats: Array[float] = []
var damage: float = 10.0


static func create(mode: int) -> Projectile:
	var proj = Global.PROJECTILE_SCENE.instantiate()
	proj.set_script(load("res://scripts/Projectile_old.gd"))
	proj._ready()
	proj.ai_mode = mode
	return proj

static func friendly(mode: int) -> Projectile:
	var proj: Projectile = create(mode)
	proj.hurt_hostile = true
	proj.hurt_friendly = false
	proj.update_collision_layers()
	return proj

static func hostile(mode: int) -> Projectile:
	var proj: Projectile = create(mode)
	proj.hurt_hostile = false
	proj.hurt_friendly = true
	proj.update_collision_layers()
	return proj

func _ready() -> void:
	if !readied:
		readied = true
		hitbox_collider.shape = collider.shape
		hitbox.body_shape_entered.connect(hit_body)

func origin(origin_: Entity) -> Projectile_old:
	origin_ent = origin_
	transform.origin = origin_.transform.origin
	return self

func ai(mode: int) -> Projectile_old:
	self.ai_mode = mode
	return self

func hurt(hhostile: bool, hfriendly: bool) -> Projectile_old:
	hurt_hostile = hhostile
	hurt_friendly = hfriendly
	update_collision_layers()
	return self

func life(time_: float) -> Projectile_old:
	lifetime = time_
	return self
	
func kill_on_no_origin(kno: bool) -> Projectile_old:
	kill_no_origin = kno
	return self
	
func set_stats(stats_: Array[float]) -> Projectile_old:
	stats = stats_
	return self

func from_item(item: Item) -> Projectile_old:
	sprite.texture = item.texture
	lifetime = item.stats[0]
	match item.use_type:
		ProcItem.TYPE_SWING:
			ai_mode = -1
			var mouse: Vector2 = DisplayServer.mouse_get_position() - DisplayServer.screen_get_size() / 2
			stats = [mouse.angle(), 0.0]
			sprite.flip_v = stats[0] < -HALF_PI || HALF_PI < stats[0]
			stats[1] = -1.6 if sprite.flip_v else 1.6
			stats[0] -= stats[1] / 2.0
		ProcItem.TYPE_CONSUME:
			ai_mode = -2
			lifetime = 60 * 1.5
			velocity = DisplayServer.mouse_get_position() - DisplayServer.screen_get_size() / 2
			velocity *= 3
			kill_no_origin = false
		_: ai_mode = 0
	return self

func add_to_world() -> Projectile_old:
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
	Global.WORLD_PROJECTILES.add_child(self)
	return self

func _process(delta) -> void:
	delta *= 60
	time += delta
	if time >= lifetime: return kill()
	if kill_no_origin && !is_instance_valid(origin_ent): return kill()
	idelta = delta
	match ai_mode:
		-2: default_physics()
		-1: rotate_around(origin_ent.transform.origin, time * stats[1] / lifetime + stats[0], 14)
		0: kill()

func _physics_process(_delta) -> void: pass

func kill() -> void:
	if is_dead: return
	is_dead = true
	var parent: Node = get_parent()
	if parent: parent.remove_child(self)
	queue_free()

func rotate_around(point: Vector2, angle: float, distance: float) -> void:
	transform = Transform2D(angle, point + Vector2.from_angle(angle) * distance)

func hit_body(body_rid: RID, body: Node2D, _bsi: int, _lsi: int) -> void:
	var has_origin := is_instance_valid(origin_ent)
	if kill_no_origin && !has_origin: return kill()
	if has_origin && origin_ent.get_rid() == body_rid: return
	if body is Entity:
		if (body.friendly && hurt_friendly) || (body.hostile && hurt_hostile):
			if has_origin: body.take_damage_from_entity(origin_ent, generate_damage_event())
			if !has_origin: body.take_damage_from_dead_entity(generate_damage_event())

func default_physics() -> void:
	velocity += Vector2(0.0, 15.0) * idelta
	velocity = velocity.lerp(Vector2(0.0, velocity.y), 0.15 * (1.0 if is_on_floor() else 0.0))
	move_and_slide()

# TODO better projectile damage system
func generate_damage_event() -> DamageEvent:
	var dmg: DamageEvent = DamageEvent.create(damage)
	return dmg

func update_collision_layers() -> void:
	collision_layer = (Global.COLLISION.FRIENDLY_ENT if hurt_friendly else 0) | (Global.COLLISION.HOSTILE_ENT if hurt_hostile else 0)
	collision_mask = Global.COLLISION.WORLD
	hitbox.collision_mask = collision_layer
	hitbox.collision_layer = 0
