CREATE
(
     parent "ManagedElement=1,ENodeBFunction=1"
     identity CMSAUTO
     moType EUtranCellFDD
     exception none
     nrOfAttributes 9
     tac Integer 77
     physicalLayerCellIdGroup Integer 1
     physicalLayerSubCellId Integer 0
     earfcndl Integer 1
     earfcnul Integer 18001
     cellId Integer 77
     sectorCarrierRef Array Ref "ManagedElement=1,ENodeBFunction=1,SectorCarrier=1"
     bPlmnList Array Struct 1
        nrOfElements 3
                mcc Integer 353 
                mnc Integer 57 
                mncLength Integer 2
)

CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=CMSAUTO"
   identity CMSAUTO 
   moType EUtranFreqRelation
   exception none
   nrOfAttributes 3 
   eutranFrequencyRef Ref "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1"
   createdBy Integer 0
   timeOfCreation String "2012-03-10 12:00:00"
   lastModification Integer 2
)

CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1"
   identity CMSAUTO 
   moType ExternalENodeBFunction
   exception none
   nrOfAttributes 6
   userLabel String CMSAUTO 
   eNBId Integer 161
   createdBy Integer 0
   timeOfCreation String "2012-03-10 12:00:00"
   lastModification Integer 2
   eNodeBPlmnId Struct 
        nrOfElements 3
		mcc Integer 353 
		mnc Integer 57 
		mncLength Integer 2
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=CMSAUTO"
   identity CMSAUTO 
   moType ExternalEUtranCellFDD
   exception none
   nrOfAttributes 7
   userLabel String CMSAUTO
   localCellId Integer 1
   tac Integer 1
   eutranFrequencyRef Ref "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1"
   physicalLayerCellIdGroup Integer 7
   physicalLayerSubCellId Integer 1
   createdBy Integer 0
   timeOfCreation String "2012-03-10 12:00:00"
   lastModification Integer 2

)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=CMSAUTO,EUtranFreqRelation=CMSAUTO"
   identity CMSAUTO 
   moType EUtranCellRelation
   exception none
   nrOfAttributes 3
   neighborCellRef Ref "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=CMSAUTO,ExternalEUtranCellFDD=CMSAUTO"
   createdBy Integer 0
   timeOfCreation String "2012-03-10 12:00:00"
   lastModification Integer 2
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=CMSAUTO"
   identity CMSAUTO
   moType TermPointToENB
   exception none
   nrOfAttributes 2
   createdBy Integer 0
   timeOfCreation String "2012-03-10 12:00:00"
   lastModification Integer 2
)

CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1"
   identity CMSAUTO
   moType UtranFrequency
   exception none
   nrOfAttributes 2
   userLabel String CMSAUTO
   arfcnValueUtranDl Integer 101
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=CMSAUTO"
   identity CMSAUTO
   moType UtranFreqRelation
   exception none
   nrOfAttributes 1
   utranFrequencyRef Ref "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=CMSAUTO"
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=CMSAUTO"
   identity CMSAUTO
   moType ExternalUtranCellFDD
   exception none
   nrOfAttributes 7
   userLabel String CMSAUTO-51111
   lac Integer 9
   rac Integer 9
   cellIdentity Struct
        nrOfElements 2
                rncId Integer 1
                cId Integer 1
   plmnIdentity Struct
        nrOfElements 3
                mcc Integer 353
                mnc Integer  77
                mncLength Integer 2
   createdBy Integer 1
   timeOfCreation String "2012-03-10 12:00:00"
   lastModification Integer 2
   physicalCellIdentity  Integer 77
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=CMSAUTO,UtranFreqRelation=CMSAUTO"
   identity CMSAUTO
   moType UtranCellRelation
   exception none
   nrOfAttributes 1
   externalUtranCellFDDRef Ref "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=CMSAUTO,ExternalUtranCellFDD=CMSAUTO"
   createdBy Integer 1
   timeOfCreation String "2012-03-10 12:00:00"
   lastModification Integer 2   
)


CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1"
   identity CMSAUTO
   moType GeranFreqGroup
   exception none
   nrOfAttributes 2
   userLabel String CMSAUTO
   frequencyGroupId  Integer 77
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=CMSAUTO"
   identity CMSAUTO
   moType GeranFrequency
   exception none
   nrOfAttributes 3
   userLabel String CMSAUTO
   arfcnValueGeranDl Integer 1
   bandIndicator Integer 0
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=CMSAUTO,GeranFrequency=CMSAUTO"
   identity CMSAUTO
   moType ExternalGeranCell
   exception none
   nrOfAttributes 5
   userLabel String CMSAUTO
   cellIdentity Integer 1
   ncc Integer 1
   lac Integer 1
   bcc Integer 1
   plmnIdentity Struct
        nrOfElements 3
                mcc Integer 353
                mnc Integer 84
                mncLength Integer 2
   createdBy Integer 1
   timeOfCreation String "2010-10-05 12:00:00"
   lastModification Integer 2

)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=CMSAUTO"
   identity  CMSAUTO
   moType GeranFreqGroupRelation
   exception none
   nrOfAttributes 1
   geranFreqGroupRef Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=CMSAUTO"
)
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=CMSAUTO,GeranFreqGroupRelation=CMSAUTO"
   identity  CMSAUTO
   moType GeranCellRelation
   exception none
   nrOfAttributes 3
   externalGeranCellRef Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=CMSAUTO,GeranFrequency=CMSAUTO,ExternalGeranCell=CMSAUTO"
   createdBy Integer 1
   timeOfCreation String "2010-10-05 12:00:00"
   lastModification Integer 2
)
