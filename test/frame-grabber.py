import sys
import datetime
import zmq
import random
import os
import numpy as np
import json
import matplotlib.pyplot as plt


def main():
    ZMQ_SUBSCRIBER_ADDRESS = os.environ["ZMQ_SUBSCRIBER_ADDRESS"]
    subscriber_id = random.randrange(1, 10005)

    print(f"Bringing up frame-grabber: #{subscriber_id}")

    context = zmq.Context()

    # receive work
    subscriber = context.socket(zmq.SUB)
    subscriber.connect(ZMQ_SUBSCRIBER_ADDRESS)
    subscriber.setsockopt(zmq.SUBSCRIBE, b'')

    while True:
        try:
            #header = worker_receiver.recv()

            # receive
            [header, data] = subscriber.recv_multipart()

            if sys.hexversion >= 0x03000000:
                header = header.decode()

            #print(header)
            info = json.loads(header)

            # receive data
            data = np.frombuffer(data, dtype=str(info['type']))

            # Reshape data into 2D image        
            data.shape = info['shape']

            #print(data.sum(),data)
            print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S: "), header)

            # display image
            #plt.imshow(data, cmap=plt.cm.gray)
        except:
            break

if __name__ == "__main__":
    main()