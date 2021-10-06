import sys
import os
import datetime
import zmq

def main():
    ZMQ_PUBLISHER_DEVICE_ADDRESS = os.environ['ZMQ_PUBLISHER_DEVICE_ADDRESS']
    ZMQ_SUBSCRIBER_DEVICE_ADDRESS = os.environ['ZMQ_SUBSCRIBER_DEVICE_ADDRESS']

    print('Bringing up ZMQ forwarder device')

    try:
        context = zmq.Context()
        
        # Socket facing clients
        frontend = context.socket(zmq.SUB)
        frontend.bind(ZMQ_PUBLISHER_DEVICE_ADDRESS)
        frontend.setsockopt(zmq.SUBSCRIBE, b'')
       
        # Socket facing services
        backend = context.socket(zmq.PUB)
        backend.bind(ZMQ_SUBSCRIBER_DEVICE_ADDRESS)

        # Create forwarder device
        zmq.device(zmq.FORWARDER, frontend, backend)
      
    except Exception as e:
        print(e)
        print('Bringing down ZMQ forwarder device')
    finally:
        pass
        frontend.close()
        backend.close()
        context.term()                  

if __name__ == "__main__":
    main()