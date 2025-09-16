extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var FolderPath = get_custom_map_folder()
	var Dir = DirAccess.open(FolderPath)
	if Dir:
		Dir.list_dir_begin()
		var LevelName = Dir.get_next()
		while LevelName != "":
			if not Dir.current_is_dir():
				var fullpath = FolderPath.path_join(LevelName)
				var Buttton = Button.new()
				Buttton.name = LevelName
				Buttton.text = LevelName
				
				#stores meta data
				Buttton.set_meta("scene_path", fullpath)
				
				Buttton.pressed.connect(CustomLevelLoad.bind(Buttton))
				
				self.add_child(Buttton)
			LevelName = Dir.get_next()
		Dir.list_dir_end()
		
func get_custom_map_folder() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	var folder = exe_dir.path_join("CustomMaps")
	DirAccess.make_dir_recursive_absolute(folder)
	return folder
	
func CustomLevelLoad(LevelButton: Button) -> void:
	var scenepath = LevelButton.get_meta("scene_path") as String
	if ResourceLoader.exists(scenepath):
		var packed_scene = load(scenepath)
		if packed_scene is PackedScene:
			var maproot: Node3D = get_parent().get_parent().get_parent().get_parent().get_parent().get_child(1)
			for child in maproot.get_children():
				child.queue_free()
			var instance = packed_scene.instantiate()
			print(instance.get_child_count())
			for child in instance.get_children():
				if child.get_child_count() >= 0:
					for children in child.get_children():
						children.owner = child
						print(child.name, "has: ", children.name)
				child.reparent(maproot)
			instance.queue_free()
			get_parent().get_parent().visible = false
	else:
		print("HELLO")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
