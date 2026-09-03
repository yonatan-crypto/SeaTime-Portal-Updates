public without sharing class StaffLoginController {
    
    private static final String FROM_ADDRESS = 'yonatan@sea-time.co.il';
    private static final String TO_ADDRESS = 'bodygw@sms.inforu.co.il';

    @AuraEnabled
    public static Map<String, Object> isValidCredentials(Map<String, String> userCredentials) {
        Map<String, Object> result = new Map<String, Object>();
        String userName = userCredentials.get('userName');
        String password = userCredentials.get('password');
        
        List<Employee__c> employees = [SELECT Id, Name, Employee_Phone__c, Employee_Email__c, Login_Attempt__c, Is_Strong_Password__c, Strong_Password__c, Active__c 
                                       FROM Employee__c 
                                       WHERE Employee_Email__c = :userName LIMIT 1];
        
        if (employees.isEmpty()) {
            result.put('isValidCreds', false);
            return result;
        }
        
        Employee__c emp = employees[0];

        // Block inactive employees
        if (emp.Active__c == false) {
            result.put('isValidCreds', false);
            result.put('isInactive', true);
            result.put('errorMessage', 'חשבון המדריך אינו פעיל. גישתך למערכת נחסמה. אנא פנה להנהלה.');
            return result;
        }
        Boolean isPhoneUsedAsPassword = (emp.Employee_Phone__c != null && emp.Employee_Phone__c == password);
        Boolean isStrongPassword = false;
        
        if (emp.Strong_Password__c != null && emp.Is_Strong_Password__c == true) {
            Blob targetBlob = Blob.valueOf(password);
            Blob hash = Crypto.generateDigest('SHA-256', targetBlob);
            String encodedHash = EncodingUtil.convertToHex(hash);
            isStrongPassword = (emp.Strong_Password__c == encodedHash);
        }
        
        Boolean isValidCreds = isStrongPassword || isPhoneUsedAsPassword;
        result.put('isValidCreds', isValidCreds);
        result.put('isStrongPassword', isStrongPassword);
        result.put('isPhoneUsedAsPassword', isPhoneUsedAsPassword);
        result.put('employeeRecord', emp);
        
        if (isValidCreds) {
            emp.Login_Attempt__c = 0;
        } else {
            emp.Login_Attempt__c = (emp.Login_Attempt__c == null) ? 1 : emp.Login_Attempt__c + 1;
        }
        update emp;
        
        return result;
    }
    
    @AuraEnabled
    public static Map<String, Object> isValidOtp(Id employeeId, String otp) {
        Map<String, Object> result = new Map<String, Object>();
        
        List<Employee__c> employees = [SELECT Id, Code__c, Login_Attempt__c FROM Employee__c WHERE Id = :employeeId LIMIT 1];
        if (employees.isEmpty()) {
            result.put('isOtpValidated', false);
            return result;
        }
        
        Employee__c emp = employees[0];
        Boolean isValid = (emp.Code__c != null && emp.Code__c == otp);
        result.put('isOtpValidated', isValid);
        result.put('employeeRecord', emp);
        
        if (isValid) {
            emp.Login_Attempt__c = 0;
        } else {
            emp.Login_Attempt__c = (emp.Login_Attempt__c == null) ? 1 : emp.Login_Attempt__c + 1;
        }
        update emp;
        
        return result;
    }
    
    @AuraEnabled
    public static void createOtp(Id employeeId) {
        List<Employee__c> employees = [SELECT Id, Code__c, Employee_Phone__c, Active__c FROM Employee__c WHERE Id = :employeeId LIMIT 1];
        if (!employees.isEmpty() && employees[0].Active__c != false) {
            Employee__c emp = employees[0];
            String code = String.valueOf(Math.round(Math.random() * 899999) + 100000);
            emp.Code__c = code;
            update emp;
            
            // Send SMS via InforU gateway
            if (String.isNotBlank(emp.Employee_Phone__c)) {
                sendSMS(emp.Employee_Phone__c, code);
            }
        }
    }

    private static void sendSMS(String phoneNumber, String otpCode) {
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
        }
    }
    
    @AuraEnabled
    public static Boolean saveStrongPassword(Id employeeId, String newPassword) {
        if (newPassword == null || newPassword.length() < 8) {
            return false;
        }
        
        List<Employee__c> employees = [SELECT Id, Strong_Password__c, Is_Strong_Password__c FROM Employee__c WHERE Id = :employeeId LIMIT 1];
        if (employees.isEmpty()) {
            return false;
        }
        
        Blob targetBlob = Blob.valueOf(newPassword);
        Blob hash = Crypto.generateDigest('SHA-256', targetBlob);
        String encodedHash = EncodingUtil.convertToHex(hash);
        
        Employee__c emp = employees[0];
        emp.Strong_Password__c = encodedHash;
        emp.Is_Strong_Password__c = true;
        update emp;
        
        return true;
    }
}
