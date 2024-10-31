class_name FrameBoundAutoscroller
extends CameraControllerBase

@export var top_left: Vector2 = Vector2(-12.5, 6.5)
@export var bottom_right: Vector2 = Vector2(12.5, -6.5)
@export var autoscroll_speed: float = 8.0

func _ready() -> void:
	super()
	position = target.position


func _process(delta: float) -> void:
	if !current:
		# Updates the vessel's location to use as a reference when not active
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()
	
	position.x += autoscroll_speed * delta
	
	# Calculate frame boundaries based on top_left and bottom_right
	var frame_left = position.x + top_left.x
	var frame_right = position.x + bottom_right.x
	var frame_top = position.z + top_left.y
	var frame_bottom = position.z + bottom_right.y
	
	var player_pos = target.global_position
	var player_velocity = target.velocity
	
	# Apply boundary constraints to keep player within the frame
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
	
	# Update player position and velocity
	target.global_position = player_pos
	target.velocity = player_velocity
	
	super(delta)

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Define frame boundaries for drawing based on top_left and bottom_right
	var left: float = top_left.x - target.RADIUS
	var right: float = bottom_right.x + target.RADIUS
	var top: float = top_left.y + target.RADIUS
	var bottom: float = bottom_right.y - target.RADIUS
	
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

	# Free the mesh after one frame
	await get_tree().process_frame
	mesh_instance.queue_free()
