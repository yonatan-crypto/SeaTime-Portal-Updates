/**
 *	SEAT-25 Create vf with button to start the scheduled job "ResetBatchScheduler" in the first time
 *	controller of PortalSettings Page 
 *	author Hadar Berman
 *
 *	@class PortalSettingsPageController
 *	@constractor
 */
public with sharing class PortalSettingsPageController {
	
	public String message {get;set;}
	private Current_Scheduled_ID__c custSettings;
	
	public PortalSettingsPageController(){
		getCustomSettings();
	}
	
	/**
	 *	SEAT-25 Create vf with button to start the scheduled job "ResetBatchScheduler" in the first time
	 *	start the scheduled job "start ResetBatch" if it`s not started yet
	 *	author Hadar Berman
	 *
	 *	@method executeScheduler
	 *	@return PageReference
	 */
	public PageReference executeScheduler(){
		Boolean isExistSchedule = isExistSchedule();
		this.message = isExistSchedule == false ? restartScheduler() : 'The scheduled job "start ResetBatch" is already started';
		return null;
	}
	
	/**
	 *	SEAT-25 Create vf with button to start the scheduled job "ResetBatchScheduler" in the first time
	 *	restart a new scheduled job 
	 *	author Hadar Berman
	 *
	 *	@method restartScheduler
	 */
    private String restartScheduler(){
    	String messageToReturn;
        try{
    	ResetBatchScheduler sch = new ResetBatchScheduler();
    	sch.scheduleBatch();
    	messageToReturn = 'The scheduled job started';
    	}catch(Exception e){
    		messageToReturn = e.getMessage();
    	}
        return messageToReturn;
    }
    
    /**
	 *	SEAT-25 Create vf with button to start the scheduled job "ResetBatchScheduler" in the first time
	 *	get custom setting with id of current scheduled job
	 *	author Hadar Berman
	 *
	 *	@method getCustomSettings
	 */
    private void getCustomSettings(){
    	List<Current_Scheduled_ID__c> customSettingList = [SELECT Id, Scheduled_Job_ID__c  
    													   FROM Current_Scheduled_ID__c LIMIT 1];
    	if(!customSettingList.isEmpty()){
    		this.custSettings = customSettingList[0];
    	}
    }
    
    /**
	 *	SEAT-25 Create vf with button to start the scheduled job "ResetBatchScheduler" in the first time
	 *	check if there is active schedulued job 
	 *	author Hadar Berman
	 *
	 *	@method isExistSchedule
	 */
    private Boolean isExistSchedule(){
    	if(this.custSettings == null){
			return false;
		}
    	Id itemID = this.custSettings.Scheduled_Job_ID__c;
    	List<CronTrigger> ctList = [SELECT TimesTriggered, NextFireTime
    								FROM CronTrigger 
    								WHERE Id = :itemID];
 		if(ctList.isEmpty()){
 			return false;
 		}
 		return true;
    }
    
}