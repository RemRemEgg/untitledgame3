class_name HUD
extends CanvasLayer

@onready var health_bar: ProgressBar = $margin/stats/h_box_container/v_box_container/health_bar as ProgressBar


func _ready() -> void: pass

func update(player: Player) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
