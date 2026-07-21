@isTest
private class CreateCruiseTest {

    @isTest static void test_CreateCruise_1() {
        Boats__c boat = new Boats__c(Name='TestBoat');
        insert boat;
        String start = '14:00 22/03/2018';
        String endd = '16:00 22/03/2018';
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='Cruise__c' AND Name='Club'];
        Account account = new Account(Name='TestAccount');
        insert account;

        Test.startTest();
        PageReference pRef;
        pRef = Page.CreateCruise;
        Map<String, String> param = pRef.getParameters();
        param.put('boatId', boat.Id);
        param.put('start', start);
        param.put('end', endd);
        Test.setCurrentPage(pRef);
        CreateCruise ctrl = new CreateCruise();
        ctrl.cruise.RecordTypeId = rt.Id;
        ctrl.cruise.AccountName__c = account.Id;
        ctrl.isClassic = true;
        ctrl.save();
        Test.stopTest();
    }

    @isTest static void test_CreateCruise_2() {
        Boats__c boat = new Boats__c(Name='TestBoat');
        insert boat;
        String start = '14:00 22/03/2018';
		String endd  = '16:00 22/03/2018';
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='Cruise__c' AND Name='Club'];
        Account account = new Account(Name='TestAccount');
        insert account;

        Test.startTest();
        PageReference pRef;
        pRef = Page.CreateCruise;
        Map<String, String> param = pRef.getParameters();
        param.put('boatId', boat.Id);
        param.put('start', start);
        param.put('end', endd);
        Test.setCurrentPage(pRef);
        CreateCruise ctrl = new CreateCruise();
        ctrl.cruise.RecordTypeId = rt.Id;
        ctrl.cruise.AccountName__c = account.Id;
        ctrl.isClassic = false;
        ctrl.save();
        Test.stopTest();
    }

}