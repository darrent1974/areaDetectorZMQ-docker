import sys
import datetime
import zmq
import random
import os
import numpy as np
import json


def consumer():
    ZMQ_WORKER_ADDRESS = os.environ["ZMQ_WORKER_ADDRESS"]
    worker_id = random.randrange(1, 10005)

    print(f"Bringin up worker: #{worker_id}")

    context = zmq.Context()

    # receive work
    worker_receiver = context.socket(zmq.PULL)
    worker_receiver.connect(ZMQ_WORKER_ADDRESS)

    while True:
        # receive header
        try:
            header = worker_receiver.recv()
            if sys.hexversion >= 0x03000000:
                header = header.decode()
        except:
            break
        #print(header)
        info = json.loads(header)

        # receive data
        data = np.frombuffer(worker_receiver.recv(), dtype=str(info['type']))
        #data.reshape(info['shape'])
        #print(data.sum(),data)
        print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S: "), header)


consumer()