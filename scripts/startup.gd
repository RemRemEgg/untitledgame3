extends Control

func _ready() -> void:
	Engine.max_fps = 60
	load_game.call_deferred()

func load_game() -> void:
	await get_tree().create_timer(0.5).timeout
	ItemData.register_all()
	Entity.TEMP_CONST_PROCAI = ProcAI.generate_new()
	#finish_loading()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

#func finish_loading() -> void:
	#for i in range(50):
		##curtain.color.a -= 0.02
		#await get_tree().create_timer(0.01).timeout
