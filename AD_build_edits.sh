#!/bin/bash

# Required edits to configure AD
# recommended edits: https://areadetector.github.io/master/install_guide.html

cd ${AREA_DETECTOR}

# Add ZMQ to top-level AD makefile
sed -i '/include $(TOP)\/configure\/RULES_TOP/i \
    ifdef ADZMQ\nDIRS := $(DIRS) $(ADZMQ)\n$(ADZMQ)_DEPEND_DIRS += $(ADCORE)\nendif' \
    Makefile

cd ${AREA_DETECTOR}/configure

# Create local files in AD configure
cp EXAMPLE_RELEASE.local RELEASE.local
cp EXAMPLE_RELEASE_LIBS.local RELEASE_LIBS.local
cp EXAMPLE_RELEASE_PRODS.local RELEASE_PRODS.local
cp EXAMPLE_CONFIG_SITE.local CONFIG_SITE.local

# RELEASE_LIBS.local changes
sed -i s:'SUPPORT=/corvette/home/epics/devel':'SUPPORT=/opt/synApps/support':g RELEASE_LIBS.local
sed -i s:'areaDetector-3-10':'areaDetector-${AD_TAG}':g RELEASE_LIBS.local
sed -i s:'asyn-4-41':'asyn-R4-41':g RELEASE_LIBS.local
sed -i s:'EPICS_BASE=/corvette/usr/local/epics-devel/base-7.0.4':'EPICS_BASE=${EPICS_ROOT}':g RELEASE_LIBS.local

# RELEASE_PRODS.local changes
sed -i s:'areaDetector-3-10':'areaDetector-${AD_TAG}':g RELEASE_PRODS.local
sed -i s:'asyn-4-41':'asyn-R4-41':g RELEASE_PRODS.local
sed -i s:'autosave-5-10':'autosave-R5-10-2':g RELEASE_PRODS.local
sed -i s:'busy-1-7-2':'busy-R1-7-3':g RELEASE_PRODS.local
sed -i s:'calc-3-7-3':'calc-R3-7-4':g RELEASE_PRODS.local
sed -i s:'devIocStats-3-1-16':'iocStats-3-1-16':g RELEASE_PRODS.local
sed -i s:'EPICS_BASE=/corvette/usr/local/epics-devel/base-7.0.4':'EPICS_BASE=${EPICS_ROOT}':g RELEASE_PRODS.local
sed -i s:'seq-2-2-5':'seq-2-2-8':g RELEASE_PRODS.local
sed -i s:'sscan-2-11-3':'sscan-R2-11-4':g RELEASE_PRODS.local
sed -i s:'SUPPORT=/corvette/home/epics/devel':'SUPPORT=/opt/synApps/support':g RELEASE_PRODS.local

# RELEASE.local changes
sed -i s:'#ADSIMDETECTOR=':'ADSIMDETECTOR=':g RELEASE.local 

# Add ZMQ into RELEASE.local and RELEASE_PRODS.local (at an appropriate location)
sed -i '/^#ADRIXSCAM=.*/a ADZMQ=$(AREA_DETECTOR)\/ADZMQ' RELEASE.local
sed -i '/^#ADPLUGINEDGE=.*/a #ADZMQ plugin\nADZMQ=$(AREA_DETECTOR)\/ADZMQ' RELEASE_PRODS.local

# Create ADCore plugin files
cd ${AREA_DETECTOR}/ADCore/iocBoot
cp EXAMPLE_commonPlugins.cmd commonPlugins.cmd
cp EXAMPLE_commonPlugin_settings.req commonPlugin_settings.req

# Add ADZMQ to simDetectorIOC configure/RELEASE (After ADSIMDETECTOR line)
cd ${AREA_DETECTOR}/ADSimDetector/iocs/simDetectorIOC/configure
sed -i '/^ADSIMDETECTOR=.*/a ADZMQ=$(AREA_DETECTOR)\/ADZMQ' RELEASE

# Add ADZMQSupport.dbd file to IOC simDetectorApp/src Makefile 
cd ${AREA_DETECTOR}/ADSimDetector/iocs/simDetectorIOC/simDetectorApp/src
sed -i '/^$(PROD_NAME)_DBD.*/a $(PROD_NAME)_DBD += ADZMQSupport.dbd' Makefile
sed -i '/^PROD_LIBS +=.*/a PROD_LIBS += ADZMQ' Makefile
