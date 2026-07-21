public with sharing class hlp_triggerChanges {
	
	private List<SObject> triggerNew;
	private Map<Id,SObject> triggerOldMap;
	private Map<String,Set<Id>> changeSetIds = new Map<String,Set<Id>>();

	public hlp_triggerChanges(){
		if(trigger.isUpdate){
			this.triggerNew = Trigger.New;
			this.triggerOldMap = Trigger.OldMap;
		}
	}

	public Boolean isCollectionChanged(String colectionName){
		if(trigger.isUpdate){
			if(changeSetIds.get(colectionName) != null){
				return !changeSetIds.get(colectionName).isEmpty();
			} else {
				return false;
			}
		} else {
			return false;
		}
	}

	public Set<Id> getCollectionChanges(String collectionName){
        return this.changeSetIds.get(collectionName) != null ? this.changeSetIds.get(collectionName) : new Set<Id>();
	}

	public void setNewCollection(String collectionName,List<String> fieldNames){
		Set<Id> ids = new Set<Id>();
        for(SObject newRecord : this.triggerNew) {
            for(String field : fieldNames) {        
                if(this.triggerOldMap.get(newRecord.id).get(field) != newRecord.get(field) ) {   
                   ids.add(newRecord.id); 
                }
            }
        }
        if (!ids.isEmpty()) {
            this.changeSetIds.put(collectionName, ids);
        }
	}
}