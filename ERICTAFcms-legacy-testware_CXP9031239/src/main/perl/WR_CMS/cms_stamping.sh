#!/bin/sh

# sample crontab entry is 
# 05 22 * * * /opt/ericsson/atoss/tas/WR_CMS/cms_stamping.sh

. /home/nmsadm/.profile

TIME="`date +%Y%m%d%H%M`"

LOGDIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

LOGDIR="$LOGDIR""CMS_STAMPING_""$TIME"

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 9.9.9.9.9

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.1

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.2

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.3

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.4

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.6

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.7

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.8

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.9

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.4.12

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.7.1

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.7.2

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.7.6

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.7.8

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.6 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.7 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.8 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.9 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.10 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.11 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.15 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.16 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.17 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.18 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.19 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.20 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.21 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.24 

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 5.1.1.1.3 

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 4.4.2.1.20 

# /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 5.1.1.1.54 

# /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 5.1.1.1.56

# Run offline online at the end so not to effect other TC's...

# Need to wait 10 min here as TC's above can effect 1.5 
`sleep 600`

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.5 

# /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 5.1.1.1.55

# /opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 5.1.1.1.52 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.2 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.3 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.1 

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.1.27

/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t 1.15.4

/opt/ericsson/atoss/tas/WR_CMS/master.pl -t 0.0.0.0.0CLEAN

/opt/ericsson/atoss/tas/WR_CMS/proxy.pl -t 0.0.0.0.0CLEAN

/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t 8.8.8.8.8

/opt/ericsson/atoss/tas/WR_CMS/batch_log.sh $TIME CMS_ STAMPING

/opt/ericsson/atoss/tas/WR_CMS/report.pl "$LOGDIR" "ehimgar" STAMP

/opt/ericsson/atoss/tas/WR_CMS/report_junit.pl "$LOGDIR" "ehimgar" STAMP

