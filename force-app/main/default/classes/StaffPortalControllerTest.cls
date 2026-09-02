@isTest
private class StaffPortalControllerTest {
    
    @testSetup
    static void setup() {
        Boats__c b = new Boats__c(Name = 'Test Boat', Active__c = true, BoatsSchedulerOrder__c = 1);
        insert b;
        
        Employee__c emp = new Employee__c(Name = 'Test Guide', Employee_Email__c = 'guide@test.com', Employee_Phone__c = '1234567890');
        insert emp;
        
        Account acc = new Account(Name = 'Test Account', Phone = '1234', Email__c = 'testacc@test.com');
        insert acc;
        
        Transaction__c sub = new Transaction__c(
            Name = 'Test Transaction',
            Account_Name__c = acc.Id,
            Date_of_Transaction__c = System.today(),
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(30),
            type_of_membership__c = 'חבר מועדון כולל פרטיות'
        );
        insert sub;
        
        RecordType nonClubRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Cruise__c' AND DeveloperName != 'Club' LIMIT 1];
        
        Cruise__c c = new Cruise__c(
            RecordTypeId = nonClubRT.Id,
            Boat__c = b.Id,
            Guide__c = emp.Id,
            AccountName__c = acc.Id,
            Transaction__c = sub.Id,
            Start_Date__c = DateTime.now().addHours(1),
            End_Date__c = DateTime.now().addHours(2),
            Status__c = 'Approved'
        );
        insert c;
        
        Co_Cruise_Members__c ccm = new Co_Cruise_Members__c(
            Cruise__c = c.Id,
            Account_Co__c = acc.Id
        );
        insert ccm;
    }
    
    @isTest
    static void testGetDailyCruises() {
        Test.startTest();
        List<Cruise__c> cruises = StaffPortalController.getDailyCruises(Date.today());
        Test.stopTest();
        
        System.assertNotEquals(0, cruises.size());
    }
    
    @isTest
    static void testGetGuideCruises() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        
        Test.startTest();
        List<Cruise__c> cruises = StaffPortalController.getGuideCruises(emp.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, cruises.size());
    }
    
    @isTest
    static void testGetCruiseParticipants() {
        Cruise__c c = [SELECT Id FROM Cruise__c LIMIT 1];
        
        Test.startTest();
        List<Co_Cruise_Members__c> members = StaffPortalController.getCruiseParticipants(c.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, members.size());
    }
    
    @isTest
    static void testGetActiveBoats() {
        Test.startTest();
        List<Boats__c> boats = StaffPortalController.getActiveBoats();
        Test.stopTest();
        
        System.assertNotEquals(0, boats.size());
    }
}
