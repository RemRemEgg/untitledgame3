class_name Player
extends Entity

static var DEATH_SCREEN := preload("res://scenes/ui/death_screen.tscn")

@onready var camera: Camera = self.get_node_or_null("camera") as Camera
@onready var hud: HUD = self.get_node_or_null("camera/HUD") as HUD

@onready var tx_sync: MultiplayerSynchronizer = get_node("tx_sync") as MultiplayerSynchronizer
var peer_uuid: int = -1
var true_puppet_position: Vector2 = Vector2.ZERO
var is_main_player: bool = false
var is_ghost: bool = false
var base_mod: Color = Color.WHITE

var dash_time: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var dash_power: float = 3.2
var cyote: float = 0.0

var jump_mem: float = 0.0
var input_dir: float = 0.0

# TODO weaponry
var weapons: Array[Item] = [null, null, null, null]
var active_weapon: int = 0
var using_time: float = 0.0
var using_item: bool = false

func puppetify() -> void:
	var temp_cam := get_node("camera")
	remove_child(temp_cam)
	temp_cam.queue_free.call_deferred()

func make_main_player() -> void:
	get_node("camera").enabled = true
	Global.MAIN_PLAYER = self
	is_main_player = true

func _ready() -> void:
	friction = 0.14
	speed = 168
	acceleration = 25
	gravity = Vector2(0.0, 11.0)
	jump_power = 224
	health = 100.0
	max_health = health
	friendly = true
	hostile = false
	collision_layer = Global.COLLISION.FRIENDLY_ENT
	collision_mask = Global.COLLISION.WORLD
	if is_main_player:
		hud.player = self

func die() -> void:
	death_time = 1
	collision_layer = 0x0
	collision_mask = 0x0
	velocity /= 80.0
	var ds: Node = DEATH_SCREEN.instantiate()
	camera.add_child(ds)
	is_ghost = true
	to_ghost.rpc()

func death() -> void:
	var v: float = 0.5 / death_time
	base_mod = Color(v, v, v, v)
	velocity *= 0.96
	global_position += velocity
	death_time += idelta
	if death_time > 90:
		for pds in camera.get_children():
			if pds.get_meta("death_screen", false):
				camera.remove_child(pds)
				pds.queue_free()
		death_time = 0.0

@rpc("authority", "call_local", "reliable")
func to_ghost() -> void:
	base_mod = Color(5, 5, 5, .2)
	velocity = Vector2.ZERO
	is_ghost = true
	collision_layer = 0x0
	collision_mask = 0x0

@rpc("authority", "call_local", "reliable")
func respawn() -> void:
	death_time = 0.0
	is_ghost = false
	update_collision_layers()
	health = max_health
	velocity = Vector2.ZERO
	base_mod = Color.WHITE

func get_feet_pos() -> Vector2: return global_position - Vector2(0.0, col_shape.height / 2.0)

var stairs_timer := 0.0
var stairs_power := 0.0

func _process(delta: float) -> void:
	idelta = delta * 60.0
	sprite.self_modulate = base_mod
	if !is_main_player: return puppet_process()
	if death_time > 0.0: return death()
	if is_ghost: return ghost_process()
	main_process()

func main_process() -> void:
	hud.update()
	iof = is_on_floor()
	jump_mem -= idelta
	cyote -= idelta
	if iof: cyote = 5
	dash_time += idelta
	if using_time > 0.0:
		using_time -= idelta
		if using_time <= 0.0: done_using()
	
	input_dir = Input.get_axis("left", "right")
	if input_dir:
		sprite.flip_h = input_dir < 0
		xccelerate(Global.fsign(input_dir))
		var dss := get_world_2d().direct_space_state
		var sray_origin := get_global_transform().origin + Vector2(input_dir * 5, 9)
		var sray := PhysicsRayQueryParameters2D.create(sray_origin, sray_origin + Vector2(0, 8), Global.COLLISION.WORLD)
		var scol := dss.intersect_ray(sray)
		if scol:
			var hray_origin := get_global_transform().origin + Vector2(0, 10)
			var hray := PhysicsRayQueryParameters2D.create(hray_origin + Vector2(input_dir * 5.5, 0), hray_origin + Vector2(input_dir * 14, 0), Global.COLLISION.WORLD)
			var hcol := dss.intersect_ray(hray)
			if hcol:
				var hp := hcol.get("position") as Vector2
				var vray_origin := hp + Vector2(input_dir, -20)
				var vray := PhysicsRayQueryParameters2D.create(vray_origin, vray_origin + Vector2(0, 14), Global.COLLISION.WORLD)
				var vcol := dss.intersect_ray(vray)
				if vcol:
					var vp := vcol.get("position") as Vector2
					if hp.y - vp.y < 7:
						var ds := Vector2(hp.x, vp.y) - (hray_origin + Vector2(input_dir * 3, 0))
						if ds.length_squared() < 4:
							position = Vector2(hp.x, vp.y) - Vector2(input_dir * 6, 12)
						else:
							stairs_timer = 1
							stairs_power = ds.y
	else: xccelerate(0)
	apply_gravity(1.0 + (0.3 if velocity.y > 0 else (!Input.is_action_pressed("jump") as float)))
	
	if stairs_timer > 0.0:
		stairs_timer -= idelta
		velocity.y = stairs_power * 32
	
	if jump_mem > 0.0 && cyote > 0.0:
		cyote = -100.0
		jump_mem = -100.0
		jump(input_dir * 0.25)
	
	if dash_time < -30: velocity = dash_dir
	move_and_slide()
	true_puppet_position = position
	if dash_time < -30: velocity = dash_dir / dash_power
	
	if hurt_time > -1: hurt_time -= idelta
	if hurt_time > 0: sprite.self_modulate = Color.PALE_VIOLET_RED
	
	if using_item: use_item(weapons[active_weapon])

func puppet_process() -> void:
	var display_pos = position
	position = true_puppet_position
	apply_gravity(1.0)
	xccelerate(Global.fsign(input_dir))
	move_and_slide()
	true_puppet_position = position
	position = display_pos.lerp(true_puppet_position, 0.5)
	if hurt_time > 0: sprite.self_modulate = Color.PALE_VIOLET_RED

func ghost_process() -> void:
	hud.update()
	sprite.self_modulate = Color(5, 5, 5, .2)
	if using_time > 0.0: using_time -= idelta
	
	var vinput_dir := Input.get_vector("left", "right", "up", "down")
	if vinput_dir:
		sprite.flip_h = vinput_dir.x < 0
		acceleration /= 3
		xyccelerate(Global.fsign(vinput_dir.x), Global.fsign(vinput_dir.y))
		acceleration *= 3
	else: velocity *= 0.98
	#apply_gravity(1.0 + (0.3 if velocity.y > 0 else (!Input.is_action_pressed("jump") as float)))
	
	move_and_slide()
	true_puppet_position = position
	
	if hurt_time > -1: hurt_time -= idelta

func _input(event: InputEvent) -> void:
	if !is_main_player: return
	if event is InputEventKey:
		if Input.is_action_just_pressed("jump"): jump_mem = 10
		if Input.is_action_just_pressed("dash") && dash_time >= 0.0:
			var dir := Input.get_vector("left", "right", "up", "down")
			if !dir: dir = Vector2(-1.0 if sprite.flip_h else 1.0, 0.0);
			dash_time = -33
			dash_dir = dir * speed * dash_power
		if event.keycode == KEY_CTRL: Engine.time_scale = 0.25 if event.pressed else 1.0
		if event.keycode >= 49 && event.keycode <= 52: active_weapon = event.keycode - 49
	if event is InputEventMouseButton:
		var eiemb: InputEventMouseButton = event as InputEventMouseButton
		match eiemb.button_index:
			# TODO weaponry
			1: using_item = eiemb.pressed
			2 when eiemb.pressed: pass
			3 when eiemb.pressed: global_position = get_global_mouse_position()
			4 when eiemb.pressed: Engine.time_scale *= 2
			5 when eiemb.pressed: Engine.time_scale *= 0.5
			_: pass

func use_item(item: Item) -> void:
	if item == null: return
	if using_time <= 0.0 && item.proc_item.use_type != ProcItem.TYPE_NONE:
		using_time = item.proc_item.stats[0]
		# TODO weaponry
		for index in item.proc_item.proj_indices:
			Server.create_projectile.rpc_id(1, index, get_global_mouse_position() - global_position, item.proc_item.stats[ProcItem.STATS.DAMAGE])
		#if item.proj_index != -1:

# TODO weaponry
func done_using() -> void: pass

func _physics_process(_delta: float): pass

@rpc("authority", "reliable", "call_local")
func teleport(tp_pos: Vector2) -> void:
	position = tp_pos
	true_puppet_position = tp_pos
	velocity = Vector2.ZERO
	
@rpc("authority", "reliable", "call_local")
func warp(tp_pos: Vector2) -> void:
	camera.warp(tp_pos)
	position += tp_pos
	true_puppet_position += tp_pos



static func get_seralized_inventory() -> Array:
	var invin: Array = []
	read_inventory()
	for item in Global.SAVEFILE_PROCITEMS: invin.append(item.seralize(0x0))
	return invin

static func read_inventory() -> void:
	Global.SAVEFILE_PROCITEMS = [ProcItem.STATIC_ITEMS[1], ProcItem.STATIC_ITEMS[2]]
	Global.SAVEFILE_ITEMS = [0, 1]

static func deserialize_inventory(arr: Array) -> Array[ProcItem]:
	var items: Array[ProcItem] = []
	for sitem in arr: if sitem is Array[float]: items.append(ProcItem.deserialize(sitem as Array[float]))
	return items
