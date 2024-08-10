extends Control

@onready var main_menu: Control = $margin/main as Control
@onready var multiplayer_menu: Control = $margin/multiplayer as Control
@onready var singleplayer_menu: Control = $margin/singleplayer as Control

func _ready() -> void: pass

func move() -> void:
	main_menu.visible = false
	main_menu.set_process(false)

# TODO setup savefiles
func new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/worlds/overworld.tscn")

func to_singleplayer() -> void:
	move()
	singleplayer_menu.visible = true
	singleplayer_menu.set_process(true)

func to_multiplayer() -> void:
	move()
	multiplayer_menu.visible = true
	multiplayer_menu.set_process(true)

func back() -> void:
	main_menu.visible = true
	main_menu.set_process(true)
	
	multiplayer_menu.visible = false
	multiplayer_menu.set_process(false)
	singleplayer_menu.visible = false
	singleplayer_menu.set_process(false)

# TODO make settings
func settings() -> void: pass

func exit() -> void: get_tree().quit()
