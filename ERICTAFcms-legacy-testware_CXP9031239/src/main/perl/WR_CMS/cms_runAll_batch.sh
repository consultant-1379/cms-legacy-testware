#!/bin/ksh

. /home/nmsadm/.profile

TIME="`date +%Y%m%d%H%M`"

LOGDIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

LOGDIR="$LOGDIR""CMS_BATCH_""$TIME"

MO=$1

BATCH=$2

BATCH_ID=$3

if [ $# -eq 0 ]
then
   echo "Pass the -p to run proxy batch  e.g. $0 -p"
   echo "Pass the -m to run master batch e.g. $0 -m"
   exit 0
fi

if [ $MO = "-m" ]
then
    /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 9.9.9.9.9	
    /opt/ericsson/atoss/tas/WR_CMS/master.pl -t 4.3.1.2.1 &
    sleep 60
    /opt/ericsson/atoss/tas/WR_CMS/master.pl -t 4.3.2.2.1 &
    sleep 60
    /opt/ericsson/atoss/tas/WR_CMS/master.pl -t 4.3.3.2.1 &
    /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 8.8.8.8.8
elif [ $MO = "-p" ]
then
    /opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 1
    sleep 60
    /opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 2
    sleep 60
    /opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 3
else
   echo "Pass the -p to run proxy batch e.g. $0 -p"
   echo "Pass the -m to run master batch e.g. $0 -m"
   exit 0
fi


