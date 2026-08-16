import json
import enum


class Action(enum.Enum):
    Chat = enum.auto() # User is sending a chat message
    Ok = enum.auto() # User is ok to log in
    Deny = enum.auto() # User is denied login
    Register = enum.auto() # User wants to register
    Login = enum.auto() # User wants to log in
    ModelData = enum.auto() # Server is sending model data to the client
    Movement = enum.auto() # User is moving their character
    Tp = enum.auto() # User is teleporting their character
    Instance = enum.auto() # User is sending their instance data
    Character = enum.auto() # User is sending their character data
    Visual = enum.auto() # User is sending their visual data
    SpawnNode = enum.auto() # Server is sending a new node to the client
    DeleteNode = enum.auto() # Client is sending a node deletion to the Server
    UpdateRocks = enum.auto() # Server is sending an update to the rocks count
    RockRequest = enum.auto() # Client is requesting to add rocks to their instanced entity
    PurchaseRequest = enum.auto() # Client is requesting to purchase an upgrade
    NewUpgrade = enum.auto() # Server is sending a new upgrade to the client

class Packet:
    def __init__(self, action: Action, *payloads):
        self.action: Action = action
        self.payloads: tuple = payloads

    def __str__(self) -> str:
        serialize_dict = {'a': self.action.name}
        for i in range(len(self.payloads)):
            serialize_dict[f'p{i}'] = self.payloads[i]
        data = json.dumps(serialize_dict, separators=(',', ':'))
        return data

    def __bytes__(self) -> bytes:
        return str(self).encode('utf-8')

class ChatPacket(Packet):
    def __init__(self, sender: str, message: str):
        super().__init__(Action.Chat, sender, message)

class OkPacket(Packet):
    def __init__(self):
        super().__init__(Action.Ok)

class DenyPacket(Packet):
    def __init__(self, reason: str):
        super().__init__(Action.Deny, reason)

class RegisterPacket(Packet):
    def __init__(self, username: str, password: str):
        super().__init__(Action.Register, username, password)

class LoginPacket(Packet):
    def __init__(self, username: str, password: str):
        super().__init__(Action.Login, username, password)

class ModelDataPacket(Packet):
    def __init__(self, model_data: dict):
        super().__init__(Action.ModelData, model_data)

class MovementPacket(Packet):
    def __init__(self, x: float, y: float, instance_id: int = None):
        super().__init__(Action.Movement, x, y, instance_id)
class TpPacket(Packet):
    def __init__(self, x: float, y: float, instance_id: int = None):
        super().__init__(Action.Tp, x, y, instance_id)
class InstancePacket(Packet):
    def __init__(self, instance_data: dict):
        super().__init__(Action.Instance, instance_data)
class CharacterPacket(Packet):
    def __init__(self, character_indx: int):
        super().__init__(Action.Character, character_indx)
class VisualPacket(Packet):
    def __init__(self, anim: int, flip: bool, instance_id: int = None):
        super().__init__(Action.Visual, anim, flip, instance_id)
class SpawnNodePacket(Packet):
    def __init__(self, node_type: int, x: float, y: float, respawn_timer: float, id: int):
        super().__init__(Action.SpawnNode, node_type, x, y, respawn_timer, id)
class UpdateRocksPacket(Packet):
    def __init__(self, instance_id: int, rocks: int):
        super().__init__(Action.UpdateRocks, instance_id, rocks)
class DeleteNodePacket(Packet):
    def __init__(self, node_id: int):
        super().__init__(Action.DeleteNode, node_id)
class RockRequestPacket(Packet):
    def __init__(self, amount: int):
        super().__init__(Action.RockRequest, amount)
class PurchaseRequestPacket(Packet):
    def __init__(self, upgrade_id: str, cost: int):
        super().__init__(Action.PurchaseRequest, upgrade_id, cost)
class NewUpgradePacket(Packet):
    def __init__(self, upgrade_id: str):
        super().__init__(Action.NewUpgrade, upgrade_id)


def from_json(json_str: str) -> Packet:
    obj_dict = json.loads(json_str)

    action = None
    payloads = []
    for key, value in obj_dict.items():
        if key == 'a':
            action = value

        elif key[0] == 'p':
            index = int(key[1:])
            payloads.insert(index, value)

    # Use reflection to construct the specific packet type we're looking for
    class_name = action + "Packet"
    try:
        constructor: type = globals()[class_name]
        return constructor(*payloads)
    except KeyError as e:
        print(
            f"KeyError: {class_name} is not a valid packet name. Stacktrace: {e}")
    except TypeError:
        print(
            f"TypeError: {class_name} can't handle arguments {tuple(payloads)}.")
