#! /bin/bash


CSTESTDIR=/opt/ericsson/nms_cif_cs/etc/unsupported/bin
CSNAME=Seg_masterservice_CS
REGIONCSNAME=Region_CS

NEWSTR=`grep -i IM_ROOT /etc/opt/ericsson/system.env`;
NEWSTR1="$(echo "$NEWSTR" | sed "s/IM_ROOT=//g")"

ROOTMO=${NEWSTR1}"_R"
RNCFUNCTION=${ROOTMO},SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1
ERBS=SubNetwork=ONRM_RootMo_R,MeContext=LTE01ERBS00001,ManagedElement=1,ENodeBFunction=1


if [ $# -lt 1 ] ; then
            echo "Usage : ./delete-Idle-proxy.sh <option> "
            echo "Usage : <option> valid or plan "
            exit 0
fi

case "$1" in
'valid')
echo "delete in the valid"

${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC,ExternalCdma2000Cell=proxyC 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC
 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG,GeranFrequency=proxyG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG 

${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ERBS},UtraNetwork=1,UtranFrequency=proxyU

;;
'plan')

echo "delete in the plan"

PLANNEDAREA=proxy
echo "Try and delete planned area first !!!"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice dp ${PLANNEDAREA}
echo "Test the delete of Mo's in PlannedArea"
echo "Create PlannedArea  ${PLANNEDAREA}"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cp ${PLANNEDAREA}

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC,ExternalCdma2000Cell=proxyC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC,Cdma2000Freq=proxyC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ERBS},Cdma2000Network=1,Cdma2000FreqBand=proxyC

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG,GeranFrequency=proxyG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ERBS},GeraNetwork=1,GeranFreqGroup=proxyG 

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ERBS},UtraNetwork=1,UtranFrequency=proxyU

;;
*)
	echo "Did Nothing "
        echo "Usage : ./delete-Idle-proxy.sh <option> "
        echo "Usage : <option> valid or plan "
esac
exit 0
