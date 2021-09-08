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
    git submodule update --init --recursive ADViewers

# Clone ADZMQ into areaDetector modules
RUN git clone -b ${ZMQ_TAG} --single-branch ${ZMQ_REPO}

ENV IOCADSIMDETECTOR=${AREA_DETECTOR}/ADSimDetector/iocs/simDetectorIOC/iocBoot/iocSimDetector
RUN ln -s ${IOCADSIMDETECTOR} ${SUPPORT}/iocSimDetector && \
    ln -s ${IOCADSIMDETECTOR} /opt/iocSimDetector

# Execute script to modify AD and configure for use with ZMQ
COPY AD_build_edits.sh /tmp/
RUN /tmp/AD_build_edits.sh

WORKDIR ${SUPPORT}
RUN make release && \
    bash /opt/copy_screens.sh ${SUPPORT} /opt/screens && \
    bash /opt/modify_adl_in_ui_files.sh  /opt/screens/ui

# Build it all
WORKDIR ${AREA_DETECTOR}
RUN make -j8 all 2>&1

COPY ./IOCs/simDetectorIOC/run_simDetectorIOC ${IOCADSIMDETECTOR}/run
COPY ./IOCs/simDetectorIOC/runADSimDetector.sh /opt/
COPY ./IOCs/simDetectorIOC/auto_settings.req ${IOCADSIMDETECTOR}/ 
RUN cp ${XXX}/iocBoot/iocxxx/softioc/in-screen.sh ${IOCADSIMDETECTOR}/

# Execute script to modify simDetectorIOC startup commands
COPY simDetectorIOC_edits.sh /tmp
RUN /tmp/simDetectorIOC_edits.sh

WORKDIR ${SUPPORT}
CMD ["/bin/bash"]
