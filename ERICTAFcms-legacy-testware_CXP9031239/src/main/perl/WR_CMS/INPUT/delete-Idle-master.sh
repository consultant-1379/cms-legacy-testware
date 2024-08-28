#! /bin/bash


CSTESTDIR=/opt/ericsson/nms_cif_cs/etc/unsupported/bin
CSNAME=Seg_masterservice_CS
REGIONCSNAME=Region_CS

NEWSTR=`grep -i IM_ROOT /etc/opt/ericsson/system.env`;
NEWSTR1="$(echo "$NEWSTR" | sed "s/IM_ROOT=//g")"

ROOTMO=${NEWSTR1}"_R"
RNCFUNCTION=${ROOTMO},SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1


if [ $# -lt 1 ] ; then
            echo "Usage : ./delete-Idle-master.sh <option> "
            echo "Usage : <option> valid or plan "
            exit 0
fi

case "$1" in
'valid')
echo "valid"
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ROOTMO},ExternalCdma2000Plmn=1,ExternalCdma2000Cell=masterC 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ROOTMO},ExternalCdma2000FreqBand=masterC,ExternalCdma2000Freq=masterC
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ROOTMO},ExternalCdma2000FreqBand=masterC

${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ROOTMO},ExternalUtranFreq=masterU
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ROOTMO},ExternalGsmFreq=masterG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ROOTMO},ExternalGsmFreqGroup=masterG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} dm ${ROOTMO},FreqManagement=1,ExternalEutranFrequency=masterG

;;
'plan')

echo "plan"

PLANNEDAREA=masters
echo "Try and delete planned area first !!!"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice dp ${PLANNEDAREA}
echo "Test the delete of Mo's in PlannedArea"
echo "Create PlannedArea  ${PLANNEDAREA}"
${CSTESTDIR}/cstest -s ${CSNAME} -ns masterservice cp ${PLANNEDAREA}

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ROOTMO},ExternalCdma2000Plmn=1,ExternalCdma2000Cell=masterC 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ROOTMO},ExternalCdma2000FreqBand=masterC,ExternalCdma2000Freq=masterC 
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ROOTMO},ExternalCdma2000FreqBand=masterC

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ROOTMO},ExternalUtranFreq=masterU
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ROOTMO},ExternalGsmFreq=masterG
${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ROOTMO},ExternalGsmFreqGroup=masterG

${CSTESTDIR}/cstest -s ${REGIONCSNAME} -p ${PLANNEDAREA} dm ${ROOTMO},FreqManagement=1,ExternalEutranFrequency=masterG


echo "Finished delete in  ${PLANNEDAREA}"

;;
*)
	echo "Did Nothing "
        echo "Usage : ./delete-masters.sh <option> "
        echo "Usage : <option> valid or plan "
esac
exit 0
