class_name ProcProj

var projectile: Projectile

var initalizer: Callable = kill
var base: Callable = kill
var base_type: int = 0
var max_time: float = 0.0
var kill_no_origin: bool = true

var pierce: int = 0
var terrain_active: bool = true
var damage_mod: float = 1.0

var static_index: int = 0
static var AIS: Array[ProcProj] = []

func finalize() -> void:
	initalizer = base_to_init_callable()
	base = base_to_callable()

func _to_string() -> String: return "ProcProj[%s]<%s, %s %s %s-%s %s>" % [static_index, base_type, max_time, pierce, kill_no_origin, terrain_active, damage_mod]

func fire(origin: Entity, direction: Vector2, damage: float) -> Projectile:
	Server.next_projectile = Global.PROJECTILE_SCENE.instantiate() as Projectile
	register_projectile(Server.next_projectile)
	Server.next_projectile.friendly = origin.friendly
	Server.next_projectile.hostile = origin.hostile
	Server.next_projectile.origin = origin
	Server.next_projectile.velocity = direction
	Server.next_projectile._ready()
	Server.next_projectile.damage *= damage
	initalizer.call(Server.next_projectile)
	var sp_data: Array[float] = Server.mp_projectile_data.to_array(Server.next_projectile)
	Global.WORLD.projectile_spawner.spawn(sp_data)
	return Server.next_projectile

func register_projectile(proj: Projectile) -> void:
	proj.proc_proj = self
	proj.pierce = pierce
	proj.terrain = terrain_active
	proj.damage *= damage_mod
	proj.sprite = proj.get_node("sprite")
	match base_type:
		bases.SWING: proj.sprite.texture = ProcItem.load_texture("res://assets/textures/item/sword.png") as Texture2D
		bases.ARROW: proj.sprite.texture = ProcItem.load_texture("res://assets/textures/item/rock.png") as Texture2D
		bases.BULLET: proj.sprite.texture = ProcItem.load_texture("res://assets/textures/mobs/golem_fist.png") as Texture2D

func process(proj: Projectile) -> void:
	proj.time += proj.idelta
	if proj.time >= max_time: return kill(proj)
	if kill_no_origin && !is_instance_valid(proj.origin): return kill(proj)
	base.call(proj)

func collide_with_body(proj: Projectile, body: Node2D, body_rid: RID) -> void:
	if !Server.is_host: return
	if proj.hitbox.collision_mask == 0: return
	var has_origin := is_instance_valid(proj.origin)
	if kill_no_origin && !has_origin: return kill(proj)
	if has_origin && proj.origin.get_rid() == body_rid: return
	if body is Entity: (body as Entity).take_damage(generate_damage_event(proj))
	pierce -= 1
	if pierce == -1: kill(proj)

func generate_damage_event(proj: Projectile) -> DamageEvent:
	var dmg: DamageEvent = DamageEvent.create(proj.damage)
	return dmg

func none()->void:pass
func kill(proj: Projectile) -> void:
	proj.queue_free()
	proj.hitbox.collision_mask = 0x0
	proj.hitbox.collision_layer = 0x0

class bases: enum {SWING, ARROW, BULLET}
func base_to_callable() -> Callable:
	match base_type:
		bases.SWING: return swing
		bases.ARROW: return arrow
		bases.BULLET: return bullet
	return none
func base_to_init_callable() -> Callable:
	match base_type:
		bases.SWING: return swing_initalizer
		bases.ARROW: return arrow_initalizer
		bases.BULLET: return bullet_initalizer
	return none

#region base functions

func swing_initalizer(proj: Projectile) -> void:
	proj.mem = [proj.velocity.angle(), 0.0]
	proj.sprite.flip_v = proj.mem[0] < -PI/2 || PI/2 < proj.mem[0]
	proj.mem[1] = -1.6 if proj.sprite.flip_v else 1.6
	proj.mem[0] -= proj.mem[1] / 2.0
	proj.idelta = 0.0
	swing(proj)
func swing(proj: Projectile) -> void:
	var angle: float = proj.time * proj.mem[1] / max_time + proj.mem[0]
	proj.transform = Transform2D(angle, proj.origin.global_position + Vector2.from_angle(angle) * 14)

func arrow_initalizer(proj: Projectile) -> void:
	proj.velocity = proj.velocity.normalized() * proj.speed
	proj.transform = proj.origin.global_transform
func arrow(proj: Projectile) -> void:
	proj.apply_gravity((proj.time/max_time + 0.5)**2)
	proj.move_and_slide()
	if proj.iof: proj.velocity = proj.velocity.move_toward(Vector2.ZERO, proj.idelta*32)

func bullet_initalizer(proj: Projectile) -> void:
	proj.velocity = proj.velocity.normalized() * proj.speed
	proj.transform = proj.origin.global_transform
func bullet(proj: Projectile) -> void:
	proj.move_and_slide()
	if proj.iof: proj.velocity = proj.velocity.move_toward(Vector2.ZERO, proj.idelta*32)

#endregion##########################################################################################
