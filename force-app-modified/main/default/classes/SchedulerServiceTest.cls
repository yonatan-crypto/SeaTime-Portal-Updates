@isTest(seealldata=true)
private class SchedulerServiceTest {
	static testMethod void createSchedulerTest() {
        
        Account acc = new Account();
        acc.Name = 'hadar test';
        acc.Login_Token__c = '123456789';
        insert acc;
        
        SchedulerService ss = new SchedulerService();
        Transaction__c tran = ss.createTransaction(null, acc.Id);
        
        List<Cruise__c> existingCruiseList = new List<Cruise__c>();
        List<Cruise__c> cList = new List<Cruise__c>();
        
        Cruise__c cruiseItem = new Cruise__c();
        cruiseItem.Start_Date__c = Datetime.newInstance(2017, 10, 16, 08, 00, 00);
        cruiseItem.End_Date__c = Datetime.newInstance(2017, 10, 16, 11, 00, 00);
        
        Cruise__c cruiseItem2 = new Cruise__c();
        cruiseItem2.Start_Date__c = Datetime.newInstance(2017, 10, 16, 13, 00, 00);
        cruiseItem2.End_Date__c = Datetime.newInstance(2017, 10, 16, 18, 00, 00);
        
        Cruise__c cruiseItem3 = new Cruise__c();
        cruiseItem3.Start_Date__c = Datetime.newInstance(2017, 10, 16, 19, 00, 00);
        cruiseItem3.End_Date__c = Datetime.newInstance(2017, 10, 16, 20, 00, 00);
        
        Cruise__c cruiseItem4 = new Cruise__c();
        cruiseItem4.Start_Date__c = Datetime.newInstance(2017, 10, 16, 21, 00, 00);
        cruiseItem4.End_Date__c = Datetime.newInstance(2017, 10, 16, 23, 00, 00);
        
        existingCruiseList.add(cruiseItem);
        existingCruiseList.add(cruiseItem2);
        existingCruiseList.add(cruiseItem3);
        existingCruiseList.add(cruiseItem4);
        
        SeatimeSchedulerWebappController.SecureAccount securAcc = SeatimeSchedulerWebappController.getSecureAccount(acc.Login_Token__c);
        Map<Id,Boats__c> idBoatsObjMap = SeatimeSchedulerWebappController.getAccountBoats(securAcc);
        Test.startTest();
 /* -----------------------------------------------------------------------------*/
        Boats__c boat1 = new Boats__c();
		boat1.Name = 'מיתוס';
		boat1.License_Number__c = 222222; 
		boat1.Type__c = 'Sailboat'; 
		boat1.Max_Passenger__c = 12; 
		boat1.Docking__c = 'Wharf'; 
		insert boat1;
        Certification__c cer = new Certification__c();
		cer.Boat__c = boat1.Id;
		cer.Account_Name__c = acc.Id;
		insert cer;
		  
				Date today = System.today();
		
		Transaction__c tran2 = new Transaction__c();
		tran2.Name = 'Alon'; //
		tran2.Account_Name__c = acc.Id;
		tran2.Type__c = 'Sailboat'; //
		Date todaytran2 = System.today();
		tran2.Date_of_Transaction__c = today.addDays(-30);
		tran2.Start_Date__c = today.addDays(-20);
		tran2.End_Date__c = today.addDays(10);
		tran2.Subscripption_Type__c = 'Bank Hours';
		tran2.Total_Hours__c = 20;
		tran2.weekday__c = 2;
		tran2.weekend__c = 3;
		tran2.type_of_membership__c = 'חבר מועדון כולל פרטיות';
		insert tran2;
		
		Event event = new Event();
		event.Is_Locked__c = true;
		event.Origin__c = 'Employee';
		event.DurationInMinutes = 30;
		event.ActivityDateTime = System.now();
		insert event;
		
		Event event2 = new Event();
		event2.Is_Locked__c = true;
		event2.Origin__c = 'Classroom';
		event2.DurationInMinutes = 30;
		event2.ActivityDateTime = System.now();
		insert event2;
        		Cruise__c cruise1 = new Cruise__c();
		cruise1.AccountName__c = acc.Id;
		cruise1.Transaction__c = tran.Id;
		cruise1.Boat__c = boat1.Id; 
		RecordType recordTypeClub = [SELECT Id,Name,DeveloperName FROM RecordType WHERE Name = 'Club'];
		cruise1.RecordTypeId = recordTypeClub.Id; 
		cruise1.Status__c = 'Awaiting for Approval'; 
		Date crDate = System.today().addDays(1);
		cruise1.Start_Date__c = Datetime.newInstance(crDate.year(), crDate.month(), crDate.day(), 13, 00, 00);
		cruise1.End_Date__c = Datetime.newInstance(crDate.year(), crDate.month(), crDate.day(), 17, 00, 00);
		
		Cruise__c cruise2 = new Cruise__c();
		cruise2.AccountName__c = acc.Id;
		cruise2.Transaction__c = tran.Id;
		cruise2.Boat__c = boat1.Id; 
		cruise2.Status__c = 'Approved';
		crDate = System.today().addDays(1);
		cruise2.Start_Date__c = Datetime.newInstance(crDate.year(), crDate.month(), crDate.day(), 11, 00, 00);
		cruise2.End_Date__c = Datetime.newInstance(crDate.year(), crDate.month(), crDate.day(), 12, 00, 00);

        List<Cruise__c> crList = new List<Cruise__c>{cruise1, cruise2};
            try{
			insert crList;	  
			}catch(DmlException e) {
				 System.debug('An unexpected error has occurred: ' + e.getMessage());
			}	 
            /*--------------------------------------------------*/
       //t.a Test.startTest();
        SchedulerService service = new SchedulerService(acc.Id, 2, idBoatsObjMap, System.today());
		List<Customer_Setting__mdt> settingsList = [SELECT Id, 
                                                           Label, 
                                                           Start_time__c, 
                                                           End_time__c
                                            		FROM Customer_Setting__mdt];
        Set <SchedulerService.Slot> slts = new Set <SchedulerService.Slot>();
        for(Customer_Setting__mdt s:settingsList)   slts.add(service.stringToSlot(s));
        service.setTimeSlots(slts,existingCruiseList, null, Datetime.newInstance(2017, 10, 16, 00, 00, 00));
        service.prepareScheduler();
        service.getEmployeeClassroomEvents();
        Test.stopTest();
		
    }
}