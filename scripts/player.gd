class_name Player
extends Entity

static var DEATH_SCREEN := preload("res://scenes/ui/death_screen.tscn")

@onready var camera: Camera2D = $camera as Camera2D
@onready var hud: HUD = $camera/HUD as HUD

var dash_time: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var dash_power: float = 3.2
var cyote: float = 0.0;
var jump_mem: float = 0.0

# TODO weaponry
var weapons: Array[PlayerItem] = [PlayerItem.from(ItemData.ids.SWORD), PlayerItem.from(ItemData.ids.ROCK)]
var active_weapon: int = 0
var using_time: float = 0.0
var using_item: bool = false

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

func die() -> void:
	death_time = 1
	collision_layer = 0x0
	collision_mask = 0x0
	velocity /= 80.0
	var ds: Node = DEATH_SCREEN.instantiate()
	camera.add_child(ds)

func death() -> void:
	var v: float = 0.5 / death_time
	sprite.self_modulate = Color(v, v, v, v)
	velocity *= 0.96
	global_position += velocity
	death_time += idelta
	if death_time > 90:
		for pds in camera.get_children():
			if pds.get_meta("death_screen", false):
				camera.remove_child(pds)
				pds.queue_free()
		respawn()

func respawn() -> void:
	death_time = 0.0
	update_collision_layers()
	health = max_health
	velocity = Vector2.ZERO
	sprite.self_modulate = Color.WHITE
	global_position = Vector2.ZERO
	Global.WORLD.to_overworld()

func get_feet_pos() -> Vector2: return global_position - Vector2(0.0, col_shape.height / 2.0)

var stairs_timer := 0.0
var stairs_power := 0.0

func _process(delta: float) -> void:
	hud.update(self)
	if death_time > 0.0: return death()
	idelta = delta * 60.0
	iof = is_on_floor()
	jump_mem -= idelta
	cyote -= idelta
	if iof: cyote = 5
	dash_time += idelta
	if using_time > 0.0:
		using_time -= idelta
		if using_time <= 0.0: done_using()
	
	var input_dir: float = Input.get_axis("left", "right")
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
	if dash_time < -30: velocity = dash_dir / dash_power
	
	hurt_time -= idelta
	sprite.self_modulate = Color.WHITE
	if hurt_time > 0: sprite.self_modulate = Color.PALE_VIOLET_RED
	
	if using_item: use_item(weapons[0])

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("jump"): jump_mem = 10
		if Input.is_action_just_pressed("dash") && dash_time >= 0.0:
			var dir := Input.get_vector("left", "right", "up", "down")
			if !dir: dir = Vector2(-1.0 if sprite.flip_h else 1.0, 0.0);
			dash_time = -33
			dash_dir = dir * speed * dash_power
		if event.keycode == KEY_CTRL: Engine.time_scale = 0.25 if event.pressed else 1.0
	if event is InputEventMouseButton:
		var eiemb: InputEventMouseButton = event as InputEventMouseButton
		match eiemb.button_index:
			# TODO weaponry
			1: using_item = eiemb.pressed
			2 when eiemb.pressed && weapons[1]: use_item(weapons[1])
			3 when eiemb.pressed: pass
			4 when eiemb.pressed:
				Engine.time_scale *= 2
			5 when eiemb.pressed:
				Engine.time_scale *= 0.5
			_: pass

func use_item(item: PlayerItem) -> void:
	if using_time <= 0.0 && item.data.use_type != ItemData.NONE:
		using_time = item.data.stats[0]
		# TODO weaponry
		item.get_projectile().fire(self, get_global_mouse_position() - global_position).add_to_world()

# TODO weaponry
func done_using() -> void: pass

func _physics_process(_delta: float): pass

class PlayerItem:
	var data: ItemData
	var projectile: Projectile
	
	static func from(lookup: int) -> PlayerItem:
		var plit: PlayerItem = PlayerItem.new()
		plit.data = ItemData.lookup(lookup)
		return plit
	
	func get_projectile() -> Projectile:
		if !projectile: create_projectile()
		return projectile
	
	func create_projectile() -> void:
		if !data: data = ItemData.AIR_DATA
		match data.use_type:
			ItemData.SWING:
				projectile = Projectile.new()
				projectile.base_type = Projectile.bases.SWING
				projectile.pierce = -1
				projectile.max_time = data.stats[ItemData.S_USE_TIME]
			ItemData.THROW:
				projectile = Projectile.new()
				projectile.base_type = Projectile.bases.ARROW
				projectile.speed *= 3
				projectile.friction = 0.1
				projectile.air_friction = 0.0
				projectile.max_time = data.stats[ItemData.S_USE_TIME] * 3
				projectile.terrain_active = true
			ItemData.NONE, _:
				projectile = Projectile.new()
		projectile.texture = ItemData.texture_lookup(data.reg_id)
		projectile.damage = data.stats[ItemData.S_DAMAGE]




