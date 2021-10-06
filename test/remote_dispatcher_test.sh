#!/bin/bash

# Start proxy in background
bluesky-0MQ-proxy ${REMOTE_DISPATCHER_PUB_PORT} ${REMOTE_DISPATCHER_SUB_PORT} &

python remote_dispatcher_test.py