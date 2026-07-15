extends Node2D

@onready var nodes: Node2D = $Nodes
var TREE = preload("res://Scenes/tree.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals._spawnNode.connect(_spawnNode)

func _spawnNode(id, x, y, RespawnTimer):
	if id == 1:
		_spawnTree(x, y, RespawnTimer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _spawnTree(x, y, RespawnTimer):
	print("SPAWNING IN TREE")
	var t = TREE.instantiate()
	nodes.add_child(t)
	t.global_position = Vector2(x,y)
