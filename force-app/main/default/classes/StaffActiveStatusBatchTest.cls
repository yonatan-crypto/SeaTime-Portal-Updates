@isTest
private class StaffActiveStatusBatchTest {

    @isTest
    static void testBatchAndSchedule() {
        Employee__c empActive = new Employee__c(
            Name = 'מדריך פעיל בדיקה',
            Employee_Email__c = 'active_test@sea-time.co.il',
            Employee_Phone__c = '0501111111',
            Active__c = false
        );
        Employee__c empInactive = new Employee__c(
            Name = 'מדריך לא פעיל בדיקה',
            Employee_Email__c = 'inactive_test@sea-time.co.il',
            Employee_Phone__c = '0502222222',
            Active__c = true
        );
        insert new List<Employee__c>{ empActive, empInactive };

        Boats__c boat = new Boats__c(Name = 'סירת בדיקה', Active__c = true, BoatsSchedulerOrder__c = 1);
        insert boat;

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

        // Create cruise within last 30 days for empActive
        Cruise__c c = new Cruise__c(
            RecordTypeId = nonClubRT.Id,
            Guide__c = empActive.Id,
            Boat__c = boat.Id,
            AccountName__c = acc.Id,
            Transaction__c = sub.Id,
            Start_Date__c = DateTime.now().addDays(-10),
            End_Date__c = DateTime.now().addDays(-10).addHours(3),
            Status__c = 'Approved'
        );
        insert c;

        Test.startTest();
        StaffActiveStatusBatch.runNow();
        StaffActiveStatusBatch.scheduleDaily();
        Database.executeBatch(new StaffActiveStatusBatch());
        Test.stopTest();

        Employee__c updatedActive = [SELECT Id, Active__c FROM Employee__c WHERE Id = :empActive.Id];
        Employee__c updatedInactive = [SELECT Id, Active__c FROM Employee__c WHERE Id = :empInactive.Id];

        System.assertEquals(true, updatedActive.Active__c, 'Employee with recent cruise should be active');
        System.assertEquals(false, updatedInactive.Active__c, 'Employee without recent cruise should be inactive');
    }
}
