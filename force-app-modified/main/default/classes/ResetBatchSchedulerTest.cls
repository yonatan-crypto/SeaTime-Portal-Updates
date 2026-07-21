@isTest
public with sharing class ResetBatchSchedulerTest {
    
   static testmethod void executeBatch() {
   	
		Account account = new Account();
		account.Name = 'HadarTest';
		account.First_Name__c = 'Hadar';
		account.Last_Name__c = 'Test';
		account.Phone = '0521234567';
		account.Email__c = 'test@gmail.com';
		account.Account_Status__c = 'Club Member';
		account.Interest__c = 'Club Membership';
		account.Login_Token__c = 'before batch';
		account.Login_Attempt__c = 11;
		account.VerificationCode_Attempt__c = 11;
		account.Reset_Attempts_On__c = System.now().addHours(-5);
		account.Session_Timeout__c = System.now().addDays(-1);
		insert account; 
		
		Test.startTest();
		String jobId = Database.executeBatch(new ResetBatch());
		Test.stopTest();
		
		Id accountId = account.Id;
		Account expectedAccount = [SELECT Id,Login_Token__c,Login_Attempt__c,VerificationCode_Attempt__c,Reset_Attempts_On__c,Session_Timeout__c 
								   FROM Account 
								   WHERE Id = : accountId];
		System.assertEquals(null, expectedAccount.Login_Token__c);
		System.assertEquals(null, expectedAccount.Reset_Attempts_On__c);
		System.assertEquals(null, expectedAccount.Session_Timeout__c);
		System.assertEquals(0, expectedAccount.Login_Attempt__c);
		System.assertEquals(0, expectedAccount.VerificationCode_Attempt__c);
    
   }
}