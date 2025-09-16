extends Panel

@onready var Name = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var NewName = $NameText
	var NameButton = $DoneButton
	NameButton.pressed.connect(ChooseName)

func ChooseName():
	Name = $Name.text
	get_parent().get_parent().Name = Name
	get_parent().get_child(0).text = "Map Name: " + Name
	get_parent().get_parent().isOpen = false
	self.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
