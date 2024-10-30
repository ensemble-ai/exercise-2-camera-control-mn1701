class_name PositionLock
extends CameraControllerBase


func _ready() -> void:
	super()
	position = target.position


func _process(delta: float) -> void:
	if !current:
		return
		
	if draw_camera_logic:
		draw_logic()
	
	global_position = target.global_position
	
	super(delta)


func draw_logic() -> void:
	pass
