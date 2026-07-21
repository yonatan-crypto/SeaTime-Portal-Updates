@IsTest
public class LoginPageAppServiceTest {

    static LoginPageAppService service = new LoginPageAppService();

    @testSetup
    static void setupData() {
        // ---------- Normal Account ----------
        Account acc1 = new Account(
            Name = 'Normal User',
            Email__c = 'normal@test.com',
            Phone = '9999999999',
            Login_Attempt__c = 0,
            Code__c = '123456',
            Is_Strong_Password__c = false
        );
        insert acc1;

        // ---------- Strong Password Account ----------
        String password = 'MyStrongPass123';
        String encryptedPassword = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(password))
        );

        Account acc2 = new Account(
            Name = 'Strong User',
            Email__c = 'strong@test.com',
            Phone = '8888888888',
            Login_Attempt__c = 0,
            Code__c = '654321',
            Is_Strong_Password__c = true,
            Strong_Password__c = encryptedPassword
        );
        insert acc2;
    }

    @IsTest
    static void testCreateOtp() {
        Account acc = [SELECT Id, Code__c FROM Account WHERE Email__c='normal@test.com' LIMIT 1];

        String oldCode = acc.Code__c;

        service.createOtp(acc.Id);

        Account updatedAcc = [SELECT Id, Code__c FROM Account WHERE Id=:acc.Id];
        System.assertNotEquals(oldCode, updatedAcc.Code__c, 'OTP should be updated');
        System.assertEquals(6, updatedAcc.Code__c.length(), 'OTP should be 6 digits');
    }

    @IsTest
    static void testCheckIfPasswordisCorrect_Both() {
        // ---------- Normal Account ----------
        Account normalAcc = [SELECT Id, Phone, Is_Strong_Password__c, Strong_Password__c 
                             FROM Account WHERE Email__c='normal@test.com' LIMIT 1];

        // Normal password correct
        Boolean normalCorrect = service.checkIfPasswordisCorrect(normalAcc, '9999999999');
        System.assertEquals(true, normalCorrect, 'Normal password should be valid');

        // Normal password incorrect
        Boolean normalWrong = service.checkIfPasswordisCorrect(normalAcc, 'wrongpassword');
        System.assertEquals(false, normalWrong, 'Incorrect normal password should fail');

        // ---------- Strong Password Account ----------
        Account strongAcc = [SELECT Id, Phone, Is_Strong_Password__c, Strong_Password__c 
                             FROM Account WHERE Email__c='strong@test.com' LIMIT 1];

        // Strong password correct
        Boolean strongCorrect = service.checkIfPasswordisCorrect(strongAcc, 'MyStrongPass123');
        System.assertEquals(true, strongCorrect, 'Strong password should validate');

        // Strong password incorrect
        Boolean strongWrong = service.checkIfPasswordisCorrect(strongAcc, 'WrongPass123');
        System.assertEquals(false, strongWrong, 'Wrong strong password should fail');
    }

    @IsTest
    static void testUpdateLoginAttemptCounter() {
        Account acc = [SELECT Id, Login_Attempt__c FROM Account WHERE Email__c='normal@test.com' LIMIT 1];

        Integer oldAttempt = acc.Login_Attempt__c.intValue();
        service.updateLoginAttemptCounter(acc);

        Account updated = [SELECT Id, Login_Attempt__c FROM Account WHERE Id=:acc.Id];
        System.assertEquals(oldAttempt + 1, updated.Login_Attempt__c.intValue(), 'Login attempt should increment by 1');
    }

    @IsTest
    static void testResetLoginAttemptCounter() {
        Account acc = [SELECT Id, Login_Attempt__c FROM Account WHERE Email__c='normal@test.com' LIMIT 1];

        // Simulate 3 login attempts
        acc.Login_Attempt__c = 3;
        update acc;

        service.resetLoginAttemptCounter(acc);

        Account updated = [SELECT Id, Login_Attempt__c FROM Account WHERE Id=:acc.Id];
        System.assertEquals(0, updated.Login_Attempt__c.intValue(), 'Login attempt should reset to 0 if between 1-5');
    }

}