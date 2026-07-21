/**
 * @description Controller class for login page of sea time blue app. 
 * @author Ceptes
 * @date Saturday-June-29-2024
 **/

public without sharing class LoginPageAppController {

    static SeaTimeAppSelector appSelector   = new SeaTimeAppSelector();
    static LoginPageAppService loginService = new LoginPageAppService();
    
    
    
    /* comment for check valid creds 1737
     
	@AuraEnabled
    public static Map<String, object> isValidCredentials(Map<String, string> userCredentials) {
        Id accountId;
        account accountRecord;
        boolean isValidCreds;
        Map<String, object> loginDetails = new Map<String, object>();
        string userName = userCredentials.get('userName');
        string password = userCredentials.get('password');
        Account[] validAccountsArray = appSelector.isValidAccountCredentials(userName);
        if(validAccountsArray.isEmpty()) {
            return loginDetails;

        } else {
            accountRecord      = validAccountsArray[0];
            isValidCreds = loginService.checkIfPasswordisCorrect(accountRecord, password);

        }
        if(isValidCreds) {
            accountId = accountRecord.Id;
            loginService.createOtp(accountId);
            loginService.resetLoginAttemptCounter(accountRecord);

        } else {
            loginService.updateLoginAttemptCounter(accountRecord);
        }

        loginDetails.put('isValidCreds', isValidCreds);
        accountRecord = [SELECT id, Phone, Login_Attempt__c, Student7Meter__c,
                StudentMeshit30__c, Code__c
                FROM Account WHERE Id =: accountId LIMIT 1];
        loginDetails.put('accountRecord',accountRecord);
		return loginDetails;

    }  
     
*/
    
   @AuraEnabled
    public static Map<String, Object> isValidCredentials(Map<String, String> userCredentials) {
    
        Account accountRecord;
        Boolean isValidCreds = false;
        Boolean isStrongPassword = false;
        Boolean isPhoneUsedAsPassword = false;
    
        Map<String, Object> loginDetails = new Map<String, Object>();
    
        String userName = userCredentials.get('userName');
        String password = userCredentials.get('password');
    
        Account[] validAccountsArray = appSelector.isValidAccountCredentials(userName);
    
        if (validAccountsArray.isEmpty()) {
            loginDetails.put('isValidCreds', false);
            loginDetails.put('isStrongPassword', false);
            loginDetails.put('isPhoneUsedAsPassword', false);
            loginDetails.put('accountRecord', null);
            return loginDetails;
        }
    
        accountRecord = validAccountsArray[0];
    
        if (accountRecord.Phone == password) {
            isPhoneUsedAsPassword = true;
        }
    
        isStrongPassword = loginService.isStrongPassword(accountRecord, password);
    
        isValidCreds = isStrongPassword || isPhoneUsedAsPassword;
    
        if (isValidCreds) {
            loginService.resetLoginAttemptCounter(accountRecord);
        } else {
            loginService.updateLoginAttemptCounter(accountRecord);
        }
    
        accountRecord = [
            SELECT Id, Phone, Login_Attempt__c, Is_Strong_Password__c
            FROM Account
            WHERE Id = :accountRecord.Id
            LIMIT 1
        ];
    
        loginDetails.put('isValidCreds', isValidCreds);
        loginDetails.put('isStrongPassword', isStrongPassword);
        loginDetails.put('isPhoneUsedAsPassword', isPhoneUsedAsPassword);
        loginDetails.put('accountRecord', accountRecord);
    
        return loginDetails;
    }

    /* comment for validate the otp 1737
      @AuraEnabled
    public static Map<String, object> isValidOtp(Id accountId, string otp) {
	 Map<String, object> otpDetails = new Map<String, object>();
        account accountRecord  = appSelector.getAccountFromId(accountId);
        boolean isOtpValidated = accountRecord.code__c == otp;
        if(!isOtpValidated) {
            loginService.updateLoginAttemptCounter(accountRecord);
        } else {
            loginService.resetLoginAttemptCounter(accountRecord);
        }
        otpDetails.put('isOtpValidated', isOtpValidated);
        otpDetails.put('accountRecord', accountRecord);
        return otpDetails;
    }
     
	*/
    
    @AuraEnabled
    public static void createOtp(Id accountId) {
        if (accountId != null) {
            loginService.createOtp(accountId);
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> isValidOtp(Id accountId, String otp) {

        Map<String, Object> otpDetails = new Map<String, Object>();

        if (accountId == null) {
            otpDetails.put('isOtpValidated', false);
            return otpDetails;
        }

        Account accountRecord = appSelector.getAccountFromId(accountId);

        if (accountRecord == null) {
            otpDetails.put('isOtpValidated', false);
            return otpDetails;
        }

        Boolean isOtpValidated = accountRecord.Code__c == otp;

        if (!isOtpValidated) {
            loginService.updateLoginAttemptCounter(accountRecord);
        } else {
            loginService.resetLoginAttemptCounter(accountRecord);
        }

        otpDetails.put('isOtpValidated', isOtpValidated);
        otpDetails.put('accountRecord', accountRecord);

        return otpDetails;
    }
    
    
    // created for save strong password 1737
    @AuraEnabled
    public static Boolean saveStrongPassword(Id accountId, String newPassword) {
        try {
            if (String.isBlank(newPassword) || newPassword.length() < 8) {
                throw new AuraHandledException('Password must be at least 8 characters long.');
            }

            Account acc = [SELECT Id, Is_Strong_Password__c, Strong_Password__c FROM Account WHERE Id = :accountId LIMIT 1];

            String encryptedPassword = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(newPassword)));

            acc.Strong_Password__c = encryptedPassword;
            acc.Is_Strong_Password__c = true;

            update acc;

            System.debug('Password successfully saved for Account Id: ' + accountId);

            return true;

        } catch (Exception e) {
            System.debug('Error saving password: ' + e.getMessage());
            throw new AuraHandledException('Failed to save password. ' + e.getMessage());
        }
    }
    
    // added code for custom metadata value 1738
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getWelcomeOverlayConfig() {
        // Fetch CMDT record from your service
        Welcome_Overlay_Config__mdt config = WelcomeOverlayConfigService.getConfig();
            return new Map<String, Object>{
            'overlayUrl' => config.Overlay_URL__c,
            'overlayBg'  => config.Overlay_BG__c,
            'blockPage'  => config.Block_Page__c
        };
    }

    
}