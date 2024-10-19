extends Node

var peer: ENetMultiplayerPeer
var peer_uuid: int = 0
var is_host: bool = false
var multi_type: String = "Unknown"
var terrain_id: int = -1

var sync_ent_ai_data: Array = []
var sync_proj_ai_data: Array = []

func type_print(text: String) -> void: Console.print("[%s] %s" % [multi_type, text])
func type_print_err(text: String) -> void: Console.print_err("[%s] %s" % [multi_type, text])

func _process(_delta: float) -> void: pass

func _ready() -> void: pass

func load_resources() -> void:
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	Console.load_status += 1

func start_server() -> void:
	multi_type = "Host"
	type_print("Starting Server")
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(15973)
	if error: return type_print_err("Failed to start server (%s)" % error)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	peer_uuid = 1
	is_host = true
	Global.load_world_root()
	Global.WORLD.change_terrain(0, true)
	multiplayer.set_multiplayer_peer(peer)
	type_print("Server Started")

func remove_player(rem_peer_id: int) -> void:
	var i: int = 0
	while i < Global.WORLD.PLAYERS.get_children().size():
		var test_player := Global.WORLD.PLAYERS.get_children()[i]
		if !test_player is Player || test_player.peer_uuid == 0 || test_player.peer_uuid == rem_peer_id:
			Global.WORLD.PLAYERS.remove_child(test_player)
			i -= 1

@rpc("any_peer", "reliable")
func request_join_game(inventory: Array) -> void:
	if !Server.is_host: return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id == 0: peer_id = 1
	Global.WORLD.player_spawner.spawn(peer_id)
	register_inventory(inventory, peer_id)
	if peer_id == 1: return
	Server.sync_entity_ais(peer_id)
	Server.sync_projectile_ais(peer_id)

func register_inventory(inventory: Array, peer_id: int) -> void:
	var procs: Array[ProcItem] = []
	for t_arr in inventory:
		var proc: ProcItem = ProcItem.deserialize(t_arr as Array[float])
		procs.append(proc)
	
	var sendback: Array = []
	for proc in procs:
		proc.register_projectiles()
		sendback.append(proc.seralize(0x1))
	
	load_inventory.rpc_id(peer_id, sendback)

func get_player_by_uuid(uuid: int) -> Player:
	var pplayers := Global.WORLD.PLAYERS.get_children()
	for tplayer in pplayers: if tplayer is Player:
		if tplayer.peer_uuid == uuid: return tplayer
	return null

func sync_entity_ais(id: int = -1) -> void:
	sync_ent_ai_data.clear()
	for ent_ai in ProcEnt.AIS:
		var data: Array[float] = []
		data.resize(3)
		data[0] = ent_ai.static_index
		data[1] = ent_ai.move_type
		data[2] = ent_ai.mod_color.to_rgba32()
		sync_ent_ai_data.append(data)
	if id == -1: mp_entity_ai_sync.rpc(sync_ent_ai_data)
	else: mp_entity_ai_sync.rpc_id(id, sync_ent_ai_data)

func sync_projectile_ais(id: int = -1) -> void:
	sync_proj_ai_data.clear()
	for proj_ai in ProcProj.AIS:
		var data: Array[float] = []
		data.resize(3)
		data[0] = proj_ai.static_index
		data[1] = proj_ai.base_type
		data[2] = proj_ai.max_time
		sync_proj_ai_data.append(data)
	if id == -1: mp_projectile_ai_sync.rpc(sync_proj_ai_data)
	else: mp_projectile_ai_sync.rpc_id(id, sync_proj_ai_data)

#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
##############################################################################################################################################################################################

static func player_spawn_function(data: Variant) -> Node:
	var cps_uuid: int = data as int
	var cps: Player = Global.PLAYER_SCENE.instantiate() as Player
	cps.peer_uuid = cps_uuid
	cps.get_node("tx_sync").set_multiplayer_authority(cps_uuid)
	cps.name = str(cps_uuid)
	if cps_uuid == Server.peer_uuid: cps.make_main_player()
	else: cps.puppetify()
	cps.set_multiplayer_authority(cps_uuid)
	return cps

@rpc("authority", "reliable")
func mp_entity_ai_sync(sync_arr: Array) -> void:
	ProcEnt.AIS.resize(sync_arr.size())
	for arr_u in sync_arr:
		var arr: Array[float] = (arr_u as Array[float])
		var sindex: int = int(arr[0])
		if ProcEnt.AIS.size() <= sindex: ProcEnt.AIS.resize(sindex + 1)
		if ProcEnt.AIS[sindex] == null:
			var new_ai := ProcEnt.new()
			new_ai.static_index = sindex
			new_ai.move_type = int(arr[1])
			new_ai.mod_color = Color.hex(int(arr[2])-1)
			ProcEnt.AIS[sindex] = new_ai

@rpc("authority", "reliable")
func mp_projectile_ai_sync(sync_arr: Array) -> void:
	ProcProj.AIS.resize(sync_arr.size())
	for arr_u in sync_arr:
		var arr: Array[float] = (arr_u as Array[float])
		var sindex: int = int(arr[0])
		if ProcProj.AIS.size() <= sindex: ProcProj.AIS.resize(sindex + 1)
		if ProcProj.AIS[sindex] == null:
			var new_ai := ProcProj.new()
			new_ai.static_index = sindex
			new_ai.base_type = int(arr[1])
			new_ai.max_time = arr[2]
			ProcProj.AIS[sindex] = new_ai

@rpc("authority", "reliable", "call_local")
func load_inventory(inventory: Array) -> void:
	var procs: Array[ProcItem] = []
	for t_arr in inventory:
		var proc: ProcItem = ProcItem.deserialize(t_arr as Array[float])
		procs.append(proc)
	
	Global.MAIN_PLAYER.weapons = []
	for i in range(Global.SAVEFILE_ITEMS.size()):
		Global.SAVEFILE_PROCITEMS[Global.SAVEFILE_ITEMS[i]].proj_indices = procs[Global.SAVEFILE_ITEMS[i]].proj_indices
		Global.MAIN_PLAYER.weapons.append(Global.SAVEFILE_PROCITEMS[Global.SAVEFILE_ITEMS[i]].create_item())

class mp_spawn_data:
	var index: int = 0
	var ent_id: int = 0
	
	static func to_array(data: Entity) -> Array[int]:
		var arr: Array[int] = []
		arr.resize(2)
		arr[0] = data.proc_ai.static_index
		arr[1] = data.name.to_int()
		return arr
	
	static func from_array(arr: Array[int]) -> mp_spawn_data:
		var data: mp_spawn_data = mp_spawn_data.new()
		data.index = arr[0]
		data.ent_id = arr[1]
		return data

static var next_enemy: Entity
static func entity_spawn_function(arr: Variant) -> Node:
	if Server.is_host: return next_enemy
	var data: mp_spawn_data = mp_spawn_data.from_array(arr as Array[int])
	if data == null: return null
	if ProcEnt.AIS.size() <= data.index || ProcEnt.AIS[data.index] == null: return null
	var ent: Entity = Global.ENTITY_SCENE.instantiate() as Entity
	ent.proc_ai = ProcEnt.AIS[data.index]
	ent.sprite = ent.get_node("sprite")
	ent.sprite.texture = ProcItem.load_texture("res://assets/textures/mobs/type_%s.png" % ProcEnt.move_names[ent.proc_ai.move_type]) as Texture2D
	return ent

class mp_projectile_data:
	var index: int
	
	static func to_array(data: Projectile) -> Array[float]:
		var arr: Array[float] = []
		arr.resize(1)
		arr[0] = data.proc_proj.static_index
		return arr
	
	static func from_array(arr: Array[float]) -> mp_projectile_data:
		var data: mp_projectile_data = mp_projectile_data.new()
		data.index = int(arr[0])
		return data

@rpc("any_peer", "reliable", "call_local")
func create_projectile(index: int, pos: Vector2, damage: float) -> void:
	var player := get_player_by_uuid(multiplayer.get_remote_sender_id())
	if player: ProcProj.AIS[index].fire(player, pos, damage)

static var next_projectile: Projectile
func projectile_spawn_function(arr: Variant) -> Node:
	if Server.is_host: return next_projectile
	var data: mp_projectile_data = mp_projectile_data.from_array(arr as Array[float])
	if data == null: return null
	if data.index < 0 || ProcProj.AIS.size() <= data.index: return null
	var proj: Projectile = Global.PROJECTILE_SCENE.instantiate() as Projectile
	proj.proc_proj = ProcProj.AIS[data.index]
	proj.sprite = proj.get_node("sprite")
	match proj.proc_proj.base_type:
		ProcProj.bases.SWING: proj.sprite.texture = ProcItem.load_texture("res://assets/textures/item/sword.png") as Texture2D
		ProcProj.bases.ARROW: proj.sprite.texture = ProcItem.load_texture("res://assets/textures/item/rock.png") as Texture2D
		ProcProj.bases.BULLET: proj.sprite.texture = ProcItem.load_texture("res://assets/textures/mobs/golem_fist.png") as Texture2D
	return proj

func popup_spawn_function(arr: Variant) -> Node:
	var data: Array = arr as Array
	var popup = TextPopup.create(data[0], Vector2(data[1], data[2]))
	return popup

func peer_connected(peer_id: int) -> void: type_print("Peer connected: %s" % peer_id)
func peer_disconnected(peer_id: int) -> void:
	type_print("Peer disconnected: %s" % peer_id)
	if is_host: get_player_by_uuid(peer_id).queue_free()

@rpc("authority", "reliable", "call_local")
func leave_game() -> void:
	if peer: peer.close()
	if is_host:
		is_host = false
		leave_game.rpc()
	peer = null
	multiplayer.set_multiplayer_peer(null)
	multi_type = "Unknown"
	type_print("Returning to Menu")
	peer_uuid = 0
	is_host = false
	sync_ent_ai_data.clear()
	sync_proj_ai_data.clear()
	Global.WORLD.change_terrain_local(-2, true)

##############################################################################################################################################################################################
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #

func join_server(address: String) -> void:
	multi_type = "Client"
	type_print("Booting")
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, 15973)
	if error: return type_print_err("Failed to boot client (%s)" % error)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	type_print("Attempting to join...")

func connection_failed() -> void: type_print("Failed to Connect")
func server_disconnected() -> void:
	type_print("Server Disconnected")
	leave_game()

func connected_to_server() -> void:
	type_print("Connected to Server")
	peer_uuid = peer.get_unique_id()
	is_host = false
	multi_type = "Client %s" % peer_uuid
	Global.load_world_root()
	Global.WORLD.change_terrain_local(0, true)
	type_print("Joining Game")
	request_join_game.rpc_id(1, Player.get_seralized_inventory())
