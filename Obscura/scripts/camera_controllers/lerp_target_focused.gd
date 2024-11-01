class_name LerpTargetFocusedSmoothing
extends CameraControllerBase

@export var lead_speed: float = 60.0
@export var leash_distance: float = 6.0
@export var catchup_delay_duration: float = 0.2
@export var catchup_speed: float = 25.0

var time_since_stopped: float = 0.0

func _process(delta: float) -> void:
	if !current:
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()
	
	var tpos = target.global_position
	var cpos = global_position
	var distance_to_player = Vector2(tpos.x, tpos.z).distance_to(Vector2(cpos.x, cpos.z))
	
	# Determine if the vessel is moving
	var is_player_moving = (abs(target.velocity.x) > 0 || abs(target.velocity.z) > 0)
	
	if is_player_moving:
		# Reset the catch-up delay timer
		time_since_stopped = 0.0
		
		# Calculate movement direction based on the vessel's velocity in the x-z plane
		var movement_direction = Vector3(target.velocity.x, 0, target.velocity.z).normalized()
		
		# Move the camera in the vessel's direction at lead_speed
		global_position.x += movement_direction.x * lead_speed * delta
		global_position.z += movement_direction.z * lead_speed * delta
		
		# Check if the camera has exceeded the leash distance
		distance_to_player = Vector2(tpos.x, tpos.z).distance_to(Vector2(global_position.x, global_position.z))
		if distance_to_player > leash_distance:
			# Reposition the camera at the leash boundary
			var direction_to_vessel = Vector3(tpos.x - global_position.x, 0, tpos.z - global_position.z).normalized()
			global_position.x = tpos.x - direction_to_vessel.x * leash_distance
			global_position.z = tpos.z - direction_to_vessel.z * leash_distance
	
	else:
		time_since_stopped += delta
		# If the timer exceeds the delay duration, start moving the camera back to the vessel
		if time_since_stopped >= catchup_delay_duration:
			# Calculate direction to the vessel and apply catchup speed
			var direction_to_player = Vector3(tpos.x - global_position.x, 0, tpos.z - global_position.z).normalized()
			global_position.x += direction_to_player.x * catchup_speed * delta
			global_position.z += direction_to_player.z * catchup_speed * delta
	
	super(delta)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	# Draw a 5x5 cross in the center of the screen
	immediate_mesh.surface_add_vertex(Vector3(2.5, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(-2.5, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, 2.5))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, -2.5))
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	# Free the mesh after one frame
	await get_tree().process_frame
	mesh_instance.queue_free()
