extends CanvasLayer

@onready var inspectorwindow = $PropertyMenu/ScrollContainer/VBoxContainer
@onready var LevelLoaderMenu = $LevelLoaderMenu/ScrollContainer/VBoxContainer
@export var DifferentCreatables: Array #the different items you can create
@export var Tools: Array #the different tools like property edit, create, or delete
@export var Name: String #don't edit
@onready var isOpen: bool = false
var OBJ = load("res://Interactables/cubes/Explosive/Explosive_Barrel.tscn") #the starting item to be created
var TOOL = "Transform Edit" #the starting tool

var target_object = null
var field_map: Dictionary = {}

func _ready() -> void:
	AddItems()
	var OBJButton = $ToolsMenu/ObjectButton
	OBJButton.item_selected.connect(ChoseItem)
	var ToolsButton = $ToolsMenu/OptionButton
	ToolsButton.item_selected.connect(ChoseTool)
	var NameButton = $"Name&PositionMenu/Button"
	NameButton.pressed.connect(OpenNamingConvention)
	var FileManager = $FileManager/MenuButton
	FileManager.get_popup().id_pressed.connect(_on_menu_button_id_pressed)

func _on_menu_button_id_pressed(id):
	match id:
		0:
			Save()
		1:
			Load()

func get_custom_map_folder() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	var folder = exe_dir.path_join("CustomMaps")
	DirAccess.make_dir_recursive_absolute(folder)
	return folder

func Save():
	var packedscene = PackedScene.new()
	var maproot: Node3D = get_parent().get_parent().get_child(1)
	for children in maproot.get_children():
		if children.has_method("Replace"):
			children.Replace(maproot)
		if children.get_child_count() >= 0:
			for child in children.get_children():
				child.owner = children
				print(children.name, "has: ", child.name)
		else:
			print("No children found in: ", children.name )
		print(children.name)
		children.owner = maproot
	print(maproot)
	var mapName = Name + ".tscn"
	packedscene.pack(maproot)
	var path = get_custom_map_folder().path_join(mapName)
	var err = ResourceSaver.save(packedscene, path)
	if err == OK:
		print("Saved to... " + path)
		print(maproot.get_children())
		
	else:
		print("OH NO... Error Code: " + str(err))
		
	get_tree().change_scene_to_file("res://Title.tscn")
	
func Load():
	var WARNING = $"WARNING!"
	WARNING.visible = true

func OpenNamingConvention():
	if isOpen == false:
		$"Name&PositionMenu/NAMING".visible = true
		isOpen = true

func ChoseItem(ItemIndex: int):
	if ItemIndex >= 0 and ItemIndex < DifferentCreatables.size():
		var path = DifferentCreatables[ItemIndex]
		OBJ = path
		print(OBJ, "", path)
		
func ChoseTool(ItemIndex: int):
	if ItemIndex >= 0 and ItemIndex < Tools.size():
		TOOL = Tools[ItemIndex]
	
func AddItems():
	var OBJButton = $ToolsMenu/ObjectButton
	for i in DifferentCreatables:
		var path = i.get_path()
		var Name = path.right(-path.rfind("/") - 1).left(-5)
		OBJButton.add_item(str(Name))
	var ToolsButton = $ToolsMenu/OptionButton
	for i in Tools:
		ToolsButton.add_item(i)

func inspect(object_to_inspect):
	if object_to_inspect == null:
		return
	if TOOL == "Property Edit":
		target_object = object_to_inspect
		for r in inspectorwindow.get_children():
			inspectorwindow.remove_child(r)
			
			r.queue_free()
		field_map.clear()

		var props = target_object.get_property_list()
		for prop in props:
			var name = prop.name
			var usage = prop.usage
			var type = prop.type

			# Only show exported or visible properties
			if not (usage & PROPERTY_USAGE_EDITOR):
				continue

			var value = target_object.get(name)

			var hbox = HBoxContainer.new()
			var label = Label.new()
			label.text = name + ":"
			hbox.add_child(label)

			if not type == TYPE_BOOL:
				var input = LineEdit.new()
				input.text = str(value)
				input.name = name
				input.expand_to_text_length = true
				input.connect("text_submitted", Callable(self, "_on_property_changed").bind(name))
				hbox.add_child(input)

				field_map[name] = input
				inspectorwindow.add_child(hbox)
			elif type == TYPE_BOOL:
				var input = CheckBox.new()
				input.text = str(value)
				input.name = name
				input.button_pressed = bool(value)
				input.connect("toggled", Callable(self,"_on_bool_property_changed").bind(name, input))
				hbox.add_child(input)
				
				field_map[name] = input
				inspectorwindow.add_child(hbox)
				
	elif TOOL == "Create":
		CreateOBJ()
	elif TOOL == "Destroy":
		DestroyOBJ(object_to_inspect)
	elif TOOL == "Transform Edit":
		SummonTransform(object_to_inspect)
	elif TOOL == "Scale Edit":
		SummonScale(object_to_inspect)

func _on_property_changed(new_text: String, prop_name: String):
	if target_object == null:
		print("NULL")
		return
	var input = field_map[prop_name]
	var old_value = target_object.get(prop_name)
	var new_value = _parse_value(new_text, typeof(old_value))
	target_object.set(prop_name, new_value)
	
func _on_bool_property_changed(toggled_on: bool, prop_name: String, property_item: CheckBox):
	if target_object == null:
		return
	var input = field_map[prop_name]
	var old_value = target_object.get(prop_name)
	var new_value = _parse_value(str(toggled_on), typeof(old_value))
	property_item.text = str(new_value)
	target_object.set(prop_name, new_value)
	print("HELLO WORLD I AM ", prop_name)
	
func _parse_value(text: String, type_enum: int):
	match type_enum:
		TYPE_INT:
			return text.to_int()
		TYPE_FLOAT:
			return text.to_float()
		TYPE_BOOL:
			return text.to_lower() in ["true", "1"]
		TYPE_STRING:
			return text
		TYPE_VECTOR2:
			var parts = text.replace("(", "").replace(")", "").split(",")
			return Vector2(parts[0].to_float(), parts[1].to_float()) if parts.size() == 2 else Vector2.ZERO
		TYPE_VECTOR3:
			var parts = text.replace("(", "").replace(")", "").split(",")
			return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float()) if parts.size() == 3 else Vector3.ZERO
		_:
			return text

func CreateOBJ():
	var instance = OBJ.instantiate()
	get_parent().get_parent().get_child(1).add_child(instance)
	instance.global_position = get_parent().get_child(1).global_position
	
func DestroyOBJ(target_Object):
	target_Object.get_parent().queue_free()
	
@onready var TransformPoint: Node3D = get_parent().get_parent().find_child("ArrowHolder").find_child("Transform")
@onready var basescale = TransformPoint.scale
func SummonTransform(OBJ: Node3D):
	if not OBJ.is_in_group("Arrows"):
		print("Transformed Summoned to: ", OBJ.global_position)
		TransformPoint.visible = true
		TransformPoint.reparent(OBJ)
		TransformPoint.global_position = OBJ.global_position
		TransformPoint.scale = basescale
		TransformPoint.global_scale(Vector3(OBJ.scale.x * 2, OBJ.scale.y * 2, OBJ.scale.z * 2))
		print(TransformPoint.scale)
	else:
		print(OBJ.name)
		var Movement = OBJ.get_parent().get_parent()
		#This is the Transform movemnent part
		if OBJ.name == "Y-Arrow":
			Movement.global_position.y += 0.5
		elif OBJ.name == "-Y-Arrow":
			Movement.global_position.y -= 0.5
		elif OBJ.name == "X-Arrow":
			Movement.global_position.x += 0.5
		elif OBJ.name == "-X-Arrow":
			Movement.global_position.x -= 0.5
		elif OBJ.name == "Z-Arrow":
			Movement.global_position.z += 0.5
		elif OBJ.name == "-Z-Arrow":
			Movement.global_position.z -= 0.5
			
@onready var ScalePoint: Node3D = get_parent().get_parent().find_child("ArrowHolder").find_child("Scale")
@onready var baseSscale = ScalePoint.scale
func SummonScale(OBJ: Node3D):
	if not OBJ.is_in_group("Arrows"):
		print("Scale Summoned to: ", OBJ.global_position)
		ScalePoint.visible = true
		ScalePoint.reparent(OBJ)
		ScalePoint.global_position = OBJ.global_position
		ScalePoint.scale = basescale
		ScalePoint.global_scale(Vector3(OBJ.scale.x * 2, OBJ.scale.y * 2, OBJ.scale.z * 2))
		print(ScalePoint.scale)
	else:
		print(OBJ.name)
		var Movement = OBJ.get_parent().get_parent()
		#This is the object Scaling part
		if OBJ.name == "Y-Arrow":
			Movement.scale.y += 0.5
		elif OBJ.name == "-Y-Arrow":
			Movement.scale.y -= 0.5
		elif OBJ.name == "X-Arrow":
			Movement.scale.x -= 0.5
		elif OBJ.name == "-X-Arrow":
			Movement.scale.x += 0.5
		elif OBJ.name == "Z-Arrow":
			Movement.scale.z += 0.5
		elif OBJ.name == "-Z-Arrow":
			Movement.scale.z -= 0.5
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
