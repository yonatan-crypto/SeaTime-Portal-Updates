@IsTest 
public with sharing class SeatimeSchedulerWebappControllerTest {
	
	static testMethod void testController() {
		//PREPARE DATA
		Account acc = new Account();
		acc.Name = 'hadar test';
		acc.First_Name__c = 'hadar';
		acc.Last_Name__c = 'test';
		acc.Phone = '0549234443';
		acc.Email__c = 'hadartest@gmail.com';
		acc.Account_Status__c = 'Club Member';
		acc.Interest__c = 'Basic Course';	
        acc.Login_Token__c = '123456789';
		insert acc;
		
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
		  
		Transaction__c tran = new Transaction__c();
		tran.Name = 'Alon';
		tran.Account_Name__c = acc.Id;
		tran.Type__c = 'Sailboat';
		Date today = System.today();
		tran.Date_of_Transaction__c = today.addDays(-30);
		tran.Start_Date__c = today.addDays(-20);
		tran.End_Date__c = today.addDays(10);
		tran.Subscripption_Type__c = 'Bank Hours';
		tran.Total_Hours__c = 20;
		tran.weekday__c = 2;
		tran.weekend__c = 3;
		tran.type_of_membership__c = 'חבר מועדון כולל פרטיות';
		insert tran;
		
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
		//insert tran2;
		
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
	
		//TEST	
		System.debug('crList: '+crList);
		SeatimeSchedulerWebappController ctrl = new SeatimeSchedulerWebappController();
        ctrl.getSchedulerMdtStatusSetting();
        Boolean isSandbox = ctrl.isSandbox;
        String currentUserLocale = ctrl.currentUserLocale;
        String currentUserType = ctrl.currentUserType;
        String orgBoats = ctrl.orgBoats;
        String orgCruiseRecordTypes = ctrl.orgCruiseRecordTypes;
        String orgAccounts = ctrl.orgAccounts;
        SeatimeSchedulerWebappController.getOrgBoats();
        SeatimeSchedulerWebappController.getOrgAccounts();
        SeatimeSchedulerWebappController.SecureAccount securAcc = SeatimeSchedulerWebappController.getSecureAccount(acc.Login_Token__c);
        SeatimeSchedulerWebappController.getAccountBoats(securAcc);
        SeatimeSchedulerWebappController.getCruisesForScheduler(securAcc, System.today().addDays(1));
        SeatimeSchedulerWebappController.getOrgCruises();
        SeatimeSchedulerWebappController.getEmployeeClassroomEvents();
        SeatimeSchedulerWebappController.getCruiseHistory(securAcc);
        SeatimeSchedulerWebappController.getPersonalDetails(securAcc);
        
        String cruise1Json = JSON.serialize(cruise1);
		SeatimeSchedulerWebappController.saveCruiseEvent(cruise1Json);
        String cruiseErrorJson = '{"attributes":{"type":"Cruise__c"},"AccountName__c":"'+acc.Id+'","Status__c":"Awaiting for Approval","Start_Date__c":"2017-10-24T10:00:00.000+0000","End_Date__c":"2017-10-24T14:00:00.000+0000","Start_Time":"19:00:00.000","End_time":"20:00:00.000"}';
		SeatimeSchedulerWebappController.saveCruiseEvent(cruiseErrorJson);
		String cruiseExceptionJson = '{"attributes":{"type":"Cruise__c"},"Start_Date__c":"+cruise2.Start_Date__c+","End_Date__c":"+cruise2.End_Date__c+","Start_Time":"19:00:00.000","End_time":"20:00:00.000"}';
		SeatimeSchedulerWebappController.saveCruiseEvent(cruiseExceptionJson);
		cruise2.Start_Date__c = cruise2.Start_Date__c.addMinutes(20);
		cruise2.End_Date__c = cruise2.End_Date__c.addMinutes(20);
		String cruiseExceptionJson3 = JSON.serialize(cruise2);
		SeatimeSchedulerWebappController.saveCruiseEvent(cruiseExceptionJson3);
		
		String accountJson = JSON.serialize(acc);
		SeatimeSchedulerWebappController.updatePersonalDetails(accountJson, securAcc);
		SeatimeSchedulerWebappController.updatePersonalDetails('{"attributes":{"type":"Account"},"Name":"hadar error"}', securAcc);
    
	}
}