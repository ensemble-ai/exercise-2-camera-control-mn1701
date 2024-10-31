class_name LerpSmoothing
extends CameraControllerBase

@export var follow_speed: float = 35.0
@export var catchup_speed: float = 0.01
@export var leash_distance: float = 8.0

func _ready() -> void:
	super()
	position = target.position

func _process(delta: float) -> void:
	if !current:
		return
	
	if draw_camera_logic:
		draw_logic()
	
	var tpos = target.global_position
	var cpos = global_position
	var distance_to_player = tpos.distance_to(cpos)
	
	# Determine if the player is moving based on target's velocity
	var is_player_moving = (target.velocity.x || target.velocity.z > 0)
	
	# Use follow_speed if the player is moving, otherwise use catchup_speed
	var speed = follow_speed if is_player_moving else catchup_speed
	
	# Find direction of player position
	var direction_to_player = (tpos - cpos).normalized()
	# Limit the maximum distance between the vessel and camera
	if distance_to_player > leash_distance + target.RADIUS:
		global_position.x = tpos.x - direction_to_player.x * leash_distance
		global_position.z = tpos.z - direction_to_player.z * leash_distance
	else:
		# Move the camera towards the player
		global_position.x += direction_to_player.x * speed * delta
		global_position.z += direction_to_player.z * speed * delta
	
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
