import math

from server import packet
from server import models
from server.protocol import GameServerProtocol
from django.db import transaction


class area:
    def __init__(self, x1: float, y1: float, x2: float, y2: float):
        self.min_x = min(x1, x2)
        self.max_x = max(x1, x2)
        self.min_y = min(y1, y2)
        self.max_y = max(y1, y2)

    def contains(self, x: float, y: float) -> bool:
        return (self.min_x <= x <= self.max_x) and (self.min_y <= y <= self.max_y)

## Unused???
def direction_to(current: list[float], target: list[float]) -> list[float]:
    if target == current:
        return [0, 0]
    n_x = target[0] - current[0]
    n_y = target[1] - current[1]

    length = math.dist(current, target)

    return [n_x / length, n_y / length]


## COMMANDS
def handle_command(command: str, sender: 'GameServerProtocol'):
    message = command.split(" ")
    isAdmin = sender.actor.instanced_entity.IsAdmin if sender.actor else False

    if message[0] == "/help":
        sender.send_client(packet.ChatPacket("Server", "Player commands: /help, /whoami /whereami"))
        if isAdmin:
            sender.send_client(packet.ChatPacket("Server", "Admin commands: /tp <x> <y>, /spawntree, /addrocks <amount> [player], /spawntrash"))
    elif message[0] == "/whoami":
        if sender.actor:
            sender.send_client(packet.ChatPacket("Server", f"You are logged in as {sender.actor.user.username}."))
        else:
            sender.send_client(packet.ChatPacket("Server", "You are not logged in."))
    elif message[0] == "/whereami":
        if sender.actor and sender.actor.instanced_entity:
            x = sender.actor.instanced_entity.x
            y = sender.actor.instanced_entity.y
            sender.send_client(packet.ChatPacket("Server", f"You are at coordinates ({x}, {y})."))
        else:
            sender.send_client(packet.ChatPacket("Server", "Error: Contact an administrator."))
    elif message[0] == "/tp":
        if not isAdmin:
            sender.send_client(packet.ChatPacket("Server", "You do not have permission to use this command."))
            return
        if len(message) < 3:
            sender.send_client(packet.ChatPacket("Server", "Usage: /tp <x> <y>"))
            return

        try:
            x = float(message[1])
            y = float(message[2])
        except ValueError:
            sender.send_client(packet.ChatPacket("Server", "Invalid coordinates."))
            return

        if sender.actor and sender.actor.instanced_entity:
            instanced_entity = sender.actor.instanced_entity
            instanced_entity.x = x
            instanced_entity.y = y
            instanced_entity.save()

            p = packet.TpPacket(x, y, instanced_entity.id)
            print("Sending tp packet to all players:", p.payloads)
            sender.send_client(p)  # Send the teleport packet to the sender
            # sender.broadcast(p, exclude_self=True)
    elif message[0] == "/spawntree":
        if not isAdmin:
            sender.send_client(packet.ChatPacket("Server", "You do not have permission to use this command."))
            return
        x = sender.actor.instanced_entity.x if sender.actor and sender.actor.instanced_entity else 0
        y = sender.actor.instanced_entity.y if sender.actor and sender.actor.instanced_entity else 0

        new_node = models.WorldNode(node_type=1, x=x, y=y, RespawnTimer=30.0)
        new_node.save()
        if hasattr(sender, 'factory'):
            sender.factory.world_objects.append(new_node)

        p = packet.SpawnNodePacket(1, x, y, 30.0)
  
        sender.send_client(p) 
        
        # Broadcast the network byte data out to all other clients right now
        if hasattr(sender, 'factory'):
            for player_protocol in sender.factory.players:
                if player_protocol != sender and player_protocol.actor is not None:
                    player_protocol.send_client(p)
    elif message[0] == "/spawntrash":
        if not isAdmin:
            sender.send_client(packet.ChatPacket("Server", "You do not have permission to use this command."))
            return
        x = sender.actor.instanced_entity.x if sender.actor and sender.actor.instanced_entity else 0
        y = sender.actor.instanced_entity.y if sender.actor and sender.actor.instanced_entity else 0

        new_node = models.WorldNode(node_type=2, x=x, y=y, RespawnTimer=30.0)
        new_node.save()
        if hasattr(sender, 'factory'):
            sender.factory.world_objects.append(new_node)

        p = packet.SpawnNodePacket(2, x, y, 30.0)
  
        sender.send_client(p) 
        
        # Broadcast the network byte data out to all other clients right now
        if hasattr(sender, 'factory'):
            for player_protocol in sender.factory.players:
                if player_protocol != sender and player_protocol.actor is not None:
                    player_protocol.send_client(p)
    elif message[0] == "/addrocks":
        if not isAdmin:
            sender.send_client(packet.ChatPacket("Server", "You do not have permission to use this command."))
            return
        if len(message) < 2:
            sender.send_client(packet.ChatPacket("Server", "Usage: /addrocks <amount>"))
            return

        try:
            amount = int(message[1])
        except ValueError:
            sender.send_client(packet.ChatPacket("Server", "Invalid amount."))
            return
        player = None
        try:
            player = message[2] if len(message) > 2 else None
        except IndexError:
            player = None

        if player != None:
            # Find the player by username
            target_protocol = None
            if hasattr(sender, 'factory'):
                for p in sender.factory.players:
                    if p.actor and p.actor.user.username == player:
                        target_protocol = p
                        break
            if target_protocol is None:
                sender.send_client(packet.ChatPacket("Server", f"Player '{player}' not found."))
                return
            target_protocol.actor.instanced_entity.Rocks += amount
            target_protocol.actor.instanced_entity.save()
            p = packet.UpdateRocksPacket(target_protocol.actor.instanced_entity.id, target_protocol.actor.instanced_entity.Rocks)
            target_protocol.send_client(p)  # Send the UpdateRocks packet to the target player
        elif sender.actor and sender.actor.instanced_entity:
            instanced_entity = sender.actor.instanced_entity
            instanced_entity.Rocks += amount
            instanced_entity.save()

            p = packet.UpdateRocksPacket(instanced_entity.id, instanced_entity.Rocks)
            sender.send_client(p)  # Send the UpdateRocks packet to the sender
            # sender.broadcast(p, exclude_self=True)
    else:
        sender.send_client(packet.ChatPacket("Server", f"Unknown command: {command}"))