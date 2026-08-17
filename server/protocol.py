import math
import queue

from django.db import transaction
import packet
import util
import time
from server import models
from autobahn.twisted.websocket import WebSocketServerProtocol
from django.contrib.auth import authenticate


class GameServerProtocol(WebSocketServerProtocol):
    def __init__(self):
        super().__init__()
        self._packet_queue: queue.Queue[tuple['GameServerProtocol', packet.Packet]] = queue.Queue()
        self._state: callable = self.LOGIN
        self.actor: models.Actor = None
        self._newest_pos: tuple[float, float] = None
        self._new_char: int = None

    def PLAY(self, sender: 'GameServerProtocol', p: packet.Packet):
        if p.action == packet.Action.Chat:
            msg = p.payloads
            if sender == self:
                if msg[1].startswith('/'):
                    util.handle_command(msg[1], self)
                else:
                    clean_msg = self.factory.filter.censor(p.payloads[1])
                    p = packet.ChatPacket(p.payloads[0], clean_msg)
                    print("NEW CHAT MESSAGE:", p.payloads)
                    self.broadcast(p, exclude_self=True)
            else:
                self.send_client(p)
        elif p.action == packet.Action.Movement: # Issue a player movement
            #self._player_target = p.payloads
            if sender == self:
                self._newest_pos = p.payloads
                # self.broadcast(p, exclude_self=True) # Send the movement to everyone else
            else:
                self.send_client(p)
        elif p.action == packet.Action.ModelData: # Send our model to everyone else
            self.send_client(p)
        elif p.action == packet.Action.Instance: # Send our instance data to everyone else
            self.send_client(p)
        elif p.action == packet.Action.Tp: # Issue a player teleport
            print(f"tp packet received: {p.payloads}")
            self.send_client(p)
        elif p.action == packet.Action.Visual: 
            if sender != self:
                self.send_client(p)
            else:
                entity_id = self.actor.instanced_entity.entity.id
                p = packet.VisualPacket(p.payloads[0], p.payloads[1], entity_id)
                self.broadcast(p, exclude_self=True)
        elif p.action == packet.Action.Character:
            if sender == self:
                self._new_char = p.payloads[0]
                self.actor.avatar_id = self._new_char
                self.actor.save()
                self.broadcast(p, exclude_self=True)
            else:
                self.send_client(p)
        elif p.action == packet.Action.SpawnNode:
            self.send_client(p)
        elif p.action == packet.Action.UpdateRocks:
            self.send_client(p)
        elif p.action == packet.Action.DeleteNode:
            if sender == self:
                # Delete the node from the database
                node_id = p.payloads[0]
                try:
                    node = models.WorldNode.objects.get(id=node_id)
                    node.delete()
                    for n in self.factory.world_objects:
                        if n.id == node_id:
                            self.factory.world_objects.remove(n)
                            break  # Stop searching once found

                    # Broadcast the deletion to all other players
                    self.broadcast(p, exclude_self=True)
                except models.WorldNode.DoesNotExist:
                    print(f"Node with id {node_id} does not exist.")
            else:
                self.send_client(p)
        elif p.action == packet.Action.RockRequest:
            if sender == self:
                amount = p.payloads[0]
                instanced_entity = self.actor.instanced_entity
                instanced_entity.Rocks += amount
                instanced_entity.save()
                # Send an update to the player about their new rock count
                update_packet = packet.UpdateRocksPacket(instanced_entity.entity.id, instanced_entity.Rocks)
                self.send_client(update_packet)
        elif p.action == packet.Action.PurchaseRequest:
            if sender != self: return
            if self.purchase_upgrade(self.actor.instanced_entity.id, p.payloads[0], p.payloads[1]):
                # Send an update to the player about their new rock count
                update_packet = packet.UpdateRocksPacket(self.actor.instanced_entity.entity.id, self.actor.instanced_entity.Rocks)
                self.send_client(update_packet)
                # Send an update to the player about their purchased upgrades
                new_upgrade_packet = packet.NewUpgradePacket(p.payloads[0])
                self.send_client(new_upgrade_packet)
                # Send OK Packet
                self.send_client(packet.OkPacket())
            else:
                self.send_client(packet.DenyPacket("Purchase failed. Check if you have enough rocks or if the upgrade is already owned."))
        else:
            print(f"Unhandled packet in PLAY state: {p}")

    def LOGIN(self, sender: 'GameServerProtocol', p: packet.Packet):
        if p.action == packet.Action.Login:
            if len(self.factory.players) >= 50:
                print(f"Server is full. Current players: {len(self.factory.players)}")
                self.send_client(packet.DenyPacket("Server is full. Please try again later."))
                return
            username, password = p.payloads

            user = authenticate(username=username, password=password)
            if user:
                self.actor = models.Actor.objects.get(user=user)
                if self._new_char is not None:
                    self.actor.avatar_id = self._new_char
                    self.actor.save()

                if self not in self.factory.players:
                    self.factory.players.add(self)

                self.send_client(packet.OkPacket())
                self.send_client(packet.ModelDataPacket(models.create_dict(self.actor)))
                self._state = self.PLAY
                # tell other players that we just logged in and send them our model data
                self.broadcast(packet.ModelDataPacket(models.create_dict(self.actor)), exclude_self=True)
                # Recieve all the data from the other players
                for other in self.factory.players:
                    if other != self and other.actor:
                        self.send_client(packet.ModelDataPacket(models.create_dict(other.actor)))
                for node in self.factory.world_objects:
                    self.send_client(packet.SpawnNodePacket(node.node_type, node.x, node.y, node.RespawnTimer, node.id))
            else:
                self.send_client(packet.DenyPacket("Invalid username or password"))
        elif p.action == packet.Action.Register:
            username, password = p.payloads
            if not username or not password:
                self.send_client(packet.DenyPacket("Username and password cannot be empty"))
                return

            if models.User.objects.filter(username=username).exists():
                self.send_client(packet.DenyPacket("Username already exists"))
                return
            # Check if the username contains profanity
            if self.factory.filter.contains_profanity(username):
                self.send_client(packet.DenyPacket("Username contains inappropriate language"))
                return
            # Create a user for login
            user = models.User.objects.create_user(username=username, password=password)
            user.save()
            # Create an entity and instanced entity for the player
            player_entity = models.Entity(name=username)
            player_entity.save()
            # Create an instance entity for the player at (0, 0)
            player_ientity = models.InstancedEntity(entity=player_entity, x=0, y=0)
            player_ientity.save()
            # Save everything as an Actor and save it
            player = models.Actor(user=user, instanced_entity=player_ientity)
            player.save()
            # Send an Ok packet to the client to indicate successful registration
            self.send_client(packet.OkPacket())
        elif p.action == packet.Action.Character:
            index = p.payloads[0]
            if self.actor is not None:
                if 0 <= index < 6:
                    self.actor.avatar_id = index
                    self.actor.save()
            else:
                self._new_char = index
    
    def update_pos(self) -> bool:
        # Dont run if no player
        if self._newest_pos is None:
            return False 
        # Grab the current position of the player
        current_pos = (self.actor.instanced_entity.x, self.actor.instanced_entity.y)
        # Calculate the distance between the current position and the newest position
        # -----------
        # - Newest Position - is the last postiion the client sent
        # - Current position - is the last positionm the server has for that player
        distance = math.sqrt((self._newest_pos[0] - current_pos[0]) ** 2 + (self._newest_pos[1] - current_pos[1]) ** 2)
        # If the distance is greater than 0.1, move the player
        if distance > 0.1:
            # set the new position of the player to the newest position
            self.actor.instanced_entity.x = self._newest_pos[0]
            self.actor.instanced_entity.y = self._newest_pos[1]
            return True
        else:
            return False
    # Looping call that runs every tickrate to process packets and send data to clients
    def tick(self):
        # Process all the packets in the queue
        while not self._packet_queue.empty():
            s, p = self._packet_queue.get()
            self._state(s, p)
        # Send our data if we are in the PLAY state and we have moved
        if self._state == self.PLAY:
            if self.update_pos(): # Check if we should move
                self.broadcast(packet.MovementPacket(self.actor.instanced_entity.x, self.actor.instanced_entity.y, self.actor.instanced_entity.entity.id), exclude_self=True)

    # Send a packet to all players except for the sender
    def broadcast(self, p: packet.Packet, exclude_self: bool = False):
        for other in self.factory.players:
            if other == self and exclude_self:
                continue
            other.onPacket(self, p)

    # Override
    def onConnect(self, request):
        print(f"Client connecting: {request.peer}")
    # When player connects
    def onOpen(self):
        print("WebSocket connection opened")
        self._state = self.LOGIN

    # Override
    # def onClose(self, wasClean, code, reason):
    #     if self in self.factory.players and self.actor is not None:
    #         # Save the player data to the database
    #         print(f"Saving player data for {self.actor.user.username} to the database")
    #         self.actor.instanced_entity.save()
    #         self.actor.save()
    #     self.factory.players.remove(self)
    #     print(f"Websocket connection closed{' unexpectedly' if not wasClean else ' cleanly'} with code {code}: {reason}")

    def connectionLost(self, reason):
        if self.actor is not None:
            print(f"Saving player data for {self.actor.user.username}...")
            try:
                self.actor.instanced_entity.save()
                self.actor.save()
            except Exception as e:
                print(f"Database save failed: {e}")
                
        if self in self.factory.players:
            self.factory.players.remove(self)
        super().connectionLost(reason)

    # Override
    # Recieve message and decode it into a packet, then send it to the onPacket function
    def onMessage(self, payload, isBinary):
        decoded_payload = payload.decode('utf-8')

        try:
            p: packet.Packet = packet.from_json(decoded_payload)
        except Exception as e:
            print(f"Could not load message as packet: {e}. Message was: {payload.decode('utf8')}")

        self.onPacket(self, p)
    # Add packet to the queue to be processed in the next tick
    def onPacket(self, sender: 'GameServerProtocol', p: packet.Packet):
        self._packet_queue.put((sender, p))
        if p.action != packet.Action.Movement and p.action != packet.Action.Visual:
            print(f"Queued packet: {p}")
    # Send data to our client
    def send_client(self, p: packet.Packet):
        b = bytes(p)
        self.sendMessage(b)

    def purchase_upgrade(self, instanced_entity_id: int, upgrade_id: str, cost: int) -> bool:
        # Use atomic transaction to avoid race conditions with currency
        with transaction.atomic():
            player = self.actor.instanced_entity
            
            # Ensure purchased_upgrades is initialized
            if player.purchased_upgrades is None:
                player.purchased_upgrades = []

            # Check if player has enough currency
            if player.Rocks < cost:
                return False  # Insufficient funds

            # Process purchase
            player.Rocks -= cost
            player.purchased_upgrades.append(upgrade_id)
            
            # Save both fields back to the database
            player.save()
            return True
