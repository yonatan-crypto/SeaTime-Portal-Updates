/**
 * @description Business logic for LoginPageAppController
 * @author Ceptes
 * @date Saturday-June-29-2024
 **/

public without sharing class LoginPageAppService {
    
    private static final String FROM_ADDRESS = 'yonatan@sea-time.co.il';
    private static final String TO_ADDRESS = 'bodygw@sms.inforu.co.il';
    
    public void createOtp(Id accountId) {

        integer sixDigitOtp = generate6DigitRandomNumber();
        
        // Query Account to get Phone number for SMS
        Account accountRecord = [
            SELECT Id, Phone, Code__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        accountRecord.Code__c = String.valueOf(sixDigitOtp);
        update accountRecord;
        
        // Send SMS with OTP code
        if (String.isNotBlank(accountRecord.Phone)) {
            sendSMS(accountRecord.Phone, String.valueOf(sixDigitOtp));
        }
    }
    
    private void sendSMS(String phoneNumber, String otpCode) {
        try {
            List<OrgWideEmailAddress> owes = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = :FROM_ADDRESS
                LIMIT 1
            ];
            
            if (owes.isEmpty()) {
                System.debug('OrgWideEmailAddress not found for: ' + FROM_ADDRESS);
                return;
            }
            
            String smsMessage = 'Your verification code is: ' + otpCode;
            
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setOrgWideEmailAddressId(owes[0].Id);
            emailMessage.setSubject(phoneNumber);
            emailMessage.setPlainTextBody(smsMessage);
            emailMessage.setToAddresses(new String[] {TO_ADDRESS});
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
            
        } catch (Exception ex) {
            System.debug('Error sending SMS: ' + ex.getMessage());
            System.debug('StackTrace: ' + ex.getStackTraceString());
            // Don't throw exception - OTP is still created even if SMS fails
        }
    }

    // NEW METHOD: Check if user is using strong password 1737
    public boolean isStrongPassword(Account accountRecord, String password) {
        if (accountRecord.Is_Strong_Password__c == true &&
            String.isNotBlank(accountRecord.Strong_Password__c)) {

            String encryptedInput = EncodingUtil.convertToHex(
                Crypto.generateDigest('SHA-256', Blob.valueOf(password))
            );

            if (encryptedInput == accountRecord.Strong_Password__c) {
                return true;
            }
        }
        return false;
    }
    
    
	/* comment for creation stron password 1737
    public boolean checkIfPasswordisCorrect(Account accountRecord, string password) {
        return accountRecord.Phone == password;
    }*/
    
    
    public boolean checkIfPasswordisCorrect(Account accountRecord, String password) {

        // Normal (soft) password - phone number
        if (accountRecord.Phone == password) {
            return true;
        }

        // Strong password check
        if (isStrongPassword(accountRecord, password)) {
            return true;
        }

        return false;
    }

    public void updateLoginAttemptCounter(Account accountRecord) {
      
        accountRecord.Login_Attempt__c = getLoginAttempt(accountRecord);
        
        update accountRecord;
    }

    public void resetLoginAttemptCounter(Account accountRecord) {

        accountRecord.Login_Attempt__c = getLoginAttempt(accountRecord);
        
        if(accountRecord.Login_Attempt__c  > 0 && accountRecord.Login_Attempt__c < 6) {
            accountRecord.Login_Attempt__c = 0;
            update accountRecord;
        }
    }

    //Service utility methods

    Decimal getLoginAttempt(Account accountRecord) {
       return  accountRecord.Login_Attempt__c == null ? 0 : accountRecord.Login_Attempt__c + 1;
    }

    integer generate6DigitRandomNumber() {
        return Integer.ValueOf(Math.round((Math.random() * (900000) + 100000)));
    }
}