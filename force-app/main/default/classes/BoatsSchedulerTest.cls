@isTest
private class BoatsSchedulerTest {

    @isTest static void test_BoatsSchedulerService_1() {
        Test.startTest();
        PageReference pRef;
        pRef = Page.BoatsSchedulerService;
        Map<String, String> param = pRef.getParameters();
        param.put('loadResources', '');
        Test.setCurrentPage(pRef);
        BoatsSchedulerService ctrl = new BoatsSchedulerService();
        ctrl.action();
        Test.stopTest();
    }

    @isTest static void test_BoatsSchedulerService_2() {
        Test.startTest();
        PageReference pRef;
        pRef = Page.BoatsSchedulerService;
        Map<String, String> param = pRef.getParameters();
        param.put('loadEvents', '');
        param.put('start', '2018-03-22');
        param.put('end', '2018-03-23');
        Test.setCurrentPage(pRef);
        BoatsSchedulerService ctrl = new BoatsSchedulerService();
        ctrl.action();
        Test.stopTest();
    }

    @isTest static void test_BoatsSchedulerService_3() {
        Boats__c boat = new Boats__c(Name='TestBoat');
        insert boat;
        Account account = new Account(Name='TestAccount');
        insert account;
        Transaction__c trans = new Transaction__c(Account_Name__c=account.Id, Date_of_Transaction__c = Date.newInstance(2023, 9, 4), type_of_membership__c = 'חבר מועדון כולל פרטיות');
        insert trans;
        Cruise__c cruise = new Cruise__c(Boat__c=boat.Id, AccountName__c=account.Id, Transaction__c=trans.Id, Start_Date__c=Datetime.now(), End_Date__c=Datetime.now());
        insert cruise;

        Test.startTest();
        PageReference pRef;
        pRef = Page.BoatsSchedulerService;
        Map<String, String> param = pRef.getParameters();
        param.put('updateEvent', '');
        param.put('id', cruise.Id);
        param.put('start', '2018-03-22 14:00:00');
        param.put('end', '2018-03-23 16:00:00');
        Test.setCurrentPage(pRef);
        BoatsSchedulerService ctrl = new BoatsSchedulerService();
        ctrl.action();
        Test.stopTest();
    }

}