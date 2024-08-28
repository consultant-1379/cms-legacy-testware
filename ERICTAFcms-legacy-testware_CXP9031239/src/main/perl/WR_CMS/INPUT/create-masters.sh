#! /bin/bash


CSTESTDIR=/opt/ericsson/nms_cif_cs/etc/unsupported/bin
CSNAME=Seg_masterservice_CS
REGIONCSNAME=Region_CS

NEWSTR=`grep -i IM_ROOT /etc/opt/ericsson/system.env`;
NEWSTR1="$(echo "$NEWSTR" | sed "s/IM_ROOT=//g")"

ROOTMO=${NEWSTR1}"_R"
RNCFUNCTION=${ROOTMO},SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1

#echo "${ROOTMO}"
#echo "${RNCFUNCTION}"
#exit 0

if [ $# -lt 1 ] ; then
            echo "Usage : ./create-masters.sh <option> "
            echo "Usage : <option> valid or plan "
            exit 0
fi




case "$1" in
'valid')
echo "valid"

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master -attr mcc 777 -attr mnc 777 -attr mncLength 3 -attr userLabel master
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master -attr userLabel master -attr lac 777 -attr t3212 254
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,RoutingArea=master -attr userLabel master -attr rac 77 -attr nmo 1
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,ServiceArea=master -attr userLabel master -attr sac 211 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,MbmsServiceArea=master -attr sac 211 -attr userLabel master
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},ExternalGsmPlmn=master -attr userLabel master -attr mcc 776 -attr mnc 776 -attr mncLength 3
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},ExternalGsmCell=master -attr parentSystem ${ROOTMO},ExternalGsmPlmn=master -attr lac 776 -attr cellIdentity 776  -attr mcc 776 -attr mnc 776 -attr mncLength 3 -attr ncc 2 -attr bcc 2 -attr bandIndicator 0 -attr bcchFrequency 2 -attr userLabel master

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},ExternalUtranPlmn=masterTD -attr userLabel masterTD -attr mcc 775 -attr mnc 775 -attr mncLength 3
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},ExternalTdUtranCell=masterUtranTD  -attr tdCellParameterId 1 -attr tdUarfcn 9400 -attr parentSystem ${ROOTMO},ExternalUtranPlmn=masterTD -attr mcc 775 -attr mnc 775 -attr mncLength 3 cId 28 -attr rncId 102 -attr lac 775 -attr rac 75 -attr userLabel masterUtranTD

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},ExternalUtranPlmn=master -attr userLabel master -attr mcc 774 -attr mnc 774 -attr mncLength 3
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -ns masterservice cm ${ROOTMO},ExternalUtranCell=masterUtran -attr parentSystem ${ROOTMO},ExternalUtranPlmn=master -attr mcc 774 -attr mnc 774 -attr mncLength 3 -attr cId 28 -attr rncId 102 -attr uarfcnUl 112 -attr uarfcnDl 537 -attr lac 775 -attr primaryScramblingCode 2 -attr rac 75 -attr userLabel masterUtran
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cm ${RNCFUNCTION},UtranCell=master -attr cId 7777 -attr localCellId 3  -attr utranCellIubLink ${RNCFUNCTION},IubLink=1 -attr lac 777 -attr sac 777 -attr rac 77 -attr tCell 1 -attr uarfcnUl 12 -attr uarfcnDl 437 -attr primaryScramblingCode 2 -attr sib1PlmnScopeValueTag 1 -attr userLabel master

#${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cm SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=master -attr administrativeState 1 -attr operationalState 1 -attr dlChannelBandwidth 3000 -attr cellId 777 -attr tac 188 -attr earfcnul 18001 -attr physicalLayerSubCellId 1 -attr physicalLayerCellIdGroup 101 -attr earfcndl 1200 -attr userLabel master -attr sectorFunctionRef SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,SectorEquipmentFunction=1


;;
'plan')

echo "plan"

PLANNEDAREA=masters
echo "Try and delete planned area first !!!"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice dp ${PLANNEDAREA}
echo "Test the Creation of Mo's in PlannedArea"
echo "Create PlannedArea  ${PLANNEDAREA}"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cp ${PLANNEDAREA}

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master -attr mcc 777 -attr mnc 777 -attr mncLength 3 -attr userLabel master
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master -attr userLabel master -attr lac 777 -attr t3212 254
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,RoutingArea=master -attr userLabel master -attr rac 77 -attr nmo 1
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,LocationArea=master,ServiceArea=master -attr userLabel master -attr sac 211 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},Areas=1,Plmn=master,MbmsServiceArea=master -attr sac 211 -attr userLabel master
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},ExternalGsmPlmn=master -attr userLabel master -attr mcc 776 -attr mnc 776 -attr mncLength 3
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},ExternalGsmCell=master -attr parentSystem ${ROOTMO},ExternalGsmPlmn=master -attr lac 776 -attr cellIdentity 776  -attr mcc 776 -attr mnc 776 -attr mncLength 3 -attr ncc 2 -attr bcc 2 -attr bandIndicator 0 -attr bcchFrequency 2 -attr userLabel master

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},ExternalUtranPlmn=masterTD -attr userLabel masterTD -attr mcc 775 -attr mnc 775 -attr mncLength 3
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},ExternalTdUtranCell=masterUtranTD  -attr tdCellParameterId 1 -attr tdUarfcn 9400 -attr parentSystem ${ROOTMO},ExternalUtranPlmn=masterTD -attr mcc 775 -attr mnc 775 -attr mncLength 3 cId 28 -attr rncId 102 -attr lac 775 -attr rac 75 -attr userLabel masterTD


${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},ExternalUtranPlmn=master -attr userLabel master -attr mcc 774 -attr mnc 774 -attr mncLength 3
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${ROOTMO},ExternalUtranCell=masterUtran -attr parentSystem ${ROOTMO},ExternalUtranPlmn=master -attr mcc 774 -attr mnc 774 -attr mncLength 3 -attr cId 28 -attr rncId 102 -attr uarfcnUl 112 -attr uarfcnDl 537 -attr lac 775 -attr primaryScramblingCode 2 -attr rac 75 -attr userLabel master

${CSTESTDIR}/cstest -s ${CSNAME} -p ${PLANNEDAREA} -ns masterservice cm ${RNCFUNCTION},UtranCell=master -attr cId 7777 -attr localCellId 3 -attr utranCellIubLink ${RNCFUNCTION},IubLink=1 -attr lac 777 -attr sac 777 -attr rac 77 -attr tCell 1 -attr uarfcnUl 12 -attr uarfcnDl 437 -attr primaryScramblingCode 2 -attr sib1PlmnScopeValueTag 1 -attr userLabel master

#${CSTESTDIR}/cstest -s ${CSNAME} -p ${PLANNEDAREA} -ns masterservice cm SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=master -attr administrativeState 1 -attr operationalState 1 -attr dlChannelBandwidth 3000 -attr cellId 177 -attr tac 188 -attr earfcnul 18001 -attr physicalLayerSubCellId 1 -attr physicalLayerCellIdGroup 101 -attr earfcndl 1200 -attr userLabel master -attr sectorFunctionRef SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,SectorEquipmentFunction=1

echo "Finished creating in  ${PLANNEDAREA}"

;;
*)
	echo "Did Nothing "
        echo "Usage : ./create-masters.sh <option> "
        echo "Usage : <option> valid or plan "
esac
exit 0
