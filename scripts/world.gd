class_name World
extends Node2D

@onready var background: Sprite2D = $background as Sprite2D

@onready var TERRAIN: Node2D = $terrain as Node2D
@onready var ENTITIES: Node2D = $entities as Node2D
@onready var PLAYERS: Node2D = $players as Node2D
@onready var PROJECTILES: Node2D = $projectiles as Node2D

func _ready() -> void: pass

func _enter_tree() -> void: Global.WORLD = self as Node2D

func _process(_delta: float) -> void: pass

func parallax() -> void: background.transform.origin = $players/player/camera.get_global_transform().origin * 0.4

func throw_player() -> void:
	var player: Player = get_node("players/player") as Player
	player.get_parent().remove_child(player)
	Global.PLAYER = player

func catch_player() -> Player:
	var player: Player = Global.PLAYER
	PLAYERS.add_child(player)
	Global.PLAYER = null
	return player

func to_overworld() -> void:
	throw_player()
	get_tree().change_scene_to_file("res://scenes/worlds/overworld.tscn")
