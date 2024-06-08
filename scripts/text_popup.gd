class_name TextPopup
extends Control

static var SCENE: PackedScene = preload("res://scenes/ui/text_popup.tscn")
# TODO make text popups look better
@onready var txt: Label = $text as Label
@onready var anim: AnimationPlayer = $anim as AnimationPlayer
var velocity: Vector2 = Vector2(randf() * 1.5 - 0.75, -(randf() * 0.3 + 0.5)) * 96

var text: String :
	set(val):
		text = val
		txt.text = text

static func create(val: String) -> TextPopup:
	var txtpop := SCENE.instantiate() as TextPopup
	txtpop.txt = txtpop.get_node("text") as Label
	txtpop.text = val
	return txtpop

func add_to_world(world: Node, pos: Vector2) -> TextPopup:
	var parent = get_parent()
	if parent: parent.remove_child(self)
	world.add_child(self)
	global_position = pos
	return self

func _ready() -> void: pass

func _process(delta: float) -> void:
	position += velocity * delta
	velocity.x *= 0.96
	velocity.y += delta * 86
