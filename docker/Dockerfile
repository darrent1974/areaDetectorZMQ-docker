ARG BASE_IMAGE

FROM  $BASE_IMAGE
USER  root
WORKDIR /home

# Install libraries from offical repo needed by area detector
#    * libusb (newer faster usb support)
#    * X11 (for GraphicsMagick)
# * xvfb for remote GUI viewing
# * run IOCs in screen sessions (base-os provides)

RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update  -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  \
       libx11-dev \
       locales \
       x11-xserver-utils \
       xorg-dev \
       xvfb \
       && \
    rm -rf /var/lib/apt/lists/*

# Correctly setup locale to supress compilation messages
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

# ============ parent image definitions ============
# additional software packages added here
ENV APP_ROOT="/opt"
# for use with `crontab -e`
ENV EDITOR="nano"
ENV EPICS_HOST_ARCH=linux-x86_64
ENV EPICS_ROOT="${APP_ROOT}/base"
ENV PATH="${PATH}:${EPICS_ROOT}/bin/${EPICS_HOST_ARCH}"
ENV SUPPORT="${APP_ROOT}/synApps/support"
ENV PATH="${PATH}:${SUPPORT}/utils"

# ============ EPICS area detector ============

ARG AREA_DETECTOR_REPO
ARG AREA_DETECTOR_REPO_TAG
ARG ZMQ_REPO
ARG ZMQ_TAG

WORKDIR ${SUPPORT}

ENV AD_TAG=${AREA_DETECTOR_REPO_TAG}
ENV AREA_DETECTOR=${SUPPORT}/areaDetector-${AD_TAG}
ENV ADZMQ=${AREA_DETECTOR}/ADZMQ

# Clone passed areaDetector repo & tag
RUN git clone -b ${AD_TAG} --single-branch ${AREA_DETECTOR_REPO} ./areaDetector-${AD_TAG} && \
    echo "AREA_DETECTOR=\$(SUPPORT)/areaDetector-${AD_TAG}" >>  ${SUPPORT}/configure/RELEASE

WORKDIR ${AREA_DETECTOR}

# Pull required submodules
RUN git submodule update --init --recursive ADCore && \
    git submodule update --init --recursive ADSupport && \
    git submodule update --init --recursive ADSimDetector && \
#    git submodule update --init --recursive ADURL && \
#    git submodule update --init --recursive pvaDriver && \
    git submodule update --init --recursive ADViewers
#    git submodule update --init --recursive ffmpegServer

# Clone ADZMQ into areaDetector modules
RUN git clone -b ${ZMQ_TAG} --single-branch ${ZMQ_REPO}

# Clone ADPluginEdge for testing
#RUN git clone https://github.com/areaDetector/ADPluginEdge.git

# Required edits to configure AD
# recommended edits: https://areadetector.github.io/master/install_guide.html

# Add ZMQ to top-level AD makefile
WORKDIR ${AREA_DETECTOR}
RUN sed -i '/include $(TOP)\/configure\/RULES_TOP/i \
    ifdef ADZMQ\nDIRS := $(DIRS) $(ADZMQ)\n$(ADZMQ)_DEPEND_DIRS += $(ADCORE)\nendif' \
    Makefile

# Create local files in AD configure
WORKDIR ${AREA_DETECTOR}/configure
RUN cp EXAMPLE_RELEASE.local RELEASE.local && \
    cp EXAMPLE_RELEASE_LIBS.local RELEASE_LIBS.local && \
    cp EXAMPLE_RELEASE_PRODS.local RELEASE_PRODS.local && \
    cp EXAMPLE_CONFIG_SITE.local CONFIG_SITE.local

# RELEASE_LIBS.local changes
RUN sed -i s:'SUPPORT=/corvette/home/epics/devel':'SUPPORT=/opt/synApps/support':g RELEASE_LIBS.local && \
    sed -i s:'areaDetector-3-10':'areaDetector-${AD_TAG}':g RELEASE_LIBS.local && \
    sed -i s:'asyn-4-41':'asyn-R4-41':g RELEASE_LIBS.local && \
    sed -i s:'EPICS_BASE=/corvette/usr/local/epics-devel/base-7.0.4':'EPICS_BASE=${EPICS_ROOT}':g RELEASE_LIBS.local

# RELEASE_PRODS.local changes
RUN sed -i s:'areaDetector-3-10':'areaDetector-${AD_TAG}':g RELEASE_PRODS.local && \
    sed -i s:'asyn-4-41':'asyn-R4-41':g RELEASE_PRODS.local && \
    sed -i s:'autosave-5-10':'autosave-R5-10-2':g RELEASE_PRODS.local && \
    sed -i s:'busy-1-7-2':'busy-R1-7-3':g RELEASE_PRODS.local && \
    sed -i s:'calc-3-7-3':'calc-R3-7-4':g RELEASE_PRODS.local && \
    sed -i s:'devIocStats-3-1-16':'iocStats-3-1-16':g RELEASE_PRODS.local && \
    sed -i s:'EPICS_BASE=/corvette/usr/local/epics-devel/base-7.0.4':'EPICS_BASE=${EPICS_ROOT}':g RELEASE_PRODS.local && \
    sed -i s:'seq-2-2-5':'seq-2-2-8':g RELEASE_PRODS.local && \
    sed -i s:'sscan-2-11-3':'sscan-R2-11-4':g RELEASE_PRODS.local && \
    sed -i s:'SUPPORT=/corvette/home/epics/devel':'SUPPORT=/opt/synApps/support':g RELEASE_PRODS.local

# Testing
#RUN sed -i s:'#ADPLUGINEDGE=':'ADPLUGINEDGE=':g RELEASE_PRODS.local 

# RELEASE.local changes
RUN sed -i s:'#ADSIMDETECTOR=':'ADSIMDETECTOR=':g RELEASE.local 
#sed -i s:'#ADURL=':'ADURL=':g RELEASE.local && \
#sed -i s:'#PVADRIVER=':'PVADRIVER=':g RELEASE.local

# testing
#RUN sed -i s:'#ADPLUGINEDGE=':'ADPLUGINEDGE=':g RELEASE.local 

# Add ZMQ into RELEASE.local and RELEASE_PRODS.local (at an appropriate location)
RUN sed -i '/^#ADRIXSCAM=.*/a ADZMQ=$(AREA_DETECTOR)\/ADZMQ' RELEASE.local && \
    sed -i '/^#ADPLUGINEDGE=.*/a #ADZMQ plugin\nADZMQ=$(AREA_DETECTOR)\/ADZMQ' RELEASE_PRODS.local    

# Create ADCore plugin files
WORKDIR ${AREA_DETECTOR}/ADCore/iocBoot
RUN cp EXAMPLE_commonPlugins.cmd commonPlugins.cmd && \
    cp EXAMPLE_commonPlugin_settings.req commonPlugin_settings.req

# Update
#RUN sed -i s:'#file "NDEdge_settings.req"':'file "NDEdge_settings.req"':g commonPlugin_settings.req 
#RUN sed -i s:'#NDEdgeConfigure':'NDEdgeConfigure':g commonPlugins.cmd
#RUN sed -i s:'#dbLoadRecords("$(ADPLUGINEDGE)/db/NDEdge.template"':'dbLoadRecords("$(ADPLUGINEDGE)/db/NDEdge.template"':g commonPlugins.cmd
#RUN sed -i s:'#set_requestfile_path("$(ADPLUGINEDGE)/edgeApp/Db")':'set_requestfile_path("$(ADPLUGINEDGE)/edgeApp/Db")':g commonPlugins.cmd

# update commonPlugin_settings.req & commonPlugins.cmd
#WORKDIR ${AREA_DETECTOR}/ADCore/iocBoot
# ZMQ Setup
#ZMQDriverConfig("ZMQ1", "tcp://127.0.0.1:5432", -1, -1)
#dbLoadRecords("ADBase.template",     "P=$(PREFIX),R=cam1:,PORT=$(PORT),ADDR=0,TIMEOUT=1")
#
#NDZMQConfigure("NDZMQ1", "tcp://*:1234", 3, 0, "ZMQ1", 0, -1, -1)
#dbLoadRecords("$(ADCORE)/ADApp/Db/NDPluginBase.template","P=$(PREFIX),R=ZMQ1:,PORT=NDZMQ1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT),NDARRAY_ADDR=0")
#set_requestfile_path("$(ADZMQ)/zmqApp/Db")

ENV IOCADSIMDETECTOR=${AREA_DETECTOR}/ADSimDetector/iocs/simDetectorIOC/iocBoot/iocSimDetector
RUN ln -s ${IOCADSIMDETECTOR} ${SUPPORT}/iocSimDetector
RUN ln -s ${IOCADSIMDETECTOR} /opt/iocSimDetector
COPY ./workspace/simDetectorIOC/run_simDetectorIOC ${IOCADSIMDETECTOR}/run
COPY ./workspace/simDetectorIOC/runADSimDetector.sh /opt/
RUN cp ${XXX}/iocBoot/iocxxx/softioc/in-screen.sh ${IOCADSIMDETECTOR}/

# Create local files in ADZMQ configure
WORKDIR ${ADZMQ}/configure
RUN echo 'SUPPORT=/opt/synApps/support' >> RELEASE.local && \
    echo 'EPICS_BASE='${EPICS_ROOT} >> RELEASE.local && \
    echo 'ASYN=$(SUPPORT)/asyn-R4-41' >> RELEASE.local && \
    echo 'BUSY=$(SUPPORT)/busy-R1-7-3' >> RELEASE.local && \
    echo 'CALC=$(SUPPORT)/calc-R3-7-4' >> RELEASE.local && \
    echo 'SSCAN=$(SUPPORT)/sscan-R2-11-4' >> RELEASE.local && \
    echo 'AUTOSAVE=$(SUPPORT)/autosave-R5-10-2' >> RELEASE.local && \
    echo 'AREA_DETECTOR='${AREA_DETECTOR} >> RELEASE.local && \
    echo 'ADBINARIES=$(AREA_DETECTOR)/ADBinaries' >> RELEASE.local && \
    echo 'ADCORE=$(AREA_DETECTOR)/ADCore' >> RELEASE.local

RUN ls ${ADZMQ}/configure
RUN cat RELEASE.local

ENV IOCADZMQ=${AREA_DETECTOR}/ADZMQ/iocs/zmqIOC/iocBoot/iocZMQ
RUN ln -s ${IOCADZMQ} ${SUPPORT}/iocZMQ && \
    ln -s ${IOCADZMQ} /opt/iocZMQ
RUN cp ${XXX}/iocBoot/iocxxx/softioc/in-screen.sh ${IOCADZMQ}/

WORKDIR ${SUPPORT}
RUN make release && \
    bash /opt/copy_screens.sh ${SUPPORT} /opt/screens && \
    bash /opt/modify_adl_in_ui_files.sh  /opt/screens/ui

# Build it all
WORKDIR ${AREA_DETECTOR}
#RUN make -j8 all 2>&1

WORKDIR ${SUPPORT}
CMD ["/bin/bash"]
