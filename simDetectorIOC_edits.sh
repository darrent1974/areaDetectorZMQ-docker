#!/bin/bash

# Add ADZMQ plugin & server to IOC startup script
cd ${IOCADSIMDETECTOR}
sed -i '/^set_requestfile_path("$(ADSIMDETECTOR)\/simDetectorApp\/Db").*/i \
NDZMQConfigure("NDZMQ1", "tcp://*:1234", 3, 0, "$(PORT)", 0, -1, -1) \
dbLoadRecords("$(ADCORE)\/ADApp\/Db\/NDPluginBase.template","P=$(PREFIX),R=ZMQ1:,PORT=NDZMQ1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT),NDARRAY_ADDR=0")\n' st_base.cmd

# Turn off settings auto saving
sed -i s:'create_monitor_set(':'#create_monitor_set(':g st_base.cmd 