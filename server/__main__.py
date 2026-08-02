import random
import manage
import sys
import protocol
from twisted.python import log
from twisted.internet import reactor, task
from autobahn.twisted.websocket import WebSocketServerFactory

from server import models


class GameFactory(WebSocketServerFactory):
    def __init__(self, hostname: str, port: int):
        self.protocol = protocol.GameServerProtocol
        super().__init__(f"ws://{hostname}:{port}")
        self.tickrate: int = 20

        self.players: set[protocol.GameServerProtocol] = set()

        self.world_objects: list[models.WorldNode] = list(models.WorldNode.objects.all())

        tickloop = task.LoopingCall(self.tick)
        tickloop.start(1 / self.tickrate)  # 20 times per second
        trashloop = task.LoopingCall(self.spawn_trash)
        trashloop.start(10)  # Every 10 seconds

    def tick(self):
        for p in self.players:
            p.tick()

    def spawn_trash(self):
        # Check if there are any players in the game
        if len(self.players) == 0:
            print("No players in the game. Not spawning new trash node.")
            return
        # Get current trash count
        trash_count = len([node for node in self.world_objects if node.node_type == 2])
        # 3 Trash nodes per player
        if trash_count < len(self.players) * 3:
            print("Trash Count:", trash_count, "Players:", len(self.players), "Spawning new trash node.")
            # Spawn a new trash node at a random position
            x = random.uniform(0, 3000)
            y = random.uniform(-1800, 2000)
            new_node = models.WorldNode(node_type=2, x=x, y=y, RespawnTimer=30.0)
            new_node.save()
            self.world_objects.append(new_node)

            p = protocol.packet.SpawnNodePacket(2, x, y, 30.0, new_node.id)
            for player_protocol in self.players:
                if player_protocol.actor is not None:
                    player_protocol.send_client(p)
        else:
            print("Trash Count:", trash_count, "Players:", len(self.players), "Not spawning new trash node.")

    # Override
    def buildProtocol(self, addr):
        p = super().buildProtocol(addr)
        self.players.add(p)
        return p


if __name__ == '__main__':
    log.startLogging(sys.stdout)

    PORT: int = 8081
    factory = GameFactory('0.0.0.0', PORT)

    reactor.listenTCP(PORT, factory)
    reactor.run()
