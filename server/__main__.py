import random
import manage
import sys
import protocol
from twisted.python import log
from twisted.internet import reactor, task, ssl
from autobahn.twisted.websocket import WebSocketServerFactory
from better_profanity import profanity

from server import models
import util

###                  Pond 1                                         Left Side of map                    Pond 2                              House 1                         House 2
UnaccessableAreas = [util.area(1555.5, -599.08, 2024.51, -200.83), util.area(-1472, -696, -128, 1984), util.area(528, -2352, 1280, -1858), util.area(3136, -64, 3456, 256), util.area(3968, -192, 4800, 320)]


class GameFactory(WebSocketServerFactory):
    def __init__(self, hostname: str, port: int):
        self.protocol = protocol.GameServerProtocol
        super().__init__(f"ws://{hostname}:{port}")
        self.tickrate: int = 20
        self.unconnected_protocols: set[protocol.GameServerProtocol] = set()
        self.players: set[protocol.GameServerProtocol] = set()

        self.filter = profanity


        self.world_objects: list[models.WorldNode] = list(models.WorldNode.objects.all())

        tickloop = task.LoopingCall(self.tick)
        tickloop.start(1 / self.tickrate)  # 20 times per second
        trashloop = task.LoopingCall(self.spawn_trash)
        trashloop.start(10)  # Every 10 seconds

    def tick(self):
        for p in self.unconnected_protocols:
            p.tick()

    def spawn_trash(self):
        # Check if there are any players in the game
        if len(self.players) == 0:
            return
        # Get current trash count
        trash_count = min(len([node for node in self.world_objects if node.node_type == 2]), 50)  # Limit to 50 trash nodes
        # 3 Trash nodes per player
        if trash_count < len(self.players) * 3:
            # Spawn a new trash node at a random position
            x = random.uniform(-1280, 5000)
            y = random.uniform(-2176, 2000)
            # Dont let it spawn in unaccessable areas
            while any(area.contains(x, y) for area in UnaccessableAreas):
                x = random.uniform(-1280, 5000)
                y = random.uniform(-2176, 2000)
            new_node = models.WorldNode(node_type=2, x=x, y=y, RespawnTimer=30.0)
            new_node.save()
            self.world_objects.append(new_node)

            p = protocol.packet.SpawnNodePacket(2, x, y, -1.0, new_node.id)
            for player_protocol in self.players:
                if player_protocol.actor is not None:
                    player_protocol.send_client(p)

    # Override
    def buildProtocol(self, addr):
        p = super().buildProtocol(addr)
        self.unconnected_protocols.add(p)
        return p


if __name__ == '__main__':
    log.startLogging(sys.stdout)
    profanity.load_censor_words()

    #certs_dir: str = f"{sys.path[0]}/certs"
    #certs_dir: str = "/etc/letsencrypt/live/eskinovammo.servequake.com"
    #context_factory = ssl.DefaultOpenSSLContextFactory(f"{certs_dir}/server.key", f"{certs_dir}/server.crt")
    #print(context_factory)
    #  context_factory = ssl.DefaultOpenSSLContextFactory(
    #      f"{certs_dir}/privkey.pem",
    #      f"{certs_dir}/fullchain.pem"
    #  )

    # with open(f"{certs_dir}/privkey.pem", "rb") as key_file:
    #     key_data = key_file.read()
    # with open(f"{certs_dir}/fullchain.pem", "rb") as cert_file:
    #     cert_data = cert_file.read()

    # certificate = ssl.PrivateCertificate.loadPEM(key_data + cert_data)
    # context_factory = certificate.options()

    PORT: int = 8081
    factory = GameFactory('127.0.0.1', PORT)
    #factory = GameFactory('eskinovammo.servequake.com', PORT)

    reactor.listenTCP(PORT, factory, interface='127.0.0.1')
    reactor.run()
