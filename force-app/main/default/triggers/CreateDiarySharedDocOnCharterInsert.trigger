trigger CreateDiarySharedDocOnCharterInsert on charters__c (after insert) {
	CreateDiarySharedDocOnCharterInsert_Apex.insertChildRecord(trigger.new);
}