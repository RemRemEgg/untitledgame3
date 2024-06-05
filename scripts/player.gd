class_name Player
extends Entity

@onready var sprite: Sprite2D = $sprite
@onready var camera: Camera2D = $camera
	
var dash := [0.0, Vector2.ZERO]
var dash_power: float = 3.2
var cyote: float = 0.0;
var jump_mem: float = 0.0

# TODO weaponry
var weapons: Array[PlayerItem] = [null, null]
var active_weapon: int = 0
var using_time: float = 0.0

func _ready() -> void:
	friction = 0.16
	speed = 240.0
	acceleration = 36
	gravity = Vector2(0.0, 15.0)
	jump_power = 260.0
	health = 10000000.0
	max_health = health
	friendly = true
	hostile = false
	collision_layer = Global.COLLISION.FRIENDLY_ENT
	collision_mask = Global.COLLISION.WORLD

func _process(delta: float) -> void:
	idelta = delta * 60.0
	iof = is_on_floor()
	jump_mem -= idelta
	cyote -= idelta
	if iof: cyote = 5
	dash[0] += idelta
	if using_time > 0.0:
		using_time -= idelta
		if using_time <= 0.0: done_using()
	
	var input_dir: float = Input.get_axis("left", "right")
	if input_dir:
		sprite.flip_h = input_dir < 0
		xccelerate(sign(input_dir))
	else: xccelerate(0)
	apply_gravity(1.0 + (0.3 if velocity.y > 0 else (!Input.is_action_pressed("jump") as float)))
	
	if jump_mem > 0.0:# && cyote > 0.0:
		cyote = -100.0
		jump_mem = -100.0
		jump(input_dir * 0.25)
	
	if dash[0] < -30: velocity = dash[1]
	move_and_slide()
	if dash[0] < -30: velocity = dash[1] / dash_power

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("jump"): jump_mem = 10
		if Input.is_action_just_pressed("dash") && dash[0] >= 0.0:
			var dir := Input.get_vector("left", "right", "up", "down")
			if !dir: dir = Vector2(-1.0 if sprite.flip_h else 1.0, 0.0);
			dash = [-33, dir * speed * dash_power]
	if event is InputEventMouseButton:
		match event.button_index:
			# TODO weaponry
			1 when event.pressed && weapons[0]: use_item(weapons[0])
			2 when event.pressed && weapons[1]: use_item(weapons[1])
			3 when event.pressed:
				Engine.max_fps = (120 if Engine.max_fps == 16 else 16)
			4 when event.pressed:
				for i in range(1):
					var dummy: Entity = (load("res://scenes/world/entity.tscn") as PackedScene).instantiate() as Entity
					dummy.global_transform.origin = get_global_mouse_position()
					dummy.friendly = false
					get_node("/root/world/entities").add_child(dummy)
			5:
				ItemData.register_all()
				weapons = [PlayerItem.from(ItemData.ids.SWORD), PlayerItem.from(ItemData.ids.ROCK)]
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
				projectile.max_time = data.stats[0]
			ItemData.THROW:
				projectile = Projectile.new()
				projectile.base_type = Projectile.bases.ARROW
				projectile.speed *= 3
				projectile.friction = 0.1
				projectile.air_friction = 0.0
				projectile.max_time = data.stats[0] * 3
				projectile.terrain_active = true
			ItemData.NONE, _:
				projectile = Projectile.new()
		projectile.texture = data.texture




