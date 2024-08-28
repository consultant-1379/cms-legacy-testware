#!/bin/sh

# sample crontab entry is 
# 05 22 * * * /opt/ericsson/atoss/tas/WR_CMS/cms_stamping.sh

. /home/nmsadm/.profile

TIME="`date +%Y%m%d%H%M`"

LOGDIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

LOGDIR="$LOGDIR""CMS_STAMPING_""$TIME"

/opt/ericsson/atoss/tas/WR_CMS/proxy_pico.pl -t 4.4.1.3.4

/opt/ericsson/atoss/tas/WR_CMS/proxy_pico.pl -t 0.0.0.0.0CLEAN

/opt/ericsson/atoss/tas/WR_CMS/batch_log.sh $TIME CMS_ STAMPING

/opt/ericsson/atoss/tas/WR_CMS/report.pl "$LOGDIR" "ehimgar" STAMP



