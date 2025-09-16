extends Panel

@onready var LoadButton = $LOAD
@onready var CancelButton = $CANCEL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LoadButton.pressed.connect(Open)

func Open():
	var LoadMenu = get_parent().find_child("LevelLoaderMenu")
	LoadMenu.visible = true
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
