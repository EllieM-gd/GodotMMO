extends Button
class_name ShopItem

@export var shop_item: String = "*ITEM*"
@export var description: String = "NO DESC."
@export var cost: Array[int] = []
var currentUpgradeLevel: int = 0


func _ready():
	pressed.connect(_purchased)
	name = shop_item
	_update_text()

func _update_text():
	if currentUpgradeLevel >= len(cost):
		text = shop_item + "\n"
		text += "PURCHASED"
		disabled = true
		return
	text = shop_item
	text += "\n" + description + "\n"
	text += str(cost[currentUpgradeLevel]) + " Rocks"

	
func _purchased():
	print("Purchased Queued: " , str(Globals.rock_count))
	if Globals.rock_count >= cost[currentUpgradeLevel]:
		#TODO: Add a request to the server to verify players money
		Globals.request_rocks.emit(-cost[currentUpgradeLevel])
		#TODO: Make an inventory system or something 
		currentUpgradeLevel += 1
		_update_text()
