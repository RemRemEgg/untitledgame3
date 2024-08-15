extends Node

var peer: ENetMultiplayerPeer
var peer_uuid: int = 0
var multi_type: String = "Unknown"

func type_print(text: String) -> void: Console.print("[%s] %s" % [multi_type, text])
func type_print_err(text: String) -> void: Console.print_err("[%s] %s" % [multi_type, text])

func _ready() -> void:
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)

func start_server() -> void:
	multi_type = "Host"
	type_print("Booting")
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(15973)
	if error: return type_print_err("Failed to host server (%s)" % error)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	peer_uuid = 1
	type_print("Hosted")


func join_server(address: String) -> void:
	multi_type = "Client"
	type_print("Booting")
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, 15973)
	if error: return type_print_err("Failed to join server (%s)" % error)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	type_print("Hosted")

func add_player(peer_id: int, is_main_host: bool) -> void:
	var new_player: Player = Player.STATIC_SCENE.instantiate() as Player
	new_player.name = "player_%s" % peer_id
	new_player.peer_uuid = peer_id
	new_player.get_node("rx_sync").set_multiplayer_authority(1)
	Global.WORLD.PLAYERS.add_child(new_player)
	new_player.set_multiplayer_authority(peer_id, true)
	if is_main_host:
		new_player.camera.enabled = true
		Global.MAIN_PLAYER = new_player


func connected_to_server() -> void:
	peer_uuid = peer.get_unique_id()
	multi_type = "Client %s" % peer_uuid
	type_print("Connected to Server")
	to_overworld()
	var arr: Array[float] = [0.5, 0.5, 0.56, 0.5]
	join_game.rpc_id(1, peer.get_unique_id(), arr)
func connection_failed() -> void: type_print("Failed to Connect")
func server_disconnected() -> void: type_print("Server Disconnected")
func peer_connected(peer_id: int) -> void: type_print("Peer connected: %s" % peer_id)
func peer_disconnected(peer_id: int) -> void: type_print("Peer disconnected: %s" % peer_id)

static var OVERWORLD := preload("res://scenes/worlds/overworld.tscn")
func to_overworld() -> void:
	var overworld := OVERWORLD.instantiate()
	var old_world := Global.get_tree().root.get_child(-1)
	Global.get_tree().root.remove_child(old_world)
	Global.get_tree().root.add_child(overworld)

@rpc("any_peer", "reliable")
func join_game(peer_id: int, other_peers: Array[float]) -> void:
	add_player(peer_id, false)
	Console.print("other_peers: %s" % other_peers)
	Console.print("other_peers2: %s" % other_peers[2])
	Console.print("other_peers.size: %s" % other_peers.size())
	Console.print("basic array: %s" % [0.5, 0.5, 0.56, 0.5])
	Console.print("done")
