/**
 *	SEAT-25 Create vf with button to start the scheduled job "ResetBatchScheduler" in the first time
 *	author Hadar Berman
 *
 *	@class PortalSettingsPageControllerTest
 *	@async
 */
@IsTest 
public with sharing class PortalSettingsPageControllerTest {
	
	static testmethod void executeSchedulerTest() {
		
		PortalSettingsPageController ctrlWithNullCustomSetting = new PortalSettingsPageController();
		ctrlWithNullCustomSetting.executeScheduler();
		
		//prepare data
		Current_Scheduled_ID__c custSetting = new Current_Scheduled_ID__c();
		custSetting.Scheduled_Job_ID__c = '08e2600000Cljpr';
		insert custSetting;
		
		PortalSettingsPageController PSController = new PortalSettingsPageController();
		PSController.executeScheduler();
		
	}
    
}