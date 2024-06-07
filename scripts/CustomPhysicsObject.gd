class_name CustomPhysicsObject
extends CharacterBody2D

var idelta: float = 0.0
var iof: bool = false
var friction: float = 0.14
var air_friction: float = 0.035
var speed: float = 128.0
var acceleration: float = 24
var gravity: Vector2 = Vector2(0.0, 15.0)

func apply_gravity(mult: float) -> void: velocity += gravity * idelta * mult
func xccelerate(direction: float) -> void: velocity = velocity.move_toward(Vector2(direction * speed, velocity.y), acceleration * idelta)
func yccelerate(direction: float) -> void: velocity = velocity.move_toward(Vector2(velocity.x, direction * speed), acceleration * idelta)
func xyccelerate(dx: float, dy: float) -> void: velocity = velocity.move_toward(Vector2(dx * speed, dy * speed), acceleration * idelta)
func xyvccelerate(dir: Vector2) -> void: velocity = velocity.move_toward(dir * speed, acceleration * idelta)
func __apply_friction() -> void: velocity = velocity.move_toward(Vector2(0.0, velocity.y), (friction if iof else air_friction) * speed * idelta)

var friendly: bool = true
var hostile: bool = true
var terrain: bool = true

func update_collision_layers() -> void:
	collision_layer = (Global.COLLISION.FRIENDLY_ENT if friendly else 0x0) | (Global.COLLISION.HOSTILE_ENT if hostile else 0x0)
	collision_mask = Global.COLLISION.WORLD if terrain else 0x0
