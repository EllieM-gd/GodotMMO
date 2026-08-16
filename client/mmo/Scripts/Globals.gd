extends Node

signal _RegisterConfirmed
signal _RegisterDenied
signal _LoginFailed
signal _LoginSuccess
signal OK
signal NO(reason: String)

signal _player_dc

signal _spawnNode(type: int, x: float, y: float, RespawnTimer: float, id: int)
signal _deleteNode(id: int)

signal request_rocks(num: int)
var rock_count: int = 0

signal chatTyping(val: bool)
var localPlayerUsername: String = ""

signal update_trash(num: int)
var localRecyclingCount: int = 0
var localMaxRecyclingCount: int = 3
var RecyclingMultiplier: int = 1


signal openShop
signal closeShop
signal shopWaiting(val:bool)
signal MakePurchase(id: String, cost: int)
signal NewUpgrade(id: String)

func _ready():
	NewUpgrade.connect(newUpgrade)

var Characters = [
	load("res://Sprites/SpriteFrames/Bunny.tres"), # 0 = Bunny
	load("res://Sprites/SpriteFrames/Chick.tres"), # 1 = Chick
	load("res://Sprites/SpriteFrames/Frog.tres"), # 2 = Frog
	load("res://Sprites/SpriteFrames/Hen.tres"), # 3 = Hen
	load("res://Sprites/SpriteFrames/Kitty.tres"), # 4 = Kitty
	load("res://Sprites/SpriteFrames/Snake.tres") # 5 = Snake
]

func newUpgrade(upgrade: String):
	if upgrade.substr(0, upgrade.length() - 2) == "RockClub":
		RecyclingMultiplier = 1 + int(upgrade[-1])
	elif upgrade.substr(0, upgrade.length() - 2) == "Bag":
		localMaxRecyclingCount = 3 + int(upgrade[-1])
		update_trash.emit(localRecyclingCount)
