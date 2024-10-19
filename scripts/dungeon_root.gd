extends Node2D

var spawn_timer := 0.0
var spawn_rate := 8.0
var end_timer := 0.0

func _ready() -> void: if !Server.is_host: return

func _process(delta: float) -> void:
	if !Server.is_host: return
	spawn_timer += delta
	if spawn_timer > spawn_rate:
		spawn_timer -= spawn_rate
		spawn_rate = 2.5 + ((spawn_rate - 2.5) * .9999)
		ProcEnt.spawn_random_enemy()
	
	if end_timer == 0.0:
		var all_dead: bool = true
		for player in get_tree().get_nodes_in_group(&"players"): all_dead = all_dead && player.is_ghost
		if all_dead: end_timer = 1.0
	else:
		end_timer += delta
		if end_timer > 5: Global.WORLD.change_terrain(0, false)
