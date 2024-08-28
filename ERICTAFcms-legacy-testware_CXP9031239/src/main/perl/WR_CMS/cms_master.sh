#!/bin/sh

# sample crontab entry is 
# 05 22 * * * /opt/ericsson/atoss/tas/WR_CMS/cms_stamping.sh

. /home/nmsadm/.profile

server=hostname

TIME="`date +%Y%m%d%H%M`"

LOGDIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

LOGDIR="$LOGDIR""CMS_MASTER_"."$server"."_"."$TIME"

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 9.9.9.9.9

/opt/ericsson/atoss/tas/WR_CMS/master.pl -a

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 8.8.8.8.8

/opt/ericsson/atoss/tas/WR_CMS/batch_log.sh $TIME CMS_ MASTER

/opt/ericsson/atoss/tas/WR_CMS/report.pl "$LOGDIR" "ehimgar" MASTER

