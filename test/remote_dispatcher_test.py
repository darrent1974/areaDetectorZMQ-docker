import os
from bluesky.callbacks.zmq import RemoteDispatcher

REMOTE_DISPATCHER_SUB_PORT = os.environ["REMOTE_DISPATCHER_SUB_PORT"]

print(f'Subscribing to remote dispatcher on port: {REMOTE_DISPATCHER_SUB_PORT}')

d = RemoteDispatcher(f'localhost:{REMOTE_DISPATCHER_SUB_PORT}')
d.subscribe(print)

# when done subscribing things and ready to use:
d.start()  # runs event loop forever