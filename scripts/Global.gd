extends Node

static var DUNGEON_GEN_TEMP: Node2D
static var GEN_STEP: int = 0

static var PLAYER: Node2D

static var WORLD_PROJECTILES: Node2D

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
