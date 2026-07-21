/** 
	* @author hadar berman
	* @since NOV 2017
	* @desc batch to update Login_Token__c, Login_Attempt__c, VerificationCode_Attempt__c in Account
	*/
global with sharing class ResetBatch implements Database.Batchable<sObject> {
	
	private static final Datetime DATENOW = System.now();
	private static final String QUERY = 'SELECT Id,Name,Reset_Attempts_On__c,Session_Timeout__c FROM Account WHERE Reset_Attempts_On__c < : DATENOW OR Session_Timeout__c < : DATENOW';

	private List<Account> sessionCaseList = new List<Account>();
	private List<Account> attemptsCaseList = new List<Account>();
	
	public ResetBatch(){} //constractor
	
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(QUERY);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
    	resetAttemptsAndSession(scope);
    	update scope;
    }
    
    global void finish(Database.BatchableContext BC){
    	restartScheduler();
    }
    
    /** 
    * @desc update the required fields 
    * @param List<Account> scope
    * @return 
    */
    private void resetAttemptsAndSession(List<Account> scope){
    	splitScope(scope);
    	if(!this.sessionCaseList.isEmpty()){
    		for(Account accountItem : this.sessionCaseList){
    			accountItem.Login_Token__c = null;
    			accountItem.Session_Timeout__c = null;
    		}
    	}
    	if(!this.attemptsCaseList.isEmpty()){
    		for(Account accountItem : this.attemptsCaseList){
    			accountItem.Login_Attempt__c = 0;
    			accountItem.VerificationCode_Attempt__c = 0;
    			accountItem.Reset_Attempts_On__c = null;
    		}
    	}
    }
    
    /** 
    * @desc populate the lists: attemptsCaseList, sessionCaseList
    * @param List<Account> scope
    * @return 
    */
    private void splitScope(List<Account> scope){
    	for(Account accountItem : scope){
    		if(accountItem.Reset_Attempts_On__c != null){
    			this.attemptsCaseList.add(accountItem);
    		}
    		if(accountItem.Session_Timeout__c != null){
    			this.sessionCaseList.add(accountItem);
    		}
    	}
    }
    
    /** 
    * @desc restart a new scheduled job 
    * @param 
    * @return 
    */
    private void restartScheduler(){
    	ResetBatchScheduler sch = new ResetBatchScheduler();
    	if(!Test.isRunningTest()){
    		sch.scheduleBatch();
    	}
    }
    
}