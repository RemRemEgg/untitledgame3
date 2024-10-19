extends Node2D

@onready var start_game_area: Area2D = $start_game_area as Area2D
@onready var drop_area: Area2D = $drop_area as Area2D
@onready var drop_block: StaticBody2D = $drop_block as StaticBody2D

func _process(_delta: float) -> void:
	if !Server.is_host: return
	var can_drop: bool = true
	var overlaps: Array[Node2D] = drop_area.get_overlapping_bodies()
	for player in get_tree().get_nodes_in_group(&"players"): can_drop = can_drop && overlaps.has(player)
	if can_drop: descend.rpc()

@rpc("authority", "reliable", "call_local")
func descend() -> void:
	if Server.is_host: drop_area.global_position.y -= 100
	drop_block.global_position.x += 100

func _start_game_hit(body: Node2D) -> void:
	if !Server.is_host: return
	start_game_area.global_position.x -= 200
	if body is Player: start_game.call_deferred()

func start_game() -> void:
	Global.WORLD.change_terrain(1, false)
	ProcEnt.AIS.clear()
	ProcEnt.AI_STEP = -1
