#!/bin/sh

# sample crontab entry is 
# 05 22 * * * /opt/ericsson/atoss/tas/WR_CMS/cms_BIT_FT.sh

. /home/nmsadm/.profile

TIME="`date +%Y%m%d%H%M`"

LOGDIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

LOGDIR="$LOGDIR""CMS_BIT_FT_""$TIME"

##################################################################################################################
#
# master and proxy test cases are more in number so take more time and can not be cover over night in single batch
# 2 new bactes have been created just for BIT master batch 4 and proxy batch 5 
#
###################################################################################################################

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 9.9.9.9.9

/opt/ericsson/atoss/tas/WR_CMS/master.pl -t 0.0.0.0.0CLEAN
/opt/ericsson/atoss/tas/WR_CMS/proxy.pl -t 0.0.0.0.0CLEAN

/opt/ericsson/atoss/tas/WR_CMS/master.pl -b 4 

/opt/ericsson/atoss/tas/WR_CMS/proxy.pl -b 5 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.1

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.2

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.3

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.4

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.6

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.7

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.12

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.7.1

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.7.6

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.7.8

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.6 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.8 


/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.15

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.16 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.17 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.18 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.19 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.20 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.21 


/opt/ericsson/atoss/tas/WR_CMS/master.pl -t 0.0.0.0.0CLEAN
/opt/ericsson/atoss/tas/WR_CMS/proxy.pl -t 0.0.0.0.0CLEAN


/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 8.8.8.8.8

/opt/ericsson/atoss/tas/WR_CMS/batch_log.sh $TIME CMS_BIT_ FT

/opt/ericsson/atoss/tas/WR_CMS/report.pl "$LOGDIR" "ehimgar" BIT
