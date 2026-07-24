extends CanvasModulate
@onready var canvas_modulate: CanvasModulate = $"."

func _ready() -> void:
	canvas_modulate.visible = true
	
