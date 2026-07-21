/**
 *	SEAT-20 | SEAT-22 : Server side to login page
 *	test service to controller of login page 
 *	author Hadar Berman
 *
 *	@class LoginPageControllerService
 * 	@static
 */
@IsTest 
public with sharing class LoginPageControllerTest {
	
	 
	/**
     *	SEAT-20 Server side to login page
     *	author Hadar Berman
     
     *	@method loginToSystem
     *	@async
     */
	static testmethod void loginToSystem() {
		
		Account account = new Account();
		account.Name = 'HadarTest';
		account.First_Name__c = 'Hadar';
		account.Last_Name__c = 'Test';
		account.Phone = '0521234567';
		account.Email__c = 'test@gmail.com';
		account.Account_Status__c = 'Club Member';
		account.Interest__c = 'Club Membership';
		account.VerificationCode_Attempt__c = 1;
		insert account; 
		
		Account accountMax = new Account();
		accountMax.Name = 'HadarTestMax';
		accountMax.First_Name__c = 'Hadar';
		accountMax.Last_Name__c = 'Test';
		accountMax.Phone = '0541234567';
		accountMax.Email__c = 'testMax@gmail.com';
		accountMax.Account_Status__c = 'Club Member';
		accountMax.Interest__c = 'Club Membership';
		accountMax.Login_Attempt__c = 7;
		accountMax.VerificationCode_Attempt__c = 4;
		insert accountMax; 
		
		String accountNull = '{"username":"","password":"0541234567","isResendCode":false,"isFirstStep":true,"code":""}';
		String firstStepMax = '{"username":"testMax@gmail.com","password":"0541234567","isResendCode":false,"isFirstStep":true,"code":""}';
		String secondStepMax = '{"username":"testMax@gmail.com","password":"0541234567","isResendCode":false,"isFirstStep":false,"code":""}';
		String resendCodeMax = '{"username":"testMax@gmail.com","password":"0541234567","isResendCode":true,"isFirstStep":false,"code":""}';
		String firstStepFail = '{"username":"test@gmail.com","password":"05212345","isResendCode":false,"isFirstStep":true,"code":""}';
		String firstStepSuccess = '{"username":"test@gmail.com","password":"0521234567","isResendCode":false,"isFirstStep":true,"code":""}';
		String secondStepFail = '{"username":"test@gmail.com","password":"0521234567","isResendCode":false,"isFirstStep":false,"code":"111111"}';
		String secondStepSuccess = '{"username":"test@gmail.com","password":"0521234567","isResendCode":false,"isFirstStep":false,"code":"123456"}';
		String resendCodeSuccess = '{"username":"test@gmail.com","password":"0521234567","isResendCode":true,"isFirstStep":false,"code":""}';
		String resendCodeSuccess2 = '{"username":"test@gmail.com","password":"0521234567","isResendCode":true,"isFirstStep":false,"code":""}';
		
		List<String> testList = new List<String>();
		testList.add(accountNull);
		testList.add(firstStepMax);
		testList.add(secondStepMax);
		testList.add(resendCodeMax);
		testList.add(firstStepSuccess);
		testList.add(firstStepFail);
		testList.add(resendCodeSuccess);
		testList.add(secondStepFail);
		testList.add(secondStepSuccess);
		testList.add(resendCodeSuccess2);
		
		for(Integer index=0 ; index < testList.size() ; index++){
			LoginPageController.signIn(testList[index]);
		}
		
		LoginPageController newForTest = new LoginPageController();
	}
	
	
	



	
    
}