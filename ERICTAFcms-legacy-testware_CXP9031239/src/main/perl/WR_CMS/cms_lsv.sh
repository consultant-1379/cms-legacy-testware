#!/bin/sh

# sample crontab entry is 
# 05 22 * * * /opt/ericsson/atoss/tas/WR_CMS/cms_lsv.sh

. /home/nmsadm/.profile

TIME="`date +%Y%m%d%H%M`"

LOGDIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

LOGDIR="$LOGDIR""CMS_LSV_""$TIME"

##################################################################################################################
#
# master and proxy test cases are more in number so take more time and can not be cover over night in single batch
# So run these Test Cases seperately by scheduling "cms_master_proxy_batch.sh" script in batches.
# e.g. master test case batch 1 : cms_master_proxy_batch.sh -m -b 1
# e.g. proxy test case batch 1 :  cms_master_proxy_batch.sh -p -b 1
#
###################################################################################################################

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 9.9.9.9.9
sleep 360

#/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -m -b 1
#sleep 360
#/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -m -b 2
#sleep 360
#/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -m -b 3
#sleep 360
#/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -m -b 4 this is BIT / FT batch...

#/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 1
#sleep 360
/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 2
sleep 360
/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 3
sleep 360
/opt/ericsson/atoss/tas/WR_CMS/cms_master_proxy_batch.sh -p -b 4
sleep 360

/opt/ericsson/atoss/tas/WR_CMS/cms_stamping.sh


#/opt/ericsson/atoss/tas/WR_CMS/master.pl -t 0.0.0.0.0CLEAN

#/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 8.8.8.8.8

#/opt/ericsson/atoss/tas/WR_CMS/batch_log.sh $TIME CMS_LSV_

#/opt/ericsson/atoss/tas/WR_CMS/report.pl "$LOGDIR" "ehimgar"
