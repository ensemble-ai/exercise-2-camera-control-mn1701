class_name PushZone
extends CameraControllerBase

@export var speedup_zone_top_left: Vector2 = Vector2(-5, -5)
@export var speedup_zone_bottom_right: Vector2 = Vector2(5, 5)
@export var pushbox_top_left: Vector2 = Vector2(-8, -8)
@export var pushbox_bottom_right: Vector2 = Vector2(8, 8)
@export var push_ratio: float = 0.5
var recenter_speed: float = 20.0

func _process(delta: float) -> void:
	if !current:
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()

	# Calculate box dimensions
	var pushbox_width = pushbox_bottom_right.x - pushbox_top_left.x
	var pushbox_height = pushbox_bottom_right.y - pushbox_top_left.y

	var tpos = target.global_position
	var cpos = global_position

	# Determine if the vessel is inside the speedup zone
	var inside_speedup_zone = (tpos.x - target.WIDTH / 2.0 > cpos.x + speedup_zone_top_left.x and tpos.x + target.WIDTH / 2.0 < cpos.x + speedup_zone_bottom_right.x and tpos.z - target.WIDTH / 2.0 > cpos.z + speedup_zone_top_left.y and tpos.z + target.WIDTH / 2.0 < cpos.z + speedup_zone_bottom_right.y)

	if inside_speedup_zone:
		# Inside the inner box; camera does not move
		pass
	
	# If in the area between speedup zone and pushbox, move the camera at fixed speed in vessel's direction
	if !inside_speedup_zone:
		var direction_to_target = (Vector2(tpos.x - cpos.x, tpos.z - cpos.z)).normalized()
		global_position.x += direction_to_target.x * target.BASE_SPEED * push_ratio * delta
		global_position.z += direction_to_target.y * target.BASE_SPEED * push_ratio * delta
	
	# Boundary checks for the pushbox, camera move with the vessel with the same velocity
	var diff_left = (tpos.x - target.WIDTH / 2.0) - (cpos.x - pushbox_width / 2.0)
	if diff_left < 0:
		global_position.x += diff_left
	
	var diff_right = (tpos.x + target.WIDTH / 2.0) - (cpos.x + pushbox_width / 2.0)
	if diff_right > 0:
		global_position.x += diff_right
	
	var diff_top = (tpos.z - target.WIDTH / 2.0) - (cpos.z - pushbox_height / 2.0)
	if diff_top < 0:
		global_position.z += diff_top
	
	var diff_bottom = (tpos.z + target.WIDTH / 2.0) - (cpos.z + pushbox_height / 2.0)
	if diff_bottom > 0:
		global_position.z += diff_bottom
	
	if target.velocity.length() == 0:
		# Re-center the camera to place the vessel inside the inner box when vessel is stationary
		var inner_box_center = Vector3((speedup_zone_top_left.x + speedup_zone_bottom_right.x) / 2 + cpos.x, 
			cpos.y, (speedup_zone_top_left.y + speedup_zone_bottom_right.y) / 2 + cpos.z)
		var re_center_direction = (inner_box_center - cpos).normalized()
		global_position.x += re_center_direction.x * recenter_speed * delta
		global_position.z += re_center_direction.z * recenter_speed * delta
	
	super(delta)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	# Draw pushbox boundary
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_top_left.y))

	# Draw speedup zone boundary
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_top_left.y))

	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	# Free the mesh after one frame
	await get_tree().process_frame
	mesh_instance.queue_free()
