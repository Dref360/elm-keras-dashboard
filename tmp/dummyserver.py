import threading
import time

import numpy as np
from SimpleWebSocketServer import SimpleWebSocketServer, WebSocket
import json
listeners = []


class SimpleEcho(WebSocket):
    def update(self, data):
        self.sendMessage(json.dumps(data))

    def handleConnected(self):
        print(self.address, 'connected')

    def handleClose(self):
        print(self.address, 'closed')


server = SimpleWebSocketServer('', 8080, SimpleEcho)


def run():
    epoch = 0
    while True:
        data = {
            'epoch': epoch,
            'loss': (np.sin(epoch / 10)),
            'val_loss': (np.cos(epoch / 10))
        }
        print("SEND", data)
        for ws in server.connections.values():
            ws.update(data)
        time.sleep(2)
        epoch += 1


t = threading.Thread(target=run)
t.daemon = True
t.start()
server.serveforever()
