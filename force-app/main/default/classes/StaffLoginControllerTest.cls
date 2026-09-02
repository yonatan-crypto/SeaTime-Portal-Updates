@isTest
private class StaffLoginControllerTest {
    
    @testSetup
    static void setup() {
        Employee__c emp = new Employee__c(Name = 'Test Guide', Employee_Email__c = 'test@example.com', Employee_Phone__c = '0501234567', Login_Attempt__c = 0);
        insert emp;
    }
    
    @isTest
    static void testIsValidCredentials_Phone() {
        Test.startTest();
        Map<String, String> creds = new Map<String, String>{
            'userName' => 'test@example.com',
            'password' => '0501234567'
        };
        Map<String, Object> result = StaffLoginController.isValidCredentials(creds);
        Test.stopTest();
        
        System.assertEquals(true, result.get('isValidCreds'));
        System.assertEquals(true, result.get('isPhoneUsedAsPassword'));
        System.assertEquals(false, result.get('isStrongPassword'));
    }
    
    @isTest
    static void testIsValidCredentials_StrongPassword() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        StaffLoginController.saveStrongPassword(emp.Id, 'SuperSecret123');
        
        Test.startTest();
        Map<String, String> creds = new Map<String, String>{
            'userName' => 'test@example.com',
            'password' => 'SuperSecret123'
        };
        Map<String, Object> result = StaffLoginController.isValidCredentials(creds);
        Test.stopTest();
        
        System.assertEquals(true, result.get('isValidCreds'));
        System.assertEquals(true, result.get('isStrongPassword'));
    }
    
    @isTest
    static void testIsValidCredentials_Invalid() {
        Test.startTest();
        Map<String, String> creds = new Map<String, String>{
            'userName' => 'test@example.com',
            'password' => 'wrongpass'
        };
        Map<String, Object> result = StaffLoginController.isValidCredentials(creds);
        Test.stopTest();
        
        System.assertEquals(false, result.get('isValidCreds'));
        Employee__c emp = [SELECT Login_Attempt__c FROM Employee__c LIMIT 1];
        System.assertEquals(1, emp.Login_Attempt__c);
    }
    
    @isTest
    static void testIsValidOtp() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        emp.Code__c = '123456';
        update emp;
        
        Test.startTest();
        Map<String, Object> result = StaffLoginController.isValidOtp(emp.Id, '123456');
        Test.stopTest();
        
        System.assertEquals(true, result.get('isOtpValidated'));
    }
    
    @isTest
    static void testIsValidOtp_Invalid() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        emp.Code__c = '123456';
        update emp;
        
        Test.startTest();
        Map<String, Object> result = StaffLoginController.isValidOtp(emp.Id, '654321');
        Test.stopTest();
        
        System.assertEquals(false, result.get('isOtpValidated'));
    }
    
    @isTest
    static void testCreateOtp() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        
        Test.startTest();
        StaffLoginController.createOtp(emp.Id);
        Test.stopTest();
        
        Employee__c updatedEmp = [SELECT Code__c FROM Employee__c WHERE Id = :emp.Id];
        System.assertNotEquals(null, updatedEmp.Code__c);
    }
    
    @isTest
    static void testSaveStrongPassword_Invalid() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        
        Test.startTest();
        Boolean result = StaffLoginController.saveStrongPassword(emp.Id, 'short');
        Test.stopTest();
        
        System.assertEquals(false, result);
    }
}
