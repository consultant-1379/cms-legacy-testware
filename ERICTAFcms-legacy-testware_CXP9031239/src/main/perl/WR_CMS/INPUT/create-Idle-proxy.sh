#! /bin/bash


CSTESTDIR=/opt/ericsson/nms_cif_cs/etc/unsupported/bin
CSNAME=Seg_masterservice_CS
REGIONCSNAME=Region_CS

NEWSTR=`grep -i IM_ROOT /etc/opt/ericsson/system.env`;
NEWSTR1="$(echo "$NEWSTR" | sed "s/IM_ROOT=//g")"

ROOTMO=${NEWSTR1}"_R"
RNCFUNCTION=${ROOTMO},SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1
ERBS=SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,ENodeBFunction=1


if [ $# -lt 1 ] ; then
            echo "Usage : ./create-Idle-proxy.sh <option> "
            echo "Usage : <option> valid or plan "
            exit 0
fi

case "$1" in
'valid')
echo "valid"

${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC -attr hrpdBandClass 17 -attr userLabel proxyC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC -attr freqCdma 17 -attr userLabel proxyC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC,ExternalCdma2000Cell=proxyC -attr pnOffset 17 -attr userLabel proxyC -attr cellGlobalIdHrpd "2001:0db8:0000:0000:0000:0000:1428:07ab"

${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG -attr frequencyGroupId 17 -attr userLabel proxyG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG,GeranFrequency=proxyG -attr arfcnValueGeranDl 17 -attr bandIndicator 1 -attr userLabel proxyG

${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ERBS},UtraNetwork=1,UtranFrequency=proxyU -attr arfcnValueUtranDl 17 -attr userLabel proxyU





;;
'plan')

echo "plan"

PLANNEDAREA=proxy
echo "Try and delete planned area first !!!"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice dp ${PLANNEDAREA}
echo "Test the Creation of Mo's in PlannedArea"
echo "Create PlannedArea  ${PLANNEDAREA}"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cp ${PLANNEDAREA}

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC -attr hrpdBandClass 17 -attr userLabel proxy
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC -attr freqCdma 17 -attr userLabel proxyC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC,ExternalCdma2000Cell=proxyC -attr pnOffset 17 -attr userLabel proxyC -attr cellGlobalIdHrpd "2001:0db8:0000:0000:0000:0000:1428:07ab"

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG -attr frequencyGroupId 17 -attr userLabel proxyG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG,GeranFrequency=proxyG -attr arfcnValueGeranDl 17 -attr bandIndicator 1 -attr userLabel proxyG

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm  ${ERBS},UtraNetwork=1,UtranFrequency=proxyU -attr arfcnValueUtranDl 17 -attr userLabel proxyU

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm  ${ERBS},EUtraNetwork=1,ExternalENodeBFunction=2,ExternalEUtranCellFDD=proxyEC -attr eutranFrequencyRef SubNetwork=ONRM_RootMo_R,SubNetwork=LTE01,MeContext=LTE01ERBS00001,ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1 -attr localCellId 14 -attr physicalLayerCellIdGroup 14 -attr physicalLayerSubCellId 2 -attr tac 14

echo "Finished creating in  ${PLANNEDAREA}"

;;
*)
	echo "Did Nothing "
        echo "Usage : ./create-Idle-proxy.sh <option> "
        echo "Usage : <option> valid or plan "
esac
exit 0
