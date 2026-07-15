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

    def tick(self):
        for p in self.players:
            p.tick()

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
