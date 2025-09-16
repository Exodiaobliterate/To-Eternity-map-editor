extends Node3D

class_name Reference

@onready var To_Replace: Object

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func Replace(NodeToParent: Node3D):
	var ReplacableObject = self
	var Replace = To_Replace.instantiate()
	Replace.global_position = ReplacableObject.global_position
	NodeToParent.add_child(Replace)
	ReplacableObject.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
