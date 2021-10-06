import sys
import os
import datetime
import zmq
from zmq.devices import monitored_queue
from zhelpers import zpipe
from threading import Thread

# listener thread
# The listener receives all messages flowing through the proxy, on its
# pipe. Here, the pipe is a pair of ZMQ_PAIR sockets that connects
# attached child threads via inproc. In other languages your mileage may vary:

def listener_thread (pipe):

    print('Starting listener thread')

    # Print headers that arrive on the pipe
    while True:
        try:
            header = pipe.recv()
            if sys.hexversion >= 0x03000000:
                header = header.decode()

            print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S: "), header)

        except zmq.ZMQError as e:
            if e.errno == zmq.ETERM:
                break           # Interrupted
        except:
            break


def main():
    ZMQ_PRODUCER_DEVICE_ADDRESS = os.environ['ZMQ_PRODUCER_DEVICE_ADDRESS']
    ZMQ_WORKER_DEVICE_ADDRESS = os.environ['ZMQ_WORKER_DEVICE_ADDRESS']

    print('Bringing up ZMQ monitored-queue device')

    try:
        context = zmq.Context()
        
        pipe = zpipe(context)

        x_subscriber = context.socket(zmq.XSUB)
        #x_subscriber.connect(ZMQ_PRODUCER_DEVICE_ADDRESS)
        x_subscriber.bind(ZMQ_PRODUCER_DEVICE_ADDRESS)

        x_publisher = context.socket(zmq.XPUB)
        x_publisher.bind(ZMQ_WORKER_DEVICE_ADDRESS)

        l_thread = Thread(target=listener_thread, args=(pipe[1],))
        l_thread.start()

        # Create monitored queue
        monitored_queue(x_subscriber, x_publisher, pipe[0], b'pub', b'sub')
    
    except KeyboardInterrupt:
        print ("Interrupted")        
    except Exception as e:
        print(e)
        print('Bringing down ZMQ monitored-queue device')
    finally:
        pass
        x_subscriber.close()
        x_publisher.close()
        pipe.close()
        context.term()                  

if __name__ == "__main__":
    main()