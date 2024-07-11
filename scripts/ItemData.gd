class_name ItemData
extends Resource

static var REGISTRY: Array[ItemData] = []
static var AIR_DATA: ItemData = create(ids.AIR, "", "Air", NONE, [0, 0])
static var NULL_TEXTURE: ImageTexture

static func lookup(reg_id_: int) -> ItemData:
	if reg_id_ >= REGISTRY.size(): return AIR_DATA
	var itda := REGISTRY[reg_id_]
	if itda: return itda
	return AIR_DATA

static func texture_lookup(reg_id_: int) -> ImageTexture:
	if reg_id_ >= REGISTRY.size(): return NULL_TEXTURE
	var itda := REGISTRY[reg_id_]
	if itda && itda.texture: return itda.texture
	return NULL_TEXTURE

var reg_id: int
var texture: ImageTexture
var name: String
var use_type: int
var stats: Array[float]

var projectiles: Array[ProjectileData] = []

class ProjectileData: var x: int

enum {
	NONE,    # [ usetime, scale
	SWING,   # + damage
	THROW,
	LAUNCH,
	CONSUME
}

enum {
	S_USE_TIME,
	S_SIZE,
	S_DAMAGE
}
#TODO: make [1] work
const DEF_NONE: Array[float]    = [20, 16, 10]
const DEF_SWING: Array[float]   = [20, 16, 10]
const DEF_THROW: Array[float]   = [20, 16, 10]
const DEF_LAUNCH: Array[float]  = [20, 16, 10]

class ids: enum {AIR, SWORD, ROCK, CHERRY}
static func register_all() -> void:
	var image: Image = Image.create_from_data(2, 2, false, Image.FORMAT_RGB8, [0,0,0,0xff,0,0xff,0xff,0,0xff,0,0,0])
	image.resize(16, 16, 0)
	NULL_TEXTURE = ImageTexture.create_from_image(image)
	
	register(AIR_DATA)
	var reges: Array[ItemData] = [
		create(ids.SWORD, "item/sword", "Sword", SWING, [15, 32, 15]),
		create(ids.ROCK, "item/rock", "Rock lmao", THROW, []),
		create(ids.CHERRY, "item/cherry", "cherry (yummy)", CONSUME, [])
	]
	for i in range(reges.size()):
		register(reges[i])

func _to_string() -> String: return "Item[id=%s,name=%s,type=%s]" % [reg_id, name, use_type]

static func register(item: ItemData) -> void:
	if REGISTRY.size() <= item.reg_id: REGISTRY.resize(item.reg_id + 1)
	if REGISTRY[item.reg_id] != null: Console.print_err("Duplicate registration for item '%s'" % item)
	REGISTRY[item.reg_id] = item

static func create(reg_id_: int, texture_path_: String, name_: String, use_type_: int, stats_: Array[float]) -> ItemData:
	var item: ItemData = ItemData.new()
	item.reg_id = reg_id_
	if texture_path_: item.texture = load_texture("res://assets/textures/%s.png" % texture_path_)
	item.name = name_
	item.use_type = use_type_
	
	var def_stats: Array[float]
	match use_type_:
		NONE: def_stats = DEF_NONE
		SWING: def_stats = DEF_SWING
		THROW: def_stats = DEF_THROW
		LAUNCH: def_stats = DEF_LAUNCH
	for i in range(def_stats.size()):
		if stats_.size() <= i:
			stats_.push_back(def_stats[i])
	item.stats = stats_
	return item

static func load_texture(path: String) -> ImageTexture:
	if !FileAccess.file_exists(path):
		Console.print_err("Failed to load texture '%s'" % path)
		return NULL_TEXTURE
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))
