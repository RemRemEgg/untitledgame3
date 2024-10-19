extends Sprite2D

var origin: Vector2 = Vector2.ZERO
@export var parallax: float = 0.1

func _ready() -> void: origin = global_position

func _process(_delta: float) -> void:
	if Global.MAIN_PLAYER: global_position = origin + parallax * Global.MAIN_PLAYER.camera.global_position
