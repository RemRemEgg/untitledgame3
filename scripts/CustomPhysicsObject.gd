class_name CustomPhysicsObject
extends CharacterBody2D

var idelta: float = 0.0
var iof: bool = false
var friction: float = 0.14
var air_friction: float = 0.25
var speed: float = 128.0
var acceleration: float = 24
var gravity: Vector2 = Vector2(0.0, 15.0)

func apply_gravity(mult: float) -> void: velocity += gravity * idelta * mult
func xccelerate(direction: float) -> void: velocity = velocity.move_toward(Vector2(direction * speed * idelta, velocity.y), acceleration)
func apply_friction() -> void: velocity = velocity.move_toward(Vector2(0.0, velocity.y), friction * (1.0 if iof else air_friction) * speed * (1 + idelta))

var friendly: bool = true
var hostile: bool = true

func update_collision_layers() -> void:
	collision_layer = (Global.COLLISION.FRIENDLY_ENT if friendly else 0) | (Global.COLLISION.HOSTILE_ENT if hostile else 0)
	collision_mask = Global.COLLISION.WORLD
