/**
 * Created by Nabhan on 1/1/2021.
 */

@IsTest
private class TEST_BulkSMSController {
    @testSetup
    static void dataInit() {
        Account acc = new Account();
        acc.Name = 'testAcc';
        acc.First_Name__c = 'testLast';
        acc.Last_Name__c = 'test';
        acc.Phone = '0549234443';
        acc.Email__c = 'test@gmail.com';
        acc.Account_Status__c = 'Club Member';
        acc.Interest__c = 'Basic Course';
        insert acc;

        Boats__c boat1 = new Boats__c();
        boat1.Name = 'מיתוס';
        boat1.License_Number__c = 222222;
        boat1.Type__c = 'Sailboat';
        boat1.Max_Passenger__c = 12;
        boat1.Docking__c = 'Wharf';
        boat1.Active__c = true;
        insert boat1;

        Certification__c cer = new Certification__c();
        cer.Boat__c = boat1.Id;
        cer.Account_Name__c = acc.Id;
        insert cer;

        Transaction__c tran = new Transaction__c();
        tran.Name = 'Alon';
        tran.Account_Name__c = acc.Id;
        tran.Type__c = 'Sailboat';
        Date today = System.today();
        tran.Date_of_Transaction__c = today.addDays(1);
        tran.Start_Date__c = today.addDays(1);
        tran.End_Date__c = today.addDays(10);
        tran.Subscripption_Type__c = 'Bank Hours';
        tran.Total_Hours__c = 20;
        tran.weekday__c = 2;
        tran.weekend__c = 3;
        tran.RecordTypeid = [select id from RecordType Where Name='נקודות' limit 1].id;
        tran.type_of_membership__c = 'חבר מועדון כולל פרטיות';
        insert tran;

        /*---------------------- T.A -----------------------*/
        PriceList__c pl = new PriceList__c();
        pl.name='teszed';
        pl.Start_Date__c = System.Today();
        pl.Price__c=50;
        pl.Type__c = 'מבצע';
        insert pl;
        String btid = [select id from Boats__c where Active__c=true limit 1].id;
        PriceListLine__c pls = new PriceListLine__c();
        pls.PriceList__c=pl.id;
        pls.Type__c='Club';
        pls.Boat__c=btid;
        pls.StartText__c='10:00';
        pls.Price__c=40;
        Pls.HPrice__c=45;
        insert pls;
        pls.StartText__c='11:00';
        update pls;

        PriceList__c pl2 = new PriceList__c();
        pl2.name='teszed2';
        pl2.Start_Date__c = System.Today().AddDays(-5);
        pl2.Price__c=50;
        pl2.Type__c = 'רגיל';
        insert pl2;
        String btid2 = [select id from Boats__c where Active__c=true limit 1].id;
        PriceListLine__c pls2 = new PriceListLine__c();
        pls2.PriceList__c=pl2.id;
        pls2.Type__c='Club';
        pls2.Boat__c=btid;
        pls2.StartText__c='10:00';
        pls2.Price__c=40;
        Pls2.HPrice__c=45;
        insert pls2;
        pls2.StartText__c='11:00';
        update pls2;

        Boats__c boat2 = new Boats__c();
        boat2.Name = 'אננדה';
        boat2.License_Number__c = 222222;
        boat2.Type__c = 'Sailboat';
        boat2.Max_Passenger__c = 12;
        boat2.Docking__c = 'Wharf';
        insert boat2;

        courses__c testCourses = new courses__c(date__c = Date.today().addDays(1), SMS_Message__c = 'Test Message');
        insert testCourses;

        Partecipant__c testPartecipant = new Partecipant__c(course__c = testCourses.Id, Partecipant__c = acc.Id);
        insert testPartecipant;

        Cruise__c cruise1 = new Cruise__c();
        RecordType clubRecordType = [SELECT Id,Name,DeveloperName FROM RecordType WHERE DeveloperName =: 'Club' LIMIT 1];
        cruise1.RecordTypeId = clubRecordType.Id;
        cruise1.AccountName__c = acc.Id;
        cruise1.Transaction__c = tran.Id;
        cruise1.Boat__c = boat2.Id;
        cruise1.Cruise_Type__c = 'Club';
        cruise1.Status__c = 'Approved';
        cruise1.SMS_Message__c = 'Test Message';
        Date crDate = System.today().addDays(1);
        cruise1.Start_Date__c = Datetime.newInstance(crDate.year(), crDate.month(), crDate.day(), 13, 00, 00);
        cruise1.End_Date__c = Datetime.newInstance(crDate.year(), crDate.month(), crDate.day(), 17, 00, 00);

        insert cruise1;

        Co_Cruise_Members__c testCoCruiseMember = new Co_Cruise_Members__c(Cruise__c = cruise1.Id, Account_Co__c = acc.Id);
        insert testCoCruiseMember;
    }

    @isTest
    static void testSendCourseSMS() {
        List<courses__c> courseList = [SELECT Id FROM courses__c];
        Test.startTest();
        Boolean result = BulkSMSController.sendSMSToCourseMembers(courseList[0].Id);
        System.debug(result);
        Test.stopTest();
    }

    @isTest
    static void testSendCruiseSMS() {
        List<Cruise__c> cruiseList = [SELECT Id FROM Cruise__c];
        Test.startTest();
        Boolean result = BulkSMSController.sendSMSToCruiseMembers(cruiseList[0].Id);
        System.debug(result);
        Test.stopTest();
    }
}