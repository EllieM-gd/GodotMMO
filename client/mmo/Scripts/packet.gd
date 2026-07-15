extends Object

var action: String
var payloads: Array

func _init(_action: String, _payload: Array):
	action = _action
	payloads = _payload
	
func tostring() -> String:
	var serialized_dict: Dictionary = {"a": action}
	for i in range(len(payloads)):
		serialized_dict["p%d" % i] = payloads[i]
	var data: String = JSON.stringify(serialized_dict)
	return data
	
static func json_to_action_payloads(json_str: String) -> Array:
	var new_action: String
	var payload: Array = []
	var obj_dict: Dictionary = JSON.parse_string(json_str)
	
	for key in obj_dict.keys():
		var value = obj_dict[key]
		if key == "a":
			new_action = value
		elif key[0] == "p":
			var index: int = key.split_floats("p", true)[1]
			payload.insert(index, value)
	return [new_action, payload]
