#!/bin/ksh

# sample crontab entry is 
# 05 22 * * * /opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 1

. /home/nmsadm/.profile

TIME="`date +%Y%m%d%H%M`"

MO=$1
BATCH=$2
BATCH_ID=$3
batch_type="CMS_BATCH_"

if [ $# -eq 0 ]
then
   echo "Pass the -p to run proxy batch with -b and batch id e.g. $0 -p -b 1"
   echo "Pass the -m to run master batch with -b and batch id e.g. $0 -m -b 1"
   exit 0
fi

GDIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

if [ $MO = "-m" ]
then
    batch_type="CMS_MASTER_BATCH_"
    LOGDIR="$GDIR""$batch_type""$BATCH_ID""_""$TIME"

    /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 9.9.9.9.9	
    /opt/ericsson/atoss/tas/WR_CMS/master.pl $BATCH $BATCH_ID
    /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 8.8.8.8.8
    
elif [ $MO = "-p" ]
then
    batch_type="CMS_PROXY_BATCH_"
    LOGDIR="$GDIR""$batch_type""$BATCH_ID""_""$TIME"

    /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 9.9.9.9.9
    /opt/ericsson/atoss/tas/WR_CMS/proxy.pl $BATCH $BATCH_ID
    /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 8.8.8.8.8
else
   echo "Pass the -p to run proxy batch with -b and batch id e.g. $0 -p -b 1"
   echo "Pass the -m to run master batch with -b and batch id e.g. $0 -m -b 1"
   exit 0
fi

/opt/ericsson/atoss/tas/WR_CMS/batch_log.sh $TIME $batch_type $BATCH_ID
/opt/ericsson/atoss/tas/WR_CMS/report.pl "$LOGDIR" "ehimgar" "$batch_type" "$BATCH_ID"
/opt/ericsson/atoss/tas/WR_CMS/report_junit.pl "$LOGDIR" "ehimgar" "$batch_type" "$BATCH_ID"

