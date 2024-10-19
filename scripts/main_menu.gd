extends Control

@onready var main_menu: Control = $margin/main as Control
@onready var multiplayer_menu: Control = $margin/multiplayer as Control
@onready var singleplayer_menu: Control = $margin/singleplayer as Control

@onready var ip_input: LineEdit = $margin/multiplayer/vbox/ip_input as LineEdit

func _ready() -> void:
	Console.load_status = -1
	if Console.active:
		Console.toggle()
		#dbg_auto_join()

func dbg_auto_join() -> void:
	Server.peer = ENetMultiplayerPeer.new()
	var error: Error = Server.peer.create_server(15973)
	Server.peer.close()
	Server.peer = null
	if error:
		get_window().position.x += 480
		await get_tree().create_timer(0.2).timeout
		join_game()
	else:
		get_window().position.x -= 480
		new_game()

func _process(_delta: float) -> void: return

func move() -> void:
	main_menu.visible = false
	main_menu.set_process(false)

# TODO setup savefiles
func new_game() -> void:
	Server.start_server()
	Server.request_join_game(Player.get_seralized_inventory())
	queue_free()

# TODO add address validation & error handling
func join_game() -> void:
	Server.join_server(ip_input.text if !ip_input.text.is_empty() else "127.0.0.1")

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
