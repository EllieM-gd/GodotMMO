extends Node

signal _RegisterConfirmed
signal _RegisterDenied
signal _LoginFailed
signal _LoginSuccess

signal _player_dc

signal _spawnNode(type: int, x: float, y: float, RespawnTimer: float, id: int)
signal _deleteNode(id: int)

signal request_rocks(num: int)

signal chatTyping(val: bool)

var localPlayerUsername: String = ""

# TODO: MAKE SERVER SIDE LATER
signal update_trash(num: int)
var localRecyclingCount: int = 0
var localMaxRecyclingCount: int = 3


var Characters = [
	load("res://Sprites/SpriteFrames/Bunny.tres"), # 0 = Bunny
	load("res://Sprites/SpriteFrames/Chick.tres"), # 1 = Chick
	load("res://Sprites/SpriteFrames/Frog.tres"), # 2 = Frog
	load("res://Sprites/SpriteFrames/Hen.tres"), # 3 = Hen
	load("res://Sprites/SpriteFrames/Kitty.tres"), # 4 = Kitty
	load("res://Sprites/SpriteFrames/Snake.tres") # 5 = Snake
]
