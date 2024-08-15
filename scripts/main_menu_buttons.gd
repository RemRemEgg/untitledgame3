extends TextureButton

@export var function: String = "";
@export var fntn: Callable = _ready

func _ready() -> void:
	pressed.connect(_on_press)

func _on_press() -> void:
	get_tree().root.get_node("main_menu").call_deferred(function)
