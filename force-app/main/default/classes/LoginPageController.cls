/**
 *	SEAT-20 | SEAT-22 : Server side to login page
 *	controller of login page 
 *	author Hadar Berman
 *
 *	@class LoginPageController
 * 	@module ???
 *	@constractor
 */
global class LoginPageController {

    //public members
    public Boolean isSandbox {get{ return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox; } private set;} 
    public String currentUserType {get {return UserInfo.getUserType();} private set;}   

    //private members
    private final static String AUTH_COOKIE_NAME = 'seatimeAccountCookie';
    private final static String ERORR_NOT_EXISTS = 'ERORR_NOT_EXISTS';

    public String redirectCookie { get { return SeatimeAuthenticationService.getCookie(AUTH_COOKIE_NAME).getValue();} private set;}
	
    public LoginPageController(){
        SeatimeAuthenticationService.killCookie(AUTH_COOKIE_NAME);
    } //constractor

	/** 
    * @desc invoke sign-in process 
    * @param String sobjectJSONStr (JSON CredentialObject)
    * @method signIn
    * @return Response
    */	
    @RemoteAction
    global static Response signIn(String sobjectJSONStr){
        CredentialObject detailsFromPage = (CredentialObject)JSON.deserialize(sobjectJSONStr,CredentialObject.Class);
        Account existAcc = getAccount(detailsFromPage.username , detailsFromPage.password);
        if(String.isNotBlank(existAcc.Id)){
            LoginPageControllerService loginService = new LoginPageControllerService(
                existAcc, 
                detailsFromPage.password, 
                detailsFromPage.code, 
                detailsFromPage.isFirstStep, 
                detailsFromPage.isResendCode
            );
            return loginService.getResponse();
        }
        return new Response(ERORR_NOT_EXISTS,'account does not exist');
    }//method:remoting:signin   
    
    /** 
    * @desc get account by email
    * @param String email
    * @method getAccount
    * @return Account
    */	
    private static Account getAccount(String email, String phone){
    	List<Account> existAcc = new List<Account>();
        if(email != null){
            existAcc = [SELECT Id,
                              Email__c,
                              Phone,
                              Code__c,
                              Login_Attempt__c,
                              VerificationCode_Attempt__c,
                              Session_Timeout__c,
                              Reset_Attempts_On__c 
        			   FROM Account 
        			   WHERE Email__c =:email 
                       AND Phone =: phone];
        }
        if(!existAcc.isEmpty() && existAcc.size() == 1 ){
            return existAcc[0];
        }
    	return new Account();
    }//method:getter:Account
    
    /** 
    * @desc inner class of parameters from page (input fields)
    * @class CredentialObject
    */
    private class CredentialObject {
        public String username {get;set;}
        public String password {get;set;}
        public String code {get;set;}
        public Boolean isFirstStep {get;set;}
        public Boolean isResendCode {get;set;}
    }//class:inner

    /** 
    * @desc inner class to return response to page
    * @class Response
    */  
    global class Response {
        public String status {get;set;}
        public String description {get;set;}
        public String resultData {get;set;}
        public String stackTrace {get;set;}
        
        public String redirectUrl {get;private set;}
        public String securityToken {get;private set;}
        public String cookieDomain {get;private set;}


        public Response(){}//constructor:default

        public Response(String status,String description){
            this.status =  status;
            this.description = description;
        }//constructor:overload

        public Response(String status,String securityToken,String redirectUrl){
            this.status =  status;
            this.redirectUrl = redirectUrl;
            this.securityToken = securityToken;
        }//constructor:overload:token response

    }//class:inner    

    
}//class:controller