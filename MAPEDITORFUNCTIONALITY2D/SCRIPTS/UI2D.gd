extends CanvasLayer

@onready var inspectorwindow = $PropertyMenu/ScrollContainer/VBoxContainer
@onready var tilesetMenu = $ToolsMenu/TilesetMenu
@onready var tilesetbox = $ToolsMenu/TilesetMenu/TileMaps/TilesetBox
@onready var LevelLoaderMenu = $LevelLoaderMenu/ScrollContainer/VBoxContainer
@export var DifferentCreatables: Array #the different items you can create
@export var Tools: Array #the different tools like property edit, create, or delete
@export var Name: String #don't edit
@onready var isOpen: bool = false
@export var gridsize: float = 32.0 #the grid size of each grid, change to size of the tiles in your tileset
@export var Tilesources: int #only use tilesets that are in your tilemap
@export_category("UI")
@export var Border: Texture2D
var OBJ = load("res://MAPEDITORFUNCTIONALITY2D/SpriteScenes/Player_Example.tscn") #the starting item to be created
var TOOL = "Tilemap Edit" #the starting tool

var target_object = null
var field_map: Dictionary = {}

var current_tilesource := 0

# Called when the node enters the scene tree for the first time.
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
	tilesetMenu.visible = true
	updateTilesetMenu()
	
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
	var maproot: Node2D = get_parent().get_parent().get_child(1)
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
				
func CreateOBJ():
	var instance = OBJ.instantiate()
	get_parent().get_parent().get_child(1).add_child(instance)
	instance.global_position = get_parent().get_global_mouse_position()

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
			
func updateTilesetMenu():
	var tilemap: TileMapLayer = get_parent().get_parent().find_child("Map").find_child("MapLayer")
	var tile_sources = tilemap.tile_set.get_source_count()
	var sourcesbuttonholder = $ToolsMenu/TilesetMenu/ScrollContainer/HBoxContainer
	for i in range(tile_sources):
		var source_texture = tilemap.tile_set.get_source(i)
		var newbutton = Button.new()
		newbutton.text = "Source %d" % (i + 1)
		newbutton.connect("pressed", Callable(self, "on_source_selected").bind(i))
		sourcesbuttonholder.add_child(newbutton)
		
func on_source_selected(source_index: int) -> void:
	current_tilesource = source_index
	populatetiles()
	print(source_index + 1)
	

func populatetiles():
	for i in tilesetbox.get_children():
		tilesetbox.remove_child(i)
		i.queue_free()
	var tilemap: TileMapLayer = get_parent().get_parent().find_child("Map").find_child("MapLayer")
	var source_tex: TileSetAtlasSource = tilemap.tile_set.get_source(current_tilesource)
	for tile_id in source_tex.get_tiles_count():
		var region: Vector2 = source_tex.get_tile_id(tile_id)
		var newbutton = TextureButton.new()
		newbutton.name = "TileButton %d" % (tile_id)
		var newatlusTexture = AtlasTexture.new()
		newbutton.texture_normal = newatlusTexture
		newbutton.set_meta("Region", region)
		newatlusTexture.atlas = source_tex.texture
		newatlusTexture.region = Rect2(region.x * 32.0, region.y * 32.0, gridsize, gridsize)
		newbutton.connect("pressed", Callable(self, "chosetile").bind(newbutton.name, newbutton.get_meta("Region"), newbutton.texture_normal, newbutton))
		tilesetbox.add_child(newbutton)
		print(tilesetbox.get_children(), " and... ", newbutton.texture_normal, " and... ", newatlusTexture.atlas)

@onready var ChosenTile = null
@onready var Canplace: bool = false
#@onready var CurrentTileButton: TextureButton
func chosetile(TileName: String, TileRegion: Vector2, newtexture: AtlasTexture, TileButton: TextureButton):
	print("Executed the change")
	ChosenTile = null
	Canplace = false
	print("Chose: ", TileName, " And it's region = ", TileRegion)
	ChosenTile = Vector2i(TileRegion)
	TileSeer.texture = newtexture
	Canplace = true
	deleteTile()
	#if not TileButton.find_child("Border"):
		#var Border_texture = TextureRect.new()
		#Border_texture.texture = Border
		#Border_texture.name = "Border"
		#Border_texture.size = Vector2(gridsize, gridsize)
		#TileButton.add_child(Border_texture)
		#if not CurrentTileButton == TileButton and not CurrentTileButton == null:
			#ClearBorders(CurrentTileButton)
		#else:
			#print("HELLO :> ", CurrentTileButton)
		#CurrentTileButton = TileButton
		#print("Bordername: ", Border_texture.name, " and it's parented to: ", Border_texture.get_parent())
#		
 #func ClearBorders(TileButton: TextureButton) -> void: #i couldn't figure it out, but maybe you can...
	#print(TileButton.name, "WHAT THE ****!")
	#var Border = TileButton.find_child("Border")
	#print(Border.name)
	#TileButton.remove_child(Border)
	
func createTile(Tileregion: Vector2i):
	var tilemap: TileMapLayer = get_parent().get_parent().find_child("Map").find_child("MapLayer")
	var prev_region = Tileregion
	print(prev_region, " VS ", Tileregion)
	if prev_region == Tileregion and not Tileregion == null and Canplace != false:
		var MousePos = tilemap.get_global_mouse_position()
		var LocalMousePos = tilemap.local_to_map(MousePos)
		print("Mouse: ", LocalMousePos)
		tilemap.set_cell(Vector2i(LocalMousePos.x, LocalMousePos.y), current_tilesource, Tileregion)
		tilemap.fix_invalid_tiles()
		print("Executed the placing")
		
func deleteTile():
	var tilemap: TileMapLayer = get_parent().get_parent().find_child("Map").find_child("MapLayer")
	var MousePos = tilemap.get_global_mouse_position()
	var LocalMousePos = tilemap.local_to_map(MousePos)
	print("Mouse: ", LocalMousePos)
	tilemap.erase_cell(Vector2i(LocalMousePos.x, LocalMousePos.y))
	
func deleteOBJ(result: CollisionObject2D):
	var MousePos = get_parent().get_global_mouse_position()
	var OBJ = result
	print(result)
	if not OBJ is TileMapLayer:
		OBJ.queue_free()
	else:
		print("HEY! THAT'S A DAMN TILEMAP!!!")

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

@onready var TileSeer: TextureRect = $TileSeer
var canupdate: bool = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if TOOL == "Tilemap Edit": #and canupdate == true:
		var Mousepos = TileSeer.get_global_mouse_position()
		var snapped_x = floor(((Mousepos.x) / gridsize)) * gridsize
		var snapped_y = floor(((Mousepos.y) / gridsize)) * gridsize
		var target_location = Vector2(snapped_x, snapped_y)
		TileSeer.set_position(target_location - TileSeer.size / 2)
		TileSeer.set_global_position(target_location - TileSeer.size / 2)
		if TileSeer.position != target_location:
			var tween = create_tween()
			tween.tween_property(TileSeer, "position", target_location, 0.1)#.set_trans(Tween.TRANS_SINE)
		if TileSeer.visible == false:
			TileSeer.visible = true
	elif not TOOL == "Tilemap Edit" and not TileSeer.visible == false:
		TileSeer.visible = false
