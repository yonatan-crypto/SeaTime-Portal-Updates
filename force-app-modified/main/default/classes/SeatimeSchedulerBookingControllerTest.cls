@isTest
public class SeatimeSchedulerBookingControllerTest {
  @isTest
  static void testSeaTimeSchedulerBookingWithAllCriteriaTrue() {
    try {
      Account testAccount = new Account();
      testAccount.Name = 'Test Account';
      testAccount.Phone = '1234567890';
      testAccount.Email__c = 'abc@gmail.com';
      testAccount.Student7Meter__c = true;
      testAccount.StudentMeshit30__c = false;

      insert testAccount;
      system.debug('accountid:::' + testAccount.id);

      Transaction__c transactionInstance = new Transaction__c();
      transactionInstance.Name = 'Test Transatcion';
      transactionInstance.Start_Date__c = Date.today();
      transactionInstance.End_Date__c = Date.today() + 1;
      transactionInstance.Account_Name__c = testAccount.Id;
      transactionInstance.Date_of_Transaction__c = Date.today();
      transactionInstance.Total_Points__c = 45;
      transactionInstance.Used_Points__c = 5;

      transactionInstance.type_of_membership__c = 'חבר מועדון כולל פרטיות';
    insert transactionInstance;
      system.debug('Transaction:::' + transactionInstance.Id);

      Boats__c boatInstance = new Boats__c();
      boatInstance.Name = 'Test Boat';
      boatInstance.Active__c = true;
      boatInstance.License_Number__c = 234;
      boatInstance.Type__c = 'sailboat';
      boatInstance.Max_Passenger__c = 40;

      insert boatInstance;

      Id recordTypeIdSailEnriching = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Enriching')
        .getRecordTypeId();

      system.debug(
        'recordTypeIdSailEnriching:::: ' + recordTypeIdSailEnriching
      );

      Cruise__c sailInstance1 = new Cruise__c();
      sailInstance1.RecordTypeId = recordTypeIdSailEnriching;
      sailInstance1.Transaction__c = transactionInstance.Id;
      sailInstance1.Boat__c = boatInstance.Id;
      sailInstance1.Start_Date__c = date.today();
      sailInstance1.End_Date__c = Date.today() + 1;
      sailInstance1.Status__c = 'Approved';
      sailInstance1.Additional_Info__c = 'Hello';
      sailInstance1.SCCount__c = 5;

      insert sailInstance1;

      Id recordTypeIdSailFriend = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Friends')
        .getRecordTypeId();

      Cruise__c sailInstance2 = new Cruise__c();
      sailInstance2.RecordTypeId = recordTypeIdSailFriend;
      sailInstance2.Transaction__c = transactionInstance.Id;
      sailInstance2.Boat__c = boatInstance.Id;
      sailInstance2.Start_Date__c = date.today();
      sailInstance2.End_Date__c = Date.today() + 1;
      sailInstance2.Status__c = 'Approved';
      sailInstance2.SCCount__c = 5;

      insert sailInstance2;
      system.debug('sailInstance2:::' + sailInstance2.Id);

      Id recordTypeIdSailCourse = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Course')
        .getRecordTypeId();

      Cruise__c sailInstance3 = new Cruise__c();
      sailInstance3.RecordTypeId = recordTypeIdSailCourse;
      sailInstance3.Transaction__c = transactionInstance.Id;
      sailInstance3.Boat__c = boatInstance.Id;
      sailInstance3.Start_Date__c = date.today();
      sailInstance3.End_Date__c = Date.today() + 1;
      sailInstance3.Status__c = 'Approved';
      sailInstance3.SCCount__c = 5;
      sailInstance3.Course_Type__c = 'קורס 7 מטר';

      insert sailInstance3;
      system.debug('sailInstance3:::' + sailInstance3);

      Id recordTypeIdSailCertification = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Certification')
        .getRecordTypeId();

      Cruise__c sailInstance4 = new Cruise__c();
      sailInstance4.RecordTypeId = recordTypeIdSailCertification;
      sailInstance4.Transaction__c = transactionInstance.Id;
      sailInstance4.Boat__c = boatInstance.Id;
      sailInstance4.Start_Date__c = date.today();
      sailInstance4.End_Date__c = Date.today() + 1;
      sailInstance4.Status__c = 'Approved';
      sailInstance4.SCCount__c = 5;

      insert sailInstance4;
      system.debug('sailInstance4:::' + sailInstance4);

      Test.startTest();

      SeatimeSchedulerBookingController.WrapperController wrappedObj = SeatimeSchedulerBookingController.seaTimeSchedulerBooking(
        testAccount.id
      );
      Test.stopTest();

      Assert.areEqual(
        4,
        wrappedObj.innerWrp.size(),
        'The innerWrp obj should have 4 sail object records'
      );
    } catch (Exception e) {
      system.debug('Message in Test Class::' + e.getMessage());
      system.debug('Line Number in Test Class::' + e.getLineNumber());
    }
  }

  @isTest
  static void testSeaTimeSchedulerBookingWithStudent7MeterFalse() {
    try {
      Account testAccount = new Account();
      testAccount.Name = 'Test Account';
      testAccount.Phone = '1234567890';
      testAccount.Email__c = 'abc@gmail.com';
      testAccount.Student7Meter__c = false;
      testAccount.StudentMeshit30__c = false;

      insert testAccount;
      system.debug('accountid:::' + testAccount.id);

      Transaction__c transactionInstance = new Transaction__c();
      transactionInstance.Name = 'Test Transatcion';
      transactionInstance.Start_Date__c = Date.today();
      transactionInstance.End_Date__c = Date.today() + 1;
      transactionInstance.Account_Name__c = testAccount.Id;
      transactionInstance.Date_of_Transaction__c = Date.today();
      transactionInstance.Total_Points__c = 45;
      transactionInstance.Used_Points__c = 0;

      transactionInstance.type_of_membership__c = 'חבר מועדון כולל פרטיות';
    insert transactionInstance;
      system.debug('Transaction:::' + transactionInstance.Id);

      Boats__c boatInstance = new Boats__c();
      boatInstance.Name = 'Test Boat';
      boatInstance.Active__c = true;
      boatInstance.License_Number__c = 234;
      boatInstance.Type__c = 'sailboat';
      boatInstance.Max_Passenger__c = 40;

      insert boatInstance;

      Id recordTypeIdSailEnriching = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Enriching')
        .getRecordTypeId();

      system.debug(
        'recordTypeIdSailEnriching:::: ' + recordTypeIdSailEnriching
      );

      Cruise__c sailInstance1 = new Cruise__c();
      sailInstance1.RecordTypeId = recordTypeIdSailEnriching;
      sailInstance1.Transaction__c = transactionInstance.Id;
      sailInstance1.Boat__c = boatInstance.Id;
      sailInstance1.Start_Date__c = date.today();
      sailInstance1.End_Date__c = Date.today() + 1;
      sailInstance1.Status__c = 'Approved';
      sailInstance1.Additional_Info__c = 'Hello';
      sailInstance1.SCCount__c = 5;

      insert sailInstance1;

      Id recordTypeIdSailFriend = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Friends')
        .getRecordTypeId();

      Cruise__c sailInstance2 = new Cruise__c();
      sailInstance2.RecordTypeId = recordTypeIdSailFriend;
      sailInstance2.Transaction__c = transactionInstance.Id;
      sailInstance2.Boat__c = boatInstance.Id;
      sailInstance2.Start_Date__c = date.today();
      sailInstance2.End_Date__c = Date.today() + 1;
      sailInstance2.Status__c = 'Approved';
      sailInstance2.SCCount__c = 5;

      insert sailInstance2;
      system.debug('sailInstance2:::' + sailInstance2.Id);

      Id recordTypeIdSailCourse = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Course')
        .getRecordTypeId();

      Cruise__c sailInstance3 = new Cruise__c();
      sailInstance3.RecordTypeId = recordTypeIdSailCourse;
      sailInstance3.Transaction__c = transactionInstance.Id;
      sailInstance3.Boat__c = boatInstance.Id;
      sailInstance3.Start_Date__c = date.today();
      sailInstance3.End_Date__c = Date.today() + 1;
      sailInstance3.Status__c = 'Approved';
      sailInstance3.SCCount__c = 5;
      sailInstance3.Course_Type__c = 'קורס 7 מטר';

      insert sailInstance3;
      system.debug('sailInstance3:::' + sailInstance3);

      Id recordTypeIdSailCertification = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Certification')
        .getRecordTypeId();

      Cruise__c sailInstance4 = new Cruise__c();
      sailInstance4.RecordTypeId = recordTypeIdSailCertification;
      sailInstance4.Transaction__c = transactionInstance.Id;
      sailInstance4.Boat__c = boatInstance.Id;
      sailInstance4.Start_Date__c = date.today();
      sailInstance4.End_Date__c = Date.today() + 1;
      sailInstance4.Status__c = 'Approved';
      sailInstance4.SCCount__c = 5;

      insert sailInstance4;
      system.debug('sailInstance4:::' + sailInstance4);

      Test.startTest();

      SeatimeSchedulerBookingController.WrapperController wrappedObj = SeatimeSchedulerBookingController.seaTimeSchedulerBooking(
        testAccount.id
      );
      Test.stopTest();

      Assert.areEqual(
        3,
        wrappedObj.innerWrp.size(),
        'The innerWrp obj should have 3 sail object records'
      );
    } catch (Exception e) {
      system.debug('Message in Test Class::' + e.getMessage());
      system.debug('Line Number in Test Class::' + e.getLineNumber());
    }
  }
  @isTest
  static void testSeaTimeSchedulerBookingWithStudent7MeterTrue() {
    try {
      Account testAccount = new Account();
      testAccount.Name = 'Test Account';
      testAccount.Phone = '1234567890';
      testAccount.Email__c = 'abc@gmail.com';
      testAccount.Student7Meter__c = true;
      testAccount.StudentMeshit30__c = false;

      insert testAccount;
      system.debug('accountid:::' + testAccount.id);

      Transaction__c transactionInstance = new Transaction__c();
      transactionInstance.Name = 'Test Transatcion';
      transactionInstance.Start_Date__c = Date.today();
      transactionInstance.End_Date__c = Date.today() + 1;
      transactionInstance.Account_Name__c = testAccount.Id;
      transactionInstance.Date_of_Transaction__c = Date.today();
      transactionInstance.Total_Points__c = 45;
      transactionInstance.Used_Points__c = 40;

      transactionInstance.type_of_membership__c = 'חבר מועדון כולל פרטיות';
    insert transactionInstance;
      system.debug('Transaction:::' + transactionInstance.Id);

      Boats__c boatInstance = new Boats__c();
      boatInstance.Name = 'Test Boat';
      boatInstance.Active__c = true;
      boatInstance.License_Number__c = 234;
      boatInstance.Type__c = 'sailboat';
      boatInstance.Max_Passenger__c = 40;

      insert boatInstance;

      Id recordTypeIdSailEnriching = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Enriching')
        .getRecordTypeId();

      system.debug(
        'recordTypeIdSailEnriching:::: ' + recordTypeIdSailEnriching
      );

      Cruise__c sailInstance1 = new Cruise__c();
      sailInstance1.RecordTypeId = recordTypeIdSailEnriching;
      sailInstance1.Transaction__c = transactionInstance.Id;
      sailInstance1.Boat__c = boatInstance.Id;
      sailInstance1.Start_Date__c = date.today();
      sailInstance1.End_Date__c = Date.today() + 1;
      sailInstance1.Status__c = 'Approved';
      sailInstance1.Additional_Info__c = 'Hello';
      sailInstance1.SCCount__c = 5;

      insert sailInstance1;

      Id recordTypeIdSailFriend = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Friends')
        .getRecordTypeId();

      Cruise__c sailInstance2 = new Cruise__c();
      sailInstance2.RecordTypeId = recordTypeIdSailFriend;
      sailInstance2.Transaction__c = transactionInstance.Id;
      sailInstance2.Boat__c = boatInstance.Id;
      sailInstance2.Start_Date__c = date.today();
      sailInstance2.End_Date__c = Date.today() + 1;
      sailInstance2.Status__c = 'Approved';
      sailInstance2.SCCount__c = 5;

      insert sailInstance2;
      system.debug('sailInstance2:::' + sailInstance2.Id);

      Id recordTypeIdSailCourse = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Course')
        .getRecordTypeId();

      Cruise__c sailInstance3 = new Cruise__c();
      sailInstance3.RecordTypeId = recordTypeIdSailCourse;
      sailInstance3.Transaction__c = transactionInstance.Id;
      sailInstance3.Boat__c = boatInstance.Id;
      sailInstance3.Start_Date__c = date.today();
      sailInstance3.End_Date__c = Date.today() + 1;
      sailInstance3.Status__c = 'Approved';
      sailInstance3.SCCount__c = 5;
      sailInstance3.Course_Type__c = 'קורס 7 מטר';

      insert sailInstance3;
      system.debug('sailInstance3:::' + sailInstance3);

      Id recordTypeIdSailCertification = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Certification')
        .getRecordTypeId();

      Cruise__c sailInstance4 = new Cruise__c();
      sailInstance4.RecordTypeId = recordTypeIdSailCertification;
      sailInstance4.Transaction__c = transactionInstance.Id;
      sailInstance4.Boat__c = boatInstance.Id;
      sailInstance4.Start_Date__c = date.today();
      sailInstance4.End_Date__c = Date.today() + 1;
      sailInstance4.Status__c = 'Approved';
      sailInstance4.SCCount__c = 5;

      insert sailInstance4;
      system.debug('sailInstance4:::' + sailInstance4);

      Test.startTest();

      SeatimeSchedulerBookingController.WrapperController wrappedObj = SeatimeSchedulerBookingController.seaTimeSchedulerBooking(
        testAccount.id
      );
      Test.stopTest();

      Assert.areEqual(
        1,
        wrappedObj.innerWrp.size(),
        'The innerWrp obj should have 1 sail object records'
      );
    } catch (Exception e) {
      system.debug('Message in Test Class::' + e.getMessage());
      system.debug('Line Number in Test Class::' + e.getLineNumber());
    }
  }

  @isTest
  static void testSeaTimeSchedulerBookingWithTxnPointsLessThanThirty() {
    try {
      Account testAccount = new Account();
      testAccount.Name = 'Test Account';
      testAccount.Phone = '1234567890';
      testAccount.Email__c = 'abc@gmail.com';
      testAccount.Student7Meter__c = true;
      testAccount.StudentMeshit30__c = false;

      insert testAccount;
      system.debug('accountid:::' + testAccount.id);

      Transaction__c transactionInstance = new Transaction__c();
      transactionInstance.Name = 'Test Transatcion';
      transactionInstance.Start_Date__c = Date.today();
      transactionInstance.End_Date__c = Date.today() + 1;
      transactionInstance.Account_Name__c = testAccount.Id;
      transactionInstance.Date_of_Transaction__c = Date.today();
      transactionInstance.Total_Points__c = 45;
      transactionInstance.Used_Points__c = 40;

      transactionInstance.type_of_membership__c = 'חבר מועדון כולל פרטיות';
    insert transactionInstance;
      system.debug('Transaction:::' + transactionInstance.Id);

      Boats__c boatInstance = new Boats__c();
      boatInstance.Name = 'Test Boat';
      boatInstance.Active__c = true;
      boatInstance.License_Number__c = 234;
      boatInstance.Type__c = 'sailboat';
      boatInstance.Max_Passenger__c = 40;

      insert boatInstance;

      Id recordTypeIdSailEnriching = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Enriching')
        .getRecordTypeId();

      system.debug(
        'recordTypeIdSailEnriching:::: ' + recordTypeIdSailEnriching
      );

      Cruise__c sailInstance1 = new Cruise__c();
      sailInstance1.RecordTypeId = recordTypeIdSailEnriching;
      sailInstance1.Transaction__c = transactionInstance.Id;
      sailInstance1.Boat__c = boatInstance.Id;
      sailInstance1.Start_Date__c = date.today();
      sailInstance1.End_Date__c = Date.today() + 1;
      sailInstance1.Status__c = 'Approved';
      sailInstance1.Additional_Info__c = 'Hello';
      sailInstance1.SCCount__c = 5;

      insert sailInstance1;

      Id recordTypeIdSailFriend = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Friends')
        .getRecordTypeId();

      Cruise__c sailInstance2 = new Cruise__c();
      sailInstance2.RecordTypeId = recordTypeIdSailFriend;
      sailInstance2.Transaction__c = transactionInstance.Id;
      sailInstance2.Boat__c = boatInstance.Id;
      sailInstance2.Start_Date__c = date.today();
      sailInstance2.End_Date__c = Date.today() + 1;
      sailInstance2.Status__c = 'Approved';
      sailInstance2.SCCount__c = 5;

      insert sailInstance2;
      system.debug('sailInstance2:::' + sailInstance2.Id);

      Id recordTypeIdSailCourse = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Course')
        .getRecordTypeId();

      Cruise__c sailInstance3 = new Cruise__c();
      sailInstance3.RecordTypeId = recordTypeIdSailCourse;
      sailInstance3.Transaction__c = transactionInstance.Id;
      sailInstance3.Boat__c = boatInstance.Id;
      sailInstance3.Start_Date__c = date.today();
      sailInstance3.End_Date__c = Date.today() + 1;
      sailInstance3.Status__c = 'Approved';
      sailInstance3.SCCount__c = 5;
      sailInstance3.Course_Type__c = 'קורס 7 מטר';

      insert sailInstance3;
      system.debug('sailInstance3:::' + sailInstance3);

      Id recordTypeIdSailCertification = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Certification')
        .getRecordTypeId();

      Cruise__c sailInstance4 = new Cruise__c();
      sailInstance4.RecordTypeId = recordTypeIdSailCertification;
      sailInstance4.Transaction__c = transactionInstance.Id;
      sailInstance4.Boat__c = boatInstance.Id;
      sailInstance4.Start_Date__c = date.today();
      sailInstance4.End_Date__c = Date.today() + 1;
      sailInstance4.Status__c = 'Approved';
      sailInstance4.SCCount__c = 5;

      insert sailInstance4;
      system.debug('sailInstance4:::' + sailInstance4);

      Test.startTest();

      SeatimeSchedulerBookingController.WrapperController wrappedObj = SeatimeSchedulerBookingController.seaTimeSchedulerBooking(
        testAccount.id
      );
      Test.stopTest();

      Assert.areEqual(
        1,
        wrappedObj.innerWrp.size(),
        'The innerWrp obj should have 1 sail object records'
      );
    } catch (Exception e) {
      system.debug('Message in Test Class::' + e.getMessage());
      system.debug('Line Number in Test Class::' + e.getLineNumber());
    }
  }

  @isTest
  static void testSeaTimeSchedulerBookingWithStudentMeshit30True() {
    try {
      Account testAccount = new Account();
      testAccount.Name = 'Test Account';
      testAccount.Phone = '1234567890';
      testAccount.Email__c = 'abc@gmail.com';
      testAccount.Student7Meter__c = true;
      testAccount.StudentMeshit30__c = true;

      insert testAccount;
      system.debug('accountid:::' + testAccount.id);

      Transaction__c transactionInstance = new Transaction__c();
      transactionInstance.Name = 'Test Transatcion';
      transactionInstance.Start_Date__c = Date.today();
      transactionInstance.End_Date__c = Date.today() + 1;
      transactionInstance.Account_Name__c = testAccount.Id;
      transactionInstance.Date_of_Transaction__c = Date.today();
      transactionInstance.Total_Points__c = 45;
      transactionInstance.Used_Points__c = 40;

      transactionInstance.type_of_membership__c = 'חבר מועדון כולל פרטיות';
    insert transactionInstance;
      system.debug('Transaction:::' + transactionInstance.Id);

      Boats__c boatInstance = new Boats__c();
      boatInstance.Name = 'Test Boat';
      boatInstance.Active__c = true;
      boatInstance.License_Number__c = 234;
      boatInstance.Type__c = 'sailboat';
      boatInstance.Max_Passenger__c = 40;

      insert boatInstance;

      Id recordTypeIdSailEnriching = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Enriching')
        .getRecordTypeId();

      system.debug(
        'recordTypeIdSailEnriching:::: ' + recordTypeIdSailEnriching
      );

      Cruise__c sailInstance1 = new Cruise__c();
      sailInstance1.RecordTypeId = recordTypeIdSailEnriching;
      sailInstance1.Transaction__c = transactionInstance.Id;
      sailInstance1.Boat__c = boatInstance.Id;
      sailInstance1.Start_Date__c = date.today();
      sailInstance1.End_Date__c = Date.today() + 1;
      sailInstance1.Status__c = 'Approved';
      sailInstance1.Additional_Info__c = 'Hello';
      sailInstance1.SCCount__c = 5;

      insert sailInstance1;

      Id recordTypeIdSailFriend = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Friends')
        .getRecordTypeId();

      Cruise__c sailInstance2 = new Cruise__c();
      sailInstance2.RecordTypeId = recordTypeIdSailFriend;
      sailInstance2.Transaction__c = transactionInstance.Id;
      sailInstance2.Boat__c = boatInstance.Id;
      sailInstance2.Start_Date__c = date.today();
      sailInstance2.End_Date__c = Date.today() + 1;
      sailInstance2.Status__c = 'Approved';
      sailInstance2.SCCount__c = 5;

      insert sailInstance2;
      system.debug('sailInstance2:::' + sailInstance2.Id);

      Id recordTypeIdSailCourse = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Course')
        .getRecordTypeId();

      Cruise__c sailInstance3 = new Cruise__c();
      sailInstance3.RecordTypeId = recordTypeIdSailCourse;
      sailInstance3.Transaction__c = transactionInstance.Id;
      sailInstance3.Boat__c = boatInstance.Id;
      sailInstance3.Start_Date__c = date.today();
      sailInstance3.End_Date__c = Date.today() + 1;
      sailInstance3.Status__c = 'Approved';
      sailInstance3.SCCount__c = 5;
      sailInstance3.Course_Type__c = 'קורס 7 מטר';

      insert sailInstance3;
      system.debug('sailInstance3:::' + sailInstance3);

      Id recordTypeIdSailCertification = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Certification')
        .getRecordTypeId();

      Cruise__c sailInstance4 = new Cruise__c();
      sailInstance4.RecordTypeId = recordTypeIdSailCertification;
      sailInstance4.Transaction__c = transactionInstance.Id;
      sailInstance4.Boat__c = boatInstance.Id;
      sailInstance4.Start_Date__c = date.today();
      sailInstance4.End_Date__c = Date.today() + 1;
      sailInstance4.Status__c = 'Approved';
      sailInstance4.SCCount__c = 5;

      insert sailInstance4;
      system.debug('sailInstance4:::' + sailInstance4);

      Test.startTest();

      SeatimeSchedulerBookingController.WrapperController wrappedObj = SeatimeSchedulerBookingController.seaTimeSchedulerBooking(
        testAccount.id
      );
      Test.stopTest();

      Assert.areEqual(
        3,
        wrappedObj.innerWrp.size(),
        'The innerWrp obj should have 3 sail object records'
      );
    } catch (Exception e) {
      system.debug('Message in Test Class::' + e.getMessage());
      system.debug('Line Number in Test Class::' + e.getLineNumber());
    }
  }

  @isTest
  static void testSeaTimeSchedulerBookingWithAllCriteriaFalse() {
    try {
      Account testAccount = new Account();
      testAccount.Name = 'Test Account';
      testAccount.Phone = '1234567890';
      testAccount.Email__c = 'abc@gmail.com';
      testAccount.Student7Meter__c = false;
      testAccount.StudentMeshit30__c = false;

      insert testAccount;
      system.debug('accountid:::' + testAccount.id);

      Transaction__c transactionInstance = new Transaction__c();
      transactionInstance.Name = 'Test Transatcion';
      transactionInstance.Start_Date__c = Date.today();
      transactionInstance.End_Date__c = Date.today() + 1;
      transactionInstance.Account_Name__c = testAccount.Id;
      transactionInstance.Date_of_Transaction__c = Date.today();
      transactionInstance.Total_Points__c = 45;
      transactionInstance.Used_Points__c = 40;

      transactionInstance.type_of_membership__c = 'חבר מועדון כולל פרטיות';
    insert transactionInstance;
      system.debug('Transaction:::' + transactionInstance.Id);

      Boats__c boatInstance = new Boats__c();
      boatInstance.Name = 'Test Boat';
      boatInstance.Active__c = true;
      boatInstance.License_Number__c = 234;
      boatInstance.Type__c = 'sailboat';
      boatInstance.Max_Passenger__c = 40;

      insert boatInstance;

      Id recordTypeIdSailEnriching = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Enriching')
        .getRecordTypeId();

      system.debug(
        'recordTypeIdSailEnriching:::: ' + recordTypeIdSailEnriching
      );

      Cruise__c sailInstance1 = new Cruise__c();
      sailInstance1.RecordTypeId = recordTypeIdSailEnriching;
      sailInstance1.Transaction__c = transactionInstance.Id;
      sailInstance1.Boat__c = boatInstance.Id;
      sailInstance1.Start_Date__c = date.today();
      sailInstance1.End_Date__c = Date.today() + 1;
      sailInstance1.Status__c = 'Approved';
      sailInstance1.Additional_Info__c = 'Hello';
      sailInstance1.SCCount__c = 5;

      insert sailInstance1;

      Id recordTypeIdSailFriend = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Friends')
        .getRecordTypeId();

      Cruise__c sailInstance2 = new Cruise__c();
      sailInstance2.RecordTypeId = recordTypeIdSailFriend;
      sailInstance2.Transaction__c = transactionInstance.Id;
      sailInstance2.Boat__c = boatInstance.Id;
      sailInstance2.Start_Date__c = date.today();
      sailInstance2.End_Date__c = Date.today() + 1;
      sailInstance2.Status__c = 'Approved';
      sailInstance2.SCCount__c = 5;

      insert sailInstance2;
      system.debug('sailInstance2:::' + sailInstance2.Id);

      Id recordTypeIdSailCourse = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Course')
        .getRecordTypeId();

      Cruise__c sailInstance3 = new Cruise__c();
      sailInstance3.RecordTypeId = recordTypeIdSailCourse;
      sailInstance3.Transaction__c = transactionInstance.Id;
      sailInstance3.Boat__c = boatInstance.Id;
      sailInstance3.Start_Date__c = date.today();
      sailInstance3.End_Date__c = Date.today() + 1;
      sailInstance3.Status__c = 'Approved';
      sailInstance3.SCCount__c = 5;
      sailInstance3.Course_Type__c = 'קורס 7 מטר';

      insert sailInstance3;
      system.debug('sailInstance3:::' + sailInstance3);

      Id recordTypeIdSailCertification = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
        .get('Certification')
        .getRecordTypeId();

      Cruise__c sailInstance4 = new Cruise__c();
      sailInstance4.RecordTypeId = recordTypeIdSailCertification;
      sailInstance4.Transaction__c = transactionInstance.Id;
      sailInstance4.Boat__c = boatInstance.Id;
      sailInstance4.Start_Date__c = date.today();
      sailInstance4.End_Date__c = Date.today() + 1;
      sailInstance4.Status__c = 'Approved';
      sailInstance4.SCCount__c = 5;

      insert sailInstance4;
      system.debug('sailInstance4:::' + sailInstance4);

      Test.startTest();

      SeatimeSchedulerBookingController.WrapperController wrappedObj = SeatimeSchedulerBookingController.seaTimeSchedulerBooking(
        testAccount.id
      );
      Test.stopTest();

      Assert.areEqual(
        0,
        wrappedObj.innerWrp.size(),
        'The innerWrp obj should have 0 sail object records'
      );
    } catch (Exception e) {
      system.debug('Message in Test Class::' + e.getMessage());
      system.debug('Line Number in Test Class::' + e.getLineNumber());
    }
  }

  @isTest
  static void testInsertSubCustomers() {
    Account testAccount = new Account();
    testAccount.Name = 'Test Account';
    testAccount.Phone = '1234567890';
    testAccount.Email__c = 'abc@gmail.com';

    insert testAccount;

    Transaction__c transactionInstance = new Transaction__c();
    transactionInstance.Name = 'Test Transatcion';
    transactionInstance.Start_Date__c = Date.today();
    transactionInstance.End_Date__c = Date.today() + 1;
    transactionInstance.Account_Name__c = testAccount.Id;
    transactionInstance.Date_of_Transaction__c = Date.today();
    transactionInstance.Total_Points__c = 45;
    transactionInstance.Used_Points__c = 5;

    transactionInstance.type_of_membership__c = 'חבר מועדון כולל פרטיות';
    insert transactionInstance;

    Boats__c boatInstance = new Boats__c();
    boatInstance.Name = 'Test Boat';
    boatInstance.Active__c = true;
    boatInstance.License_Number__c = 234;
    boatInstance.Type__c = 'sailboat';
    boatInstance.Max_Passenger__c = 40;

    insert boatInstance;

    Id recordTypeIdSailEnriching = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName()
      .get('Enriching')
      .getRecordTypeId();

    Cruise__c sailInstance = new Cruise__c();
    sailInstance.RecordTypeId = recordTypeIdSailEnriching;
    sailInstance.Transaction__c = transactionInstance.Id;
    sailInstance.type_of_enriching__c = 'מועדון';
    sailInstance.Boat__c = boatInstance.Id;
    sailInstance.Start_Date__c = date.today();
    sailInstance.End_Date__c = Date.today() + 1;
    sailInstance.Status__c = 'Approved';
    sailInstance.Additional_Info__c = 'Hello';
    sailInstance.SCCount__c = 5;

    insert sailInstance;

    Test.startTest();
    SeatimeSchedulerBookingController.WrapperController wrappedObj = SeatimeSchedulerBookingController.seaTimeSchedulerBooking(
      testAccount.Id
    );
    SeatimeSchedulerBookingController.insertSubCustomers(
      sailInstance.Id,
      wrappedObj.innerWrp[0].sailStartMonthYear,
      (String) testAccount.Id
    );
    Test.stopTest();

    List<Co_Cruise_Members__c> ccm = [
      SELECT Id, Account_Co__c, Cruise__c
      FROM Co_Cruise_Members__c
      WHERE Account_Co__c = :testAccount.Id
      WITH SYSTEM_MODE
    ];

    Assert.areEqual(
      1,
      ccm.size(),
      'There should be one Co_Cruise_Members__c record'
    );

    Assert.areEqual(
      testAccount.Id,
      ccm[0].Account_Co__c,
      'Account of Co_Cruise_Members__c record is not correct'
    );

    Assert.areEqual(
      sailInstance.Id,
      ccm[0].Cruise__c,
      'The sail for Co_Cruise_Members__c is not correct'
    );
  }
}