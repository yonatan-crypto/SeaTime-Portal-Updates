/**
 *	SEAT-23: Create scheduler
 *	start a scheduled job every some minutes (mdt: TimeToResetBatchScheduler__c) to execure the batch (ResetBatch) who`s reset attempts & token
 *	author Hadar Berman
 *
 *	@class ResetBatchScheduler
 * 	@module ???
 *	@constructor
 */
public with sharing class ResetBatchScheduler {
	
	private static final String LABEL_NAME = 'LOGIN_SETTINGS';
	private static Integer MINUTES_TO_SCHEDULE;
	
	private Current_Scheduled_ID__c prtSettings;
	
	public ResetBatchScheduler(){ //constractor
		prepareMetadata();
	} 
	
    /**
     *	SEAT-23 Create scheduler
     *	author Hadar Berman
     *
     *	@method	 scheduleBatch
     */
	public void scheduleBatch(){
		if(MINUTES_TO_SCHEDULE != null){
				String jobId = System.scheduleBatch(new ResetBatch(), 'Start ResetBatch', MINUTES_TO_SCHEDULE);
				prtSettings.Scheduled_Job_ID__c = jobId;
				update prtSettings;
		}
	}
	
	/**
     *	SEAT-23 Create scheduler
     *	author Hadar Berman
     *
     *	@method	 prepareMetadata
     */
	private void prepareMetadata(){
		List<Portal_Setting__mdt> portalSettingList = [SELECT TimeToResetBatchScheduler__c
    												   FROM Portal_Setting__mdt
    												   WHERE Label LIKE :LABEL_NAME LIMIT 1];
    	if(!portalSettingList.isEmpty()){
    		MINUTES_TO_SCHEDULE = Integer.valueOf(portalSettingList[0].TimeToResetBatchScheduler__c);
    	}
		List<Current_Scheduled_ID__c> customSettingList = [SELECT Id FROM Current_Scheduled_ID__c];
    	if(!customSettingList.isEmpty()){
    		this.prtSettings = customSettingList[0];
    	}
	}
    
}