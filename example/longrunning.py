"Dummy example with a Keras model"
from keras import Model
import numpy as np
from callback import KerasRemote
from keras.datasets.mnist import load_data
from keras.utils.np_utils import to_categorical
from keras.layers import Input, Dense, Dropout

(x_train, y_train), (x_test, y_test) = load_data()
x_train = x_train.reshape([-1, 784]).astype('float32') / 255.
x_test = x_test.reshape([-1, 784]).astype('float32') / 255.
y_train = to_categorical(y_train)
y_test = to_categorical(y_test)

x = Input([784])
o = Dense(1023, activation='relu')(x)
o = Dense(128, activation='relu')(o)
o = Dropout(0.2)(o)
o = Dense(64, activation='relu')(o)
o = Dropout(0.2)(o)
o = Dense(32, activation='relu')(o)
o = Dense(10, activation='softmax')(o)
mod = Model(x,o)
mod.compile('sgd','categorical_crossentropy', metrics=['accuracy'])

cbks = [KerasRemote()]
mod.fit(x_train,y_train,validation_data=(x_test, y_test),batch_size=128, epochs=1000000, verbose=0, callbacks=cbks)
