class_name TextPopup
extends Node2D

# TODO make text popups look better
var velocity: Vector2 = Vector2(randf() * 1.5 - 0.75, -(randf() * 0.3 + 0.5)) * 96
var time: float = 0.0
var text: String:
	set(ntext):
		text = ntext
		queue_redraw()

static func create(val: String, pos: Vector2) -> TextPopup:
	var txtpop := Global.TEXT_SCENE.instantiate() as TextPopup
	txtpop.text = val
	txtpop.global_position = pos
	return txtpop

func _ready() -> void: pass

func _process(delta: float) -> void:
	position += velocity * delta
	velocity.x *= 0.96
	velocity.y += delta * 86
	time += delta * 60
	scale /= 1.5
	match int(time/20):
		0: scale = Vector2.ONE * (1.25-(time/80))
		1: scale = Vector2.ONE
		3:
			scale = Vector2.ONE * (4-(time/20))
			self_modulate.a = scale.x
		4 when Server.is_host: queue_free()
		8: queue_free()
	scale *= 1.5

func _draw():
	draw_string_outline(Global.UI_THEME.default_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, 2)
	draw_string(Global.UI_THEME.default_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.DARK_RED)
