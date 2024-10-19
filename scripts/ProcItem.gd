class_name ProcItem
extends RefCounted

static var PROC_ITEMS: Array[ProcItem] = []
static var STATIC_ITEMS: Array[ProcItem] = []
static var NULL_TEXTURE: ImageTexture

static func lookup(reg_id_: int) -> ProcItem:
	if reg_id_ >= PROC_ITEMS.size(): return STATIC_ITEMS[0]
	var itda := PROC_ITEMS[reg_id_]
	if itda: return itda
	return STATIC_ITEMS[0]

static func static_lookup(reg_id_: int) -> ProcItem:
	if reg_id_ >= STATIC_ITEMS.size(): return STATIC_ITEMS[0]
	var itda := STATIC_ITEMS[reg_id_]
	if itda: return itda
	return STATIC_ITEMS[0]

static func texture_lookup(_reg_id_: int) -> ImageTexture:
	#if reg_id_ >= REGISTRY.size(): return NULL_TEXTURE
	#var itda := REGISTRY[reg_id_]
	#if itda && itda.texture: return itda.texture
	return NULL_TEXTURE

func seralize(direction: int) -> Array[float]:
	var data: Array[float] = []
	if direction == 0x1:
		data.resize(3 + 1+proj_indices.size())
		data[0] = direction
		data[1] = reg_id
		data[2] = build_seed
		
		data[3] = proj_indices.size()
		for i in range(data[3]):
			data[i + 4] = proj_indices[i]
		
		return data
	else:
		data.resize(4 + 1+stats.size() + 1+projectiles.size()*5)
		data[0] = direction
		data[1] = reg_id
		data[2] = build_seed
		data[3] = use_type
		
		data[4] = stats.size()
		for i in range(data[4]):
			data[i + 5] = stats[i]
		
		var o: int = 4 + 1+stats.size()
		data[o] = projectiles.size()
		for i in range(projectiles.size()):
			projectiles[i].serialize(i * 5 + o + 1, data)
		
		return data

static func deserialize(data: Array[float]) -> ProcItem:
	var direction: int = int(data[0])
	var proc: ProcItem = ProcItem.new()
	if direction == 0x1:
		proc.reg_id = int(data[1])
		proc.build_seed = int(data[2])
		
		proc.proj_indices = []
		proc.proj_indices.resize(int(data[3]))
		for i in range(proc.proj_indices.size()):
			proc.proj_indices[i] = int(data[i + 4])
		
		return proc
	else:
		proc.reg_id = int(data[1])
		proc.build_seed = int(data[2])
		proc.use_type = int(data[3])
		
		proc.stats = []
		proc.stats.resize(int(data[4]))
		for i in range(proc.stats.size()):
			proc.stats[i] = data[i + 5]
		
		var o: int = 4 + 1+proc.stats.size()
		proc.projectiles = []
		proc.projectiles.resize(int(data[o]))
		for i in range(proc.projectiles.size()):
			proc.projectiles[i] = projectile_data.deserialize(i * 5 + o + 1, data)
		
		return proc

var reg_id: int = -1
var build_seed: int = -1
var use_type: int = TYPE_NONE
var stats: Array[float]
var projectiles: Array[projectile_data]
var proj_indices: Array[int] = [-1]
var name: String = &"Item"

func register() -> void:
	reg_id = PROC_ITEMS.size()
	PROC_ITEMS.resize(reg_id + 1)
	PROC_ITEMS[reg_id] = self
	register_projectiles()

func register_projectiles() -> void:
	if !(proj_indices.size() == 1 && proj_indices[0] == -1): return
	proj_indices = []
	for atk in projectiles:
		var proc_proj: ProcProj = ProcProj.new()
		proc_proj.base_type = atk.base_type
		proc_proj.max_time = atk.max_time
		proc_proj.kill_no_origin = atk.kill_no_origin
		proc_proj.pierce = atk.pierce
		proc_proj.terrain_active = atk.terrain_active
		proc_proj.damage_mod = atk.damage_mod
		proc_proj.finalize()
		proc_proj.static_index = ProcProj.AIS.size()
		ProcProj.AIS.append(proc_proj)
		proj_indices.append(proc_proj.static_index)

class projectile_data:
	var base_type: int
	var max_time: float
	var kill_no_origin: bool
	var pierce: int
	var terrain_active: bool
	var damage_mod: float
	
	static func static_create(base_type_: int, max_time_: float, kno_: bool, pierce_: int, terrain_active_: bool, damage_mod_: float) -> projectile_data:
		var data: projectile_data = projectile_data.new()
		data.base_type = base_type_
		data.max_time = max_time_
		data.kill_no_origin = kno_
		data.pierce = pierce_
		data.terrain_active = terrain_active_
		data.damage_mod = damage_mod_
		return data
	
	func serialize(i: int, arr: Array[float]) -> void:
		arr[i + 0] = base_type
		arr[i + 1] = max_time
		arr[i + 2] = int(kill_no_origin) + (int(terrain_active) << 1)
		arr[i + 3] = pierce
		arr[i + 4] = damage_mod
	
	static func deserialize(i: int, arr: Array[float]) -> projectile_data:
		var data: projectile_data = projectile_data.new()
		data.base_type = int(arr[i])
		data.max_time = arr[i + 1]
		var flags: int = int(arr[i + 2])
		data.kill_no_origin = bool((flags >> 0) & 0x1)
		data.terrain_active = bool((flags >> 1) & 0x1)
		data.pierce = int(arr[i + 3])
		data.damage_mod = arr[i + 4]
		return data
	
	func _to_string() -> String: return "ProjData[%s, %s, %s, %s, %s, %s]" % [base_type, max_time, kill_no_origin, pierce, terrain_active, damage_mod]

func create_item() -> Item:
	var item: Item = Item.new()
	item.proc_item = self
	return item

enum { TYPE_NONE, TYPE_SWING, TYPE_THROW, TYPE_LAUNCH, TYPE_CONSUME }
class STATS: enum { USE_TIME, SIZE, DAMAGE }
#TODO: make [1] work
const DEF_NONE: Array[float]    = [20, 16, 10]
const DEF_SWING: Array[float]   = [20, 16, 10]
const DEF_THROW: Array[float]   = [20, 16, 10]
const DEF_LAUNCH: Array[float]  = [20, 16, 10]

static func register_all() -> void:
	var image: Image = Image.create_from_data(2, 2, false, Image.FORMAT_RGB8, [0,0,0,0xff,0,0xff,0xff,0,0xff,0,0,0])
	image.resize(16, 16, Image.INTERPOLATE_NEAREST)
	NULL_TEXTURE = ImageTexture.create_from_image(image)
	if NULL_TEXTURE != null: Console.print("NULL_TEXTURE created")
	else: Console.print_err("Failed to load NULL_TEXTURE, game may be unstable")
	static_create("Air", TYPE_NONE, [0, 0], [])
	static_create("Sword", TYPE_SWING, [20, 32, 15], [projectile_data.static_create(ProcProj.bases.SWING, 18, true, -1, false, 1.0), projectile_data.static_create(ProcProj.bases.BULLET, 60, false, 0, true, 0.2)])
	static_create("Rock lmao", TYPE_THROW, [], [projectile_data.static_create(ProcProj.bases.ARROW, 60, false, 0, true, 1.0)])
	static_create("cherry (yummy)", TYPE_CONSUME, [], [])
	Console.load_status += 1

func _to_string() -> String: return "Item[id=%s,bs=%s,type=%s,p=%s,pi=%s]" % [reg_id, build_seed, use_type, projectiles.size(), proj_indices.size()]

static func static_create(name_: String, use_type_: int, stats_: Array[float], projectiles_: Array[projectile_data]) -> void:
	var item: ProcItem = ProcItem.new()
	item.name = name_
	item.use_type = use_type_
	
	var def_stats: Array[float]
	match use_type_:
		TYPE_NONE: def_stats = DEF_NONE
		TYPE_SWING: def_stats = DEF_SWING
		TYPE_THROW: def_stats = DEF_THROW
		TYPE_LAUNCH: def_stats = DEF_LAUNCH
	for i in range(def_stats.size()):
		if stats_.size() <= i:
			stats_.push_back(def_stats[i])
	item.stats = stats_
	item.projectiles = projectiles_
	item.reg_id = STATIC_ITEMS.size()
	item.build_seed = -item.reg_id
	STATIC_ITEMS.resize(item.reg_id + 1)
	STATIC_ITEMS[item.reg_id] = item
	
	Console.print("Item SL: '%s' (%s)" % [name_, item.reg_id])

static var textures: Dictionary = {}
static func load_texture(path: String) -> ImageTexture:
	if textures.has(path):
		return textures.get(path)
	if !FileAccess.file_exists(path):
		Console.print_err("Failed to load texture '%s'" % path)
		return NULL_TEXTURE
	var ltexture := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))
	Console.print("Loading from disk: \"%s\"" % path)
	textures[path] = ltexture
	return ltexture
