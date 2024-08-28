#! /bin/bash


CSTESTDIR=/opt/ericsson/nms_cif_cs/etc/unsupported/bin
CSNAME=Seg_masterservice_CS
REGIONCSNAME=Region_CS

NEWSTR=`grep -i IM_ROOT /etc/opt/ericsson/system.env`;
NEWSTR1="$(echo "$NEWSTR" | sed "s/IM_ROOT=//g")"

ROOTMO=${NEWSTR1}"_R"
RNCFUNCTION=${ROOTMO},SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1


if [ $# -lt 1 ] ; then
            echo "Usage : ./create-Idle-master.sh <option> "
            echo "Usage : <option> valid or plan "
            exit 0
fi

case "$1" in
'valid')
echo "valid"

${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ROOTMO},ExternalCdma2000FreqBand=masterC -attr hrpdBandClass 12 -attr userLabel masterC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ROOTMO},ExternalCdma2000FreqBand=masterC,ExternalCdma2000Freq=masterC -attr freqCdma 12 -attr userLabel masterC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ROOTMO},ExternalCdma2000Plmn=1,ExternalCdma2000Cell=masterC -attr pnOffset 12 -attr userLabel masterC -attr cellGlobalIdHrpd "2009:0db8:2010:2011:2012:2013:1428:07ab" -attr externalCdma2000FreqRef ${ROOTMO},ExternalCdma2000FreqBand=masterC,ExternalCdma2000Freq=masterC

${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ROOTMO},ExternalGsmFreqGroup=masterG -attr frequencyGroupId 12 -attr userLabel masterG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ROOTMO},ExternalGsmFreq=masterG -attr arfcnValueGeranDl 12 -attr bandIndicator 1 -attr externalGsmFreqGroupId 12 -attr userLabel masterG

${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ROOTMO},ExternalUtranFreq=masterU -attr arfcnValueUtranDl 12 -attr userLabel masterU

${CSTESTDIR}/cstest -s ${REGIONCSNAME} cm ${ROOTMO},FreqManagement=1,ExternalEutranFrequency=masterG -attr earfcnDl 1212 -attr userLabel masterG


;;
'plan')

echo "plan"

PLANNEDAREA=masters
echo "Try and delete planned area first !!!"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice dp ${PLANNEDAREA}
echo "Test the Creation of Mo's in PlannedArea"
echo "Create PlannedArea  ${PLANNEDAREA}"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cp ${PLANNEDAREA}


${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ROOTMO},ExternalCdma2000FreqBand=masterC -attr hrpdBandClass 12 -attr userLabel masterC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ROOTMO},ExternalCdma2000FreqBand=masterC,ExternalCdma2000Freq=masterC -attr freqCdma 12 -attr userLabel masterC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ROOTMO},ExternalCdma2000Plmn=1,ExternalCdma2000Cell=masterC -attr pnOffset 12 -attr userLabel masterC -attr cellGlobalIdHrpd "2009:0db8:2010:2011:2012:2013:1428:07ab" -attr externalCdma2000FreqRef ${ROOTMO},ExternalCdma2000FreqBand=masterC,ExternalCdma2000Freq=masterC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ROOTMO},ExternalUtranFreq=masterU -attr arfcnValueUtranDl 12 -attr userLabel masterU
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ROOTMO},ExternalGsmFreqGroup=masterG -attr frequencyGroupId 12 -attr userLabel masterG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ROOTMO},ExternalGsmFreq=masterG -attr arfcnValueGeranDl 12 -attr bandIndicator 1 -attr externalGsmFreqGroupId 12 -attr userLabel masterG

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} cm ${ROOTMO},FreqManagement=1,ExternalEutranFrequency=masterG -attr earfcnDl 1212 -attr userLabel masterG

echo "Finished creating in  ${PLANNEDAREA}"

;;
*)
	echo "Did Nothing "
        echo "Usage : ./create-masters.sh <option> "
        echo "Usage : <option> valid or plan "
esac
exit 0
