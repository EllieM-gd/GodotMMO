extends Node2D

@onready var nodes: Node2D = $Nodes
var TREE = preload("res://Scenes/tree.tscn")
var PAPER = preload("res://Scenes/PaperTrash.tscn")

var AllNodes: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals._spawnNode.connect(_spawnNode)
	Globals._deleteNode.connect(_delete_node)


func _delete_node(id: int):
	if AllNodes[id]:
		AllNodes[id].queue_free()

func _spawnNode(type, x, y, RespawnTimer, id):
	if type == 1:
		_spawnTree(x, y, RespawnTimer, id)
	if type == 2:
		_spawn_trash(x,y,RespawnTimer, id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _spawnTree(x, y, RespawnTimer, id):
	var t = TREE.instantiate()
	t.id = id
	nodes.add_child(t)
	AllNodes[id] = t
	t.global_position = Vector2(x,y)
	
func _spawn_trash(x,y,timer, id):
	var t = PAPER.instantiate()
	nodes.add_child(t)
	t.find_child("Interact").id = id
	AllNodes[id] = t
	t.global_position = Vector2(x,y)
