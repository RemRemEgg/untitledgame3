extends World

func _process(_delta: float) -> void:
	parallax()

func _start_game() -> void:
	throw_player()
	get_tree().change_scene_to_file("res://scenes/worlds/dungeon_root.tscn")

func _start_game_hit(body) -> void:
	if body is Player: _start_game.call_deferred()
