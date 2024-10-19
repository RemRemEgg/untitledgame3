extends Node2D

var fall_timer: float = 0.0
const VEL_MOD: float = 2 << 19
@onready var terrain_loop: Node2D = $terrain_loop as Node2D
var gen_thread: Thread
var gen_mutex: Mutex

func _ready() -> void:
	if !Server.is_host: return
	gen_mutex = Mutex.new()
	gen_thread = Thread.new()
	gen_thread.start.call_deferred(generate)

func _process(delta: float) -> void:
	var gmp: Player = Global.MAIN_PLAYER
	var vel: float = gmp.velocity.y
	vel *= (.1 * vel + VEL_MOD) / (vel + VEL_MOD)
	gmp.velocity.y = vel
	fall_timer += delta
	
	terrain_loop.global_position.y -= gmp.global_position.y
	if terrain_loop.global_position.y < -512:
		terrain_loop.global_position.y += int(terrain_loop.global_position.y / 16) * -16
	gmp.camera.ppos.y -= gmp.global_position.y
	gmp.global_position.y = 0
	
	if Server.is_host && fall_timer > 2:
		if gen_mutex.try_lock():
			gen_mutex.unlock()
			gen_thread.wait_to_finish()
			gen_thread = null
			Server.sync_entity_ais()
			Server.sync_projectile_ais()
			Global.WORLD.change_terrain(2, false)

func generate() -> void:
	gen_mutex.lock()
	
	for i in range(10): ProcEnt.generate_new().register()
	
	gen_mutex.unlock()
