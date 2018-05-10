import datetime
import json
import logging
import threading

from SimpleWebSocketServer import SimpleWebSocketServer, WebSocket

import keras.backend as K
from keras.callbacks import Callback


def reduce_lr(self):
    logging.info("Reduce LR")
    lr = K.get_value(self.model.optimizer.lr)
    new_lr = lr * 0.1
    K.set_value(self.model.optimizer.lr, new_lr)


def save_weights(self):
    logging.info("Save weight")
    self.model.save_weights('tmp_model_weight{}.h5'.format(datetime.datetime.now().strftime("%m-%d_%H:%M")))


def stop_training(self):
    logging.info('Stop training')
    self.model.stop_training = True


calls = {'reducelr': reduce_lr,
         'stop': stop_training,
         'saveweights': save_weights}


class KerasRemote(Callback):
    def __init__(self, port=8080):
        super().__init__()
        self.hist = []
        self.server = SimpleWebSocketServer('', port, SimpleEcho)
        th = threading.Thread(target=self.server.serveforever)
        th.daemon = True
        th.start()

    def __update(self, data):
        self.hist.append(data)
        for ws in self.server.connections.values():
            ws.update(data)

    def on_batch_end(self, batch, logs=None):
        for ws in self.server.connections.values():
            ws.hist = self.hist
            if not ws.built:
                ws.send_hist(self.hist)
            while ws.cmds:
                calls[ws.cmds.pop()](self)

    def on_epoch_end(self, epoch, logs=None):

        if logs is not None:
            data = {
                'epoch': epoch,
                'logs': logs
            }
            self.__update(data)


class SimpleEcho(WebSocket):
    def __init__(self, server, sock, address):
        super().__init__(server, sock, address)
        self.cmds = []
        self.built = False

    def update(self, data):
        self.sendMessage(json.dumps(data))

    def handleMessage(self):
        state = self.data.lower()
        if state in calls.keys():
            self.cmds.append(state)
        else:
            print("Unknown message", self.address, state)

    def send_hist(self, hist):
        self.built = True
        for k in hist:
            self.update(k)

    def handleConnected(self):
        print(self.address, 'connected')

    def handleClose(self):
        print(self.address, 'closed')
