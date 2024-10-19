class_name Projectile
extends CustomPhysicsObject

static var SCENE: PackedScene = preload("res://scenes/world/projectile.tscn")

@onready var collider: CollisionShape2D = $collider as CollisionShape2D
@onready var sprite: Sprite2D = $sprite as Sprite2D
@onready var hitbox: Area2D = $hitbox as Area2D
@onready var hitbox_collider: CollisionShape2D = $hitbox/collider as CollisionShape2D

var proc_proj: ProcProj
var origin: Entity
var mem: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var time: float = 0.0
var pierce: int = 0   ###

var readied: bool = false
var damage: float = 1.0   ###

func _to_string() -> String:
	var sb := "Proj<%s> Mt: %s, p: %s, KNO: %s, col: %s%s%s" % [proc_proj.base.get_method(), proc_proj.max_time, pierce, proc_proj.kill_no_origin,\
	friendly as int, hostile as int, terrain as int]
	return sb

func _ready() -> void:
	if !readied:
		readied = true
		hitbox_collider.shape = collider.shape
		hitbox.body_shape_entered.connect(collide_with_body)
	collision_layer = (Global.COLLISION.FRIENDLY_ENT if friendly else 0x0) | (Global.COLLISION.HOSTILE_ENT if hostile else 0x0)
	collision_mask = Global.COLLISION.WORLD if terrain else 0x0
	hitbox.collision_layer = (Global.COLLISION.FRIENDLY_ENT if friendly else 0x0) | (Global.COLLISION.HOSTILE_ENT if hostile else 0x0)
	hitbox.collision_mask = (Global.COLLISION.FRIENDLY_ENT if hostile else 0x0) | (Global.COLLISION.HOSTILE_ENT if friendly else 0x0)

func _process(delta: float) -> void:
	idelta = delta * 60
	if !Server.is_host: return
	proc_proj.process(self)
	if terrain: iof = is_on_floor()

func _physics_process(_delta: float) -> void: pass

func collide_with_body(body_rid: RID, body: Node2D, _bsi: int, _lsi: int) -> void:
	proc_proj.collide_with_body(self, body, body_rid)
