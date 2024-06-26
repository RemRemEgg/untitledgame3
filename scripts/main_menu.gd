extends Control

@onready var loading: Control = $loading as Control
@onready var loading_text: TextureRect = $loading/loading_text as TextureRect
@onready var curtain: ColorRect = $loading/curtain as ColorRect

func _ready() -> void:
	Engine.max_fps = 60
	loading.visible = true
	call_deferred("load_game")

func finish_loading() -> void:
	for i in range(50):
		curtain.color.a -= 0.02
		await get_tree().create_timer(0.01).timeout
	remove_child(loading)
	loading.call_deferred("queue_free")

func load_game() -> void:
	ItemData.register_all()
	await get_tree().create_timer(0).timeout
	loading_text.visible = false
	Entity.TEMP_CONST_PROCAI = ProcAI.generate_new()
	finish_loading()

# TODO setup savefiles
func new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/worlds/overworld.tscn")

# TODO make settings
func settings() -> void: pass

func exit() -> void: get_tree().quit()
