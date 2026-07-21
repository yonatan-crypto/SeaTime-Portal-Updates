@IsTest
public class LoginPageAppControllerTest {

    /* =========================================================
       TEST DATA SETUP
       username = Email
       password = Phone (soft login)
    ==========================================================*/
    @testSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Student',
            Email__c = 'test@student.com',   
            Phone = '9999999999',             
            Login_Attempt__c = 0,
            Code__c = '123456',
            Is_Strong_Password__c = false
        );
        insert acc;
    }

    /* =========================================================
       HELPER
    ==========================================================*/
    private static Account getAcc() {
        return [
            SELECT Id, Email__c, Phone,
                   Login_Attempt__c,
                   Code__c,
                   Is_Strong_Password__c,
                   Strong_Password__c
            FROM Account
            LIMIT 1
        ];
    }

    /* =========================================================
      SOFT PASSWORD LOGIN (OTP CREATED)
       Covers:
       - account found
       - isValidCreds = true
       - isStrongPassword = false
       - createOtp()
       - resetLoginAttemptCounter()
    ==========================================================*/
    @IsTest
    static void testSoftPasswordLogin() {

        Account acc = getAcc();

        Map<String,String> creds = new Map<String,String>{
            'userName' => acc.Email__c,
            'password' => acc.Phone
        };

        Test.startTest();
        Map<String,Object> result =
            LoginPageAppController.isValidCredentials(creds);
        Test.stopTest();

        System.assertEquals(true, result.get('isValidCreds'));
        System.assertEquals(false, result.get('isStrongPassword'));
        System.assertNotEquals(null, result.get('accountRecord'));
    }

    /* =========================================================
    STRONG PASSWORD LOGIN (OTP SKIPPED)
       Covers:
       - strong password branch
       - skip OTP
       - reset counter
    ==========================================================*/
    @IsTest
    static void testStrongPasswordLogin() {

        Account acc = getAcc();

        // save strong password
        LoginPageAppController.saveStrongPassword(acc.Id, 'Strong@123');

        Map<String,String> creds = new Map<String,String>{
            'userName' => acc.Email__c,
            'password' => 'Strong@123'
        };

        Test.startTest();
        Map<String,Object> result =
            LoginPageAppController.isValidCredentials(creds);
        Test.stopTest();

        System.assertEquals(true, result.get('isValidCreds'));
        System.assertEquals(true, result.get('isStrongPassword'));
        System.assertNotEquals(null, result.get('accountRecord'));
    }

    /* =========================================================
      ACCOUNT FOUND + INVALID PASSWORD
       Covers:
       - updateLoginAttemptCounter()
    ==========================================================*/
    @IsTest
    static void testInvalidPasswordWithAccount() {

        Account acc = getAcc();

        Map<String,String> creds = new Map<String,String>{
            'userName' => acc.Email__c,
            'password' => '0000000000'
        };

        Test.startTest();
        Map<String,Object> result =
            LoginPageAppController.isValidCredentials(creds);
        Test.stopTest();

        System.assertEquals(false, result.get('isValidCreds'));
        System.assertNotEquals(null, result.get('accountRecord'));
    }

    /* =========================================================
       NO ACCOUNT FOUND
       Covers:
       - validAccountsArray.isEmpty()
    ==========================================================*/
    @IsTest
    static void testNoAccountFound() {

        Map<String,String> creds = new Map<String,String>{
            'userName' => 'noone@test.com',
            'password' => '123'
        };

        Test.startTest();
        Map<String,Object> result =
            LoginPageAppController.isValidCredentials(creds);
        Test.stopTest();

        System.assertEquals(false, result.get('isValidCreds'));
        System.assertEquals(false, result.get('isStrongPassword'));
        System.assertEquals(null, result.get('accountRecord'));
    }

    /* =========================================================
      VALID OTP
    ==========================================================*/
    @IsTest
    static void testValidOtp() {

        Account acc = getAcc();

        Test.startTest();
        Map<String,Object> result =
            LoginPageAppController.isValidOtp(acc.Id, acc.Code__c);
        Test.stopTest();

        System.assertEquals(true, result.get('isOtpValidated'));
    }

    /* =========================================================
      INVALID OTP
    ==========================================================*/
    @IsTest
    static void testInvalidOtp() {

        Account acc = getAcc();

        Test.startTest();
        Map<String,Object> result =
            LoginPageAppController.isValidOtp(acc.Id, '000000');
        Test.stopTest();

        System.assertEquals(false, result.get('isOtpValidated'));
    }

    /* =========================================================
       SAVE STRONG PASSWORD – SUCCESS
    ==========================================================*/
    @IsTest
    static void testSaveStrongPasswordSuccess() {

        Account acc = getAcc();

        Test.startTest();
        Boolean result =
            LoginPageAppController.saveStrongPassword(acc.Id, 'Strong@123');
        Test.stopTest();

        System.assertEquals(true, result);

        Account updated = [
            SELECT Is_Strong_Password__c, Strong_Password__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals(true, updated.Is_Strong_Password__c);
        System.assertNotEquals(null, updated.Strong_Password__c);
    }

    /* =========================================================
    SAVE STRONG PASSWORD – FAILURE
    ==========================================================*/
    @IsTest
    static void testSaveStrongPasswordFailure() {

        Account acc = getAcc();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LoginPageAppController.saveStrongPassword(acc.Id, '123');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }
}