extends Button
class_name ShopItem

@export var shop_id: String = "NULL"
@export var shop_item: String = "*ITEM*"
@export var description: String = "NO DESC."
@export var cost: Array[int] = []
var currentUpgradeLevel: int = 0


func _ready():
	pressed.connect(_purchase)
	name = shop_item
	Globals.shopWaiting.connect(func(val): disabled = val )
	Globals.NewUpgrade.connect(upgrade)
	_update_text()
# For when the server sends us upgrade stuff
func upgrade(s: String):
	if s.substr(0, s.length() - 2) == shop_id:
		if int(s[-1]) > currentUpgradeLevel:
			currentUpgradeLevel = int(s[-1])
			_update_text()
# Handle updating text for us
func _update_text():
	if currentUpgradeLevel > len(cost) - 1:
		text = shop_item + "\n"
		text += "PURCHASED"
		disabled = true
		return
	text = shop_item
	text += "\n" + description + "\n"
	text += str(cost[currentUpgradeLevel]) + " Rocks"

	
func _purchase():
	if currentUpgradeLevel > len(cost) - 1:
		disabled = true
		return
	#if Globals.rock_count >= cost[currentUpgradeLevel]:
		#TODO: Add a request to the server to verify players money
	Globals.MakePurchase.emit(shop_id + "_" + str(currentUpgradeLevel + 1), cost[currentUpgradeLevel])
	Globals.OK.connect(_ok)
	Globals.NO.connect(_no)
	Globals.shopWaiting.emit(true)	

func _disconnect_signals():
	Globals.OK.disconnect(_ok)
	Globals.NO.disconnect(_no)
	Globals.shopWaiting.emit(false)
	_update_text()

func _ok():
	# Update button text
	_update_text()
	_disconnect_signals()
func _no(reason):
	printerr(reason)
	_disconnect_signals()
