extends Camera3D

var mouse_sensitivity = 0.3
var camera_pitch = 0 # To track vertical rotation
var direction = -global_transform.basis.z
var speed = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("Throw"): #right click
		# Rotate around the global Y-axis (yaw)
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		# Rotate around the camera's local X-axis (pitch)
		var change_pitch = (-event.relative.y * mouse_sensitivity) / 10 
		camera_pitch += change_pitch
		# Clamp the pitch to prevent flipping
		camera_pitch = clamp(camera_pitch, deg_to_rad(-90), deg_to_rad(90))
		rotation.x = camera_pitch
		print(rotation.x)
	if Input.is_action_pressed("forward") and Input.is_action_pressed("Throw"):
		direction += -global_transform.basis.z
	if Input.is_action_pressed("backward") and Input.is_action_pressed("Throw"):
		direction += global_transform.basis.z
		
	# Normalize so diagonal movement isn't faster
	direction = direction.normalized()

	# Apply to position (or velocity)
	position += direction * speed * get_process_delta_time()
	
	if Input.is_action_just_pressed("PickUp"): #left click
		Fire()
		
func Fire():
	var TOOL = $CanvasLayer.TOOL
	var space_state = get_world_3d().direct_space_state

	var start = global_transform.origin
	var direction = -global_transform.basis.z # forward direction
	var end = start + direction * 1000.0 # ray length (e.g. 1000 units)

	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	#if result == null:
		#print("Sorry nope")
		#return
	if result and TOOL == "Property Edit" or TOOL == "Destroy" or TOOL == "Transform Edit" or TOOL == "Scale Edit":
	### Does glitch out sometimes, couldn't figure out the error, 
	### the error is Invalid access to property or key 'collider' 
	### on a base object of type 'Dictionary'.
		$CanvasLayer.inspect(result.collider)
	elif TOOL == "Create":
		$CanvasLayer.CreateOBJ()
