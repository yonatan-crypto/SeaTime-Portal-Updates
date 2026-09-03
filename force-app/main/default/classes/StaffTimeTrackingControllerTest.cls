@isTest
private class StaffTimeTrackingControllerTest {

    @isTest
    static void testMonthlyReportAndEntries() {
        // Create test Employee
        Employee__c emp = new Employee__c(
            Name = 'מדריך בדיקה',
            Employee_Phone__c = '0501234567',
            Employee_Email__c = 'instructor@example.com',
            Employee_Type__c = 'שעתי',
            Travel_Cost__c = 25,
            Rate_Instruction__c = 70,
            Rate_Dock_Duty__c = 50,
            Rate_Maintenance__c = 50,
            Rate_General__c = 70
        );
        insert emp;

        // Create test Boat
        Boats__c boat = new Boats__c(Name = 'ספינת מבחן', Active__c = true, BoatsSchedulerOrder__c = 1);
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

        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Cruise__c' LIMIT 1];

        // Create test Cruises for a past month so they have already occurred
        Integer testYear = 2025;
        Integer testMonth = 6;
        Date testDate = Date.newInstance(testYear, testMonth, 10);
        DateTime dtStart = DateTime.newInstance(testDate, Time.newInstance(9, 0, 0, 0));
        DateTime dtEnd = DateTime.newInstance(testDate, Time.newInstance(13, 0, 0, 0));

        Cruise__c c1 = new Cruise__c(
            RecordTypeId = rt.Id,
            Boat__c = boat.Id,
            Guide__c = emp.Id,
            AccountName__c = acc.Id,
            Transaction__c = sub.Id,
            Start_Date__c = dtStart,
            End_Date__c = dtEnd,
            Status__c = 'Approved'
        );
        insert c1;

        // Test Dock Duty cruise
        Cruise__c c2 = new Cruise__c(
            RecordTypeId = rt.Id,
            Boat__c = boat.Id,
            Guide__c = emp.Id,
            AccountName__c = acc.Id,
            Transaction__c = sub.Id,
            Start_Date__c = dtStart.addDays(1),
            End_Date__c = dtEnd.addDays(1),
            Status__c = 'Approved',
            Dock_Duty__c = true
        );
        insert c2;

        // Also create a FUTURE cruise in current month to verify it is NOT included
        Cruise__c cFuture = new Cruise__c(
            RecordTypeId = rt.Id,
            Boat__c = boat.Id,
            Guide__c = emp.Id,
            AccountName__c = acc.Id,
            Transaction__c = sub.Id,
            Start_Date__c = DateTime.now().addDays(10),
            End_Date__c = DateTime.now().addDays(10).addHours(3),
            Status__c = 'Approved'
        );
        insert cFuture;

        Test.startTest();
        StaffTimeTrackingController.MonthlySummary summary = StaffTimeTrackingController.getMonthlyReport(
            emp.Id, testYear, testMonth
        );
        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assertEquals(2, summary.entries.size(), 'Should only include the 2 performed cruises');

        // Test accountant report
        List<StaffTimeTrackingController.AccountantReportRow> accountantRows = StaffTimeTrackingController.getAccountantMonthlyReport(testYear, testMonth);
        System.assertNotEquals(0, accountantRows.size(), 'Should have accountant rows for test month');

        // Test Save manual entry
        Time_Entry__c manualEntry = new Time_Entry__c(
            Employee__c = emp.Id,
            Work_Date__c = testDate,
            Start_Time__c = '14:00',
            End_Time__c = '18:00',
            Entry_Type__c = 'תחזוקה',
            Description__c = 'תחזוקת ציוד'
        );
        Time_Entry__c saved = StaffTimeTrackingController.saveTimeEntry(manualEntry);
        System.assertNotEquals(null, saved.Id, 'Saved entry should have Id');

        // Test Delete entry
        Boolean deleted = StaffTimeTrackingController.deleteTimeEntry(saved.Id);
        System.assertEquals(true, deleted, 'Entry should be deleted');
        Test.stopTest();
    }

    @isTest
    static void testMonthlySalaryEmployee() {
        Employee__c emp = new Employee__c(
            Name = 'עובד חודשי',
            Employee_Phone__c = '0507654321',
            Employee_Email__c = 'monthly@example.com',
            Employee_Type__c = 'חודשי',
            Monthly_Salary__c = 8500,
            Travel_Cost__c = 25
        );
        insert emp;

        Test.startTest();
        StaffTimeTrackingController.MonthlySummary summary = StaffTimeTrackingController.getMonthlyReport(
            emp.Id, 2025, 6
        );
        System.assertNotEquals(null, summary);

        // Test Accountant Report
        List<StaffTimeTrackingController.AccountantReportRow> reportRows = StaffTimeTrackingController.getAccountantMonthlyReport(
            2025, 6
        );
        System.assertNotEquals(null, reportRows);
        Test.stopTest();
    }
}
