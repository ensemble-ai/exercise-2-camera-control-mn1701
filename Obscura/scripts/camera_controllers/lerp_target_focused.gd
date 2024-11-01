class_name LerpTargetFocusedSmoothing
extends CameraControllerBase

@export var lead_speed: float = target.BASE_SPEED + 10
@export var catchup_delay_duration: float = 0.2
@export var catchup_speed: float = 20.0
@export var leash_distance: float = 2.0

var time_since_stopped: float = 0.0

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
	
	var tpos = target.global_position
	var cpos = global_position
	var distance_to_player = Vector2(tpos.x, tpos.z).distance_to(Vector2(cpos.x, cpos.z))

	var is_player_moving = (target.velocity.x != 0 || target.velocity.z != 0)

	# Calculate direction of player movement
	var movement_direction = Vector3(target.velocity.x, 0, target.velocity.z).normalized()
	var direction_to_player = Vector3(tpos.x - cpos.x, 0, tpos.z - cpos.z).normalized()

	# Handle camera behavior based on movement and catchup delay
	if is_player_moving:

		time_since_stopped = 0.0
		if distance_to_player < leash_distance + target.RADIUS:
			global_position.x += movement_direction.x * lead_speed * delta
			global_position.z += movement_direction.z * lead_speed * delta
		else:
			global_position.x = tpos.x - direction_to_player.x * leash_distance
			global_position.z = tpos.z - direction_to_player.z * leash_distance
	else:
		time_since_stopped += delta
		if time_since_stopped >= catchup_delay_duration:
			# Move the camera towards the player, scaling speed based on distance
			global_position.x += direction_to_player.x * catchup_speed * delta * (max(distance_to_player / leash_distance, 0.05))
			global_position.z += direction_to_player.z * catchup_speed * delta * (max(distance_to_player / leash_distance, 0.05))
	
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