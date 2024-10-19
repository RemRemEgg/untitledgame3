class_name World
extends Node2D

@onready var TERRAIN: Node2D = $terrain as Node2D
@onready var ENTITIES: Node2D = $entities as Node2D
@onready var PLAYERS: Node2D = $players as Node2D
@onready var PROJECTILES: Node2D = $projectiles as Node2D
@onready var POPUPS: Node2D = $popups as Node2D
@onready var player_spawner: MultiplayerSpawner = $spawners/player_spawner as MultiplayerSpawner
@onready var projectile_spawner: MultiplayerSpawner = $spawners/projectile_spawner as MultiplayerSpawner
@onready var entity_spawner: MultiplayerSpawner = $spawners/entities_spawner as MultiplayerSpawner
@onready var popups_spawner: MultiplayerSpawner = $spawners/popups_spawner as MultiplayerSpawner

var arr: Array = []
class test_ai:
	var type: float
	var texture: String
	var thing: Vector2
	
	static func rand() -> test_ai:
		var ai: test_ai = test_ai.new()
		ai.type = randf()
		ai.texture = "%x" % randi_range(10, 700)
		ai.thing = Vector2.ZERO.rotated(randf_range(0, PI * 20))
		return ai
	
	func _to_string() -> String:
		return "testai: %s, %s, (%s, %s)" % [type, texture, thing[0], thing[1]]

func _ready() -> void:
	player_spawner.set_spawn_function(Server.player_spawn_function)
	projectile_spawner.set_spawn_function(Server.projectile_spawn_function)
	entity_spawner.set_spawn_function(Server.entity_spawn_function)
	popups_spawner.set_spawn_function(Server.popup_spawn_function)

func _process(_delta: float) -> void: pass

static var TERRAIN_OVERWORLD: PackedScene = preload("res://scenes/world/terrain/overworld.tscn")
static var TERRAIN_DESCENT: PackedScene = preload("res://scenes/world/terrain/descent.tscn")
static var TERRAIN_DUNGEON: PackedScene = preload("res://scenes/world/terrain/dungeon.tscn")

func change_terrain(terrain_id: int, refresh: bool = false) -> void:
	if !Server.is_host: return
	match terrain_id:
		_: clear_terrain()
	change_terrain_local.rpc(terrain_id, refresh)

@rpc("authority", "call_local", "reliable")
func change_terrain_local(terrain_id: int, refresh: bool = false) -> void:
	Server.type_print("Terrain Change %s -> %s (%s)" % [Server.terrain_id, terrain_id, refresh])
	if !refresh && terrain_id == Server.terrain_id: return
	Server.terrain_id = terrain_id
	match terrain_id:
		-2:
			clear_terrain()
			var tree: SceneTree = get_tree()
			get_parent().remove_child(self)
			tree.change_scene_to_file("res://scenes/ui/main_menu.tscn")
		0:
			clear_terrain()
			TERRAIN = TERRAIN_OVERWORLD.instantiate() as Node2D
			add_child(TERRAIN)
			move_child(TERRAIN, 1)
			if Global.MAIN_PLAYER:
				Global.MAIN_PLAYER.respawn.rpc()
				Global.MAIN_PLAYER.teleport(Vector2.ZERO)
		1:
			clear_terrain()
			TERRAIN = TERRAIN_DESCENT.instantiate() as Node2D
			add_child(TERRAIN)
			move_child(TERRAIN, 1)
			Global.MAIN_PLAYER.warp(-Vector2(854, 1344))
		2:
			clear_terrain()
			TERRAIN = TERRAIN_DUNGEON.instantiate() as Node2D
			add_child(TERRAIN)
			move_child(TERRAIN, 1)
			Global.MAIN_PLAYER.warp(Vector2(0, -2400 - Global.MAIN_PLAYER.global_position.y))

func clear_terrain() -> void:
	if TERRAIN:
		remove_child(TERRAIN)
		TERRAIN.queue_free.call_deferred()
		TERRAIN = null
	remove_child(ENTITIES)
	ENTITIES.queue_free.call_deferred()
	remove_child(PROJECTILES)
	PROJECTILES.queue_free.call_deferred()
	remove_child(POPUPS)
	POPUPS.queue_free.call_deferred()
	
	ENTITIES = Node2D.new()
	ENTITIES.name = "entities"
	PROJECTILES = Node2D.new()
	PROJECTILES.name = "projectiles"
	POPUPS = Node2D.new()
	POPUPS.name = "popups"
	
	add_child(ENTITIES)
	move_child(PLAYERS, 3)
	add_child(PROJECTILES)
	add_child(POPUPS)
	
	entity_spawner.spawn_path = NodePath(^"../../entities")
	player_spawner.spawn_path = NodePath(^"../../players")
	projectile_spawner.spawn_path = NodePath(^"../../projectiles")
	popups_spawner.spawn_path = NodePath(^"../../popups")

func tp_all_players(tp_pos: Vector2) -> void:
	for player in PLAYERS.get_children():
		if player is Player:
			(player as Player).teleport.rpc(tp_pos)
