extends Node

static var MAIN_PLAYER: Player

static var WORLD: World

static var SAVEFILE_PROCITEMS: Array[ProcItem]
static var SAVEFILE_ITEMS: Array[int]

static var PLAYER_SCENE: PackedScene
static var TEXT_SCENE: PackedScene
static var PROJECTILE_SCENE: PackedScene
static var ENTITY_SCENE: PackedScene
static var WORLD_SCENE: PackedScene
static var UI_THEME: Theme

static var PROJECTILE_TEX: Array[MHTexture]

func load_resources() -> void:
	SAVEFILE_PROCITEMS = []
	SAVEFILE_ITEMS = []
	
	PLAYER_SCENE = load("res://scenes/player/player.tscn") as PackedScene
	TEXT_SCENE = load("res://scenes/ui/text_popup.tscn") as PackedScene
	PROJECTILE_SCENE = load("res://scenes/world/projectile.tscn") as PackedScene
	ENTITY_SCENE = load("res://scenes/world/entity.tscn") as PackedScene
	WORLD_SCENE = load("res://scenes/world/world_root.tscn") as PackedScene
	UI_THEME = load("res://assets/other/ui_theme.tres") as Theme
	
	PROJECTILE_TEX = []
	Console.load_status += 1

# TODO remove dbg kill
func _input(event: InputEvent) -> void:
	if event.is_action("DBG_EXIT", true): get_tree().quit()
	if event.is_action("DBG_DCH", false) && event.is_pressed(): get_tree().debug_collisions_hint = !get_tree().debug_collisions_hint

func fsign(num: float) -> int: return int(0<num)-int(num<0)

class COLLISION:
	static var WORLD_STATIC: int = 0b0001_0001
	static var WORLD_DYN: int =    0b0010_0010
	static var WORLD: int = WORLD_DYN | WORLD_STATIC
	
	static var HOSTILE_ENT: int =  0b0001_0000_0000
	static var FRIENDLY_ENT: int = 0b0010_0000_0000
	static var HOSTILE_PROJ: int = HOSTILE_ENT << 4
	static var FRIENDLY_PROJ: int = FRIENDLY_ENT << 4

class TEMP:
	static var FORCE_AI_TYPE: int = -1

func load_world_root() -> void:
	var root: World = WORLD_SCENE.instantiate() as World
	var old_world := Global.get_tree().root.get_child(-1)
	Global.get_tree().root.remove_child(old_world)
	Global.get_tree().root.add_child(root)
	Global.WORLD = root
