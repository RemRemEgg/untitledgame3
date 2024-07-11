class_name dungeon_root
extends World

var spawn_timer := 0.0
var spawn_rate := 8

func _ready() -> void:
	var player := catch_player()
	player.velocity = Vector2.ZERO
	player.position = Vector2.ZERO
	Entity.AIS = []
	Entity.AI_STEP = -1

func _process(delta: float) -> void:
	parallax()
	
	spawn_timer += delta
	if spawn_timer > spawn_rate:
		spawn_timer -= spawn_rate
		spawn_rate = 2.5 + ((spawn_rate - 2.5) * .9999)
		spawn_random_enemy()

func spawn_random_enemy() -> void:
	var dummy: Entity = (load("res://scenes/world/entity.tscn") as PackedScene).instantiate() as Entity
	dummy.global_transform.origin = Vector2(randi_range(-800, 800), -320)
	dummy.friendly = false
	Global.WORLD.ENTITIES.add_child(dummy)
