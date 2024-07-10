extends World

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	parallax()

func _start_game() -> void:
	throw_player()
	get_tree().change_scene_to_file("res://scenes/worlds/dungeon_root.tscn")

func _start_game_hit(body) -> void:
	if body is Player: call_deferred("_start_game")
