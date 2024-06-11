extends CanvasLayer

var time: float = 0.0

func _ready() -> void: pass

func _process(delta: float) -> void:
	time += delta * 60.0
	if time > 30: visible = true
