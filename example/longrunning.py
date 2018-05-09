from keras import Model
import numpy as np
from callback import KerasRemote

from keras.layers import Input, Dense

x = Input([10])
o = Dense(1)
mod = Model(x,o)
mod.compile('sgd','mse')

cbks = [KerasRemote()]
mod.fit(np.ones([100, 10]), np.zeros([100, 1]), epochs=1000000, verbose=0, callbacks=cbks)
