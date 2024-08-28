#! /bin/bash


CSTESTDIR=/opt/ericsson/nms_cif_cs/etc/unsupported/bin
CSNAME=Seg_masterservice_CS
REGIONCSNAME=Region_CS

NEWSTR=`grep -i IM_ROOT /etc/opt/ericsson/system.env`;
NEWSTR1="$(echo "$NEWSTR" | sed "s/IM_ROOT=//g")"

ROOTMO=${NEWSTR1}"_R"
RNCFUNCTION=${ROOTMO},SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1


if [ $# -lt 1 ] ; then
            echo "Usage : ./delete-masters.sh <option> "
            echo "Usage : <option> valid or plan "
            exit 0
fi

case "$1" in
'valid')
echo "delete in the valid"
#${CSTESTDIR}/cstest -s ${CSNAME}  -ns masterservice dm SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=master
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice dm ${RNCFUNCTION},UtranCell=master 

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},ExternalUtranCell=masterUtran 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},ExternalTdUtranCell=masterUtranTD  
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},ExternalGsmCell=master
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},ExternalUtranPlmn=master
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},ExternalUtranPlmn=masterTD 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},ExternalGsmPlmn=master

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,MbmsServiceArea=master 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,ServiceArea=master 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,RoutingArea=master 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master

;;
'plan')

echo "delete in the plan"

PLANNEDAREA=masters
echo "Try and delete planned area first !!!"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice dp ${PLANNEDAREA}
echo "Test the Deletion of Mo's in PlannedArea"
echo "Create PlannedArea  ${PLANNEDAREA}"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cp ${PLANNEDAREA}

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master
#${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master
#${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,RoutingArea=master
#${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,ServiceArea=master  
#${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},Areas=1,Plmn=master,MbmsServiceArea=master 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},ExternalGsmPlmn=master
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},ExternalGsmCell=master 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},ExternalUtranPlmn=master 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},ExternalUtranCell=masterUtran
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},ExternalTdUtranCell=masterUtranTD  
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${ROOTMO},ExternalUtranPlmn=masterTD 

${CSTESTDIR}/cstest -s ${CSNAME} -p ${PLANNEDAREA} -ns masterservice dm ${RNCFUNCTION},UtranCell=master 
#${CSTESTDIR}/cstest -s ${CSNAME} -p ${PLANNEDAREA} -ns masterservice dm SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=master

;;
*)
	echo "Did Nothing "
        echo "Usage : ./delete-masters.sh <option> "
        echo "Usage : <option> valid or plan "
esac
exit 0
