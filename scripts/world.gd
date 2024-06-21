class_name World
extends Node2D

@onready var background: Sprite2D = $background as Sprite2D

@onready var TERRAIN: Node2D = $terrain as Node2D
@onready var ENTITIES: Node2D = $entities as Node2D
@onready var PROJECTILES: Node2D = $projectiles as Node2D

func _ready() -> void: pass

func _enter_tree() -> void: Global.WORLD = self as Node2D

func _process(_delta: float) -> void: pass
	#background.transform.origin = camera.get_screen_center_position() * 0.4

func _start_game() -> void:
	var player: Player = get_node("player") as Player
	player.get_parent().remove_child(player)
	player.remove_child(player.get_node("loading_text"))
	Global.PLAYER = player
	get_tree().change_scene_to_file("res://scenes/dungeon/root.tscn")

func _start_game_hit(body) -> void:
	if body is Player:
		($player/loading_text as TextureRect).visible = true
		call_deferred("_start_game")
