/**
 *	SEAT-20 | SEAT-22 : Server side to login page
 *	service to controller of login page 
 *	author Hadar Berman
 *
 *	@class LoginPageControllerService
 *	@constractor
 */
public without sharing class LoginPageControllerService {
    
    private static final String LABEL_NAME = 'LOGIN_SETTINGS';
    private static final String STATUS_OK_VERIFY = 'OK_VERIFY';
    private static final String STATUS_OK_SIGNIN = 'OK_SIGNIN';
    private static final String STATUS_ERROR = 'ERROR';
    private static final String STATUS_FAILURE = 'FAILURE';
    
    //CUSTOM METADATA
    private static Integer MAX_LOGIN_ATTEMPT; //7
    private static Integer MAX_VERIFICATIONCODE_ATTEMPT; //3
    private static Integer MINUTES_TO_KILL_SESSION; //60
    private static Integer MINUTES_TO_RESET_ATTEMPTS; //60
	
	//CUSTOM LABELS
    private static final String FAILURE_MESSAGE = Label.Login_Failure_Message; //The username or password or code is incorrect.
    private static final String MAX_ATTEMPT_MESSAGE = Label.Max_Attempt_Message; //Too many login attempts have been made, Please try again later.
    private static final String REDIRECT_URL = SeatimeAuthenticationService.isGuestUser() ? '/orders' : 'apex/SeatimeSchedulerWebapp';
    
    private String token;
    private String password;
    private String code;
    private Boolean isFirstStep;
    private Boolean isResendCode;
    private Account account;
    
    /**
     *	SEAT-20 Server side to login page
     *	author Hadar Berman
     *
     *	@constractor
     *	@param	  {Account} existAcc
     *	@param	  {String} password
     *	@param	  {String} code
     *	@param	  {Boolean} isFirstStep
     *	@param	  {Boolean} isResendCode
     */
    public LoginPageControllerService(Account existAcc, String password, String code, Boolean isFirstStep, Boolean isResendCode){
    	this.account = existAcc;
    	this.password = password;
    	this.code = code;
    	this.isFirstStep = isFirstStep;
    	this.isResendCode = isResendCode;
    }
    
    /** 
    * @desc method check details & do all the logic 
    * @param 
    * @return Response
    */
    public LoginPageController.Response getResponse(){
    	try{
    	   prepareMetadata();
    	}catch(Exception e){
        	return createResponse(STATUS_ERROR, '','',e.getMessage());
        }
    	if(this.account == null){
    		return createResponse(STATUS_FAILURE, FAILURE_MESSAGE,'','');
    	}
    	if(isFirstStep){
    		return verifyFirstStep();
    	}
    	if(isFirstStep == false && isResendCode == false){
    		return verifySecondStep();
    	}
    	if(isFirstStep == false && isResendCode == true){
    		return resendCode();
    	}
    	return null;
    }
    
    /** 
    * @desc method check password & send code
    * @param 
    * @return Response
    */
    private LoginPageController.Response verifyFirstStep(){
    	if(loginAttemptReachMax()){
    		updateAccount('Reach_Max');
    		return createResponse(STATUS_FAILURE, MAX_ATTEMPT_MESSAGE,'','');
    	}
    	if(verifyPassword()){ 
    		updateAccount('Success_Password');
    		return createResponse(STATUS_OK_VERIFY, '','','');
    	}else{
    		updateAccount('Failed_Verify');
    		return createResponse(STATUS_FAILURE, FAILURE_MESSAGE,'','');
    	}
    }
    
    /** 
    * @desc method check code
    * @param 
    * @return Response
    */	
    private LoginPageController.Response verifySecondStep(){
    	if(loginAttemptReachMax()){
    		updateAccount('Reach_Max');
    		return createResponse(STATUS_FAILURE, MAX_ATTEMPT_MESSAGE,'','');
    	}
    	Boolean isCodeVerified = this.verifyCode();
    	if(isCodeVerified){ 
    		updateAccount('Success_Code');
    		return new LoginPageController.Response(STATUS_OK_SIGNIN, this.token, REDIRECT_URL);
    	}else{
    		updateAccount('Failed_Verify');
    		return createResponse(STATUS_FAILURE, FAILURE_MESSAGE,'','');
    	}
    }
    
    /** 
    * @desc method resend code
    * @param 
    * @return Response
    */		
    private LoginPageController.Response resendCode(){
    	if(codeAttemptReachMax()){
    		updateAccount('Reach_Max');
    		return createResponse(STATUS_FAILURE, MAX_ATTEMPT_MESSAGE,'','');
    	}
    	updateAccount('Resend_Code');
		return createResponse(STATUS_OK_VERIFY, '','','');
    }
    	
    /** 
    * @desc create Response by parameters
    * @param String status, String description, String resultData, String stackTrace
    * @return Response
    */	
    private LoginPageController.Response createResponse(String status, String description, String resultData, String stackTrace){
		LoginPageController.Response res = new LoginPageController.Response();
		res.status = status;
		res.description = description;
		res.resultData = resultData;
		res.stackTrace = stackTrace;
		return res;
    }//method:getter:Response
    
    /** 
    * @desc check if login attempts not over the max attempt
    * @param 
    * @return Boolean
    */	
    private Boolean loginAttemptReachMax(){
    	if(this.account.Login_Attempt__c == null || account.Login_Attempt__c == 0){
			return false;
        }
    	if(this.account.Login_Attempt__c < MAX_LOGIN_ATTEMPT){
    		return false;
    	}
		return true;
    }
    
    /** 
    * @desc check if verification code attempts not over the max attempt
    * @param 
    * @return Boolean
    */	
    private Boolean codeAttemptReachMax(){
    	if(this.account.VerificationCode_Attempt__c == null || account.VerificationCode_Attempt__c == 0){
			return false;
        }
    	if(this.account.VerificationCode_Attempt__c <= MAX_VERIFICATIONCODE_ATTEMPT){
    		return false;
    	}
		return true;
    }
    
    /** 
    * @desc update the account by cases
    * @param String updateCase
    * @return 
    */	
    private void updateAccount(String updateCase){
    	Account account = this.account;
    	if(updateCase.equals('Reach_Max')){
    		account.Reset_Attempts_On__c = system.now().addMinutes(MINUTES_TO_RESET_ATTEMPTS);
    		update account;
    	}
    	if(updateCase.equals('Failed_Verify')){
    		if(account.Login_Attempt__c == null || account.Login_Attempt__c == 0){
    			account.Login_Attempt__c = 1;
        	}else account.Login_Attempt__c++;
    		update account;
    	}
    	if(updateCase.equals('Success_Password')){
    		if(account.Login_Attempt__c == null || account.Login_Attempt__c == 0){
    			account.Login_Attempt__c = 1;
        	}else account.Login_Attempt__c++;
    		if(account.VerificationCode_Attempt__c == null || account.VerificationCode_Attempt__c == 0){
    			account.VerificationCode_Attempt__c = 1;
        	}else account.VerificationCode_Attempt__c++;
			account.Code__c = String.valueOf((Math.random()*900000+100000).intValue());
            account.Login_Token__c = null;
        	if(Test.isRunningTest()){ account.Code__c = '123456'; }
    		update account;
    	}
    	if(updateCase.equals('Success_Code')){
            account.Session_Timeout__c = system.now().addMinutes(MINUTES_TO_KILL_SESSION);
            account.Code__c = null;
            account.Login_Attempt__c = 0;
            account.VerificationCode_Attempt__c = 0;
            //get account token
            account.Login_Token__c = SeatimeAuthenticationService.tokenizeAccountLoginDetails(account.Email__c,account.Phone);
    		this.token = account.Login_Token__c;
    		update account;
    	}
    	if(updateCase.equals('Resend_Code')){
			account.Code__c = String.valueOf((Math.random()*900000+100000).intValue());
        	if(Test.isRunningTest()){ account.Code__c = '123456'; }
    		if(account.VerificationCode_Attempt__c == null || account.VerificationCode_Attempt__c == 0){
    			account.VerificationCode_Attempt__c = 1;
        	}else account.VerificationCode_Attempt__c++;
    		update account;
    	}
    }
    
    /** 
    * @desc check if the password is correct
    * @param
    * @return Boolean
    */	
    private Boolean verifyPassword(){
    	if(this.account.Phone != null && this.account.Phone == this.password){
	 		return true;
	 	}
		return false;
    }
    
    /** 
    * @desc check if the code is correct
    * @param
    * @return Boolean
    */	
    private Boolean verifyCode(){
    	if(this.account.Code__c != null && this.account.Code__c == this.code){
	 		return true;
	 	}
		return false;
    }
    
    /** 
    * @desc get the 'Login_settings' record from custom metadata types 'Portal_Setting__mdt'
    * @param
    * @return 
    */	
    private static void prepareMetadata(){
    	List<Portal_Setting__mdt> portalSettingList = [SELECT MAX_LOGIN_ATTEMPTS__c,MAX_VERIFICATION_CODE_ATTEMPTS__c,
    														  MINUTES_OF_SESSION__c,MINUTES_TO_RESET_ATTEMPTS__c
    												   FROM Portal_Setting__mdt
    												   WHERE Label LIKE :LABEL_NAME LIMIT 1];
    	if(!portalSettingList.isEmpty()){
    		MAX_LOGIN_ATTEMPT = (Integer)portalSettingList[0].MAX_LOGIN_ATTEMPTS__c;
    		MAX_VERIFICATIONCODE_ATTEMPT = (Integer)portalSettingList[0].MAX_VERIFICATION_CODE_ATTEMPTS__c;
    		MINUTES_TO_KILL_SESSION = (Integer)portalSettingList[0].MINUTES_OF_SESSION__c;
    		MINUTES_TO_RESET_ATTEMPTS = (Integer)portalSettingList[0].MINUTES_TO_RESET_ATTEMPTS__c;
    	}else {
    		throw new LoginException('Login_settings from Portal_Setting__mdt was not found');
    	}
    }
    
    
    //EXCEPTIONS
    public Class LoginException Extends Exception {}
    
}