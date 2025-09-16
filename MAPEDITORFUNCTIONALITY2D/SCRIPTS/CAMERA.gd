extends Camera2D

@export var pan_speed = 25
@export var zoom_speed = 0.5

@export var min_zoom = Vector2(0.1, 0.1)
@export var max_zoom = Vector2(20.0, 20.0)

@export_category("Inputs")
@export var grab: String
@export var interact: String
@export var delete: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
@onready var isgrabbing = false
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed(grab):
			global_position -= event.relative * pan_speed #the speed of spanning
			$CanvasLayer.canupdate = false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoom_speed, zoom_speed) * get_process_delta_time()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoom_speed, zoom_speed) * get_process_delta_time()
		if Input.is_action_just_pressed(interact):
			Fire()
		if Input.is_action_pressed(delete):
			Delete()
	if Input.is_action_just_released(grab):
		$CanvasLayer.canupdate = true
	zoom = clamp(zoom, min_zoom, max_zoom)
	
func Fire():
	var TOOL = $CanvasLayer.TOOL
	var space_state = get_world_2d().direct_space_state

	var mouse_pos = get_viewport().get_mouse_position()
	print(mouse_pos)
	var ray_end_point = mouse_pos # Example: Ray points 100 pixels down

	var query = PhysicsRayQueryParameters2D.create(global_position, ray_end_point)
	print(query)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	print(result)
	if result == null:
		print("Sorry nope")
		return
	if result and TOOL == "Property Edit" or TOOL == "Destroy" or TOOL == "Transform Edit" or TOOL == "Scale Edit":
		$CanvasLayer.inspect(result.collider)
	elif TOOL == "Entity Maker":
		$CanvasLayer.CreateOBJ()
	elif TOOL == "Tilemap Edit" and not $CanvasLayer.ChosenTile == null:
		$CanvasLayer.createTile($CanvasLayer.ChosenTile)
		
func Delete():
	var TOOL = $CanvasLayer.TOOL
	
	if TOOL == "Tilemap Edit":
		$CanvasLayer.deleteTile()
	elif TOOL == "Entity Maker":
		var space_state = get_world_2d().direct_space_state
		var mouse_pos = get_global_mouse_position()
		print(mouse_pos)
		var ray_end_point = mouse_pos # Example: Ray points 100 pixels down

		var query = PhysicsRayQueryParameters2D.create(global_position, ray_end_point)
		print(query)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		if result is Dictionary:
			if not result.is_empty():
				print(result)
				$CanvasLayer.deleteOBJ(result.collider)
			else:
				print("WOW!!! EMPTY")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
