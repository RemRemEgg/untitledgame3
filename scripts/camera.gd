class_name Camera
extends Camera2D

var player: Player
var ppos: Vector2 = Vector2.ZERO

func _ready() -> void:
	player = get_parent() as Player

func _process(_delta: float) -> void:
	var direction: Vector2 = player.global_position - ppos
	var dls = direction.length_squared()
	if dls > 800**2 || dls < -1:
		ppos = player.global_position
		global_position = ppos
		return
	dls = sqrt(dls)
	direction *= (dls + 100) / (dls + 500)
	ppos += direction
	global_position = ppos

func warp(pos: Vector2) -> void: ppos += pos
