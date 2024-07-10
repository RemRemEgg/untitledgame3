extends World

func _ready() -> void:
	var player := catch_player()
	player.velocity = Vector2.ZERO
	player.position = Vector2.ZERO

func _process(delta: float) -> void:
	parallax()
