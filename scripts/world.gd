extends Node2D

# TODO fix this stuff
@onready var camera: Camera2D = $player/camera as Camera2D
@onready var background: Sprite2D = $background as Sprite2D

func _ready() -> void: pass

func _enter_tree() -> void:
	if Global.PLAYER != null:
		Global.PLAYER.transform.origin = Vector2.ZERO
		add_child(Global.PLAYER)
		Global.PLAYER = null
	Global.WORLD_PROJECTILES = $projectiles as Node2D

func _process(_delta: float) -> void:
	background.transform.origin = camera.get_screen_center_position() * 0.4

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
