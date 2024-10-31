class_name FrameBoundAutoscroller
extends CameraControllerBase

@export var frame_width: float = 25.0
@export var frame_height: float = 13.0
@export var autoscroll_speed: float = 8.0

func _ready() -> void:
	# Start camera at player's position
	position.x = target.position.x 
	position.z = target.position.z  

func _process(delta: float) -> void:
	if !current:
		return
	
	if draw_camera_logic:
		draw_logic()
	
	position.x += autoscroll_speed * delta
	
	var frame_left = position.x - frame_width / 2
	var frame_right = position.x + frame_width / 2
	var frame_top = position.z + frame_height / 2
	var frame_bottom = position.z - frame_height / 2
	
	var player_pos = target.global_position
	var player_velocity = target.velocity
	
	if player_pos.x < frame_left:
		player_pos.x = frame_left
		player_velocity.x = max(player_velocity.x, autoscroll_speed)
	
	if player_pos.x > frame_right:
		player_pos.x = frame_right
		player_velocity.x = min(player_velocity.x, 0)
	
	if player_pos.z > frame_top:
		player_pos.z = frame_top
		player_velocity.z = min(player_velocity.z, 0)
	
	if player_pos.z < frame_bottom:
		player_pos.z = frame_bottom
		player_velocity.z = max(player_velocity.z, 0)
	
	target.global_position = player_pos
	target.velocity = player_velocity
	
	super(delta)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left:float = (-frame_width / 2) - target.RADIUS
	var right:float = (frame_width / 2) + target.RADIUS
	var top:float = (-frame_height / 2) - target.RADIUS
	var bottom:float = (frame_height / 2) + target.RADIUS
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	await get_tree().process_frame
	mesh_instance.queue_free()
